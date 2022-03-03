# Industrial Agriculture and Local Economic Growth: Evidence from Historical Satellite Imagery

This repository contains the code required to reproduce the findings from my
thesis, including all data ingestion and cleaning, generation of poverty
estimates, visualizations, and estimates.

The estimates of the household durable assets index were generated using model 
weights from [Yeh et al. (2020)](https://www.nature.com/articles/s41467-020-16185-w), 
and which Christopher Yeh generously makes available on [Github](https://github.com/chrisyeh96/africa_poverty_clean). 

The final paper will be available here after it has been graded and approved 
for sharing by the Dissertation Committee. 


## Getting Started
The processed data needed to reproduce my analysis is available in RData format.
The scripts for all the plots included in my dissertation, as well as the models
presented in the dissertation is available in the `analysis` directory. 

If you want to reproduce these findings from raw data, you'll need to first: 
- Clean and organize the tabular LandMatrix files. 
- Export mosaics for the study years in areas around each of the land acquisitions.
- Generate estimates of household durable assets using Yeh et al. (2020) model weights. 

Start by installing R and RStudio. The following packages are required: 
```
- dplyr
- magrittr
- sf
- forcats
```
Once this is done, run the `prep_landmatrix.R` script to generate the cleaned
RData files for large-scale land acquisitions and the exports CSV with the locations
of LSLAs needed by Earth Engine.
 
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

