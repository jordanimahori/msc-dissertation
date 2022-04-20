# This script uses weights trained using ridge regression on extracted features from extract_features.py to predict
# household assets.

import numpy as np
import os


# ============== PARAMETERS ===============
MODEL_FOLDS = ['A', 'B', 'C', 'D', 'E']
FEATURE_DIR = 'outputs/extracted_features'

# Load Model Weights
npz = np.load('outputs/ridge_weights.npz')
weights_dict = {}
for key, value in npz.items():
    weights_dict[key] = value

# TODO: Modify this or the extract features script to fetch features from model dir
# Load Features and Predictions for Each Model
features_dict = {}
predictions_dict = {}
for fold in MODEL_FOLDS:
    features_path = os.path.join(FEATURE_DIR, f'features_{fold}.npz')
    npz = np.load(features_path)
    features_dict[fold] = npz['features']
    predictions_dict[fold] = npz['preds']


def predict_assets(feature_dict: dict,
                   weight_dict: dict):
    """
    Args:
        - feature_dict: Features to be used for prediction
        - weight_dict: Model weights for linear model

    Returns:
        - mean_prediction: Array of mean of predictions from all models
    """
    predictions = []
    for i in MODEL_FOLDS:
        weights = weight_dict[f'{i}_w']
        bias = weight_dict[f'{i}_b']
        features = feature_dict[i]
        output = np.zeros(len(features), dtype=float)
        for j in range(len(features)):
            obs = features[j].reshape(512, 1)
            output[j] = weights @ obs + bias
        predictions.append(output)
    return np.mean(predictions, axis=0)


predicted_assets = predict_assets(features_dict, weights_dict)


"""
# There is a small difference between predictions from Yeh et al. function and my predictions. Can't figure out why...
# This is how to see that difference... 
# get predictions by commenting out return value and replace it with the list of arrays

predictions = predict_assets(features_dict, weights_dict)  


difference = {}
for i, key in enumerate(predictions_dict):
    ex = predictions_dict[key]
    val = predictions[i]
    difference[key] = ex - val
    difference[f'mean_{key}'] = np.mean(ex - val)
"""
