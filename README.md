# Industrial Agriculture and Local Economic Growth: Evidence from Historical Satellite Imagery


This repository contains the code required to reproduce my thesis for the M.Sc. in Economics for Development at the University of Oxford. **I am actively working on it, and significant errors are likely to exist.** The final paper will be available here after July 2022 once it has been completed and approved for sharing publicly by the Examination Committee. 


**Acknowledgements:** Estimates of household durable assets were generated using model weights from [Yeh et al. (2020)](https://www.nature.com/articles/s41467-020-16185-w), which Christopher Yeh generously made available on [GitHub](https://github.com/chrisyeh96/africa_poverty_clean) along with other helpful functions which I greatly benefited from. Many of the functions I wrote for this dissertation for generating mosaics of Landsat imagery, exporting image patches, and processing the resulting TFRecords were based in large part on those originally written by Chris and his team. All errors are of course my own.


### Abstract
Large-scale agriculture developments are an increasingly important feature of rural economies in sub-Saharan Africa, although their effect on local economic growth is both theoretically and empirically ambiguous. In my dissertation, I study the effect that these openings have on changes in household assets in the areas surrounding 617 sites across the continent. I combine data on land acquisitions with village-level estimates of household assets which I obtain using a convolutional neural network to extract features predictive of these assets from historical satellite imagery collected by NASA's Landsat program for the period between 1985 and 2021. I then use these estimates in a differences-in-differences model, where I find that industrial agriculture openings have a modest and positive effect on household assets in areas immediately adjacent to these developments. Using a small sample of non-agricultural land acquisitions, I further present evidence suggestive of significant heterogeneity in the effect of new industrial developments. While food and non-food agriculture continue to have a positive effect, land acquisitions for the purpose of energy, forestry and mining have a moderate negative effect. I conclude with a discussion of the potential as well as the concerns for using remote-sensing and deep-learning derived predictions to answer causal questions in economics.




## Overview

**Complete instructions forthcoming.**

There are two sources of data used in my dissertation: 
- Historical Landsat Satellite Imagery, available from [Earth Engine](https://developers.google.com/earth-engine/datasets/catalog/landsat)
- Dataset of Large-Scale Land Acquisitions from the [LandMatrix](https://landmatrix.org)

Both datasets require significant processing before they can be used by the scripts in the analysis directory. Scripts to generate mosaics and export image patches, process the TFRecords, and clean the LandMatrix deals are located in the preprocessing directory. Due to dependencies between the script, they must be run in order, and each step must be completed prior to starting the next step. 

Note there is a significant amount of time required for processing. Exporting image patches takes ~15 days, and due to limits on active tasks must be run in batches. Once image patches are exported, processing the TFRecords takes ~8hrs and extracting features takes ~4hrs to complete on a machine similar to that listed below. Inference was significantly accelerated by the GPU, and without it feature extraction will take considerably longer. You will need at least 750GB of storage available to download and process the dataset, which is 350GB in its final size. 

The final dataset which I use in my analysis is available in the `data/` directory, but due to licensing and practical reasons, I cannot share the raw files. They can be obtained for free from the Google Earth Engine (requires registration) and the LandMatrix, respectively. 


### Before you start: 

You'll need Python3.7 and R > 4.0, along with several other packages in order to run everything. I recommend setting up a Conda environment, which you can do using the `env.yml` file.  


You'll also need to sign up for an account with Google Earth Engine. 


### STEPS

To begin, we'll need to obtain the locations for each land acquisition that will eventually be a part of the dataset. To do this:

1. Downloading the entire LandMatrix dataset in CSV form, which you can find from their website (TODO: Automate if possible). 
2. Run the `process_landmatrix.R` script. 
3. 








