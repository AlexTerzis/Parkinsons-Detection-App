import numpy as np
import pandas as pd

N = 500  # samples per class
TEST_DURATION_MS = 10000

def simulate_taps(mean_interval, std_interval, duration_ms):
    taps = []
    current_time = 0
    while current_time < duration_ms:
        interval = np.random.normal(mean_interval, std_interval)
        interval = max(60, interval)  # prevent unrealistic intervals
        current_time += interval
        taps.append(current_time)
    return taps

def extract_features(taps):
    intervals = np.diff(taps)
    if len(intervals) == 0:
        return [0, 0, 0, 0, 0, 0, 0]
    mean = np.mean(intervals)
    std = np.std(intervals)
    var = np.var(intervals)
    freq = 1000 / mean
    first_half = np.sum(np.array(taps) < TEST_DURATION_MS / 2)
    second_half = len(taps) - first_half
    return [len(taps), mean, std, var, freq, first_half, second_half]

data = []
labels = []

# Healthy examples
for _ in range(N):
    taps = simulate_taps(160, 15, TEST_DURATION_MS)
    data.append(extract_features(taps))
    labels.append(0)

# Parkinson examples
for _ in range(N):
    taps = simulate_taps(280, 60, TEST_DURATION_MS)
    data.append(extract_features(taps))
    labels.append(1)

# Save to CSV
columns = ['tap_count', 'mean_interval', 'std_interval', 'var_interval', 'frequency', 'first_half', 'second_half']
df = pd.DataFrame(data, columns=columns)
df['label'] = labels

df.to_csv('tapping_dataset.csv', index=False)
print("✅ Simulated dataset saved to tapping_dataset.csv")
