import logging
import os
from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from auth import get_current_user
import database
import models
import schemas

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/emergency-contacts", tags=["emergency-contacts"])


def send_sms_alert(phone_number: str, message: str) -> bool:
    """
    Sends an SMS alert via Twilio if configured in environment,
    or logs simulated SMS delivery for development/testing.
    """
    twilio_sid = os.getenv("TWILIO_ACCOUNT_SID")
    twilio_token = os.getenv("TWILIO_AUTH_TOKEN")
    twilio_from = os.getenv("TWILIO_PHONE_NUMBER")

    if twilio_sid and twilio_token and twilio_from:
        try:
            from twilio.rest import Client
            client = Client(twilio_sid, twilio_token)
            client.messages.create(
                body=message,
                from_=twilio_from,
                to=phone_number,
            )
            logger.info("Twilio SMS successfully dispatched to %s", phone_number)
            return True
        except Exception as exc:
            logger.error("Failed to send Twilio SMS to %s: %s", phone_number, exc)
            return False
    else:
        logger.info("[SIMULATED SMS] To: %s | Message: %s", phone_number, message)
        return True


def dispatch_emergency_family_alerts(
    user_id: int,
    db: Session,
    session_id: str,
    risk_score: int,
    detected_category: str,
) -> int:
    """
    Dispatches SMS alerts to all active emergency contacts for a given user
    and logs an in-app emergency notification.
    """
    contacts = (
        db.query(models.EmergencyContact)
        .filter(
            models.EmergencyContact.user_id == user_id,
            models.EmergencyContact.is_active == True,  # noqa: E712
            models.EmergencyContact.notify_sms == True,  # noqa: E712
        )
        .all()
    )

    if not contacts:
        return 0

    user = db.query(models.User).filter(models.User.id == user_id).first()
    user_name = user.full_name or user.email if user else "your family member"

    alert_body = (
        f"[ScamShield Urgent] High-risk scam call detected ({risk_score}/100 - {detected_category}) "
        f"for {user_name}. Advise them not to share OTPs, passwords, or initiate fund transfers."
    )

    sent_count = 0
    for contact in contacts:
        if send_sms_alert(contact.phone_number, alert_body):
            sent_count += 1

    try:
        notification = models.Notification(
            user_id=user_id,
            type="EMERGENCY_ALERT",
            title="Emergency Family Alert Dispatched",
            message=(
                f"Emergency alert dispatched to {len(contacts)} contact(s) "
                f"for high-risk call (Session: {session_id[:8]}..., Risk: {risk_score}%)."
            ),
            is_read=False,
        )
        db.add(notification)
        db.commit()
    except Exception as exc:
        db.rollback()
        logger.error("Failed to save emergency alert notification: %s", exc)

    return sent_count


@router.get("", response_model=List[schemas.EmergencyContactResponse])
@router.get("/", response_model=List[schemas.EmergencyContactResponse])
def get_emergency_contacts(
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(database.get_db),
):
    """
    Retrieve all emergency contacts configured by the authenticated user.
    """
    contacts = (
        db.query(models.EmergencyContact)
        .filter(models.EmergencyContact.user_id == current_user.id)
        .order_by(models.EmergencyContact.created_at.asc())
        .all()
    )
    return contacts


@router.post("", response_model=schemas.EmergencyContactResponse, status_code=status.HTTP_201_CREATED)
@router.post("/", response_model=schemas.EmergencyContactResponse, status_code=status.HTTP_201_CREATED)
def create_emergency_contact(
    payload: schemas.EmergencyContactCreate,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(database.get_db),
):
    """
    Add a new emergency contact (enforces a maximum of 3 contacts).
    """
    current_count = (
        db.query(models.EmergencyContact)
        .filter(models.EmergencyContact.user_id == current_user.id)
        .count()
    )
    if current_count >= 3:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Maximum limit of 3 emergency contacts reached.",
        )

    contact = models.EmergencyContact(
        user_id=current_user.id,
        name=payload.name.strip(),
        phone_number=payload.phone_number.strip(),
        relationship_type=payload.relationship_type.strip() if payload.relationship_type else "Family",
        notify_sms=payload.notify_sms,
        is_active=True,
    )
    db.add(contact)
    db.commit()
    db.refresh(contact)
    return contact


@router.put("/{contact_id}", response_model=schemas.EmergencyContactResponse)
@router.patch("/{contact_id}", response_model=schemas.EmergencyContactResponse)
def update_emergency_contact(
    contact_id: int,
    payload: schemas.EmergencyContactUpdate,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(database.get_db),
):
    """
    Update details or notification preferences of an emergency contact.
    """
    contact = (
        db.query(models.EmergencyContact)
        .filter(
            models.EmergencyContact.id == contact_id,
            models.EmergencyContact.user_id == current_user.id,
        )
        .first()
    )
    if not contact:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Emergency contact not found.",
        )

    if payload.name is not None:
        contact.name = payload.name.strip()
    if payload.phone_number is not None:
        contact.phone_number = payload.phone_number.strip()
    if payload.relationship_type is not None:
        contact.relationship_type = payload.relationship_type.strip()
    if payload.is_active is not None:
        contact.is_active = payload.is_active
    if payload.notify_sms is not None:
        contact.notify_sms = payload.notify_sms

    db.commit()
    db.refresh(contact)
    return contact


@router.delete("/{contact_id}", status_code=status.HTTP_200_OK)
def delete_emergency_contact(
    contact_id: int,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(database.get_db),
):
    """
    Delete an emergency contact.
    """
    contact = (
        db.query(models.EmergencyContact)
        .filter(
            models.EmergencyContact.id == contact_id,
            models.EmergencyContact.user_id == current_user.id,
        )
        .first()
    )
    if not contact:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Emergency contact not found.",
        )

    db.delete(contact)
    db.commit()
    return {"status": "deleted", "id": contact_id}


@router.post("/alert", response_model=schemas.EmergencyAlertResponse)
def dispatch_alert_endpoint(
    payload: schemas.EmergencyAlertRequest,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(database.get_db),
):
    """
    Explicitly trigger an emergency family alert for an active call or test alert.
    Dispatches SMS to configured active contacts when risk >= 70 or for test alerts.
    """
    contacts = (
        db.query(models.EmergencyContact)
        .filter(
            models.EmergencyContact.user_id == current_user.id,
            models.EmergencyContact.is_active == True,  # noqa: E712
            models.EmergencyContact.notify_sms == True,  # noqa: E712
        )
        .all()
    )

    if not contacts:
        return schemas.EmergencyAlertResponse(
            status="no_contacts_configured",
            dispatched_count=0,
            recipients=[],
        )

    sent_count = dispatch_emergency_family_alerts(
        user_id=current_user.id,
        db=db,
        session_id=payload.session_id,
        risk_score=payload.risk_score,
        detected_category=payload.detected_category,
    )

    return schemas.EmergencyAlertResponse(
        status="dispatched" if sent_count > 0 else "delivery_failed",
        dispatched_count=sent_count,
        recipients=[c.phone_number for c in contacts],
    )

