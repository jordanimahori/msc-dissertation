
# --------------------------- ENVIRONMENT ---------------------------

rm(list = ls())
setwd("~/Projects/Dissertation/agro-welfare")

library(miceadds)
library(dplyr)
library(forcats)
library(eventStudy)



# ------------------------------ DATA -------------------------------

# Master Data
mdta <- readRDS("data/mdta.RData")

# Reduced Sample - Food Agriculture Only
agriculture_food <- filter(mdta, investment_type == 'Food')

# Reduced Sample - All Agriculture
agriculture_food_nonfood <- filter(mdta, investment_type == 'Food' 
                                   | investment_type == 'Non-food')

# Reduced Sample - Agro-Industry 
agriculture_industrial <- filter(mdta, investment_type == 'Food' 
                          | investment_type == 'Non-food' 
                          | investment_type == 'Livestock'
                          | investment_type == 'Biofuels')

# Reduced Sample - Mining Only
mining <- filter(mdta, investment_type == 'Mining')

# Reduced Sample - Forestry Only
forestry <- filter(mdta, investment_type == 'Forestry')



# -------------- DIFFERENCE-IN-DIFFERENCE MODELS ------------------


# All Land Acquisitions
a1 <- lm.cluster(data = mdta, 
                formula = assets ~ operational + year_fe + level_fe,
                      cluster = 'deal_id')

a2 <- lm.cluster(data = mdta, 
                 formula = assets ~ operational + year_fe + level_fe + 
                   investment_type,
                 cluster = 'deal_id')

a3 <- lm.cluster(data = mdta, 
                 formula = assets ~ operational + year_fe + level_fe +
                   investment_type + area_contracted + area_in_operation +
                   deal_scope, 
                 cluster = 'deal_id')

a4 <- lm.cluster(data = mdta, 
                 formula = assets ~ operational + year_fe + level_fe +
                   investment_type + area_contracted + area_in_operation + 
                   deal_scope + country, 
                 cluster = 'deal_id')

a5 <- lm.cluster(data = mdta, 
                 formula = assets ~ operational + year_fe + level_fe +
                   investment_type + area_contracted + area_in_operation + 
                   deal_scope + country + operational:since_operational, 
                 cluster = 'deal_id')



# Food Agriculture Only
b1 <- lm.cluster(data = agriculture_food, 
                 formula = assets ~ operational + year_fe + level_fe,
                 cluster = 'deal_id')


b2 <- lm.cluster(data = agriculture_food, 
                 formula = assets ~ operational + year_fe + level_fe +
                   area_contracted + area_in_operation +
                   deal_scope, 
                 cluster = 'deal_id')

b3 <- lm.cluster(data = agriculture_food, 
                 formula = assets ~ operational + year_fe + level_fe +
                   area_contracted + area_in_operation + 
                   deal_scope + country, 
                 cluster = 'deal_id')

b4 <- lm.cluster(data = agriculture_food, 
                 formula = assets ~ operational + year_fe + level_fe +
                   area_contracted + area_in_operation + 
                   deal_scope + country + operational:since_operational, 
                 cluster = 'deal_id')



# Food and Non-food Agriculture
c1 <- lm.cluster(data = agriculture_food_nonfood, 
                 formula = assets ~ operational + year_fe + level_fe,
                 cluster = 'deal_id')

c2 <- lm.cluster(data = agriculture_food_nonfood, 
                 formula = assets ~ operational + year_fe + level_fe + 
                   investment_type,
                 cluster = 'deal_id')

c3 <- lm.cluster(data = agriculture_food_nonfood, 
                 formula = assets ~ operational + year_fe + level_fe +
                   investment_type + area_contracted + area_in_operation +
                   deal_scope, 
                 cluster = 'deal_id')

c4 <- lm.cluster(data = agriculture_food_nonfood, 
                 formula = assets ~ operational + year_fe + level_fe +
                   investment_type + area_contracted + area_in_operation + 
                   deal_scope + country, 
                 cluster = 'deal_id')

c5 <- lm.cluster(data = agriculture_food_nonfood, 
                 formula = assets ~ operational + year_fe + level_fe +
                   investment_type + area_contracted + area_in_operation + 
                   deal_scope + country + operational:since_operational, 
                 cluster = 'deal_id')



# Agro-Industry
d1 <- lm.cluster(data = agriculture_industrial, 
                 formula = assets ~ operational + year_fe + level_fe,
                 cluster = 'deal_id')

d2 <- lm.cluster(data = agriculture_industrial, 
                 formula = assets ~ operational + year_fe + level_fe + 
                   investment_type,
                 cluster = 'deal_id')

d3 <- lm.cluster(data = agriculture_industrial, 
                 formula = assets ~ operational + year_fe + level_fe +
                   investment_type + area_contracted + area_in_operation +
                   deal_scope, 
                 cluster = 'deal_id')

d4 <- lm.cluster(data = agriculture_industrial, 
                 formula = assets ~ operational + year_fe + level_fe +
                   investment_type + area_contracted + area_in_operation + 
                   deal_scope + country, 
                 cluster = 'deal_id')

d5 <- lm.cluster(data = agriculture_industrial, 
                 formula = assets ~ operational + year_fe + level_fe +
                   investment_type + area_contracted + area_in_operation + 
                   deal_scope + country + operational:since_operational, 
                 cluster = 'deal_id')



# ----------------------- EVENT STUDY MODELS --------------------------

# See: https://github.com/setzler/eventStudy



# ---------------------- ROBUSTNESS CHECKS ----------------------------


# Robustness Check on Observations from year = 2000 or later & signed as 
# alternative treatment variable. 


