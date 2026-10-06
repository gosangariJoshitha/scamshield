import unittest
from datetime import datetime
from types import SimpleNamespace
from unittest.mock import PropertyMock, patch

from fastapi import FastAPI
from fastapi.testclient import TestClient
from sqlalchemy import create_engine, text
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool

import auth
import database
import models
from app.services.rate_limiter import authentication_rate_limiter
from admin import router as admin_router
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
        authentication_rate_limiter.reset()
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
                        email_verified=True,
                    ),
                    models.User(
                        full_name="Test User",
                        email="user@example.com",
                        password_hash=get_password_hash("Test-User-Password-2026"),
                        role="user",
                        is_active=True,
                        email_verified=True,
                    ),
                    models.User(
                        full_name="Disabled Admin",
                        email="disabled@example.com",
                        password_hash=get_password_hash("Test-Disabled-Password-2026"),
                        role="admin",
                        is_active=False,
                        email_verified=True,
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
        app.include_router(admin_router, prefix="/api/admin")
        app.dependency_overrides[database.get_db] = override_get_db
        self.client = TestClient(app)
        self.client.__enter__()

    def tearDown(self):
        authentication_rate_limiter.reset()
        self.client.__exit__(None, None, None)

    def portal_login(self, portal, email, password, remember_me=False):
        path = "/api/auth/admin/login" if portal == "admin" else "/api/auth/login"
        return self.client.post(
            path,
            files={
                "username": (None, email),
                "password": (None, password),
                "remember_me": (None, str(remember_me).lower()),
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

    def test_repeated_login_attempts_are_rate_limited(self):
        authentication_rate_limiter.limits["login"] = (1, 60)
        first = self.portal_login(
            "user", "user@example.com", "Test-User-Password-2026"
        )
        repeated = self.portal_login(
            "user", "user@example.com", "Test-User-Password-2026"
        )
        self.assertEqual(first.status_code, 200)
        self.assertEqual(repeated.status_code, 429)
        self.assertIn("Retry-After", repeated.headers)
        self.assertEqual(
            repeated.json()["detail"],
            "Too many authentication requests. Please try again later.",
        )

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

    def test_remember_me_extends_the_access_token_lifetime(self):
        response = self.portal_login(
            "user",
            "user@example.com",
            "Test-User-Password-2026",
            remember_me=True,
        )
        self.assertEqual(response.status_code, 200)
        token_payload = auth.jwt.get_unverified_claims(response.json()["access_token"])
        seconds_until_expiry = token_payload["exp"] - int(datetime.utcnow().timestamp())
        self.assertGreater(seconds_until_expiry, auth.REMEMBER_ME_EXPIRE_DAYS * 86400 - 10)

    def test_two_factor_login_requires_a_single_use_email_code(self):
        with (
            patch.object(
                type(auth.email_service),
                "is_configured",
                new_callable=PropertyMock,
                return_value=True,
            ),
            patch.object(auth.email_service, "send_verification_code") as send_email,
        ):
            login = self.portal_login(
                "admin", "admin@example.com", "Test-Admin-Password-2026", remember_me=True
            )
            self.assertEqual(login.status_code, 200)
            self.assertTrue(login.json()["requires_two_factor"])
            self.assertNotIn("access_token", login.json())

            challenge_id = login.json()["challenge_id"]
            code = send_email.call_args.args[1]
            rejected = self.client.post(
                "/api/auth/login/verify",
                json={"challenge_id": challenge_id, "code": "000000" if code != "000000" else "000001"},
            )
            self.assertEqual(rejected.status_code, 400)

            verified = self.client.post(
                "/api/auth/login/verify",
                json={"challenge_id": challenge_id, "code": code, "remember_me": True},
            )
            self.assertEqual(verified.status_code, 200)
            self.assertTrue(verified.json()["access_token"])
            token_payload = auth.jwt.get_unverified_claims(verified.json()["access_token"])
            seconds_until_expiry = token_payload["exp"] - int(datetime.utcnow().timestamp())
            self.assertGreater(seconds_until_expiry, auth.REMEMBER_ME_EXPIRE_DAYS * 86400 - 10)

            reused = self.client.post(
                "/api/auth/login/verify",
                json={"challenge_id": challenge_id, "code": code},
            )
            self.assertEqual(reused.status_code, 400)

    def test_community_reports_return_reporter_and_source_analysis(self):
        with self.test_session() as db:
            user = db.query(models.User).filter_by(email="user@example.com").first()
            analysis = models.Analysis(
                user_id=user.id,
                content="Suspicious message",
                risk_score=75,
                risk_level="HIGH",
                classification="SCAM",
                ml_probability=0.75,
                category="Phishing",
                indicators=[],
                explanation="Suspicious link",
                evidence=[],
                recommended_action="Do not open the link.",
            )
            db.add(analysis)
            db.commit()
            analysis_id = analysis.id
            user_id = user.id

        token = auth.create_access_token(
            {"sub": str(user_id), "email": "user@example.com", "role": "user"},
            expires_delta=auth.timedelta(minutes=5),
        )
        headers = {"Authorization": f"Bearer {token}"}
        created = self.client.post(
            "/api/community/reports",
            headers=headers,
            json={
                "content": "Suspicious message",
                "category": "Phishing",
                "analysis_id": analysis_id,
            },
        )
        self.assertEqual(created.status_code, 200)
        self.assertEqual(created.json()["reporter_name"], "Test User")
        self.assertEqual(created.json()["analysis_id"], analysis_id)

        listed = self.client.get("/api/community/reports", headers=headers)
        self.assertEqual(listed.status_code, 200)
        self.assertEqual(listed.json()[0]["reporter_name"], "Test User")
        self.assertEqual(listed.json()[0]["analysis_id"], analysis_id)

    def test_password_reset_uses_email_code_and_updates_database_password(self):
        with (
            patch.object(
                type(auth.email_service),
                "is_configured",
                new_callable=PropertyMock,
                return_value=True,
            ),
            patch.object(auth.email_service, "send_verification_code") as send_email,
        ):
            requested = self.client.post(
                "/api/auth/forgot-password",
                json={"email": "user@example.com"},
            )
            self.assertEqual(requested.status_code, 200)
            code = send_email.call_args.args[1]
            reset = self.client.post(
                "/api/auth/reset-password",
                json={
                    "challenge_id": requested.json()["challenge_id"],
                    "code": code,
                    "new_password": "Updated-User-Password-2026",
                },
            )
            self.assertEqual(reset.status_code, 200)

        login = self.portal_login(
            "user", "user@example.com", "Updated-User-Password-2026"
        )
        self.assertEqual(login.status_code, 200)

    def test_admin_health_endpoint_returns_measured_checks(self):
        with self.test_session() as db:
            admin = db.query(models.User).filter_by(email="admin@example.com").first()
            admin_id = admin.id
        token = auth.create_access_token(
            {"sub": str(admin_id), "email": "admin@example.com", "role": "admin"},
            expires_delta=auth.timedelta(minutes=15),
        )
        with patch(
            "admin.rag_service",
            SimpleNamespace(collection=SimpleNamespace(count=lambda: 80)),
        ):
            response = self.client.get(
                "/api/admin/health",
                headers={"Authorization": f"Bearer {token}"},
            )

        self.assertEqual(response.status_code, 200)
        health = response.json()
        self.assertEqual(health["database"]["status"], "up")
        self.assertTrue(health["database"]["latency"].endswith("ms"))
        self.assertEqual(health["rag_service"]["status"], "up")
        self.assertIsNotNone(datetime.fromisoformat(health["system_time"]).tzinfo)

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
        with self.test_session() as db:
            admin = db.query(models.User).filter_by(email="admin@example.com").first()
            admin_id = admin.id
        token = auth.create_access_token(
            {"sub": str(admin_id), "email": "admin@example.com", "role": "admin"},
            expires_delta=auth.timedelta(minutes=15),
        )
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

    def test_unverified_user_can_read_portal_but_cannot_analyze(self):
        with self.test_session() as db:
            user = db.query(models.User).filter_by(email="user@example.com").first()
            user.email_verified = False
            db.commit()

        response = self.portal_login(
            "user", "user@example.com", "Test-User-Password-2026"
        )
        self.assertEqual(response.status_code, 200, response.text)
        token = response.json()["access_token"]
        dashboard = self.client.get(
            "/api/analysis/dashboard",
            headers={"Authorization": "Bearer " + token},
        )
        history = self.client.get(
            "/api/analysis/history",
            headers={"Authorization": "Bearer " + token},
        )
        analysis = self.client.post(
            "/api/analysis/text",
            headers={"Authorization": "Bearer " + token},
            json={"content": "Please verify this account"},
        )
        self.assertEqual(dashboard.status_code, 200)
        self.assertEqual(history.status_code, 200)
        self.assertEqual(analysis.status_code, 403)
        self.assertIn("verify your email", analysis.json()["detail"])

    def test_signup_normalizes_email_and_rejects_case_insensitive_duplicate(self):
        payload = {
            "full_name": "New Test User",
            "email": "NewUser@example.com",
            "password": "Strong-Pass-2026",
        }
        with (
            patch.object(
                type(auth.email_service),
                "is_configured",
                new_callable=PropertyMock,
                return_value=True,
            ),
            patch.object(auth.email_service, "send_verification_code"),
        ):
            response = self.client.post("/api/auth/signup", json=payload)
        duplicate = self.client.post(
            "/api/auth/signup",
            json={**payload, "email": "NEWUSER@example.com"},
        )

        self.assertEqual(response.status_code, 200)
        self.assertTrue(response.json()["account_created"])
        self.assertTrue(response.json()["verification_email_sent"])
        self.assertFalse(response.json()["email_verified"])
        self.assertEqual(duplicate.status_code, 409)

    def test_email_verification_unlocks_analysis_routes(self):
        with (
            patch.object(
                type(auth.email_service),
                "is_configured",
                new_callable=PropertyMock,
                return_value=True,
            ),
            patch.object(auth.email_service, "send_verification_code") as send_email,
        ):
            signup = self.client.post(
                "/api/auth/signup",
                json={
                    "full_name": "Verify Me",
                    "email": "verify-me@example.com",
                    "password": "Strong-Pass-2026",
                },
            )

        self.assertEqual(signup.status_code, 200)
        verification = self.client.post(
            "/api/auth/verify-email",
            json={
                "challenge_id": signup.json()["verification_challenge_id"],
                "code": send_email.call_args.args[1],
            },
        )
        self.assertEqual(verification.status_code, 200)

        login = self.portal_login(
            "user", "verify-me@example.com", "Strong-Pass-2026"
        )
        self.assertEqual(login.status_code, 200, login.text)
        token = login.json()["access_token"]
        profile = self.client.get(
            "/api/auth/me",
            headers={"Authorization": "Bearer " + token},
        )
        self.assertEqual(profile.status_code, 200)
        self.assertTrue(profile.json()["email_verified"])

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
