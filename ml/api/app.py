import os
import joblib
from flask import Flask, request, jsonify

app = Flask(__name__)

# Load the model locally
MODEL_PATH = os.path.join(os.path.dirname(__file__), "model/model.pkl")
model = joblib.load(MODEL_PATH)

@app.route('/')
def welcome():
    return "Welcome to the XGBoost Prediction API!"

@app.route('/predict', methods=['POST'])
def predict():
    data = request.get_json()
    predictions = model.predict(data['features'])
    return jsonify({'predictions': predictions.tolist()})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5001)
