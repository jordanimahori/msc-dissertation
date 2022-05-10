

# --------------------------- ENVIRONMENT ---------------------------

rm(list = ls())
setwd("~/Projects/Dissertation/agro-welfare")

library(dplyr)
library(ggplot2)
library(ggspatial)
library(rosm)
library(sf)



# ------------------------------ DATA -------------------------------

# Read pre-cleaned data into memory
lsla <- readRDS("data/intermediate/lsla.RData")
areas <- readRDS("data/intermediate/areas.RData")
locations <- readRDS("data/intermediate/locations.RData")

mdta <- readRDS("data/mdta.RData")
unfiltered_data <- readRDS("data/robustness/unfiltered_data.RData")
robust <- readRDS("data/robustness/robust.RData")
outliers <- readRDS("data/robustness/outliers.RData")


# Mean Annual Asset Wealth by Level
yearly_assets <- mdta %>%
  group_by(deal_id, year, level_fe) %>%
  summarise(mean_assets = mean(assets), median_assets = median(assets),
            operational = first(operational), signed = first(signed), 
            since_operational = first(since_operational), 
            since_signed = first(since_signed), industry = first(investment_type)) %>%
  group_by(deal_id, level_fe) %>%
  mutate(growth = (mean_assets - lag(mean_assets, order_by = year))/mean_assets, 
         diff = mean_assets - lag(mean_assets, order_by = year))



# --------------- DISTRIBUTION TREATMENT AND OUTCOMES --------------------


# Histogram of Year Contract Signed - Full Sample
lsla %>%
  filter(investment_type %in% c("Biofuels", "Food", "Non-food", "Livestock")) %>% 
  ggplot(aes(year_signed)) +
  geom_histogram(binwidth=1, colour='#000000', fill='#1f78b4', size=0.2) + 
  labs(
    x = "Year Signed",
    y = "Count"
  ) +
  theme_light()

# Histogram of Year Contract Signed - Study Years
lsla %>%
  filter(year_signed >= 1985) %>%
  filter(investment_type %in% c("Biofuels", "Food", "Non-food", "Livestock")) %>% 
  ggplot(aes(year_signed)) +
    geom_histogram(binwidth=1, colour='#000000', fill='#1f78b4', size=0.2) + 
    labs(
      x = "Year Signed",
      y = "Count"
    ) +
    theme_light()

# Histogram of Year Production Started
lsla %>%
  filter(year_operational >= 1985) %>%
  filter(investment_type %in% c("Biofuels", "Food", "Non-food", "Livestock")) %>% 
  ggplot(aes(year_operational)) +
  geom_histogram(binwidth=1, colour='#000000', fill='#1f78b4', size=0.2) + 
  labs(
    x = "Year Operational",
    y = "Count"
  ) +
  theme_light()



# Histogram of Asset Predictions (Fixed)
mdta %>%
  ggplot(aes(assets)) + 
  geom_histogram(binwidth=0.01, colour='#000000', fill='#1f78b4', size=0.2) +
  labs (
    x = "Asset Predictions",
    y = "Count"
  ) + 
  theme_light()

# Histogram of Asset Predictions (Unmodified Sample)
unfiltered_data %>%
  ggplot(aes(assets)) + 
  geom_histogram(binwidth=0.01, colour='#000000', fill='#1f78b4', size=0.2) +
  labs (
    x = "Asset Predictions",
    y = "Count"
  ) + 
  theme_light()

# Kernel Density of Asset Predictions Pre-2000 vs. Post-2000
ggplot(data = mdta) + 
  geom_density(aes(assets, group=pre_2000, fill=pre_2000, alpha=.4)) +
  theme_light()

# Boxplot of Asset Predictions, by Period
ggplot(data = mdta) +
  geom_boxplot(aes(assets, year_fe)) +
  theme_light()





# ------------------- ASSET CHANGES OVER TIME ------------------------


# Histogram of Period-to-Period Absolute Asset Changes
ggplot(data = yearly_assets, aes(x = diff)) + 
  geom_histogram(binwidth = 0.025, colour='#000000', fill='#1f78b4', size=0.05) +
  theme_light()

# Kernel Density of Period-to-Period Absolute Asset Changes, by Operational Status
yearly_assets %>%
  filter(year >= 2000 & is.na(operational) == FALSE) %>%
  ggplot(aes(x = diff)) + 
  geom_density(aes(group=operational, colour=operational, fill=operational), alpha=0.4) +
  theme_light()

# Kernel Density of Period-to-Period Absolute Asset Changes, by Level
yearly_assets %>%
  filter(year >= 2000 & is.na(operational) == FALSE) %>%
  ggplot(aes(x = diff)) + 
  geom_density(aes(group=level_fe, colour=level_fe, fill=level_fe), alpha=0.4) +
  theme_light()

