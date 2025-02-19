# Use official Python image
FROM python:3.11-slim

# Set environment variables
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PORT=8000 \
    WEBSITE_HOSTNAME=localhost \
    FLASK_APP=app.py

# Install system dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    python3-dev \
    libpq-dev \
    gcc \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Install WeasyPrint dependencies
RUN apt-get update && apt-get install -y \
    libcairo2 \
    libpango-1.0-0 \
    libpangocairo-1.0-0 \
    libgdk-pixbuf2.0-0 \
    libffi-dev \
    shared-mime-info \
    && rm -rf /var/lib/apt/lists/*

# Create necessary directories
RUN mkdir -p /home/site/wwwroot /app /opt/startup

WORKDIR /home/site/wwwroot

# Copy requirements first to leverage Docker cache
COPY requirements.txt .

# Install Python dependencies
RUN pip install --no-cache-dir -r requirements.txt gunicorn

# Copy project
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
    --log-level info \
    app:app' > startup.sh && \
    chmod +x startup.sh && \
    mv startup.sh /opt/startup/startup.sh && \
    ln -sf /opt/startup/startup.sh /home/site/wwwroot/startup.sh

# Create non-root user and set permissions
RUN useradd -m myuser && \
    chown -R myuser:myuser /app && \
    chown -R myuser:myuser /home/site/wwwroot && \
    chown -R myuser:myuser /opt/startup
USER myuser

# Expose port
EXPOSE 8000

# Health check
HEALTHCHECK --interval=30s --timeout=30s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8000/health || exit 1

# Set the startup command
CMD ["/home/site/wwwroot/startup.sh"]

