import unittest

from fastapi import FastAPI
from fastapi.testclient import TestClient
from sqlalchemy import create_engine, text
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool

import database
import models
from analysis import router as analysis_router
from auth import get_password_hash, router as auth_router
from community import router as community_router


class AuthRoleBoundaryTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.engine = create_engine(
            "sqlite://",
            connect_args={"check_same_thread": False},
            poolclass=StaticPool,
        )
        models.Base.metadata.create_all(bind=cls.engine)
        cls.test_session = sessionmaker(
            bind=cls.engine,
            autocommit=False,
            autoflush=False,
        )

    @classmethod
    def tearDownClass(cls):
        models.Base.metadata.drop_all(bind=cls.engine)
        cls.engine.dispose()

    def setUp(self):
        with self.test_session() as db:
            db.query(models.User).delete()
            db.add_all(
                [
                    models.User(
                        full_name="Test Admin",
                        email="admin@example.com",
                        password_hash=get_password_hash("Test-Admin-Password-2026"),
                        role="admin",
                        is_active=True,
                    ),
                    models.User(
                        full_name="Test User",
                        email="user@example.com",
                        password_hash=get_password_hash("Test-User-Password-2026"),
                        role="user",
                        is_active=True,
                    ),
                    models.User(
                        full_name="Disabled Admin",
                        email="disabled@example.com",
                        password_hash=get_password_hash("Test-Disabled-Password-2026"),
                        role="admin",
                        is_active=False,
                    ),
                ]
            )
            db.commit()

        def override_get_db():
            with self.test_session() as db:
                yield db

        app = FastAPI()
        app.include_router(auth_router, prefix="/api")
        app.include_router(analysis_router, prefix="/api")
        app.include_router(community_router, prefix="/api")
        app.dependency_overrides[database.get_db] = override_get_db
        self.client = TestClient(app)
        self.client.__enter__()

    def tearDown(self):
        self.client.__exit__(None, None, None)

    def portal_login(self, portal, email, password):
        path = "/api/auth/admin/login" if portal == "admin" else "/api/auth/login"
        return self.client.post(
            path,
            files={
                "username": (None, email),
                "password": (None, password),
            },
        )

    def test_user_login_rejects_admin_credentials(self):
        response = self.portal_login(
            "user", "admin@example.com", "Test-Admin-Password-2026"
        )
        self.assertEqual(response.status_code, 401)

    def test_admin_login_rejects_user_credentials(self):
        response = self.portal_login(
            "admin", "user@example.com", "Test-User-Password-2026"
        )
        self.assertEqual(response.status_code, 401)

    def test_each_portal_accepts_only_its_own_active_role(self):
        user_response = self.portal_login(
            "user", "USER@example.com", "Test-User-Password-2026"
        )
        admin_response = self.portal_login(
            "admin", "ADMIN@example.com", "Test-Admin-Password-2026"
        )
        disabled_response = self.portal_login(
            "admin", "disabled@example.com", "Test-Disabled-Password-2026"
        )

        self.assertEqual(user_response.status_code, 200)
        self.assertEqual(admin_response.status_code, 200)
        self.assertEqual(disabled_response.status_code, 401)

    def test_user_me_normalizes_legacy_null_preferences(self):
        with self.test_session() as db:
            db.execute(
                text(
                    "UPDATE users SET two_factor_enabled = NULL, "
                    "email_notifications = NULL, community_updates = NULL, "
                    "marketing_updates = NULL WHERE email = :email"
                ),
                {"email": "user@example.com"},
            )
            db.commit()

        response = self.portal_login(
            "user", "user@example.com", "Test-User-Password-2026"
        )
        token = response.json()["access_token"]
        profile = self.client.get(
            "/api/auth/me",
            headers={"Authorization": f"Bearer {token}"},
        )

        self.assertEqual(profile.status_code, 200)
        self.assertEqual(
            {
                key: profile.json()[key]
                for key in (
                    "two_factor_enabled",
                    "email_notifications",
                    "community_updates",
                    "marketing_updates",
                )
            },
            {
                "two_factor_enabled": False,
                "email_notifications": True,
                "community_updates": True,
                "marketing_updates": False,
            },
        )

    def test_admin_token_cannot_use_user_analysis_routes(self):
        response = self.portal_login(
            "admin", "admin@example.com", "Test-Admin-Password-2026"
        )
        token = response.json()["access_token"]
        dashboard = self.client.get(
            "/api/analysis/dashboard",
            headers={"Authorization": f"Bearer {token}"},
        )
        self.assertEqual(dashboard.status_code, 403)

    def test_user_token_can_use_user_analysis_routes(self):
        response = self.portal_login(
            "user", "user@example.com", "Test-User-Password-2026"
        )
        token = response.json()["access_token"]
        dashboard = self.client.get(
            "/api/analysis/dashboard",
            headers={"Authorization": f"Bearer {token}"},
        )
        self.assertEqual(dashboard.status_code, 200)

    def test_signup_normalizes_email_and_rejects_case_insensitive_duplicate(self):
        payload = {
            "full_name": "New Test User",
            "email": "NewUser@example.com",
            "password": "Strong-Pass-2026",
        }
        response = self.client.post("/api/auth/signup", json=payload)
        duplicate = self.client.post(
            "/api/auth/signup",
            json={**payload, "email": "NEWUSER@example.com"},
        )

        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.json()["email"], "newuser@example.com")
        self.assertEqual(response.json()["role"], "user")
        self.assertEqual(duplicate.status_code, 409)

    def test_signup_can_sign_in_and_load_profile(self):
        signup = self.client.post(
            "/api/auth/signup",
            json={
                "full_name": "Signup Flow User",
                "email": "signup-flow@example.com",
                "password": "Strong-Pass-2026",
            },
        )
        login = self.portal_login(
            "user", "signup-flow@example.com", "Strong-Pass-2026"
        )
        profile = self.client.get(
            "/api/auth/me",
            headers={"Authorization": f"Bearer {login.json()['access_token']}"},
        )

        self.assertEqual(signup.status_code, 200)
        self.assertEqual(login.status_code, 200)
        self.assertEqual(profile.status_code, 200)
        self.assertEqual(profile.json()["role"], "user")

    def test_signup_rejects_weak_password(self):
        response = self.client.post(
            "/api/auth/signup",
            json={
                "full_name": "Rejected Test User",
                "email": "rejected@example.com",
                "password": "weakpass",
            },
        )
        self.assertEqual(response.status_code, 422)

    def test_anonymous_community_access_is_rejected(self):
        response = self.client.get("/api/community/reports")
        self.assertEqual(response.status_code, 401)


if __name__ == "__main__":
    unittest.main()
