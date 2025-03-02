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
export GI_TYPELIB_PATH=/usr/lib/x86_64-linux-gnu/girepository-1.0
export XDG_DATA_DIRS=/usr/share:/usr/local/share

# Debug information
echo "Environment:"
env | sort
echo "Python packages:"
pip list
echo "Library paths:"
ldconfig -p | grep -E "gobject|pango|cairo"
echo "GI repository contents:"
ls -l /usr/lib/x86_64-linux-gnu/girepository-1.0/
echo "Testing imports..."
python3 -c "import gi; print('gi imported successfully')" || echo "Failed to import gi"
python3 -c "import cairo; print('cairo imported successfully')" || echo "Failed to import cairo"
python3 -c "import pdfkit; print('pdfkit imported successfully')" || echo "Failed to import pdfkit"

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
