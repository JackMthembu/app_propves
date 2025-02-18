#!/bin/bash
set -e

echo "Starting application setup..."

cd /home/site/wwwroot

# Create required directories if they don't exist
mkdir -p uploads/temp uploads/profile uploads/property uploads/documents

# Set environment variables
export FLASK_APP=app.py
export PYTHONPATH=/home/site/wwwroot

echo "Starting Gunicorn server..."
exec gunicorn --bind=0.0.0.0:8000 \
    --timeout 120 \
    --workers 2 \
    --threads 2 \
    --access-logfile '-' \
    --error-logfile '-' \
    --log-level info \
    app:app
