import flask
from flask import Flask, request, jsonify
from flask_cors import CORS
import base64
import cv2
import numpy as np
import firebase_admin
from firebase_admin import credentials, firestore

import tensorflow as tf
import tensorflow.keras.backend as K
from tensorflow.keras.layers import Layer 
import os
import traceback

os.environ['TF_CPP_MIN_LOG_LEVEL'] = '2'

app = Flask(__name__)
CORS(app)

try:
    if not firebase_admin._apps:
        cred = credentials.Certificate("firebase_key.json")
        firebase_admin.initialize_app(cred)
    db = firestore.client()
    print("Firebase connection successful.")
except FileNotFoundError:
    print("FATAL ERROR: 'firebase_key.json' not found. Please download it from your Firebase project settings.")
    db = None
except ValueError as e:
    print(f"Firebase initialization error: {e}")
    if 'app' not in str(e): 
        raise e
    db = firestore.client()


MODEL_FILE = 'fingerprint_embedding_model.h5'
EMBEDDING_MODEL = None
MODEL_INPUT_SHAPE = None

class L2Normalize(Layer):
    def __init__(self, **kwargs):
        super(L2Normalize, self).__init__(**kwargs)

    def call(self, inputs):
        return tf.nn.l2_normalize(inputs, axis=-1)

    def get_config(self):
        config = super(L2Normalize, self).get_config()
        return config


try:
    if os.path.exists(MODEL_FILE):
        EMBEDDING_MODEL = tf.keras.models.load_model(
            MODEL_FILE, 
            compile=False,
            custom_objects={'L2Normalize': L2Normalize}
        )
        
        MODEL_INPUT_SHAPE = EMBEDDING_MODEL.input_shape[1:3] 
        print(f"Successfully loaded model '{MODEL_FILE}' with input shape {MODEL_INPUT_SHAPE}.")
    else:
        print(f"FATAL ERROR: Model file '{MODEL_FILE}' not found.")
        print("Please place the .h5 file in the same directory as this script.")
except Exception as e:
    print(f"FATAL ERROR: Could not load model '{MODEL_FILE}'. Error: {e}")

SIMILARITY_MARGIN = 1.0 

def preprocess_image(img_gray, target_shape):
    """
    Prepares a single grayscale image to be fed into the Siamese model.
    """
    img_resized = cv2.resize(img_gray, target_shape, interpolation=cv2.INTER_AREA)
    img_normalized = img_resized.astype('float32') / 255.0
    img_expanded = np.expand_dims(img_normalized, axis=0) 
    img_expanded = np.expand_dims(img_expanded, axis=-1) 
    return img_expanded

import numpy as np
import traceback

# --- CRITICAL FIX: Set a stricter margin ---
# A lower margin means the system is "pickier".
# If the squared distance is > 0.4, the score will drop to 0.
SIMILARITY_MARGIN = 0.4  

def get_similarity_score(img1, img2, model, shape):
    """
    Calculates a similarity score between 0.0 and 1.0 for two images.
    """
    global SIMILARITY_MARGIN
    
    if model is None or shape is None:
        print("Error: Model not loaded.")
        return 0.0
        
    try:
        proc_img1 = preprocess_image(img1, shape)
        proc_img2 = preprocess_image(img2, shape)

        # Get embeddings
        vec1 = model.predict(proc_img1, verbose=0)[0] # verbose=0 hides progress bar
        vec2 = model.predict(proc_img2, verbose=0)[0]
        
        # Calculate Squared Euclidean Distance
        distance = np.sum(np.square(vec1 - vec2))
        
        # --- SCORING LOGIC ---
        # If distance > SIMILARITY_MARGIN, the result is negative, which max() turns to 0.0.
        # This cuts off the "weak" matches effectively.
        score = 1.0 - (distance / SIMILARITY_MARGIN)
        
        return max(0.0, min(1.0, score))

    except Exception as e:
        print(f"\n--- DETAILED ERROR IN get_similarity_score ---")
        traceback.print_exc()
        return 0.0

