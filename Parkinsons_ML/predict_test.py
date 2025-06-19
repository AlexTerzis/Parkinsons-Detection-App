import joblib
import pandas as pd

model = joblib.load('tapping_model.pkl')

sample_dict = {
    'tap_count': [40],
    'mean_interval': [260],
    'std_interval': [45],
    'var_interval': [2250],
    'frequency': [4.25],
    'first_half': [20],
    'second_half': [30]
}

df_sample = pd.DataFrame(sample_dict)
prediction = model.predict(df_sample)[0]
probability = model.predict_proba(df_sample)[0][1]

print(f"Prediction: {'Parkinson-like' if prediction == 1 else 'Healthy'}")
print(f"Probability: {probability * 100:.2f}%")
