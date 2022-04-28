
# --------------------------- ENVIRONMENT ---------------------------

rm(list = ls())
setwd("~/Projects/Dissertation/agro-welfare")

library(miceadds)
library(dplyr)

# ------------------------------ DATA -------------------------------

# Read pre-cleaned data into memory
mdta <- readRDS("data/mdta.RData")

# Reduced Sample (Food Agriculture Only)
agri <- filter(mdta, investment_type == 'Food')

# Reduced Sample (All Agriculture)
agri_all <- filter(mdta, investment_type == 'Food' 
                      | investment_type == 'Non-food')

# Reduced Sample (Agro-industry - Inclusive)
agri_indus <- filter(mdta, investment_type == 'Food' 
                          | investment_type == 'Non-food' 
                          | investment_type == 'Livestock'
                          | investment_type == 'Biofuels')

# Drop Unusually High Vals (Above 3.1)
reduced <- filter(mdta, assets < 3.1)
agri_reduced <- filter(agri_all, assets < 3.1)


# ---------------------------- MODELS -------------------------------
# All Land Acquisitions 
a <- lm.cluster(data = mdta, formula = assets ~ operational + as.factor(year),
                      cluster = 'deal_id')
summary(a)


# Food Agriculture Only
b = lm.cluster(data = agri, formula = assets ~ operational + as.factor(year),
                   cluster = 'deal_id')
summary(b)


# Food and Non-food Agriculture
c = lm.cluster(data = agri_all, formula = assets ~ operational + as.factor(year),
               cluster = 'deal_id')
summary(c)


# Food and Non-food Agriculture
d = lm.cluster(data = agri_indus, formula = assets ~ operational + as.factor(year),
               cluster = 'deal_id')
summary(d)


# FE's for Industry Model
fe = lm.cluster(data = mdta, formula = assets ~ operational + as.factor(year) 
                   + investment_type, cluster = 'deal_id')
summary(fe)


# ---------------------- ROBUSTNESS CHECKS ----------------------------

# Robustness - All
r1 = lm.cluster(data = reduced, formula = assets ~ operational + as.factor(year),
               cluster = 'deal_id')
summary(r1)


# Robustness - Food and Non-food Agriculture Only
r2 = lm.cluster(data = agri_reduced, formula = assets ~ operational + as.factor(year),
                 cluster = 'deal_id')
summary(r2)


