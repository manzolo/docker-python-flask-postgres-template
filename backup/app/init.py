from flask import Flask
from flask_sqlalchemy import SQLAlchemy
from flask_migrate import Migrate
from app.config import config_by_name
import os

db = SQLAlchemy()
migrate = Migrate()


def create_app(config_name=None):
    """Factory pattern per creare l'applicazione Flask"""
    
    app = Flask(__name__)
    
    # Carica la configurazione
    if config_name is None:
        config_name = os.environ.get('FLASK_ENV', 'development')
    
    app.config.from_object(config_by_name.get(config_name, config_by_name['default']))
    
    # Inizializza le estensioni
    db.init_app(app)
    migrate.init_app(app, db)
    
    # Registra i blueprints
    from app.routes import main_bp
    app.register_blueprint(main_bp)
    
    # Context processor per variabili globali nei template
    @app.context_processor
    def inject_global_vars():
        return dict(app_name="Flask App")
    
    return app