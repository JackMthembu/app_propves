from celery_config import Celery
from models import Enquiry, Property, Notification
from extensions import db
from datetime import datetime, timedelta
from time import sleep

celery = Celery(__name__)

@celery.task
def check_incomplete_properties():
    # Get the current time
    now = datetime.utcnow()
    # Define the time threshold (24 hours ago)
    threshold_time = now - timedelta(days=1)

    # Query for properties that are incomplete
    incomplete_properties = Property.query.filter(
        (Property.title.is_(None) | (Property.title == '')) |
        (Property.type.is_(None) | (Property.type == '')) |
        (Property.sqm.is_(None)) |
        (Property.bedroom.is_(None)) |
        (Property.bathroom.is_(None)) |
        (Property.thumbnail.is_(None))
    ).all()

    for property in incomplete_properties:
        # Check if the last notification was sent more than 24 hours ago
        last_notification = Notification.query.filter_by(property_id=property.id).order_by(Notification.timestamp.desc()).first()
        if last_notification is None or last_notification.timestamp < threshold_time:
            # Create a new notification
            notification = Notification(
                type='warning',
                title='Property Not Completed',
                message=f'Property {property.title} has not been completed. Complete the property details and add a listing.',
                property_id=property.id,
                owner_id=property.owner_id
            )
            db.session.add(notification)
            db.session.commit()
            
@celery.task
def notify_scheduled_enquiries():
    # Query for enquiries with status 'Scheduled'
    scheduled_enquiries = Enquiry.query.filter_by(status='Scheduled').all()

    for enquiry in scheduled_enquiries:
        # Create a new notification for each scheduled enquiry
        notification = Notification(
            type='info',
            title='Enquiry Scheduled',
            message=f'Enquiry for property {enquiry.property.title} is scheduled.',
            enquiry_id=enquiry.id,
            owner_id=enquiry.owner_id,
            tenant_id=enquiry.tenant_id
        )
        db.session.add(notification)

    db.session.commit()

@celery.task
def update_enquiry_outcomes():
    enquiries = Enquiry.query.filter(Enquiry.outcomes == 'scheduled').all()
    
    for enquiry in enquiries:
        if datetime.utcnow() > enquiry.scheduled_date + timedelta(hours=24):
            enquiry.outcomes = 'rejected'  # Update outcome to 'rejected'
            db.session.add(enquiry)  # Add the updated enquiry to the session

    db.session.commit()  # Commit the changes to the database


@celery.task
def long_task():
    """Simulate a long-running task"""
    sleep(10)
    return "Task complete!"
