

# --------------------------- ENVIRONMENT ---------------------------

rm(list = ls())
setwd("~/Projects/Dissertation/agro-welfare")

library(dplyr)
library(forcats)
library(ggplot2)
library(ggspatial)
library(rosm)
library(sf)
library(gridExtra)




# ------------------------------ DATA -------------------------------

# Read pre-cleaned data into memory
lsla <- readRDS("data/intermediate/lsla.RData")
areas <- readRDS("data/intermediate/areas.RData")
locations <- readRDS("data/intermediate/locations.RData")

mdta <- readRDS("data/mdta.RData")
unfiltered_data <- readRDS("data/robustness/unfiltered_data.RData")
robust <- readRDS("data/robustness/robust.RData")
outliers <- readRDS("data/robustness/outliers.RData")

event_study_main_results <- readRDS("data/intermediate/event_study_main_results.RData")
event_study_results <- readRDS("data/intermediate/event_study_results.RData")


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


# Create Indicator for Operational in 2000
yearly_assets$operational_in_2000 <- as_factor(
  ifelse(yearly_assets$year - yearly_assets$since_operational < 2000, 1, 0)
  )




# -------------------------- TABLES -------------------------------


# Summary Statistics Table for Deal Characteristics
lsla$investment_type[lsla$investment_type == 'Livestock'] <- 'Food'

summary <- lsla %>%
  group_by(investment_type) %>%
  summarise(mean_area = mean(area_contracted, na.rm=TRUE),
            std_dev_area = sd(area_contracted, na.rm=TRUE),
            min = min(area_contracted, na.rm=TRUE), 
            max = max(area_contracted, na.rm=TRUE),
            prop_transnational = mean(deal_scope == 'transnational', na.rm=TRUE),
            n = n())



# ------------------------ MAIN PLOTS -----------------------------


#----- Histogram of Asset Predictions (Windsorized)
assets_histogram <- mdta %>%
  ggplot(aes(assets)) + 
  geom_histogram(binwidth=0.01, colour='#000000', fill='#1f78b4', size=0.2) +
  labs (
    x = "Household Assets",
    y = "Count"
  ) + 
  theme_light()

ggsave("final_paper/graphics/assets_histogram.png", 
       plot=assets_histogram, width=20, height=12, units="cm", dpi=600)



#----- Map of locations
map_sites <- locations %>%
  filter(year_signed > 1970) %>%
  filter(investment_type %in% c("Biofuels", "Food", "Non-food", "Livestock")) %>% 
  ggplot() + 
  annotation_map_tile(type = "osm", zoom=5) +
  geom_sf(size=2, colour='#e34a33') +
  coord_sf() +
  theme_light()

ggsave("final_paper/graphics/map_lsla.png", 
       plot=map_sites, width = 20, height = 18, units="cm", dpi=600)



#----- Kernel Density of Asset Predictions Pre-2000 vs. Post-2000

density_1 <- ggplot(data = unfiltered_data) + 
  geom_density(aes(assets, group=pre_2000, fill=pre_2000, alpha=.4)) +
  labs (
    title="Original",
    x="Density",
    y="Asset Predictions"
  ) + 
  xlim(-2.5, 3.5) +
  guides(alpha="none") +
  theme_light()

density_2 <- ggplot(data = mdta) + 
  geom_density(aes(assets, group=pre_2000, fill=pre_2000, alpha=.4)) +
  labs (
    title="Corrected",
    x="Density",
    y="Asset Predictions"
  ) +
  xlim(-2.5, 3.5) +
  guides(alpha="none") +
  theme_light()

kernel_density_assets <- grid.arrange(density_1, density_2, ncol=2)
ggsave("final_paper/graphics/kernel_density_assets.png", 
       plot=kernel_density_assets, width=22, height=10, units="cm", dpi=600)





# --------------------------- ADDENDUM -----------------------------


