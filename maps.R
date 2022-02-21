
# ----------------------- ENVIRONMENT ---------------
rm(list = ls())
library(sf)
library(ggplot2)
library(tidyr)


# Data
locations <- st_read("./Data/Original/locations.geojson")
areas <- st_read("./Data/Original/areas.geojson")

# ---------------------- PLOTS ----------------------




# Plotting Safe 
ggplot() + 
  geom_sf(data=locations, aes(width=)) +
  coord_sf()