# Kernel Density of Period-to-Period Absolute Asset Changes, by Operational, Level = 0
yearly_assets %>%
  filter(year >= 2000 & is.na(operational) == FALSE, level_fe == 0) %>%
  ggplot(aes(x = diff)) + 
  geom_density(aes(group=operational, colour=operational, fill=operational), alpha=0.4) +
  theme_light()




# Scatterplot of Period-to-Period Growth (Winsorized)
yearly_assets %>%
  filter(growth > -5 & growth < 5) %>%
  ggplot(aes(x = growth)) + 
  geom_histogram(binwidth = 0.025, colour='#000000', fill='#1f78b4', size=0.05) +
  theme_light()

# Kernel Density of Period-to-Period Growth, by Operational Status
yearly_assets %>%
  filter(growth > -5 & growth < 5 & year >= 2000 & is.na(operational) == FALSE) %>%
  ggplot(aes(x = growth)) + 
  geom_density(aes(group=operational, colour=operational, fill=operational), alpha=0.4) +
  theme_light()




# Scatterplot of Mean Assets
ggplot(data = yearly_assets, aes(x = year, y = mean_assets)) +
  geom_point(position='jitter', alpha = 0.1) +
  geom_smooth(method= 'lm', formula = y ~ x) + 
  theme_light()

# Scatterplot of Mean Assets, Year > 2000
yearly_assets %>%
  filter(year >= 2000) %>% 
  ggplot(aes(x = year, y = mean_assets)) +
    geom_point(position='jitter', alpha = 0.1) +
    geom_smooth(method= 'lm', formula = y ~ x) + 
  theme_light()




# Scatterplot of Mean Assets, Year > 2000 & Level = 0
yearly_assets %>%
  filter(year >= 2000 & level_fe == 0) %>% 
  ggplot(aes(x = year, y = mean_assets)) +
  geom_point(position='jitter', alpha = 0.25) +
  geom_smooth(method= 'lm', formula = y ~ x) + 
  theme_light()

# Scatterplot of Mean Assets, Year > 2000 & Level = 1
yearly_assets %>%
  filter(year >= 2000 & level_fe == 1) %>% 
  ggplot(aes(x = year, y = mean_assets)) +
  geom_point(position='jitter', alpha = 0.25) +
  geom_smooth(method= 'lm', formula = y ~ x) + 
  theme_light()

# Scatterplot of Mean Assets, Year > 2000 & Level = 2
yearly_assets %>%
  filter(year >= 2000 & level_fe == 2) %>% 
  ggplot(aes(x = year, y = mean_assets)) +
  geom_point(position='jitter', alpha = 0.25) +
  geom_smooth(method = 'lm', formula = y ~ x) + 
  theme_light()






# Fitted Linear of Mean Assets, by Level
ggplot(data = yearly_assets, aes(x = year, y = mean_assets, group=level_fe)) +
  geom_smooth(method = 'lm', formula = y ~ x) + 
  theme_light()

# Fitted Local Polynomial of Mean Assets, by Level
ggplot(data = yearly_assets, aes(x = year, y = mean_assets, group=level_fe)) +
  geom_smooth(method = 'loess', formula = y ~ x) + 
  theme_light()

# Fitted Linear of Mean Assets, by Level, Year >= 2000
yearly_assets %>% 
  filter(year >= 2000) %>%
  ggplot(aes(x = year, y = mean_assets, group=level_fe)) +
  geom_smooth(method = 'lm', formula = y ~ x) + 
  theme_light()

# Fitted Local Polynomial of Mean Assets, by Level, Year >= 2000
yearly_assets %>% 
  filter(year >= 2000) %>%
  ggplot(aes(x = year, y = mean_assets, group = level_fe, colour = level_fe)) +
    geom_smooth(method = 'loess', formula = y ~ x) + 
  theme_light()

# Fitted Local Polynomial of Mean Assets, by Operational Status, Year >= 2000
yearly_assets %>% 
  filter(year >= 2000 & is.na(operational) == FALSE & level_fe == 0) %>%
  ggplot(aes(x = year, y = mean_assets)) +
  geom_smooth(aes(group = operational, colour = operational), method = 'loess', formula = y ~ x) + 
  theme_light()




# Fitted Linear Model of Mean Assets by Year Since Operational, Year >= 2000
yearly_assets %>% 
  filter(year >= 2000 & is.na(operational) == FALSE & level_fe == 0 & since_operational < 20) %>%
  ggplot(aes(x = since_operational, y = mean_assets)) +
  geom_smooth(aes(group = operational, colour = operational), method = 'lm', formula = y ~ x) + 
  theme_light()

# Fitted Local Polynomial Model of Mean Asset Diff by Year Since Operational, Year >= 2000
yearly_assets %>% 
  filter(year >= 2000 & is.na(operational) == FALSE & level_fe == 0 & 
           since_operational < 20) %>%
  ggplot(aes(x = since_operational, y = diff)) +
  geom_smooth(method = 'loess', formula = y ~ x) + 
  theme_light()