@app.route("/health", methods=["GET"])
def health():
    """Health check endpoint to confirm the server is running."""
    if db is None:
        return jsonify({"status": "error", "message": "Database not initialized"}), 500
    if EMBEDDING_MODEL is None:
        return jsonify({"status": "error", "message": "ML Model not loaded"}), 500
    return jsonify({"status": "ok", "message": "Server is healthy, Database connected, ML Model loaded."})

@app.route("/match", methods=["POST"])
def match_fingerprint():
    if db is None or EMBEDDING_MODEL is None:
        return jsonify({"error": "Server is not ready"}), 500

    input_fp_bytes = None
    if request.is_json and "fingerPrintBase64" in request.json:
        try:
            input_fp_bytes = base64.b64decode(request.json["fingerPrintBase64"])
        except Exception as e:
            return jsonify({"error": f"Invalid Base64 data: {e}"}), 400
    elif "file" in request.files:
        file = request.files["file"]
        input_fp_bytes = file.read()
    try:
        np_arr = np.frombuffer(input_fp_bytes, np.uint8)
        input_img = cv2.imdecode(np_arr, cv2.IMREAD_GRAYSCALE)
        if input_img is None:
            raise ValueError("cv2.imdecode returned None")
    except Exception as e:
        print(f"Failed to decode input image: {e}")
        return jsonify({"error": "Invalid or corrupted image format"}), 400
    
    try:
        _, buffer = cv2.imencode('.png', input_img)
        uploaded_fp_base64 = base64.b64encode(buffer).decode('utf-8')
    except Exception as e:
        print(f"Failed to re-encode uploaded image: {e}")
        uploaded_fp_base64 = ""

    matches = []
    
    try:
        citizens_ref = db.collection("citizens").stream()
        
        for doc in citizens_ref:
            citizen = doc.to_dict()
            if "fingerprint_image" not in citizen:
                continue 

            try:
                stored_fp_base64 = citizen["fingerprint_image"]
                stored_bytes = base64.b64decode(stored_fp_base64)
                np_arr2 = np.frombuffer(stored_bytes, np.uint8)
                stored_img = cv2.imdecode(np_arr2, cv2.IMREAD_GRAYSCALE)
                if stored_img is None:
                    print(f"Warning: Skipping citizen {doc.id}, failed to decode stored fingerprint.")
                    continue
            except Exception as e:
                print(f"Warning: Skipping citizen {doc.id}, error decoding stored fingerprint: {e}")
                continue

            score = get_similarity_score(
                input_img, 
                stored_img, 
                EMBEDDING_MODEL, 
                MODEL_INPUT_SHAPE
            )

            if score > 0.1:
                matches.append({
                    "nic": doc.id,
                    "name": citizen.get("name", "N/A"),
                    "passportId": citizen.get("passportId", "N/A"),
                    "profileUrl": citizen.get("profile_image", ""),
                    "score": float(score),
                    "uploaded_fp_base64": uploaded_fp_base64
                })

    except Exception as e:
        print(f"An error occurred while querying Firestore: {e}")
        return jsonify({"error": "A server error occurred during database matching."}), 500

    matches.sort(key=lambda x: x["score"], reverse=True)
    
    return jsonify({"matches": matches[:3]})


if __name__ == "__main__":
    """Main entry point to run the Flask server."""
    if EMBEDDING_MODEL is None:
        print("---")
        print("WARNING: ML MODEL IS NOT LOADED. The /match endpoint will fail.")
        print(f"Please make sure '{MODEL_FILE}' is in this directory.")
        print("---")
    if db is None:
        print("---")
        print("WARNING: FIREBASE IS NOT CONNECTED. All endpoints will fail.")
        print("Please make sure 'firebase_key.json' is in this directory.")
        print("---")
        
    print(f"Starting Flask server on http://0.0.0.0:5001")
    app.run(host="0.0.0.0", port=5001, debug=True, use_reloader=False)