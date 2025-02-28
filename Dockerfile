# Use the official Python image from the Docker Hub
FROM python:3.11-slim

# Set environment variables
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PORT=8000 \
    WEBSITE_HOSTNAME=localhost \
    FLASK_APP=app.py

# Set the working directory
WORKDIR /app

# Install system dependencies for WeasyPrint
RUN apt-get update && apt-get install -y \
    libgobject-2.0-0 \
    libpango1.0-dev \
    libgdk-pixbuf2.0-dev \
    libcairo2-dev \
    libgirepository1.0-dev \
    libglib2.0-dev \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install WeasyPrint dependencies
RUN apt-get update && apt-get install -y \
    libcairo2 \
    libpango-1.0-0 \
    libpangocairo-1.0-0 \
    libgdk-pixbuf2.0-0 \
    libffi-dev \
    shared-mime-info \
    fonts-liberation \
    libpangoft2-1.0-0 \
    libjpeg-dev \
    libopenjp2-7-dev \
    && rm -rf /var/lib/apt/lists/*

# Create fonts config directory
RUN mkdir -p /usr/share/fonts/truetype/custom && \
    fc-cache -f -v

# Create necessary directories
RUN mkdir -p /home/site/wwwroot /app /opt/startup

WORKDIR /home/site/wwwroot

# Copy the requirements file
COPY requirements.txt .

# Install Python dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Copy the rest of your application code
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

# Expose the port your app runs on
EXPOSE 8000

# Command to run your application using JSON array format
CMD ["gunicorn", "--bind=0.0.0.0:8000", "app:app"]
