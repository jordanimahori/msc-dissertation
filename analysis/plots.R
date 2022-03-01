

# --------------------------- ENVIRONMENT ---------------------------

rm(list = ls())
setwd("~/Projects/Dissertation/agro-welfare")

library(ggplot2)
library(sf)
library(RColorBrewer)



# ------------------------------ DATA -------------------------------

# Read pre-cleaned data into memory
lsla <- readRDS("./Data/lsla.RData")
areas <- readRDS("./Data/areas.RData")
locations <- readRDS("./Data/locations.RData")



# -------------------------- HISTOGRAMS ----------------------------

# Histogram for Year Contract Signed

lsla %>%
  filter(year_signed > 1970) %>%
  filter(investment_type %in% c("Biofuels", "Food", "Non-food", "Livestock")) %>% 
  ggplot(aes(year_signed)) +
    geom_histogram(binwidth=1, colour='#000000', fill='#1f78b4', size=0.2) + 
    labs(
      x = "Year Signed",
      y = "Count"
    ) +
    theme_light()

# Histogram for Year Production Started
lsla %>%
  filter(year_signed > 1970) %>%
  filter(investment_type %in% c("Biofuels", "Food", "Non-food", "Livestock")) %>% 
  ggplot(aes(year_operational)) +
  geom_histogram(binwidth=1, colour='#000000', fill='#1f78b4', size=0.2) + 
  labs(
    x = "Year Operational",
    y = "Count"
  ) +
  theme_light()



# ---------------------------- MAPS ------------------------------


# Map of locations
locations %>%
  filter(year_signed > 1970) %>%
  filter(investment_type %in% c("Biofuels", "Food", "Non-food", "Livestock")) %>% 
  ggplot() + 
    geom_sf(size=0.5, colour='#1f78b4') +
    coord_sf() +
    theme_light()

# Map of locations, scaled by area
locations %>%
  filter(year_signed > 1970) %>%
  filter(investment_type %in% c("Biofuels", "Food", "Non-food", "Livestock")) %>% 
  ggplot() + 
    geom_sf(aes(size=size_under_contract*0.000005, colour='#1f78b4')) +
    coord_sf() +
    theme_light()

# Map of areas
ggplot(areas) + 
  geom_sf(colour='#1f78b4') +
  coord_sf() +
  theme_light()
  
  
  

