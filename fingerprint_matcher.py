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
        
        if EMBEDDING_MODEL.input_shape:
             MODEL_INPUT_SHAPE = EMBEDDING_MODEL.input_shape[1:3]
        else:
             MODEL_INPUT_SHAPE = (96, 96) 

        print(f"Successfully loaded model '{MODEL_FILE}' with input shape {MODEL_INPUT_SHAPE}.")
    else:
        print(f"FATAL ERROR: Model file '{MODEL_FILE}' not found.")
        print("Please place the .h5 file in the same directory as this script.")
except Exception as e:
    print(f"FATAL ERROR: Could not load model '{MODEL_FILE}'. Error: {e}")

def rotate_image(image, angle):
    """Rotates an image by a specific angle."""
    image_center = tuple(np.array(image.shape[1::-1]) / 2)
    rot_mat = cv2.getRotationMatrix2D(image_center, angle, 1.0)
    result = cv2.warpAffine(image, rot_mat, image.shape[1::-1], flags=cv2.INTER_LINEAR, borderValue=(255,255,255))
    return result

def _preprocess_image(img, target_shape=(96, 96)):
    """
    Standard Preprocessing (Histogram Equalization)
    """
    if len(img.shape) > 2 and img.shape[2] == 3:
        img = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)

    img = cv2.equalizeHist(img)
    img = cv2.resize(img, target_shape, interpolation=cv2.INTER_AREA)
    img = img.astype(np.float32) / 255.0
    
    img = np.expand_dims(img, axis=0)
    img = np.expand_dims(img, axis=-1)
    
    return img

def get_similarity_score(img1_raw, img2_raw, model, shape):
    """
    Calculates similarity with Rotation Check + STEEPER Gaussian Scoring.
    """
    if model is None or shape is None:
        return 0.0
        
    try:
        proc_img2 = _preprocess_image(img2_raw, shape)
        vec2 = model.predict(proc_img2, verbose=0)[0]

        best_score = 0.0
        angles = [-10, 0, 10] 
        
        for angle in angles:
            if angle == 0:
                rotated_img = img1_raw
            else:
                rotated_img = rotate_image(img1_raw, angle)
            
            proc_img1 = _preprocess_image(rotated_img, shape)
            vec1 = model.predict(proc_img1, verbose=0)[0]
            distance = np.linalg.norm(vec1 - vec2)
            score = np.exp(-10 * (distance ** 2))
            
            if score > best_score:
                best_score = score
        
        return max(0.0, min(1.0, best_score))

    except Exception as e:
        print(f"Error in scoring: {e}")
        return 0.0

@app.route("/health", methods=["GET"])
def health():
    return jsonify({"status": "ok", "message": "Server is running."})

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
    except:
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
                if stored_img is None: continue
            except:
                continue

            score = get_similarity_score(
                input_img, 
                stored_img, 
                EMBEDDING_MODEL, 
                MODEL_INPUT_SHAPE
            )
            if score > 0.30: 
                matches.append({
                    "nic": doc.id,
                    "name": citizen.get("name", "N/A"),
                    "passportId": citizen.get("passportId", "N/A"),
                    "profileUrl": citizen.get("profile_image", ""),
                    "score": float(score),
                    "uploaded_fp_base64": uploaded_fp_base64
                })

    except Exception as e:
        print(f"Error querying Firestore: {e}")
        return jsonify({"error": "Database error"}), 500

    matches.sort(key=lambda x: x["score"], reverse=True)
    
    return jsonify({"matches": matches[:5]})

if __name__ == "__main__":
    if EMBEDDING_MODEL is None:
        print("WARNING: ML MODEL IS NOT LOADED.")
    app.run(host="0.0.0.0", port=5001, debug=True, use_reloader=False)