# Fitted Local Polynomial Model of Mean Asset Diff by Year Since Operational, Year > 2000
yearly_assets %>% 
  filter(year >= 2003 & is.na(signed) == FALSE & level_fe == 0 & 
           since_signed < 20 & since_signed > -20, growth > -0.5 & growth < 0.5) %>%
  ggplot(aes(x = since_signed, y = diff)) +
  geom_smooth(method = 'loess', formula = y ~ x) + 
  theme_light()

# Fitted Linear Model of Mean Asset Diff by Year Signed Signed, Year > 2000
yearly_assets %>% 
  filter(year >= 2003 & is.na(signed) == FALSE & is.na(operational) & level_fe == 0 & 
           since_signed < 10 & since_signed > -10, growth > -0.5 & growth < 0.5) %>%
  ggplot(aes(x = since_signed, y = diff, group = signed)) +
  geom_smooth(method = 'lm', formula = y ~ x) + 
  geom_point(aes(group = operational), alpha = 0.5) +
  theme_light()




# Assets In Current Year Compared to Lagged Assets, By Year, Level = 0; Unfiltered
unfiltered_data %>%
  filter(level_fe == 0, year != 1985) %>%
  ggplot(aes(x = assets, y = assets_lag_1)) +
  geom_point(alpha = 0.5) +
  facet_grid(~ year_fe) +
  theme_light()

# Assets In Current Year Compared to Lagged Assets, Post-2000, Level = 0; Unfiltered
unfiltered_data %>%
  filter(level == 0) %>%
  ggplot(aes(x = assets, y = assets_lag_1)) +
  geom_point(alpha = 0.5) +
  facet_grid(~ post_2003) +
  theme_light()



# Assets In Current Year Compared to Lagged Assets, By Year, Level = 0; Windsorized
mdta %>%
  filter(level_fe == 0, year != 1985) %>%
  ggplot(aes(x = assets, y = assets_lag_1)) +
  geom_point(alpha = 0.5) +
  facet_grid(~ year_fe) +
  theme_light()

# Assets In Current Year Compared to Lagged Assets, Post-2000, Level = 0; Windsorized
mdta %>%
  filter(level == 0) %>%
  ggplot(aes(x = assets, y = assets_lag_1)) +
  geom_point(alpha = 0.5) +
  facet_grid(~ post_2003) +
  theme_light()



# ------------------------------ MAPS --------------------------------


# Map of locations
locations %>%
  filter(year_signed > 1970) %>%
  filter(investment_type %in% c("Biofuels", "Food", "Non-food", "Livestock")) %>% 
  ggplot() + 
    annotation_map_tile(type = "osm", zoom=5) +
    geom_sf(size=1, colour='#e34a33', cache=TRUE) +
    coord_sf() +
    theme_light()

# Map of locations, scaled by area
locations %>%
  filter(year_signed > 1970) %>%
  filter(investment_type %in% c("Biofuels", "Food", "Non-food", "Livestock")) %>% 
  ggplot() +
    annotation_map_tile(type = "osm", zoom=5, cache=TRUE) +
    geom_sf(aes(size=area_contracted*0.000004, colour='#e34a33')) +
    coord_sf() +
    theme_light()

# Map of areas
ggplot(areas) + 
  geom_sf(colour='#1f78b4') +
  coord_sf() +
  theme_light()
  
  

# --------------------------- NOTES ---------------------------------

# Asset wealth is decreasing, unless we only look at the period after 2000 in 
# which case it is increasing modestly. Should we trust that? Fits somewhat 
# with the historical evidence suggesting a decline in living standards (check 
# if that's how paper interprets it) but also likely that Landsat 5 systematically 
# difference causing issues. Significant heteroskedasticity suggests this is more
# plausible. 

# Increase of asset wealth driven primarily by Level 0, and Level 1 to a lesser
# extent. Show this with regression. 

# Need to check robustness against Urban Areas

# Need to look into strangely high rates of growth and winsorize. Some > 200%... 
# check max(yearly_assets$growth, na.rm=TRUE) and min(yearly_assets$growth, na.rm=TRUE)

# There are unusual jumps in assets on the order of 1-2 pts on the index...

# No real differences in overall growth rates or changes in absolute values of 
# assets, which is suggestive of limited effects on growth.

# Perhaps story is one of immediate growth, followed by slowing growth. As plots
# suggest.

# We see growth accelerate after signing, and rapid growth in the period 
# immediately preceeding operational. 

# Check if signed conditional on operational has effect.

# QUESTION: For extreme values, should I winsorize or drop the deal_id, year 
# combinations? Assume that extreme results are algorithm failing and thus 
# should drop (and worry!).

