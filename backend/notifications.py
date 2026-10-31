import logging
from typing import Optional
from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.orm import Session

from auth import get_current_user
import database
import models
import schemas

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/notifications", tags=["notifications"])


@router.get("", response_model=schemas.NotificationListResponse)
@router.get("/", response_model=schemas.NotificationListResponse)
def get_user_notifications(
    page: int = Query(default=1, ge=1),
    limit: int = Query(default=20, ge=1, le=100),
    unread_only: bool = Query(default=False),
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(database.get_db),
):
    query = db.query(models.Notification).filter(models.Notification.user_id == current_user.id)
    if unread_only:
        query = query.filter(models.Notification.is_read == False)  # noqa: E712

    total = query.count()
    unread_count = (
        db.query(models.Notification)
        .filter(models.Notification.user_id == current_user.id, models.Notification.is_read == False)  # noqa: E712
        .count()
    )

    offset = (page - 1) * limit
    items = query.order_by(models.Notification.created_at.desc()).offset(offset).limit(limit).all()

    return schemas.NotificationListResponse(
        items=items,
        total=total,
        unread_count=unread_count,
        page=page,
        limit=limit,
        has_next=(offset + limit) < total,
    )


@router.get("/unread-count", response_model=schemas.NotificationUnreadCountResponse)
def get_unread_notification_count(
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(database.get_db),
):
    unread_count = (
        db.query(models.Notification)
        .filter(models.Notification.user_id == current_user.id, models.Notification.is_read == False)  # noqa: E712
        .count()
    )
    return schemas.NotificationUnreadCountResponse(unread_count=unread_count)


@router.post("/{notification_id}/read", response_model=schemas.NotificationResponse)
@router.patch("/{notification_id}/read", response_model=schemas.NotificationResponse)
def mark_notification_read(
    notification_id: int,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(database.get_db),
):
    notification = (
        db.query(models.Notification)
        .filter(models.Notification.id == notification_id, models.Notification.user_id == current_user.id)
        .first()
    )
    if not notification:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Notification not found",
        )

    notification.is_read = True
    db.commit()
    db.refresh(notification)
    return notification


@router.post("/read-all")
def mark_all_notifications_read(
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(database.get_db),
):
    updated = (
        db.query(models.Notification)
        .filter(models.Notification.user_id == current_user.id, models.Notification.is_read == False)  # noqa: E712
        .update({models.Notification.is_read: True}, synchronize_session=False)
    )
    db.commit()
    return {"marked_read": updated}


@router.delete("")
@router.delete("/")
def clear_all_notifications(
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(database.get_db),
):
    deleted = (
        db.query(models.Notification)
        .filter(models.Notification.user_id == current_user.id)
        .delete(synchronize_session=False)
    )
    db.commit()
    return {"deleted": deleted}
