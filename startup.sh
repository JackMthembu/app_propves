#!/bin/bash
set -e

echo "Starting application setup..."

# Create required directories if they don't exist
mkdir -p uploads/temp uploads/profile uploads/property uploads/documents

# Set environment variables
export FLASK_APP=app.py
export PYTHONPATH=/app

echo "Activating virtual environment..."
# Check if we're in the Azure environment
if [ -d "/tmp/8dd49cc763c5b00/antenv" ]; then
    source /tmp/8dd49cc763c5b00/antenv/bin/activate
fi

echo "Installing/Upgrading pip..."
python -m pip install --upgrade pip

echo "Installing dependencies..."
if [ -f "requirements.txt" ]; then
    pip install -r requirements.txt
else
    echo "No requirements.txt found!"
    exit 1
fi

echo "Running database migrations..."
flask db upgrade || echo "Warning: Database migration failed"

echo "Starting Gunicorn server..."
# Add worker timeout to handle slow startup
gunicorn --bind=0.0.0.0:8000 \
         --timeout 120 \
         --workers 2 \
         --threads 2 \
         --access-logfile '-' \
         --error-logfile '-' \
         --log-level info \
         app:app
