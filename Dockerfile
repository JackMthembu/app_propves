# Use Azure's Python image
FROM mcr.microsoft.com/appsvc/python:3.11_20241021.7

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
RUN mkdir -p /home/site/wwwroot/uploads/temp \
    /home/site/wwwroot/uploads/profile \
    /home/site/wwwroot/uploads/property \
    /home/site/wwwroot/uploads/documents

WORKDIR /home/site/wwwroot

# Copy requirements first to leverage Docker cache
COPY requirements.txt .

# Install Python dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Copy project
COPY . .

# Make startup script executable
COPY startup.sh /opt/startup/startup.sh
RUN chmod +x /opt/startup/startup.sh

# Create non-root user
RUN useradd -m myuser && chown -R myuser:myuser /home/site/wwwroot
USER myuser

# Expose port
EXPOSE 8000

# Health check
HEALTHCHECK --interval=30s --timeout=30s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8000/health || exit 1

# Set the startup command explicitly
CMD ["/opt/startup/startup.sh"]

