import hashlib
import os
import time
import threading
from collections import defaultdict, deque
from typing import Optional, Tuple
from fastapi import HTTPException, Request, status

class AnalysisRateLimiter:
    """
    Thread-safe in-memory sliding-window rate limiter.
    Limits analysis requests per authenticated user with IP fallback.
    """
    def __init__(
        self,
        default_limit: int = 60,
        default_window_seconds: int = 60,
    ):
        self.default_limit = default_limit
        self.default_window_seconds = default_window_seconds
        self.limit = int(os.getenv("ANALYSIS_RATE_LIMIT_PER_MINUTE", str(self.default_limit)))
        self.window_seconds = int(os.getenv("ANALYSIS_RATE_LIMIT_WINDOW_SECONDS", str(self.default_window_seconds)))
        self._records = defaultdict(deque)
        self._lock = threading.Lock()

    def get_identifier(self, request: Request, user: Optional[object] = None) -> str:
        """
        Derive rate limit identifier from user ID when available,
        falling back to client IP or forwarding headers.
        """
        if user is not None:
            user_id = getattr(user, "id", None)
            if user_id is not None:
                return f"user:{user_id}"
            user_email = getattr(user, "email", None)
            if user_email:
                return f"user:{user_email}"

        forwarded_for = request.headers.get("x-forwarded-for")
        if forwarded_for:
            client_ip = forwarded_for.split(",")[0].strip()
            if client_ip:
                return f"ip:{client_ip}"

        if request.client and request.client.host:
            return f"ip:{request.client.host}"

        return "ip:127.0.0.1"

    def is_allowed(
        self,
        identifier: str,
        limit: Optional[int] = None,
        window_seconds: Optional[int] = None,
    ) -> Tuple[bool, int, int]:
        """
        Check whether an identifier has quota remaining under sliding window.
        Returns: (is_allowed, retry_after_seconds, remaining_requests)
        """
        max_requests = limit if limit is not None else self.limit
        window = window_seconds if window_seconds is not None else self.window_seconds
        now = time.time()
        window_start = now - window

        with self._lock:
            timestamps = self._records[identifier]
            # Prune timestamps outside current sliding window
            while timestamps and timestamps[0] <= window_start:
                timestamps.popleft()

            if len(timestamps) >= max_requests:
                if timestamps:
                    oldest = timestamps[0]
                    retry_after = max(1, int(oldest + window - now))
                else:
                    retry_after = max(1, int(window))
                return False, retry_after, 0

            timestamps.append(now)
            remaining = max_requests - len(timestamps)
            return True, 0, remaining

    def reset(self, identifier: Optional[str] = None) -> None:
        """Reset records for testing or administrative purposes."""
        with self._lock:
            self.limit = int(os.getenv("ANALYSIS_RATE_LIMIT_PER_MINUTE", str(self.default_limit)))
            self.window_seconds = int(os.getenv("ANALYSIS_RATE_LIMIT_WINDOW_SECONDS", str(self.default_window_seconds)))
            if identifier:
                self._records.pop(identifier, None)
            else:
                self._records.clear()


analysis_rate_limiter = AnalysisRateLimiter()


def rate_limit_analysis(
    request: Request,
    current_user: Optional[object] = None,
) -> None:
    """
    FastAPI dependency to enforce rate limiting on analysis ingestion endpoints.
    """
    identifier = analysis_rate_limiter.get_identifier(request, user=current_user)
    allowed, retry_after, _ = analysis_rate_limiter.is_allowed(identifier)
    if not allowed:
        raise HTTPException(
            status_code=status.HTTP_429_TOO_MANY_REQUESTS,
            detail="Rate limit exceeded. Too many analysis requests. Please wait before submitting another request.",
            headers={"Retry-After": str(retry_after)},
        )


class AuthenticationRateLimiter:
    """Apply independent sliding-window limits by source IP and account key."""

    _DEFAULTS = {
        "signup": (5, 900),
        "login": (10, 900),
        "login_verify": (10, 900),
        "forgot_password": (5, 3600),
        "reset_password": (10, 900),
        "resend_verification": (3, 900),
    }

    def __init__(self):
        self.limits = {
            action: (
                int(os.getenv(f"AUTH_{action.upper()}_LIMIT", str(limit))),
                int(os.getenv(f"AUTH_{action.upper()}_WINDOW_SECONDS", str(window))),
            )
            for action, (limit, window) in self._DEFAULTS.items()
        }
        self._records = defaultdict(deque)
        self._lock = threading.Lock()
        self._check_count = 0

    @staticmethod
    def _client_ip(request: Request) -> str:
        if request.client and request.client.host:
            return request.client.host
        return "unknown"

    def check(
        self,
        request: Request,
        action: str,
        account_identifier: str | None = None,
    ) -> tuple[bool, int]:
        if action not in self.limits:
            raise ValueError(f"Unknown authentication rate-limit action: {action}")

        limit, window = self.limits[action]
        keys = [f"{action}:ip:{self._client_ip(request)}"]
        if account_identifier:
            account_hash = hashlib.sha256(
                account_identifier.strip().lower().encode("utf-8")
            ).hexdigest()
            keys.append(f"{action}:account:{account_hash}")

        now = time.time()
        window_start = now - window
        with self._lock:
            self._check_count += 1
            if self._check_count % 256 == 0:
                max_window = max(configured_window for _, configured_window in self.limits.values())
                stale_before = now - max_window
                for stale_key, timestamps in list(self._records.items()):
                    while timestamps and timestamps[0] <= stale_before:
                        timestamps.popleft()
                    if not timestamps:
                        self._records.pop(stale_key, None)
            for key in keys:
                timestamps = self._records[key]
                while timestamps and timestamps[0] <= window_start:
                    timestamps.popleft()

            exhausted = [
                self._records[key][0] + window - now
                for key in keys
                if len(self._records[key]) >= limit
            ]
            if exhausted:
                return False, max(1, int(max(exhausted)))

            for key in keys:
                self._records[key].append(now)
        return True, 0

    def reset(self) -> None:
        with self._lock:
            self._records.clear()
            self._check_count = 0
            self.limits = {
                action: (
                    int(os.getenv(f"AUTH_{action.upper()}_LIMIT", str(limit))),
                    int(os.getenv(f"AUTH_{action.upper()}_WINDOW_SECONDS", str(window))),
                )
                for action, (limit, window) in self._DEFAULTS.items()
            }


authentication_rate_limiter = AuthenticationRateLimiter()


def rate_limit_auth(
    request: Request,
    action: str,
    account_identifier: str | None = None,
) -> None:
    allowed, retry_after = authentication_rate_limiter.check(
        request,
        action,
        account_identifier,
    )
    if not allowed:
        raise HTTPException(
            status_code=status.HTTP_429_TOO_MANY_REQUESTS,
            detail="Too many authentication requests. Please try again later.",
            headers={"Retry-After": str(retry_after)},
        )
