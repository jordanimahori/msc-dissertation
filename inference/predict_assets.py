# This script uses weights trained using ridge regression on extracted features from extract_features.py to predict
# household assets.

from typing import Optional
import numpy as np
import os
import math


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
labels_dict = {}
for fold in MODEL_FOLDS:
    features_path = os.path.join(FEATURE_DIR, f'features_{fold}.npz')
    npz = np.load(features_path)
    features_dict[fold] = npz['features']
    labels_dict[fold] = npz['labels']

    # Assert that labels are all in order


def predict_assets(feature_dict: dict,
                   weight_dict: dict,
                   label_dict: dict):
    """
    Args:
        - feature_dict: Features to be used for prediction
        - weight_dict: Model weights for linear model
        - label_dict: Labels outputted by Yeh et al. checkpoint

    Returns:
        - mean_prediction: Array of mean of predictions from all models
    """
    labels = []
    for i in range(len(label_dict['A'])):
        assert label_dict['A'][i] == label_dict['B'][i] == label_dict['C'][i] == label_dict['D'][i] == \
               label_dict['E'][i]
        tile_id = str(int(label_dict['A'][i]))
        labels.append(tile_id)

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
    mean_prediction = np.mean(predictions, axis=0).tolist()
    return mean_prediction, labels


def get_ring_ids(rings):
    width = (rings*2 + 1)
    ar = np.arange(0, width**2, 1).reshape(width, width)
    ring_dict = {}

    for i in range(math.ceil(width / 2)):
        if math.floor(width / 2) == i:
            items = [ar[i, i].tolist()]
        else:
            items = ar[i, i:(width - i)].tolist() + ar[-(i + 1), i:(width - i)].tolist() + \
                    ar[i:(width - i), i].tolist() + ar[i:(width - i), -(i + 1)].tolist()
        ring_dict[i] = list(set(items))
    return ring_dict


# ==================== INFERENCE =====================

# Predict household material assets from extracted features using weights from ridge regression
predicted_assets, tile_labels = predict_assets(features_dict, weights_dict, labels_dict)

