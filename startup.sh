#!/bin/bash
set -e

echo "Starting application setup..."

cd /home/site/wwwroot

# Create required directories
mkdir -p uploads/temp uploads/profile uploads/property uploads/documents

# Set environment variables
export FLASK_APP=app.py
export PYTHONPATH=/home/site/wwwroot:/opt/venv/lib/python3.11/site-packages:/usr/lib/python3/dist-packages
export LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu:/usr/lib:$LD_LIBRARY_PATH

# Debug information
echo "Environment:"
env | sort
echo "Python packages:"
pip list
echo "Library paths:"
ldconfig -p | grep -E "gobject|pango|cairo"

echo "Starting Gunicorn server..."
exec gunicorn --bind=0.0.0.0:8000 \
    --timeout 120 \
    --workers 2 \
    --threads 2 \
    --access-logfile - \
    --error-logfile - \
    --log-level debug \
    --capture-output \
    app:app
