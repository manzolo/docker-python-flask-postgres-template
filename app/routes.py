from flask import Blueprint, jsonify
from . import db
from .models import User

bp = Blueprint('main', __name__)

@bp.route('/')
def index():
    users = User.query.all()
    return jsonify([{'username': user.username, 'email': user.email} for user in users])