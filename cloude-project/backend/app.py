from flask import Flask, jsonify, request
from flask_cors import CORS
import pandas as pd
import requests

app = Flask(__name__)
CORS(app)

@app.route('/api/health', methods=['GET'])
def health_check():
    return jsonify({'status': 'healthy'})

@app.route('/api/data', methods=['GET'])
def get_data():
    print('收到前端请求')
    data = {
        'message': 'Hello from backend',
        'timestamp': pd.Timestamp.now().isoformat(),
        'version': '1.0.0'
    }
    return jsonify(data)

@app.route('/api/post', methods=['POST'])
def post_data():
    print('收到 POST 请求')
    if request.is_json:
        content = request.get_json()
        return jsonify({'received': content}), 200
    return jsonify({'error': 'Request must be JSON'}), 400

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)