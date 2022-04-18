import os
from glob import glob

import tensorflow as tf
import pandas as pd


# ==================== PARAMETERS ===================

# Specify names locations for outputs in Cloud Storage.
INPUT_DIR = 'data/tfrecords_raw'
PROCESSED_DIR = 'data/tfrecords'

# Specify CSV file with locations to export
CSV_PATH = './data/earthengine_locs.csv'

# Specify image bands.
FEATURES = ['BLUE', 'GREEN', 'LAT', 'LON', 'NIR', 'RED', 'SWIR1', 'SWIR2', 'TEMP1']

# Specify the size and shape of patches expected by the model.
NUM_OBS = 25
KERNEL_SIZE = 255
KERNEL_SHAPE = [KERNEL_SIZE, KERNEL_SIZE]
COLUMNS = [
    tf.io.FixedLenFeature(shape=KERNEL_SHAPE, dtype=tf.float32) for k in FEATURES
]

# Specifies the schema for the parsed TFRecord
FEATURE_DESCRIPTION = dict(zip(FEATURES, COLUMNS))                  # Specifies schema for each feature


# ================= PARSE TFRECORDS =================

def process_tfrecords(csv_path: str, input_dir: str, processed_dir: str):
    """
    For each deal_id (i.e. observation), this function applies the parse_tfrecord function
    to each TFRecord corresponding with a deal_id specified in the CSV path. It then splits the
    TFRecord for every deal_id into TFRecords for each image patch associated with that deal_id,
    preserving the id of the tile in the filename. NOTE: It expects a single TFRecord per deal_id
    (Earth Engine will only ever output a single TFRecord for each call to ee.Export).

    Args:
    - csv_path: location of CSV file to extract deal_ids from
    - input_dir: directory in which to find TFRecord files
    - output_dir: directory in which to save processed TFRecord files
    """
    df = pd.read_csv(csv_path, float_precision='high', index_col=False)
    deal_ids = df['deal_id']

    for deal_id in deal_ids:                               # iterate over all deal_ids
        output_dir = os.path.join(processed_dir, str(deal_id))
        os.makedirs(output_dir, exist_ok=True)
        tfrecord_paths = glob(os.path.join(input_dir, str(deal_id) + '*'))
        tfrecord_paths.sort()

        for tfrecord in tfrecord_paths:                    # iterate over all years of observation
            dataset = tf.data.TFRecordDataset(tfrecord)
            observation_dict = parse_tfrecord(dataset, FEATURE_DESCRIPTION)
            year = int(tfrecord[-13:-9])                   # extracts the year from the TFRecord name

            for i, feature_dict in observation_dict.items():
                output_path = os.path.join(output_dir, f'{year}_{i:04d}.tfrecord.gz')  # NRINGS must be < 10
                example = encode_feature_dict(feature_dict)

                with tf.io.TFRecordWriter(output_path) as writer:
                    writer.write(example.SerializeToString())


def parse_tfrecord(raw_dataset: tf.data.TFRecordDataset, feature_description: dict):
    """
   This function parses a TFRecord loaded as a TFRecordDataset into its constituent observations
   and features. It expects the number of observations within the TFRecord dataset to match the
   amount specified in NUM_OBS (determined by the number of concentric rings of tiles exported
   when creating the TFRecords for each deal_id).

    Args:
    - raw_dataset: tf.data.TFRecordDataset, dataset to be parsed
    - feature description: dict, schema used to parse TFRecord

    Returns:
    - dict of observations and corresponding features
    """
    feature_description = feature_description
    feature_dict = {}

    def parse_function(example_proto):
        # Parse the `tf.train.Example` proto using the above dictionary.
        return tf.io.parse_example(example_proto, feature_description)

    for i, raw_record in enumerate(raw_dataset):
        parsed_record = parse_function(raw_record)
        feature_dict[i] = parsed_record

    return feature_dict


def encode_feature_dict(feature_dict: dict):
    """
    Serializes a dictionary of features so that it can be written as a TFRecord.

    Args:
    -feature_dict: dict, a dictionary containing features for a single observation

    Returns:
    - serialized_feature_dict: tf.train.Example
    """
    serialized_feature_dict = {}
    for key, tensor in feature_dict.items():
        feature = tf.train.Feature(float_list=tf.train.FloatList(value=tensor.numpy().flatten()))
        serialized_feature_dict[key] = feature

    features = tf.train.Features(feature=serialized_feature_dict)
    example = tf.train.Example(features=features)

    return example


# Call the function on all deal_ids to generate individual TFRecords
if __name__ == '__main__':
    process_tfrecords(csv_path=CSV_PATH, input_dir=INPUT_DIR, processed_dir=PROCESSED_DIR)
