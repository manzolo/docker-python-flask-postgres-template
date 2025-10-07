from app import create_app, db
from app.models import User, Post
import os

app = create_app(os.environ.get('FLASK_ENV', 'development'))


@app.shell_context_processor
def make_shell_context():
    """Rende disponibili i modelli nella shell Flask"""
    return {'db': db, 'User': User, 'Post': Post}


if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)