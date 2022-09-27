# Industrial Agriculture and Local Economic Growth: Evidence from Historical Satellite Imagery


This repository contains the code required to reproduce my thesis for the M.Sc. in Economics for Development at the University of Oxford. The paper is available [here]().


## Abstract 
```
Large-scale agriculture projects are an increasingly important feature of rural economies 
in sub-Saharan Africa, although their effect on local economic growth is both theoretically 
and empirically ambiguous. In this paper, I study the impact of these openings on changes 
in household assets in the areas surrounding 566 sites across the continent. I combine data 
on land acquisitions with village-level estimates of household assets which I obtain using 
a convolutional neural network to extract features predictive of these assets from historical 
satellite imagery collected by the Landsat program during the period between 1985 and 2021. I 
use the resulting panel to estimate difference-in-differences and event study models, where I 
find that industrial agriculture openings have a modest and positive effect on household 
assets in areas immediately adjacent to these developments. Using a larger sample of 
agricultural and non-agricultural land acquisitions, I further present evidence suggestive of 
significant heterogeneity in the effect of new large-scale developments. While food and 
non-food agriculture as well as mining continue to have a positive effect, land acquisitions 
for the purpose of forestry have a moderate negative effect.
```


## Overview


Research on the impact of large-scale agriculture projects has been restrained by a paucity of localized data that can be used to estimate the short and long-term impacts of such developments. I contribute to this literature by circumventing data limitations that constrained previous empirical studies and analyse the impact of commercial agriculture projects across a large number of sites over a 36-year period to provide an indicator of the average direction of this effect. To my knowledge, the panel constructed by this paper is the largest of any multi-period study that has so far been used to answer this question.  


From my introduction: 


```
In this paper, I estimate the impact of openings of large-scale commercial
agriculture projects on household assets for a large number of sites across Africa,
helping to shed light on the average direction of this effect. To do this, I construct
a novel panel dataset for the areas within a 20km radius of 566 land acquisitions
in 40 countries across the continent. I first generate granular predictions for house-
hold assets in the vicinity of these land acquisitions using a convolutional neural
network (CNN) applied to high-resolution multi-spectral satellite imagery from the
U.S. Geological Survey and NASA’s Landsat program, for the period between 1985
and 2021. I then combine these predictions with project-specific characteristics from
a dataset of land acquisitions and yearly country-level indicators for property rights
and governance.
```


While there is a lot going on in this paragraph, what this boils down to is two key steps: (1) Generate a panel dataset by tiling the area surrounding each land acquisition and use satellite imagery to generate mean household asset predictions for each tile for each 3-year period after 1985; (2) Use the panel to estimate difference-in-differences and event-study models as you would with any empirical economic study. 



### Generating the Panel Dataset

There are several steps that go into generating the panel dataset which I ultimately use in my analysis. The main points can be though of as follows: 

1. Obtain Land Acquisition Locations
2. Generate Cloud-free Mosaics
3. Generate Image Tiles
4. Obtain Asset Predictions for Each Tile 
5. Create Panel Dataset  


The first step is to identify a set of large-scale land acquisitions for which we have both precise locations for the acquisition centroids, and the date the agreement was signed and/or the date the construction of the development was completed. Not all acquisitions contain precise locations for the acquisition, the date the agreement was signed, or the date the development became operational. In the `process_landmatrix.R`, I discard acquisitions not containing this information as well as not meeting several other validation criteria. 

Next, for each identified acquisition, I generate cloud-free mosaics using imagery collected over a 3-year period, for each 3-year period starting in 1985. Three years was chosen for consistency with Yeh et al. (2020), who selected this as the minimum period over which a cloud-free image across all regions can be obtained. This processing is all performed on the imagery while it is still in Earth Engine, and utils in `utils` help abstract away the interaction with this imagery (here, I benefited significantly by the work of Christopher Yeh and colleagues, who generously made their code available and from which my utilities are adapted). 

Now, for each land acquisition and period in the study, I extract an area with a radius of 20km centred on the land acquisition centroid, which is further subdivided into a grid of 5x5 tiles each measuring 255x255 pixels across. This is done in `export_images.py`. While it would have been preferable to specify the dimensions of the study area in pixels, limitations in Earth Engine require that the area to be extracted be measured in meters, and consequently 20km was chosen experimentally as the diameter that most closely approximates the desired dimensions for all sites in my study (the spatial resolution of 30m is only true at the Equator). This introduces some noise in the placement of the tiles. I then export these tiles in TFRecord format. Earth Engine groups all tiles drawn from the same image together, so I split these apart into individual TFRecords for compatibility with `batcher.py`, as well as add a few features such as tile characteristics in `process_tfrecords.py`. 

<p align="center">
<img width="600" alt="figure_1" src="https://user-images.githubusercontent.com/40173965/192405404-986e2ac0-8e2c-4d0d-a852-1ad035bace07.png">
</p>