# Base Model -- All Observations
ra1 <- mdta %>% 
  filter(year >= 2000) %>%
  lm.cluster(formula = assets ~ operational + year_fe + level_fe + investment_type, 
             cluster = 'deal_id')

# Preferred Model -- All Observations
ra2 = mdta %>%
  filter(year >=2000) %>%
  lm.cluster(formula = assets ~ operational + year_fe + level_fe +
               investment_type + area_contracted + area_in_operation + 
               deal_scope + country + operational:since_operational, 
             cluster = 'deal_id')

# Preferred Model -- 'Signed' as Treatment
ra3 <- lm.cluster(data = mdta, 
                  formula = assets ~ signed + year_fe + level_fe + 
                    investment_type + area_contracted + area_in_operation +
                    deal_scope + country + operational:since_operational,
                  cluster = 'deal_id')



# Base Model -- Food Agriculture Only
rb1 <- agriculture_food %>% 
  filter(year >= 2000) %>%
  lm.cluster(formula = assets ~ operational + year_fe + level_fe, 
             cluster = 'deal_id')

# Preferred Model -- Food Agriculture Only
rb2 = agriculture_food %>%
  filter(year >=2000) %>%
  lm.cluster(formula = assets ~ operational + year_fe + level_fe +
               area_contracted + area_in_operation + deal_scope + country + 
               operational:since_operational, 
             cluster = 'deal_id')

# Preferred Model -- 'Signed' as Treatment
rb3 <- lm.cluster(data = agriculture_food, 
                  formula = assets ~ signed + year_fe + level_fe + 
                    area_contracted + area_in_operation + deal_scope + country + 
                    operational:since_operational, 
                  cluster = 'deal_id')



# Base Model -- Food and Non-Food Agriculture
rc1 <- agriculture_food_nonfood %>% 
  filter(year >= 2000) %>%
  lm.cluster(formula = assets ~ operational + year_fe + level_fe + investment_type, 
             cluster = 'deal_id')

# Preferred Model -- Food and Non-Food Agriculture
rc2 = agriculture_food_nonfood %>%
  filter(year >=2000) %>%
  lm.cluster(formula = assets ~ operational + year_fe + level_fe +
               investment_type + area_contracted + area_in_operation + 
               deal_scope + country + operational:since_operational, 
             cluster = 'deal_id')

# Preferred Model -- 'Signed' as Treatment
rc3 <- lm.cluster(data = agriculture_food_nonfood, 
                  formula = assets ~ signed + year_fe + level_fe + 
                    investment_type + area_contracted + area_in_operation +
                    deal_scope + country + operational:since_operational,
                  cluster = 'deal_id')



# Base Model -- Agro-Industry
rd1 <- agriculture_industrial %>% 
  filter(year >= 2000) %>%
  lm.cluster(formula = assets ~ operational + year_fe + level_fe + investment_type, 
             cluster = 'deal_id')

# Preferred Model -- Agro-Industry
rd2 = agriculture_industrial %>%
  filter(year >=2000) %>%
  lm.cluster(formula = assets ~ operational + year_fe + level_fe +
               investment_type + area_contracted + area_in_operation + 
               deal_scope + country + operational:since_operational, 
             cluster = 'deal_id')

# Preferred Model -- 'Signed' as Treatment
rd3 <- lm.cluster(data = agriculture_industrial, 
                  formula = assets ~ signed + year_fe + level_fe + 
                    investment_type + area_contracted + area_in_operation +
                    deal_scope + country + operational:since_operational,
                  cluster = 'deal_id')


# ----------------------- MODEL SUMMARIES ---------------------------


# All Industries 
summary(a1)  # Base
summary(a2)  # + industry fixed effects
summary(a3)  # + area_contracted & area_in_operation & deal_scope
summary(a4)  # + interaction between operational and since_operational
summary(a5)  # + country

summary(ra1) # A1 on observations from the year 2000 or later
summary(ra2) # A5 on observations from year 2000 or later
summary(ra3) # A5 with operational replaced by signed as treatment


# Food Agriculture Only
summary(b1)  # Analogous to A1
summary(b2)  # Analogous to A3 w.o. industry FEs
summary(b3)  # Analogous to A4 w.o. industry FEs
summary(b4)  # Analogous to A5 w.o. industry FEs

summary(rb1) # B1 on observations from the year 2000 or later
summary(rb2) # B4 on observations from year 2000 or later
summary(rb3) # B4 with operational replaced by signed as treatment


# Food and Non-Food Agriculture
summary(c1)  # Analogous to A1
summary(c2)  # Analogous to A2
summary(c3)  # Analogous to A3
summary(c4)  # Analogous to A4
summary(c5)  # Analogous to A5

summary(rc1) # C1 on observations from the year 2000 or later
summary(rc2) # C5 on observations from year 2000 or later
summary(rc3) # C5 with operational replaced by signed as treatment


# Agro-Industrial Developments
summary(d1)  # Analogous to A1
summary(d2)  # Analogous to A2
summary(d3)  # Analogous to A3
summary(d4)  # Analogous to A4
summary(d5)  # Analogous to A5

summary(rd1) # D1 on observations from the year 2000 or later
summary(rd2) # D5 on observations from year 2000 or later
summary(rd3) # D5 with operational replaced by signed as treatment







# NOTES / TODO

# C is my preferred inclusion criteria

# It seems that point estimate falls when including country FEs for all developments
# but not when the sample is restricted to agricultural developments. Could be
# that some industries are driving that decline in the point estimate. 

# Re-check SEs with bootstrapping and randomization inference. 

# Effect appears partially driven by earlier years i.e. Landsat 5 imagery
