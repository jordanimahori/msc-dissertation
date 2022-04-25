# This script uses weights trained using ridge regression on extracted features from extract_features.py to predict
# household assets.

import numpy as np
import pandas as pd
import os
import math
from glob import glob

# Parameters
MODEL_FOLDS = ['A', 'B', 'C', 'D', 'E']
MODEL_DIR = 'outputs/ms_incountry'
FEATURES_PATHS = {i: glob(os.path.join(MODEL_DIR, f'DHS_Incountry_{i}_*', 'features.npz')) for i in MODEL_FOLDS}


# Load Model Weights
npz = np.load('outputs/ridge_weights.npz')
weights_dict = {}
for key, value in npz.items():
    weights_dict[key] = value

# Load Features and Predictions for Each Model
features_dict = {}
labels_dict = {}
for fold in MODEL_FOLDS:
    features_path = FEATURES_PATHS[fold]
    npz = np.load(features_path)
    features_dict[fold] = npz['features']
    labels_dict[fold] = npz['labels']


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
        # Assert that labels are all in order
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
    # Invert dictionary to allow ring # lookup using tile_id
    ring_map = {f'{tile_number:04d}': ring_id for ring_id, tile_number in ring_dict.items()}
    return ring_map


# ==================== INFERENCE =====================

# Predict household material assets from extracted features using weights from ridge regression
predicted_assets, tile_ids = predict_assets(features_dict, weights_dict, labels_dict)

# Get mapping from tile_id to which concentric ring the tile falls into
ring_map = get_ring_ids(2)

# Construct dataframe with asset predictions and tile characteristics
dataframe = pd.DataFrame()
dataframe['assets'] = predicted_assets
dataframe['deal_id'] = [tile_id[0:4] for tile_id in tile_ids]
dataframe['tile_id'] = [tile_id[4:8] for tile_id in tile_ids]
dataframe['level'] = dataframe['tile_id'].map(lambda x: ring_map[x])

# Save dataframe in data directory
dataframe.to_csv("data/asset_predictions.csv")
