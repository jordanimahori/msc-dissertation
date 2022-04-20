#!/bin/bash

# This Bash script downloads trained TensorFlow model checkpoints
# from GitHub into the outputs/ directory.
#
# Run this script from within the preprocessing/ directory.
#
# Prerequisites: None.

mkdir -p ../outputs
cd ../outputs

BASE_GITHUB_URL="https://github.com/sustainlab-group/africa_poverty/releases/download/v1.0.1/"

MS_INCOUNTRY_MODELS=(
    "DHS_Incountry_A_ms_samescaled_b64_fc01_conv01_lr001"
    "DHS_Incountry_B_ms_samescaled_b64_fc1_conv1_lr001"
    "DHS_Incountry_C_ms_samescaled_b64_fc1.0_conv1.0_lr0001"
    "DHS_Incountry_D_ms_samescaled_b64_fc001_conv001_lr0001"
    "DHS_Incountry_E_ms_samescaled_b64_fc001_conv001_lr0001"
)


echo "Downloading and unzipping Yeh et al. Multi-spectral In-Country Model Checkpoints"
mkdir ms_incountry
for model in ${MS_INCOUNTRY_MODELS[@]}
do
    echo "Downloading model ${model}"
    url="${BASE_GITHUB_URL}/${model}.zip"
    wget --no-verbose --show-progress -P ms_incountry ${url}

    echo "Unzipping model ${model}"
    unzip "ms_incountry/${model}.zip" -d "ms_incountry/${model}"
    rm "ms_incountry/${model}.zip"
done
