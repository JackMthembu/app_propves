from ast import main
import os
from flask import Blueprint, abort, current_app, flash, redirect, render_template, url_for, request, jsonify
from flask_login import current_user, login_required
from sqlalchemy import func
from models import MaintainanceReport, Property, Listing, RentalAgreement, Transaction, User, db, Message, Owner, BankingDetails
from datetime import datetime, timedelta, date
from sqlalchemy.orm import joinedload
from investment_analyses import oer_analysis

main = Blueprint('main', __name__)

def allowed_file(filename):
    """Check if the file extension is allowed."""
    return '.' in filename and filename.rsplit('.', 1)[1].lower() in {'png', 'jpg', 'jpeg'}

def ensure_upload_folder_exists():
    """Ensure the upload folder exists."""
    if not os.path.exists(current_app.config['UPLOAD_FOLDER_PROFILE']):
        os.makedirs(current_app.config['UPLOAD_FOLDER_PROFILE'])

def active_rental_agreements():
    """Get count of active rental agreements for current user."""
    try:
        return RentalAgreement.query.filter(
            RentalAgreement.status == 'active',
            RentalAgreement.owner.has(user_id=current_user.id)
        ).count()
    except Exception as e:
        current_app.logger.error(f"Error counting active rental agreements: {str(e)}")
        return 0

def pending_rental_agreements():
    """Get count of pending rental agreements for current user."""
    try:
        return RentalAgreement.query.filter(
            RentalAgreement.status == 'pending',
            RentalAgreement.owner.has(user_id=current_user.id)
        ).count()
    except Exception as e:
        current_app.logger.error(f"Error counting pending rental agreements: {str(e)}")
        return 0

def expired_rental_agreements():
    """Get count of expired rental agreements for current user."""
    try:
        return RentalAgreement.query.filter(
            RentalAgreement.status == 'expired',
            RentalAgreement.owner.has(user_id=current_user.id)
        ).count()
    except Exception as e:
        current_app.logger.error(f"Error counting expired rental agreements: {str(e)}")
        return 0

def count_active_maintainance_reports():
    """Get count of active maintenance reports for current user's properties."""
    try:
        return db.session.query(MaintainanceReport).filter(
            MaintainanceReport.status == 'reported',
            MaintainanceReport.property_id.in_(
                db.session.query(Property.id).filter(Property.owner.has(user_id=current_user.id))
            )
        ).count()
    except Exception as e:
        current_app.logger.error(f"Error counting active maintenance reports: {str(e)}")
        return 0

def count_resolved_maintainance_reports():
    """Get count of resolved maintenance reports for current user's properties."""
    try:
        return db.session.query(MaintainanceReport).filter(
            MaintainanceReport.status == 'resolved',
            MaintainanceReport.property_id.in_(
                db.session.query(Property.id).filter(Property.owner.has(user_id=current_user.id))
            )
        ).count()
    except Exception as e:
        current_app.logger.error(f"Error counting resolved maintenance reports: {str(e)}")
        return 0

def get_expenses_summary():
    """Get summary of expenses grouped by sub-category."""
    try:
        expenses_summary = db.session.query(
            Transaction.sub_category,
            func.sum(Transaction.amount).label('total_amount')
        ).filter(
            Transaction.main_category == 'Expenses',
            Transaction.is_reconciled == True,
            Transaction.owner.has(user_id=current_user.id)
        ).group_by(
            Transaction.sub_category
        ).all()

        return {sub_category: float(total_amount) for sub_category, total_amount in expenses_summary}
    except Exception as e:
        current_app.logger.error(f"Error getting expenses summary: {str(e)}")
        return {}

