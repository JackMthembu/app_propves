# celery_config.py
from celery import Celery
from flask import Flask

flask_app = Flask(__name__)
celery = Celery('tasks', broker='redis://localhost:6379/0')
current_app = flask_app

def make_celery(app):
    celery = Celery(app.import_name, backend=app.config['CELERY_RESULT_BACKEND'], broker=app.config['CELERY_BROKER_URL'])
    celery.conf.update(app.config)
    return celery