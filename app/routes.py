from flask import Blueprint, jsonify, render_template
from . import db
from .models import User

bp = Blueprint('main', __name__)

@bp.route('/')
def index():
    """Home page with template information"""
    return render_template('index.html')

@bp.route('/api/users')
def get_users():
    """API endpoint to get all users (JSON)"""
    users = User.query.all()
    return jsonify({
        'success': True,
        'count': len(users),
        'users': [
            {
                'id': user.id,
                'username': user.username,
                'email': user.email
            } for user in users
        ]
    })

@bp.route('/api/users/<int:user_id>')
def get_user(user_id):
    """API endpoint to get a specific user"""
    user = User.query.get_or_404(user_id)
    return jsonify({
        'success': True,
        'user': {
            'id': user.id,
            'username': user.username,
            'email': user.email
        }
    })

@bp.route('/api/health')
def health_check():
    """Health check endpoint"""
    try:
        # Test database connection
        db.session.execute(db.text('SELECT 1'))
        db_status = 'healthy'
    except Exception as e:
        db_status = f'unhealthy: {str(e)}'
    
    return jsonify({
        'status': 'ok',
        'database': db_status,
        'message': 'Flask PostgreSQL Template is running'
    })