from flask import Blueprint, jsonify, request
from app import db
from app.models import User, Post

main_bp = Blueprint('main', __name__)


@main_bp.route('/')
def index():
    """Route principale"""
    return jsonify({
        'message': 'Benvenuto nella Flask App!',
        'status': 'running'
    })


@main_bp.route('/health')
def health():
    """Health check endpoint"""
    return jsonify({'status': 'healthy'}), 200


# User routes
@main_bp.route('/api/users', methods=['GET'])
def get_users():
    """Ottieni tutti gli utenti"""
    users = User.query.all()
    return jsonify([user.to_dict() for user in users])


@main_bp.route('/api/users/<int:user_id>', methods=['GET'])
def get_user(user_id):
    """Ottieni un utente specifico"""
    user = User.query.get_or_404(user_id)
    return jsonify(user.to_dict())


@main_bp.route('/api/users', methods=['POST'])
def create_user():
    """Crea un nuovo utente"""
    data = request.get_json()
    
    if not data or not data.get('username') or not data.get('email'):
        return jsonify({'error': 'Username e email sono richiesti'}), 400
    
    user = User(
        username=data['username'],
        email=data['email']
    )
    
    db.session.add(user)
    db.session.commit()
    
    return jsonify(user.to_dict()), 201


@main_bp.route('/api/users/<int:user_id>', methods=['DELETE'])
def delete_user(user_id):
    """Elimina un utente"""
    user = User.query.get_or_404(user_id)
    db.session.delete(user)
    db.session.commit()
    
    return jsonify({'message': 'Utente eliminato con successo'}), 200


# Post routes
@main_bp.route('/api/posts', methods=['GET'])
def get_posts():
    """Ottieni tutti i post"""
    posts = Post.query.all()
    return jsonify([post.to_dict() for post in posts])


@main_bp.route('/api/posts', methods=['POST'])
def create_post():
    """Crea un nuovo post"""
    data = request.get_json()
    
    if not data or not data.get('title') or not data.get('content') or not data.get('user_id'):
        return jsonify({'error': 'Title, content e user_id sono richiesti'}), 400
    
    # Verifica che l'utente esista
    user = User.query.get(data['user_id'])
    if not user:
        return jsonify({'error': 'Utente non trovato'}), 404
    
    post = Post(
        title=data['title'],
        content=data['content'],
        user_id=data['user_id']
    )
    
    db.session.add(post)
    db.session.commit()
    
    return jsonify(post.to_dict()), 201


@main_bp.route('/api/users/<int:user_id>/posts', methods=['GET'])
def get_user_posts(user_id):
    """Ottieni tutti i post di un utente"""
    user = User.query.get_or_404(user_id)
    return jsonify([post.to_dict() for post in user.posts])