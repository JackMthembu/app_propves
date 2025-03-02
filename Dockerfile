# Use Ubuntu base image
FROM ubuntu:22.04

# Set environment variables
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PORT=8000 \
    WEBSITE_HOSTNAME=localhost \
    FLASK_APP=app.py \
    DEBIAN_FRONTEND=noninteractive \
    # Python and GObject paths
    PYTHONPATH=/opt/venv/lib/python3.11/site-packages:/usr/lib/python3/dist-packages:$PYTHONPATH \
    LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu:/usr/lib:$LD_LIBRARY_PATH \
    GI_TYPELIB_PATH=/usr/lib/x86_64-linux-gnu/girepository-1.0:/usr/local/lib/girepository-1.0 \
    XDG_DATA_DIRS=/usr/share:/usr/local/share:/usr/share/gnome:/usr/local/share/gnome \
    # Additional GObject environment variables
    GI_SCANNER_DISABLE_CACHE=1 \
    GSETTINGS_SCHEMA_DIR=/usr/share/glib-2.0/schemas

# Install system dependencies
RUN apt-get update && apt-get install -y \
    software-properties-common \
    && add-apt-repository ppa:deadsnakes/ppa \
    && apt-get update && apt-get install -y \
    python3.11 \
    python3.11-dev \
    python3.11-venv \
    python3-pip \
    build-essential \
    pkg-config \
    # GObject dependencies
    libgirepository1.0-dev \
    gir1.2-gobject-2.0 \
    gir1.2-gtk-3.0 \
    libglib2.0-dev \
    libgobject-2.0-0 \
    gobject-introspection \
    gir1.2-glib-2.0 \
    # Cairo and Pango dependencies
    libcairo2-dev \
    libpango1.0-dev \
    libpangocairo-1.0-0 \
    gir1.2-pango-1.0 \
    gir1.2-freedesktop \
    # Additional required libraries
    libffi-dev \
    shared-mime-info \
    # Font-related packages
    fontconfig \
    fonts-liberation \
    # Python bindings
    python3-gi \
    python3-gi-cairo \
    python3-cffi \
    # Additional WeasyPrint dependencies
    libpango1.0-0 \
    libharfbuzz0b \
    libpangoft2-1.0-0 \
    libgdk-pixbuf2.0-0 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && ldconfig \
    # Verify GObject installation
    && pkg-config --print-requires gobject-2.0 \
    && pkg-config --print-requires glib-2.0

# Create necessary directories and set permissions
RUN mkdir -p /home/site/wwwroot /app /opt/startup /var/cache/fontconfig \
    /usr/share/fonts/truetype/custom && \
    chmod -R 777 /var/cache/fontconfig /usr/share/fonts

# Update font cache
RUN fc-cache -f -v

WORKDIR /home/site/wwwroot

# Copy requirements first
COPY requirements.txt .

# Create virtual environment and install packages
RUN python3.11 -m venv /opt/venv --system-site-packages && \
    . /opt/venv/bin/activate && \
    # Install Python packages
    pip install --upgrade pip setuptools wheel && \
    pip install --no-cache-dir -r requirements.txt gunicorn && \
    # Debug output
    echo "Python packages installed:" && \
    pip list && \
    echo "Testing WeasyPrint..." && \
    python3 -c "from weasyprint import HTML; print('WeasyPrint imported successfully')" && \
    python3 -c "from weasyprint import HTML; HTML(string='<h1>Test</h1>').write_pdf('/tmp/test.pdf')" && \
    echo "WeasyPrint test successful" && \
    # Create non-root user and set permissions
    useradd -m myuser && \
    chown -R myuser:myuser /app && \
    chown -R myuser:myuser /home/site/wwwroot && \
    chown -R myuser:myuser /opt/startup && \
    chown -R myuser:myuser /opt/venv && \
    chown -R myuser:myuser /var/cache/fontconfig && \
    chown -R myuser:myuser /usr/share/fonts && \
    chmod -R 755 /opt/venv/lib/python3.11/site-packages

# Copy application code after installing dependencies
COPY . .

# Create startup script with debug logging
RUN echo '#!/bin/sh\n\
APP_PATH=${APP_PATH:-/home/site/wwwroot}\n\
mkdir -p $APP_PATH/uploads/temp $APP_PATH/uploads/profile $APP_PATH/uploads/property $APP_PATH/uploads/documents\n\
cd $APP_PATH\n\
\n\
# Debug information\n\
echo "Python version:"\n\
python3 --version\n\
echo "Environment:"\n\
env | sort\n\
echo "Library paths:"\n\
ldconfig -p | grep gobject\n\
echo "GI repository:"\n\
ls -l /usr/lib/x86_64-linux-gnu/girepository-1.0/\n\
\n\
# Test GObject imports\n\
python3 -c "import gi; print('\''GObject imported successfully'\'')" || { echo "Failed to import GObject"; exit 1; }\n\
python3 -c "import gi; gi.require_version('\''Pango'\'', '\''1.0'\''); from gi.repository import Pango; print('\''Pango imported successfully'\'')" || { echo "Failed to import Pango"; exit 1; }\n\
\n\
# Test WeasyPrint\n\
echo "Testing WeasyPrint installation..."\n\
python3 -c "from weasyprint import HTML; print('\''WeasyPrint imported successfully'\'')" || { echo "Failed to import WeasyPrint"; exit 1; }\n\
python3 -c "from weasyprint import HTML; HTML(string='\''<h1>Test</h1>'\'').write_pdf('\''/tmp/test.pdf'\'')" || { echo "Failed to generate PDF"; exit 1; }\n\
echo "WeasyPrint test successful"\n\
\n\
# Start application\n\
exec gunicorn --bind=0.0.0.0:8000 \
    --timeout 600 \
    --workers 1 \
    --threads 1 \
    --access-logfile - \
    --error-logfile - \
    --log-level debug \
    --capture-output \
    app:app' > /opt/startup/startup.sh && \
    chmod +x /opt/startup/startup.sh && \
    ln -sf /opt/startup/startup.sh /home/site/wwwroot/startup.sh

USER myuser

EXPOSE 8000

CMD ["/opt/startup/startup.sh"]