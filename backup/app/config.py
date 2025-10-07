import os
from dotenv import load_dotenv

load_dotenv()


class Config:
    """Configurazione base dell'applicazione"""
    
    SECRET_KEY = os.environ.get('SECRET_KEY') or 'dev-secret-key-change-in-production'
    SQLALCHEMY_DATABASE_URI = os.environ.get('DATABASE_URL') or \
        'postgresql://flask_user:flask_password@localhost:5432/flask_db'
    SQLALCHEMY_TRACK_MODIFICATIONS = False
    
    # Configurazioni aggiuntive
    DEBUG = False
    TESTING = False


class DevelopmentConfig(Config):
    """Configurazione per ambiente di sviluppo"""
    DEBUG = True


class ProductionConfig(Config):
    """Configurazione per ambiente di produzione"""
    DEBUG = False


class TestingConfig(Config):
    """Configurazione per testing"""
    TESTING = True
    SQLALCHEMY_DATABASE_URI = 'postgresql://flask_user:flask_password@localhost:5432/flask_test_db'


config_by_name = {
    'development': DevelopmentConfig,
    'production': ProductionConfig,
    'testing': TestingConfig,
    'default': DevelopmentConfig
}