# ----- Scatterplot of Current Assets vs Lag, Post-2000, Level = 0; Winsorized
robust_1 <- unfiltered_data %>%
  filter(level == 0) %>%
  ggplot(aes(x = assets, y = assets_lag_1)) +
  geom_point(alpha = 0.5) +
  facet_grid(~ post_2003) +
  labs (
    title="Original",
    x="Assets",
    y="Lag Assets"
  ) +
  xlim(-2, 2.5) +
  ylim(-2, 3.2) +
  theme_light()

robust_2 <- mdta %>%
  filter(level == 0) %>%
  ggplot(aes(x = assets, y = assets_lag_1)) +
  geom_point(alpha = 0.5) +
  facet_grid(~ post_2003) +
  labs (
    title="Corrected",
    x="Assets",
    y="Lag Assets"
  ) +
  xlim(-2, 2.5) +
  ylim(-2, 3.2) +
  theme_light()


# Arrange into grid and save plots
robust_scatter <- grid.arrange(robust_1, robust_2, ncol = 1)
ggsave("final_paper/graphics/assets_vs_lag.png", 
       plot=robust_scatter, width=20, height=20, units="cm", dpi=600)





#----- Scatterplot of Current Assets vs Lag, By Year, Level = 0; Unfiltered
robust_3 <- unfiltered_data %>%
  filter(level_fe == 0, year != 1985) %>%
  ggplot(aes(x = assets, y = assets_lag_1)) +
  geom_point(alpha = 0.5) +
  labs (
    title="Original",
    x="Assets",
    y="Lag Assets"
  ) +
  facet_grid(~ year_fe) +
  theme_light()

robust_4 <- mdta %>%
  filter(level_fe == 0, year != 1985) %>%
  ggplot(aes(x = assets, y = assets_lag_1)) +
  geom_point(alpha = 0.5) +
  facet_grid(~ year_fe) +
  labs (
    title="Corrected",
    x="Assets",
    y="Lag Assets"
  ) +
  theme_light()


# Arrange into grid and save plots
robust_scatter_2 <- grid.arrange(robust_3, robust_4, ncol = 1)
ggsave("final_paper/graphics/assets_vs_lag_by_year.png", 
       plot=robust_scatter_2, width=30, height=15, units="cm", dpi=600)





#---------- Event Study Plots


# Treatment = Operational + Signed, All Observations
event_study_all_obs <- event_study_main_results %>%
  ggplot() +
  geom_point(aes(x = as_factor(j), y = estimate, group=treatment, colour = treatment)) + 
  geom_line(aes(x = as_factor(j), y = estimate, group=treatment, colour=treatment)) + 
  geom_errorbar(aes(x = as_factor(j), ymin = estimate - 1.96*st_err, ymax = estimate + 
                      1.96*st_err, width=0.3, colour=treatment)) +
  labs(
    x = "Period Relative to Treatment (treatment when j = 0)", 
    y = "\u03b4-Coefficients"
  ) + 
  facet_grid(~treatment) + 
  theme_light()

ggsave("final_paper/graphics/event_study_all_obs.png", plot=event_study_all_obs, 
       width=22, height = 10, units="cm", dpi=600)




# ---------- POLYNOMIAL SHOWING TRENDS OF ASSET GROWTH OVER TIME

# Fitted Local Polynomial of Mean Assets, by Operational Status, Year >= 2000
time_trend_pre_2000 <- yearly_assets %>% 
  filter(year >= 2000 & is.na(operational) == FALSE & level_fe == 0) %>%
  ggplot(aes(x = year, y = mean_assets)) +
  geom_smooth(aes(group = operational_in_2000, colour = operational_in_2000), 
              method = 'lm', formula = y ~ x) +
  labs(
    title="Growth in assets for firms operational in 2000",
    x = "Mean Assets", 
    y = "Year"
  ) + 
  theme_light()


ggsave("final_paper/graphics/time_trend_pre_2000.png", plot=time_trend_pre_2000, 
       width=20, height = 10, units="cm", dpi=600)









  