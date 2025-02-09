import os
from flask import Flask

def allowed_file(filename):
    ALLOWED_EXTENSIONS = {'pdf', 'csv', 'xls', 'xlsx'}
    return '.' in filename and \
           filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS

def create_app():
    app = Flask(__name__)
    
    # Configuration
    app.config['UPLOAD_FOLDER'] = os.path.join(os.path.dirname(os.path.dirname(__file__)), 'uploads')
    
    # Ensure upload directory exists
    os.makedirs(app.config['UPLOAD_FOLDER'], exist_ok=True)
    
    print("=== DEBUG: Registering blueprints ===")
    
    # Import blueprints
    try:
        from accounting import accounting_routes
        app.register_blueprint(accounting_routes, url_prefix='/accounting')
        print(f"Successfully registered accounting blueprint")
    except Exception as e:
        print(f"Error registering accounting blueprint: {str(e)}")
    
    # Debug output
    print("=== DEBUG: All registered routes ===")
    for rule in app.url_map.iter_rules():
        print(f"Route: {rule.rule} [{', '.join(rule.methods)}]")
    
    # Setup login manager and other extensions here
    from flask_login import LoginManager
    login_manager = LoginManager()
    login_manager.init_app(app)
    login_manager.login_view = 'auth.login'
    
    @login_manager.user_loader
    def load_user(user_id):
        from models import User
        return User.query.get(int(user_id))
    
    return app
    