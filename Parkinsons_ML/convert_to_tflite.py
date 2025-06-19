import tensorflow as tf

# Load the trained .h5 model
model = tf.keras.models.load_model("tapping_model.h5")

# Convert to TFLite
converter = tf.lite.TFLiteConverter.from_keras_model(model)
tflite_model = converter.convert()

# Save to file
with open("tapping_model.tflite", "wb") as f:
    f.write(tflite_model)

print("✅ Model converted and saved as tapping_model.tflite")