Finally, I obtain asset predictions by first using the model developed by Yeh et al. to extract 512-dimension feature vectors from each tile and obtain asset predictions by weighing each feature using the weights from my linear model (discussed below). This is accomplished in `extract_features.py` and `predict_assets.py` respectively. In `merge_and_validate.R`, asset predictions are associated with tile, acquisition and country characteristics for every period in the study to create a panel where the tile is the unit of observation.


**NOTE:** As the model provided by Yeh et al. (2020) is without weights, weights for the final ridge regression layer of Yeh et al. (2020)'s model must first be obtained. I obtained similar weights by following the processes detailed in their [respository](https://github.com/sustainlab-group/africa_poverty), which essentially amounts to exporting images for each DHS Cluster and training a ridge model on the feature vectors extracted from each of those images tiles and labels from their CSV of labels. See their repository for a more complete explanation of the process. 




### Empirical Estimation

The empirical analysis is similar to that in other applied microeconomic papers, and is discussed at length in the full paper available above. 




### Data
There are two principal sources of data used in my dissertation: 

- Historical Landsat Satellite Imagery, available from [Earth Engine](https://developers.google.com/earth-engine/datasets/catalog/landsat)
- Database of Large-Scale Land Acquisitions from the [LandMatrix](https://landmatrix.org)

Both datasets require significant processing to transform them into the panel used in my main analysis. Scripts to generate mosaics and export image patches, process the TFRecords, and clean the LandMatrix deals are located in the Preprocessing directory. Due to dependencies between the scripts, they must be run in order. 

As some of these scripts involve a large amount of computation, they can take some time to run. Exporting image patches for the areas surrounding each of the land acquisitions in my sample requires ~15 days for the tasks running on Earth Engine. Running inferences on each of the resulting tiles takes approximately 24hrs with a single GPU. The time required for running the other scripts is not notable (i.e. <30 mins). 

The final dataset which I use in my analysis is available in the `data/` directory, but due to licensing and practical considerations, I cannot share the raw files. They can be obtained for free from the Google Earth Engine (requires registration) and the LandMatrix, respectively. 




## Replication

### Before you start: 

This code has been tested on a virtual machine running in Google Cloud with the following specifications: 

- Instance Type: n1-highmem-8
- Operating System: Ubuntu 18.04.6 LTS 
- CPU: Intel Xeon 8 Core
- GPU: Nvidia Tesla T4
- Memory (RAM): 52GB
- Disk Storage: 1500GB


In addition, the main dependencies are Python3.7,  R > 4.0 and Tensorflow v1.15. The full list of dependencies are included in the `env.yml` file. I recommend creating a Conda environment, which you do by calling:

```
conda create env -f env.yml
```

You'll also need to sign up for an account with Google Earth Engine. 


### Steps to Generate the Panel Dataset

1. **Download and Clean the LandMatrix Dataset:**
    * Download the entire LandMatrix dataset in CSV form, which you can find from their website. (TODO: Automate) 
    * Run the `preprocessing/process_landmatrix.R` script. 

2. **Create Cloud-free Mosaics and Extract Tiles From Around Land Acquisitions:**
    * Run the `preprocessing/extract_images.py` script. 

    * **NOTE:** Due to limits on the number of active tasks, this must be run in batches. Once image patches are exported, processing the TFRecords takes ~8hrs and extracting features takes ~4hrs to complete on a machine similar to that listed below. Inference was significantly accelerated by the GPU, and without it feature extraction will take considerably longer. You will need at least 750GB of storage available to download and process the dataset, which is 350GB in its final size. 

3. **Process TFRecords for Tiles:**
    * Run the `preprocessing/process_tfrecords.py` script. 
    * Remove problematic TFRecords by running the `preprocessing/clean_tfrecords.sh` script. 

4. **Extract Features from Tiles:**
    * Download model checkpoints by running `download_model_checkpoints.sh`
    * Extract feature vectors from tiles by running `extract_features.py` from the repository root. 

5. **Predict Household Assets:**
    * Run the `predict_assets.py`

6. **Merge Asset Predictions with Aquisition and Country Characteristics:**
    * Run `merge_and_validate.R`


Scripts used to obtain the results for all tables and graphs in the paper are available under the `analysis` directory. 




**Acknowledgements:** Estimates of household durable assets were generated using model weights from [Yeh et al. (2020)](https://www.nature.com/articles/s41467-020-16185-w), which Christopher Yeh generously made available on [GitHub](https://github.com/chrisyeh96/africa_poverty_clean) along with other helpful functions which I greatly benefited from. Many of the functions for generating mosaics from Landsat imagery, exporting image patches, and processing the resulting TFRecords were based in significant part on those originally written by Chris and his team. All errors are of course my own.


