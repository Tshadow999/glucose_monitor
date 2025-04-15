import numpy as np
import pandas as pd
from scipy.signal import butter, filtfilt, detrend, savgol_filter
import tensorflow as tf
from fastapi import FastAPI, UploadFile, File
from fastapi.responses import JSONResponse

# === PARAMETERS ===
SEGMENT_LEN = 120
WARMUP_TRIM = 100
SAMPLING_RATE = 30
LOWCUT = 0.5
HIGHCUT = 8.0

# === FastAPI Setup ===
app = FastAPI()

# === Signal Processing ===
def bandpass_filter(signal, fs=SAMPLING_RATE, lowcut=LOWCUT, highcut=HIGHCUT, order=4):
    nyq = 0.5 * fs
    b, a = butter(order, [lowcut / nyq, highcut / nyq], btype='band')
    return filtfilt(b, a, signal)

def preprocess_signal(signal):
    trimmed = signal[WARMUP_TRIM:]
    filtered = bandpass_filter(trimmed)
    detrended_signal = detrend(filtered)
    normalized = (detrended_signal - np.mean(detrended_signal)) / (np.std(detrended_signal) + 1e-8)
    smoothed = savgol_filter(normalized, 15, polyorder=2)
    return smoothed

def create_segments(signal, segment_len=SEGMENT_LEN):
    return np.array([
        signal[i:i + segment_len]
        for i in range(0, len(signal) - segment_len + 1, segment_len)
    ])

# === Load TFLite Model ===
interpreter = tf.lite.Interpreter(model_path="model.tflite")
interpreter.allocate_tensors()
input_details = interpreter.get_input_details()
output_details = interpreter.get_output_details()

def predict_with_tflite(X_batch):
    predictions = []
    for x in X_batch:
        x = x.astype(np.float32).reshape(1, 120, 3)
        interpreter.set_tensor(input_details[0]['index'], x)
        interpreter.invoke()
        output = interpreter.get_tensor(output_details[0]['index'])
        predictions.append(float(output[0][0]))
    return np.array(predictions)

@app.post("/predict/")
async def make_prediction(file: UploadFile = File(...)):
    try:
        df = pd.read_csv(file.file)

        preprocessed_signals = {
            color: preprocess_signal(df[color].values)
            for color in ['GREEN', 'RED', 'IR']
        }

        segments = {
            color: create_segments(preprocessed_signals[color])
            for color in ['GREEN', 'RED', 'IR']
        }

        min_len = min(len(segments['GREEN']), len(segments['RED']), len(segments['IR']))
        green_input = segments['GREEN'][:min_len]
        red_input = segments['RED'][:min_len]
        ir_input = segments['IR'][:min_len]

        X_input = np.stack([green_input, red_input, ir_input], axis=-1)

        predictions = predict_with_tflite(X_input)

        # Filter outliers
        med = np.median(predictions)
        mad = np.median(np.abs(predictions - med)) + 1e-8
        threshold = 2.5
        filtered_preds = predictions[np.abs(predictions - med) < threshold * mad]

        final_bgl = np.mean(filtered_preds)

        return {"prediction": round(float(final_bgl), 2)}

    except Exception as e:
        return JSONResponse(status_code=500, content={"error": str(e)})
