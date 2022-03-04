# Industrial Agriculture and Local Economic Growth: Evidence from Historical Satellite Imagery


**THIS IS A WORK IN PROGRESS.**


This repository contains the code required to reproduce my thesis for the MSc 
in Economics for Development at the University of Oxford. It is currently under 
active development and significant errors are likely to exist. This repository
will contain scripts for data ingestion and cleaning, generating 3-year Landsat
mosaics and predicting an index of household durable assets from satellite
imagery. It will also contain scripts to reproduce each map and chart and my
final causal estimates for the impact of industrial agriculture developments on 
local economic growth.

The estimates of the household durable assets index were generated using model 
weights from [Yeh et al. (2020)](https://www.nature.com/articles/s41467-020-16185-w), 
and which Christopher Yeh generously makes available on [Github](https://github.com/chrisyeh96/africa_poverty_clean). 

The final paper will be available here after July 2022 it is completed and  
approved for sharing by the MSc Dissertation Committee. 


## Overview
My dissertation aims to estimate how the opening of large-scale industrial
agriculture developments across sub-Saharan Africa affects the local growth rate
in household durable assets in subsequent years. I will first generate a series 
of estimates of household durable assets for each 3-year period from 1986 to 2022 for every 6.25km x 6.25km cell in the areas surrounding industrial agriculture 
developments in my dataset using a pre-trained model from Yeh et al. (2020) and 
historical satellite imagery from NASA’s LandSat satellite constellation. I will 
then use those predictions within a stacked differences-in-differences model, 
where the unit of observation is the cell and treatment is defined as whether an 
industrial agriculture development is operational within a to-be-determined 
distance from the cell centroid. The counterfactual will be formed of cells which
receive treatment before 2022, but have not yet received treatment at the year
under comparison. 


## Getting Started

**Complete instructions for replicating my analysis will be available after July 2022.**

The processed data needed to reproduce my analysis is available in RData format.
Scripts for all the plots included in my dissertation, as well as the models
presented in the dissertation is available in the `analysis` directory. 

If you want to reproduce these findings from raw data, you'll need to first: 
- Clean and merge the data contained in the LandMatrix CSVs. 
- Generate mosaics for each 3-year period for the scenes intersecting a 40x40km region surrounding each industrial agriculture development.
- Extract patches of 255x255 pixel cells surrounding each development in TFRecord format. 
- Generate predictions for household durable assets using Yeh et al. (2020) model weights. 

Start by installing R and RStudio. The following packages are required: 
```
- dplyr
- magrittr
- sf
- forcats
```
Once this is done, run the `prep_landmatrix.R` script to generate the cleaned
RData files for large-scale land acquisitions and the exports CSV with the 
locations of LSLAs needed by Earth Engine.
 
Next, you'll need to ensure you have a working install of Python 3, with the 
following packages: 
```
- pandas
```
For the full list or to automatically set-up the environment, install Conda and 
from the root of this repository, run: 
```
conda env create -f env.yml
```
This will create a new Conda environment with all of the packages listed in env.yml. 

To generate poverty estimates, you'll first need to install and configure
Google Earth Engine, which is needed for generating cloud-free mosaics and
export them in TFRecord format so that we can generate our predictions. 

