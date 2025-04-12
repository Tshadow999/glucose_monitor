import numpy as np
import tensorflow as tf

# === Load preprocessed input ===
x_input = np.load("TFlite_model/preprocessed_segment.npy")

# === Load TFLite model ===
interpreter = tf.lite.Interpreter(model_path="fine_tuned_red_model.tflite")
interpreter.allocate_tensors()

input_details = interpreter.get_input_details()
output_details = interpreter.get_output_details()

preds = []
for seg in x_input:
    seg = seg.reshape(1, 120, 1).astype(np.float32)
    interpreter.set_tensor(input_details[0]['index'], seg)
    interpreter.invoke()
    output = interpreter.get_tensor(output_details[0]['index'])
    preds.append(output[0][0])

# === Final prediction
mean_bgl = np.mean(preds)
print(f"📊 TFLite Predicted BGL (avg of {len(preds)} segments): {mean_bgl:.2f} mg/dL")