@main.route('/')
@login_required
def dashboard():
    try:
        # Get the filter type from the query parameters, default to 'past_year'
        filter_type = request.args.get('filter', 'past_year')

        # Logic to calculate date ranges based on the filter type
        if filter_type == 'today':
            start_date = datetime.now().replace(hour=0, minute=0, second=0, microsecond=0)
            end_date = datetime.now().replace(hour=23, minute=59, second=59, microsecond=999999)
        elif filter_type == 'this_month':
            start_date = datetime.now().replace(day=1, hour=0, minute=0, second=0, microsecond=0)
            end_date = datetime.now().replace(day=1, month=datetime.now().month + 1, hour=0, minute=0, second=0, microsecond=0) if datetime.now().month < 12 else datetime.now().replace(year=datetime.now().year + 1, month=1, day=1)
        elif filter_type == 'last_month':
            start_date = (datetime.now().replace(day=1) - timedelta(days=1)).replace(day=1)
            end_date = datetime.now().replace(day=1)
        elif filter_type == 'this_year':
            start_date = datetime.now().replace(month=1, day=1, hour=0, minute=0, second=0, microsecond=0)
            end_date = datetime.now().replace(month=1, day=1, year=datetime.now().year + 1)
        elif filter_type == 'past_year':
            end_date = datetime.now()
            start_date = end_date - timedelta(days=365)
        else:
            end_date = datetime.now()
            start_date = end_date - timedelta(days=365)

        active_maintainance = MaintainanceReport.query.filter(
            MaintainanceReport.reported_date >= start_date,
            MaintainanceReport.reported_date <= end_date,
            MaintainanceReport.status == 0,
            MaintainanceReport.property_id.in_(
                db.session.query(Property.id).filter(Property.owner.has(user_id=current_user.id))
            )
        ).count()

        total_income = db.session.query(db.func.sum(Transaction.amount)).filter(
            Transaction.main_category == 'Revenue',
            Transaction.transaction_date >= start_date,
            Transaction.transaction_date < end_date,
            Transaction.is_reconciled == True,
            Transaction.owner.has(user_id=current_user.id)
        ).scalar() or 0

        total_operating_expenses = db.session.query(db.func.sum(Transaction.amount)).filter(
            Transaction.sub_category == 'Cost of Sales',
            Transaction.transaction_date >= start_date,
            Transaction.transaction_date < end_date,
            Transaction.is_reconciled == True,
            Transaction.owner.has(user_id=current_user.id)
        ).scalar() or 0

        terminated_rental_agreements = RentalAgreement.query.filter(
            RentalAgreement.status == 'no_renewal',
            RentalAgreement.date_end >= start_date,
            RentalAgreement.date_end < end_date,
            RentalAgreement.owner.has(user_id=current_user.id)
        ).count()

        tenant_count = active_rental_agreements()
        formatted_income = '{:,.2f}'.format(total_income)
        formatted_operating_expenses = '{:,.2f}'.format(total_operating_expenses)
        
        user = User.query.options(joinedload(User.currency)).filter_by(id=current_user.id).first()
        agreement = RentalAgreement.query.join(Owner).filter(
            Owner.user_id == current_user.id
        ).order_by(RentalAgreement.date_created.desc()).first()

        unread_messages_count = Message.query.filter_by(
            recipient_id=current_user.id, 
            is_read=False
        ).count()

        pending_agreements = RentalAgreement.query.filter_by(
            status='active', 
            owner_id=current_user.id
        ).all()

        progress_data = []
        for agreement in pending_agreements:
            if agreement.date_start and agreement.date_end:
                date_start = datetime.combine(agreement.date_start, datetime.min.time()) if isinstance(agreement.date_start, date) else agreement.date_start
                date_end = datetime.combine(agreement.date_end, datetime.min.time()) if isinstance(agreement.date_end, date) else agreement.date_end
                
                total_duration = (date_end - date_start).days
                elapsed_time = (datetime.now() - date_start).days
                progress_percentage = 100 - (elapsed_time / total_duration) * 100 if total_duration > 0 else 0
                progress_data.append({
                    'property_title': agreement.property.title,
                    'progress_percentage': min(max(progress_percentage, 0), 100)
                })

        oer_category = oer_analysis()
        banking_details_count = BankingDetails.query.filter_by(user_id=current_user.id).count()

        return render_template(
            'dashboard.html',
            user=user,
            total_income=formatted_income,
            total_operating_expenses=formatted_operating_expenses,
            filter=filter_type,
            terminated_rental_agreements=terminated_rental_agreements,
            tenant_count=tenant_count,
            active_maintainance=active_maintainance,
            agreement=agreement,
            offer_validity=agreement.offer_validity if agreement else None,
            unread_messages_count=unread_messages_count,
            progress_data=progress_data,
            oer_category=oer_category,
            banking_details_count=banking_details_count,
            current_user=current_user
        )
    except Exception as e:
        current_app.logger.error(f"Error in dashboard: {str(e)}")
        flash('An error occurred while loading the dashboard.', 'error')
        return redirect(url_for('main.index'))

@main.route('/maintenance')
@login_required
def maintenance():
    try:
        reports = MaintainanceReport.query.all()
        unread_messages_count = Message.query.filter_by(
            recipient_id=current_user.id,
            is_read=False
        ).count()
        return render_template('maintenance.html', reports=reports, unread_messages_count=unread_messages_count)
    except Exception as e:
        current_app.logger.error(f"Error in maintenance page: {str(e)}")
        flash('An error occurred while loading the maintenance page.', 'error')
        return redirect(url_for('main.dashboard'))

@main.route('/properties')
@login_required
def properties():
    try:
        owner = Owner.query.filter_by(user_id=current_user.id).first()
        if not owner:
            flash('You do not have any properties associated with your account.', 'danger')
            return redirect(url_for('main.dashboard'))

        properties = Property.query.filter_by(owner_id=owner.id).all()
        return render_template('properties.html', properties=properties)
    except Exception as e:
        current_app.logger.error(f"Error in properties page: {str(e)}")
        flash('An error occurred while loading the properties page.', 'error')
        return redirect(url_for('main.dashboard'))

@main.route('/tenants')
@login_required
def tenants():
    try:
        page = request.args.get('page', 1, type=int)
        per_page = 20

        owner = Owner.query.options(
            joinedload(Owner.user).joinedload(User.currency)
        ).filter_by(user_id=current_user.id).first()

        if not owner:
            flash('No owner account found.', 'danger')
            return redirect(url_for('main.dashboard'))

        active_tenants = RentalAgreement.query \
            .filter_by(owner=owner, status='active') \
            .order_by(RentalAgreement.id) \
            .paginate(page=page, per_page=per_page, error_out=False)

        for tenant in active_tenants.items:
            time_diff = tenant.date_end - tenant.date_start
            time_passed = datetime.utcnow() - datetime.combine(tenant.date_start, datetime.min.time())
            tenant.lease_life_percent = 100 - round((time_passed / time_diff * 100), 1)

        return render_template('tenants.html', active_tenants=active_tenants)
    except Exception as e:
        current_app.logger.error(f"Error in tenants page: {str(e)}")
        flash('An error occurred while loading the tenants page.', 'error')
        return redirect(url_for('main.dashboard')) 