# Use Ubuntu base image
FROM ubuntu:22.04

# Set environment variables
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PORT=8000 \
    WEBSITE_HOSTNAME=localhost \
    FLASK_APP=app.py \
    DEBIAN_FRONTEND=noninteractive \
    PYTHONPATH=/usr/lib/python3/dist-packages:$PYTHONPATH \
    LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu:/usr/lib:$LD_LIBRARY_PATH \
    GI_TYPELIB_PATH=/usr/lib/x86_64-linux-gnu/girepository-1.0 \
    XDG_DATA_DIRS=/usr/share:/usr/local/share:/usr/share/gnome:/usr/local/share/gnome

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
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && ldconfig

# Create necessary directories
RUN mkdir -p /home/site/wwwroot /app /opt/startup /var/cache/fontconfig \
    /usr/share/fonts/truetype/custom && \
    chmod 777 /var/cache/fontconfig

# Update font cache
RUN fc-cache -f -v

WORKDIR /home/site/wwwroot

# Create and activate virtual environment
RUN python3.11 -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# Copy requirements file
COPY requirements.txt .

# Install Python packages
RUN pip install --upgrade pip setuptools wheel && \
    pip install --no-cache-dir -r requirements.txt gunicorn

# Copy application code
COPY . .

# Create startup script with debug logging
RUN echo '#!/bin/sh\n\
APP_PATH=${APP_PATH:-/home/site/wwwroot}\n\
mkdir -p $APP_PATH/uploads/temp $APP_PATH/uploads/profile $APP_PATH/uploads/property $APP_PATH/uploads/documents\n\
cd $APP_PATH\n\
echo "Testing WeasyPrint installation..."\n\
python3 -c "import gi; gi.require_version('\''Pango'\'', '\''1.0'\''); from gi.repository import Pango; import sys; from weasyprint import HTML; print('\''Python version:'\'', sys.version); print('\''WeasyPrint dependencies:'\'', HTML.__file__); HTML(string='\''<h1>Test</h1>'\'').write_pdf('\''/tmp/test.pdf'\'')" 2>/tmp/weasyprint-error.log || { echo "WeasyPrint test failed"; cat /tmp/weasyprint-error.log; exit 1; }\n\
echo "WeasyPrint test successful"\n\
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

# Create non-root user and set permissions
RUN useradd -m myuser && \
    chown -R myuser:myuser /app && \
    chown -R myuser:myuser /home/site/wwwroot && \
    chown -R myuser:myuser /opt/startup && \
    chown -R myuser:myuser /opt/venv && \
    chown -R myuser:myuser /var/cache/fontconfig && \
    chown -R myuser:myuser /usr/share/fonts

USER myuser

EXPOSE 8000

CMD ["/opt/startup/startup.sh"]