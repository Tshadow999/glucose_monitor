import numpy as np
import tensorflow as tf
from fastapi import FastAPI
from pydantic import BaseModel

# Initialize FastAPI app
app = FastAPI()

# Define input data model
class InputData(BaseModel):
    input: list[float]  # List of floats as input data

# Load your TensorFlow Lite model
interpreter = tf.lite.Interpreter(model_path="../mobile_app/assets/model.tflite")
interpreter.allocate_tensors()

def predict(input_data):
    input_array = np.array(input_data, dtype=np.float32).reshape(1, 120, 1)
    
    input_details = interpreter.get_input_details()

    interpreter.set_tensor(input_details[0]['index'], input_array)
    interpreter.invoke()
    
    output_details = interpreter.get_output_details()
    output_array = interpreter.get_tensor(output_details[0]['index'])
    
    return float(output_array[0][0])


@app.post("/predict/")
async def make_prediction(data: InputData):
    result = predict(data.input)
    # Return a regular Python dictionary with the float value
    return {"prediction": float(result)}
