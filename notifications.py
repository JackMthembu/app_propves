from flask import Blueprint, app, jsonify
from flask_login import current_user
from flask_mail import Mail, Message
from models import Enquiry, Listing, Notification, Property, User
from extensions import db

notifications_routes = Blueprint('notifications_routes', __name__)

# Property Notifications
@notifications_routes.route('/property/<int:property_id>/not_completed', methods=['GET'])
def property_not_completed(property_id):
    property = Property.query.get_or_404(property_id)
    notification = Notification(
        type='warning',
        title='Property Not Completed',
        message=f'Property {property.title} has not been completed. Complete the property details and add a listing.',
        property_id=property_id,
        owner_id=property.owner_id
    )
    db.session.add(notification)
    db.session.commit()
    return jsonify({'message': 'Property not completed'}), 200

#Enquiry Notifications
@notifications_routes.route('/enquiry/<int:enquiry_id>/scheduled', methods=['GET'])
def notify_scheduled_enquiries(enquiry_id):
    enquiry = Enquiry.query.get_or_404(enquiry_id)
    notification = Notification(
        type='info',
        title='Enquiry Scheduled',
        message=f'Enquiry for property {enquiry.property.title} is scheduled.',
        enquiry_id=enquiry_id,
        owner_id=enquiry.owner_id,
        tenant_id=enquiry.tenant_id
    )
    db.session.add(notification)
    db.session.commit()
    return jsonify({'message': 'Enquiry scheduled'}), 200
