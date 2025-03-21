from ast import main
import os
from flask import Blueprint, abort, current_app, flash, redirect, render_template, url_for, request
from flask_login import current_user, login_required
from sqlalchemy import func
# from investment_analyses import oer_analysis
from models import MaintainanceReport, Property, Listing, RentalAgreement, Transaction, User, db, Message
from datetime import datetime, timedelta, date
from sqlalchemy.orm import joinedload
from models import RentalAgreement, Owner, Payment

tenant_routes = Blueprint('tenant', __name__)

@tenant_routes.route('/dashboard')
@login_required
def dashboard():
    return render_template('tenant/dashboard.html')

@tenant_routes.route('/tenant/<int:tenant_id>')
@login_required
def tenant_details(tenant_id):
    """Show details about a specific tenant."""

    # Get the rental agreement for the given tenant_id
    agreement = RentalAgreement.query.filter_by(tenant_id=tenant_id).first_or_404()

    # Check if the current user is the owner of this tenant
    owner = Owner.query.filter_by(user_id=current_user.id).first()
    if agreement.owner_id != owner.id:
        abort(403)  # Forbidden access

    # Get lease details
    lease_start = agreement.date_start
    lease_end = agreement.date_end
    rent_amount = agreement.rent_amount  # Assuming you have this in your model

    # Get payment patterns (example)
    payments = Payment.query.filter_by(rental_agreement_id=agreement.id).all()
    # ... process payments to extract patterns (e.g., late payments, average payment date) ...

    # ... gather other necessary data ...

    return render_template('tenant/tenant_details.html',
                           tenant=agreement.tenant,  # Pass the tenant object
                           lease_start=lease_start,
                           lease_end=lease_end,
                           rent_amount=rent_amount,
                           payments=payments,
                           # ... other data ...
                           )
