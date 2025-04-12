import numpy as np
import matplotlib.pyplot as plt
from scipy.signal import butter, filtfilt, savgol_filter, detrend

# === Settings ===
INPUT_FILE = r"C:\Users\hp\Downloads\REDPPGTEST1.csv"
OUTPUT_FILE = r"TFlite_model\preprocessed_segment.npy"
FS = 30
SEGMENT_LENGTH = 120
WARMUP_TRIM = 100
VARIANCE_THRESHOLD = 0.3

# === Preprocessing Functions ===
def bandpass_filter(signal, fs=30, lowcut=0.5, highcut=4.0, order=4):
    nyq = 0.5 * fs
    b, a = butter(order, [lowcut / nyq, highcut / nyq], btype='band')
    return filtfilt(b, a, signal)

def preprocess_signal(signal):
    trimmed = signal[WARMUP_TRIM:]
    filtered = bandpass_filter(trimmed)
    detrended_sig = detrend(filtered)
    normalized = (detrended_sig - np.mean(detrended_sig)) / np.std(detrended_sig)
    smoothed = savgol_filter(normalized, 15, polyorder=2)
    return smoothed

def segment_signal(signal, seg_len=120, threshold=0.3):
    segments = []
    for i in range(0, len(signal) - seg_len + 1, seg_len):
        seg = signal[i:i + seg_len]
        if np.std(seg) >= threshold:
            segments.append(seg)
    return np.array(segments)

# === Load and preprocess signal ===
signal = np.loadtxt(INPUT_FILE, delimiter=',').flatten()
processed = preprocess_signal(signal)
segments = segment_signal(processed)

if len(segments) == 0:
    print("❌ No usable segments found.")
    exit()

# === Save ALL valid segments to match Keras code ===
x_input = segments.reshape(-1, SEGMENT_LENGTH, 1).astype(np.float32)
np.save(OUTPUT_FILE, x_input)
print(f"✅ Saved {x_input.shape[0]} segments for TFLite inference.")

# === Plot first few segments ===
for i in range(min(3, len(segments))):
    plt.figure(figsize=(6, 2.5))
    plt.plot(segments[i])
    plt.title(f"Segment {i+1} | std = {np.std(segments[i]):.2f}")
    plt.grid(True)
    plt.tight_layout()
    plt.show()
