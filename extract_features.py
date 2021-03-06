"""
This script runs trained CNN models to extract features from either the DHS or
LSMS satellite images.
Usage:
    python extract_features.py
Note: this script does not take any command line options. Instead, set
parameters in the "Parameters" section below.
Prerequisites:
1) download TFRecords, process them, and create incountry folds. See
    `preprocessing/1_process_tfrecords.ipynb` and
    `preprocessing/2_create_incountry_folds.ipynb`.
2) either train models (see README.md for instructions), or download model
    checkpoints into outputs/ directory using the checkpoint download
    script in `preprocessing/4_download_model_checkpoints.sh`
"""

from __future__ import annotations

from collections import defaultdict
from collections.abc import Callable, Iterable
from glob import glob
import json
import os
from typing import Optional

import numpy as np
import tensorflow as tf

from utils import batcher, tfrecord_paths_utils
from models.resnet_model import Hyperspectral_Resnet
from utils.run import check_existing, run_extraction_on_models


OUTPUTS_ROOT_DIR = 'outputs'
INPUTS_DIR = 'data/tfrecords'


# ====================
#      Parameters
# ====================
BATCH_SIZE = 128
KEEP_FRAC = 1.0
IS_TRAINING = False

# set CACHE = True for faster feature extraction on multiple models
# only if you have enough RAM (>= 300 GB)
CACHE = False

MULTISPECTRAL_MODELS: list[str] = [
    # Paths to checkpoints for in-country multi-spectral models from Yeh et al. (2020)
    'ms_incountry/DHS_Incountry_A_ms_samescaled_b64_fc01_conv01_lr001',
    'ms_incountry/DHS_Incountry_B_ms_samescaled_b64_fc1_conv1_lr001',
    'ms_incountry/DHS_Incountry_C_ms_samescaled_b64_fc1.0_conv1.0_lr0001',
    'ms_incountry/DHS_Incountry_D_ms_samescaled_b64_fc001_conv001_lr0001',
    'ms_incountry/DHS_Incountry_E_ms_samescaled_b64_fc001_conv001_lr0001'
]

# choose which GPU to run on
os.environ['CUDA_VISIBLE_DEVICES'] = '0'

MODEL_PARAMS = {
    'fc_reg': 5e-3,  # this doesn't actually matter
    'conv_reg': 5e-3,  # this doesn't actually matter
    'num_layers': 18,
    'num_outputs': 1,
    'is_training': IS_TRAINING,
}


# ====================
# End Parameters
# ====================


def get_model_class(model_arch: str) -> Callable:
    if model_arch == 'resnet':
        model_class = Hyperspectral_Resnet
    else:
        raise ValueError('Unknown model_arch. Currently only "resnet" is supported.')
    return model_class


def get_batcher(tfrecord_dir: str, ls_bands: str, nl_band: str, num_epochs: int,
                cache: bool) -> tuple[batcher.Batcher, int, dict]:
    """
    Gets the batcher for a given dataset.
    Args
    - dataset: str, one of ['dhs', 'lsms'] # TODO
    - ls_bands: one of [None, 'ms', 'rgb']
    - nl_band: one of [None, 'merge', 'split']
    - num_epochs: int
    - cache: bool, whether to cache the dataset in memory if num_epochs > 1
    Returns
    - b: Batcher
    - size: int, length of dataset
    - feed_dict: dict, feed_dict for initializing the dataset iterator
    """
    tfrecord_paths = glob(os.path.join(tfrecord_dir, '*', '*.tfrecord.gz'))

    size = len(tfrecord_paths)
    tfrecord_paths_ph = tf.placeholder(tf.string, shape=[size])
    feed_dict = {tfrecord_paths_ph: tfrecord_paths}

    b = batcher.Batcher(
        tfrecord_files=tfrecord_paths_ph,
        label_name='wealthpooled',
        ls_bands=ls_bands,
        nl_band=nl_band,
        nl_label=None,
        batch_size=BATCH_SIZE,
        epochs=num_epochs,
        normalize='DHS',
        shuffle=False,
        augment=False,
        clipneg=True,
        cache=(num_epochs > 1) and cache,
        num_threads=5)

    return b, size, feed_dict


def read_params_json(model_dir: str, keys: Iterable[str]) -> tuple:
    """
    Reads requested keys from json file at `model_dir/params.json`.
    Args
    - model_dir: str, path to model output directory containing params.json file
    - keys: list of str, keys to read from the json file
    Returns: tuple of values
    """
    json_path = os.path.join(model_dir, 'params.json')
    with open(json_path, 'r') as f:
        params = json.load(f)
    for k in keys:
        if k not in params:
            print(f'Did not find key "{k}" in {model_dir}/params.json. Setting to None.')
    result = tuple(params.get(k, None) for k in keys)
    return result


def main() -> None:
    for model_dirs in [MULTISPECTRAL_MODELS]:
        if not check_existing(model_dirs,
                              outputs_root_dir=OUTPUTS_ROOT_DIR,
                              test_filename='features.npz'):
            print('Stopping')
            return

    # group models by batcher configuration and model_arch, where
    #   config = (dataset, ls_bands, nl_band, model_arch)
    all_models = {'dhs': MULTISPECTRAL_MODELS}
    models_by_config: dict[
        tuple[str, Optional[str], Optional[str], str], list[str]
        ] = defaultdict(list)
    for dataset, model_dirs in all_models.items():
        for model_dir in model_dirs:
            ls_bands, nl_band, model_arch = read_params_json(
                model_dir=os.path.join(OUTPUTS_ROOT_DIR, model_dir),
                keys=['ls_bands', 'nl_band', 'model_name'])
            config = (dataset, ls_bands, nl_band, model_arch)
            models_by_config[config].append(model_dir)

    for config, model_dirs in models_by_config.items():
        dataset, ls_bands, nl_band, model_arch = config
        print('====== Current Config: ======')
        print('- dataset:', dataset)
        print('- ls_bands:', ls_bands)
        print('- nl_band:', nl_band)
        print('- model_arch:', model_arch)
        print('- number of models:', len(model_dirs))
        print()

        b, size, feed_dict = get_batcher(
            tfrecord_dir=INPUTS_DIR, ls_bands=ls_bands, nl_band=nl_band,
            num_epochs=len(model_dirs), cache=CACHE)
        batches_per_epoch = int(np.ceil(size / BATCH_SIZE))

        run_extraction_on_models(
            model_dirs,
            ModelClass=get_model_class(model_arch),
            model_params=MODEL_PARAMS,
            batcher=b,
            batches_per_epoch=batches_per_epoch,
            out_root_dir=OUTPUTS_ROOT_DIR,
            save_filename='features.npz',
            batch_keys=['labels', 'locs', 'years'],
            feed_dict=feed_dict)


if __name__ == '__main__':
    main()
