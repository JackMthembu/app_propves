# Use official Python image
FROM python:3.11-slim

# Set environment variables
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PORT=8000 \
    WEBSITE_HOSTNAME=localhost \
    FLASK_APP=app.py \
    DEBIAN_FRONTEND=noninteractive

# Install system dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    python3-dev \
    libcairo2 \
    libpango-1.0-0 \
    libpangocairo-1.0-0 \
    libgdk-pixbuf2.0-0 \
    shared-mime-info \
    libpango1.0-dev \
    libcairo2-dev \
    libffi-dev \
    libjpeg-dev \
    libopenjp2-7-dev \
    python3-cffi \
    python3-brotli \
    fonts-liberation \
    libgirepository1.0-dev \
    pkg-config \
    gir1.2-pango-1.0 \
    libglib2.0-0 \
    libglib2.0-dev \
    libgirepository-1.0-1 \
    gir1.2-gobject-2.0 \
    gobject-introspection \
    python3-gi \
    python3-gi-cairo \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Create necessary directories
RUN mkdir -p /home/site/wwwroot /app /opt/startup /var/cache/fontconfig \
    /usr/share/fonts/truetype/custom && \
    chmod 777 /var/cache/fontconfig

# Set library path for GObject
ENV LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu:/usr/lib:$LD_LIBRARY_PATH \
    GI_TYPELIB_PATH=/usr/lib/x86_64-linux-gnu/girepository-1.0:/usr/lib/girepository-1.0 \
    PYTHONPATH=/usr/lib/python3/dist-packages:$PYTHONPATH

# Update font cache
RUN fc-cache -f -v

WORKDIR /home/site/wwwroot

# Copy requirements and install Python packages
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt gunicorn

# Copy application code
COPY . .

# Create startup script with debug logging
RUN echo '#!/bin/sh\n\
APP_PATH=${APP_PATH:-/home/site/wwwroot}\n\
mkdir -p $APP_PATH/uploads/temp $APP_PATH/uploads/profile $APP_PATH/uploads/property $APP_PATH/uploads/documents\n\
cd $APP_PATH\n\
echo "Testing WeasyPrint installation..."\n\
python3 -c "import sys; from weasyprint import HTML; print(\"Python version:\", sys.version); print(\"WeasyPrint dependencies:\", HTML.__file__); HTML(string=\"<h1>Test</h1>\").write_pdf(\"/tmp/test.pdf\")" || { echo "WeasyPrint test failed"; cat /tmp/weasyprint-error.log 2>/dev/null; exit 1; }\n\
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
    chown -R myuser:myuser /var/cache/fontconfig && \
    chown -R myuser:myuser /usr/share/fonts

USER myuser

EXPOSE 8000

CMD ["/opt/startup/startup.sh"]
