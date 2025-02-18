#!/bin/bash

# Apply database migrations
flask db upgrade

# Start Gunicorn
gunicorn --bind 0.0.0.0:8000 app:app
