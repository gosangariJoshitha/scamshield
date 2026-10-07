import logging
import os
import threading

from app.services.analysis_notifications import (
    process_pending_analysis_notifications,
    recover_interrupted_notifications,
)


logger = logging.getLogger(__name__)


class NotificationWorker:
    def __init__(self) -> None:
        self.poll_seconds = max(2, int(os.getenv("NOTIFICATION_POLL_SECONDS", "10")))
        self._stop_event = threading.Event()
        self._thread: threading.Thread | None = None

    def start(self) -> None:
        if os.getenv("NOTIFICATION_WORKER_ENABLED", "true").lower() != "true":
            return
        if self._thread is not None and self._thread.is_alive():
            return
        self._stop_event.clear()
        self._thread = threading.Thread(
            target=self._run,
            name="scamshield-notification-worker",
            daemon=True,
        )
        self._thread.start()

    def stop(self) -> None:
        self._stop_event.set()
        if self._thread is not None:
            self._thread.join(timeout=self.poll_seconds + 2)
            self._thread = None

    def _run(self) -> None:
        recovered = False
        while not self._stop_event.is_set():
            try:
                if not recovered:
                    recover_interrupted_notifications()
                    recovered = True
                process_pending_analysis_notifications()
            except Exception:
                logger.exception("Notification outbox polling failed.")
            self._stop_event.wait(self.poll_seconds)


notification_worker = NotificationWorker()
