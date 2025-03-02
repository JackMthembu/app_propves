# Use a base image with pre-installed dependencies
FROM ubuntu:22.04

# Prevent interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PORT=8000 \
    WEBSITE_HOSTNAME=localhost \
    FLASK_APP=app.py

# Install Python and required system packages
RUN apt-get update && apt-get install -y \
    python3.11 \
    python3.11-dev \
    python3-pip \
    python3-setuptools \
    python3-wheel \
    python3-cffi \
    libcairo2 \
    libpango-1.0-0 \
    libpangocairo-1.0-0 \
    libgdk-pixbuf2.0-0 \
    shared-mime-info \
    libpango1.0-dev \
    libharfbuzz-dev \
    libffi-dev \
    libgdk-pixbuf2.0-dev \
    libxml2-dev \
    libxslt-dev \
    libgomp1 \
    fonts-liberation \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Create necessary directories
RUN mkdir -p /home/site/wwwroot /app /opt/startup /var/cache/fontconfig \
    /usr/share/fonts/truetype/custom && \
    chmod 777 /var/cache/fontconfig

# Update font cache
RUN fc-cache -f -v

WORKDIR /home/site/wwwroot

# Copy requirements and install Python packages
COPY requirements.txt .
RUN python3.11 -m pip install --no-cache-dir -r requirements.txt gunicorn

# Copy application code
COPY . .

# Create startup script
RUN echo '#!/bin/sh\n\
APP_PATH=${APP_PATH:-/home/site/wwwroot}\n\
mkdir -p $APP_PATH/uploads/temp $APP_PATH/uploads/profile $APP_PATH/uploads/property $APP_PATH/uploads/documents\n\
cd $APP_PATH\n\
exec gunicorn --bind=0.0.0.0:8000 \
    --timeout 120 \
    --workers 2 \
    --threads 2 \
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
    chown -R myuser:myuser /opt/startup

USER myuser

EXPOSE 8000

CMD ["/opt/startup/startup.sh"]
