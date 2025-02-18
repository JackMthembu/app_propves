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
RUN mkdir -p /tmp/8dd49cc763c5b00/uploads/temp \
    /tmp/8dd49cc763c5b00/uploads/profile \
    /tmp/8dd49cc763c5b00/uploads/property \
    /tmp/8dd49cc763c5b00/uploads/documents \
    /app

WORKDIR /tmp/8dd49cc763c5b00

# Copy requirements first to leverage Docker cache
COPY requirements.txt .

# Install Python dependencies
RUN pip install --no-cache-dir -r requirements.txt gunicorn

# Copy project
COPY . .

# Make startup script executable and copy to both locations
COPY startup.sh /opt/startup/startup.sh
COPY startup.sh /app/startup.sh
RUN chmod +x /opt/startup/startup.sh /app/startup.sh

# Create non-root user
RUN useradd -m myuser && \
    chown -R myuser:myuser /tmp/8dd49cc763c5b00 && \
    chown -R myuser:myuser /app
USER myuser

# Expose port
EXPOSE 8000

# Health check
HEALTHCHECK --interval=30s --timeout=30s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8000/health || exit 1

# Let Azure App Service use its default entrypoint

