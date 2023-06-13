'''
Flask App to show how Session Cache works with ElastiCache/Redis
'''
import random
import uuid
import socket
import os
from flask import Flask, session
from flask_session import Session
import redis


app = Flask(__name__)
SECRET_KEY = os.getenv('SECRET_KEY')
app.secret_key = SECRET_KEY

# Redis setup
ELASTICACHE_HOST = os.getenv('ELASTICACHE_HOST')
ELASTICACHE_PORT = os.getenv('ELASTICACHE_PORT')
ELASTICACHE_USER = os.getenv('ELASTICACHE_USER')
ELASTICACHE_PASSWORD = os.getenv('ELASTICACHE_PASSWORD')

redis_cred_provider = redis.UsernamePasswordCredentialProvider(ELASTICACHE_USER, ELASTICACHE_PASSWORD)
redis_client = redis.RedisCluster(
    host=ELASTICACHE_HOST, 
    port=ELASTICACHE_PORT, 
    credential_provider=redis_cred_provider,
    ssl=True,
    ssl_cert_reqs=None,)

# Set session expiry time in seconds
SESSION_EXPIRATION = int(os.getenv('SESSION_EXPIRATION'))

# Configure Redis for storing the session data on the server-side
app.config['SESSION_TYPE'] = 'redis'
app.config['SESSION_PERMANENT'] = False
app.config['SESSION_USE_SIGNER'] = True
app.config['SESSION_REDIS'] = redis_client
app.config['PERMANENT_SESSION_LIFETIME'] = SESSION_EXPIRATION

# Create and initialize the Flask-Session object AFTER `app` has been configured
Session(app)


@app.route('/')
def home():
    '''
    Default App Route
    '''
    # Check if session ID exists
    if 'session_id' not in session:
        session['session_id'] = str(uuid.uuid4())

    session_id = session['session_id']

    # Check if color exists in session
    if 'color' not in session:
        session['color'] = generate_random_color()

    color = session['color']

    hostname = socket.gethostname()

    return f'<h1 style="color: {color}">Random Color: {color}</h1> \
                <h2>Session ID: {session_id}</h2> \
                <h2>Hostname: {hostname}</h2>'


def generate_random_color():
    '''
    Generate random color
    '''
    # Generate random RGB values
    red = random.randint(0, 255)
    green = random.randint(0, 255)
    blue = random.randint(0, 255)

    # Convert RGB to hexadecimal
    color_code = f'#{red:02x}{green:02x}{blue:02x}'

    return color_code


if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8080, debug=True)
