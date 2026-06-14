from flask import Flask, jsonify

app = Flask(__name__)

@app.route('/')
def hello():
    return jsonify({'message': 'Hello from Flask backend!'})

@app.route('/api/health')
def health_check():
    return jsonify({'status': 'healthy'})

@app.route('/api/ping')
def ping():
    return jsonify({'status': 'ok', 'version': '1.0.1'})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)