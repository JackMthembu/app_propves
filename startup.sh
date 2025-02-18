#!/bin/bash
set -e

echo "Starting application setup..."

# Set working directory
cd /home/site/wwwroot

# Create required directories if they don't exist
mkdir -p uploads/temp uploads/profile uploads/property uploads/documents

# Set environment variables
export FLASK_APP=app.py
export PYTHONPATH=/home/site/wwwroot

echo "Installing/Upgrading pip..."
python -m pip install --upgrade pip

echo "Installing dependencies..."
if [ -f "requirements.txt" ]; then
    pip install --no-cache-dir -r requirements.txt
fi

echo "Running database migrations..."
flask db upgrade || echo "Warning: Database migration failed"

echo "Starting Gunicorn server..."
exec gunicorn --bind=0.0.0.0:8000 \
    --timeout 120 \
    --workers 2 \
    --threads 2 \
    --access-logfile '-' \
    --error-logfile '-' \
    --log-level info \
    app:app
