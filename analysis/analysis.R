
# This script estimates the causal effect of industrial agriculture developments
# and other large-scale land acquisitions on changes in household assets from 
# 1985 to 2021. 

# DATA: Loads the master data file, 'mdta', and creates additional datasets 
# representing subsets of the original data according to specific criteria. 
# have the same estimated household assets.

# FIXED EFFECTS MODELS: This section defines and estimates fixed effects 
# models for each subset. Models iteratively add additional terms to check
# robustness of the point estimates on signed / operational to additional
# covariates. 

# EVENT STUDY MODELS: This section defines and estimates event study models for 
# each of the above-created subsets. Similar to for DiDs, I iteratively add  
# terms to check the robustness of point estimates to additional covariates. 

# MODEL SUMMARIES: This section can be run to view summaries for each model. 



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




# ----------------------- FIXED EFFECTS MODELS -------------------------


#---------- ALL LAND ACQUISITIONS

# All: Treatment = Operational; Controls + No FEs
a1 <- lm.cluster(data = mdta, 
                formula = assets ~ operational + level_fe*operational + 
                  area_contracted + area_in_operation + deal_scope,
                cluster = 'deal_id')

# All:  Treatment = Operational; Controls + Year & Deal FEs
a2 <- lm.cluster(data = mdta, 
                 formula = assets ~ operational + level_fe*operational + 
                   area_contracted + area_in_operation + deal_scope +
                   year_fe + deal_id,
                 cluster = 'deal_id')

# All: Treatment = Operational; Controls + Year & Country FEs + Investment Type
a3 <- lm.cluster(data = mdta, 
                 formula = assets ~ operational + level_fe*operational + 
                   area_contracted + area_in_operation + deal_scope +
                   year_fe + country + operational*investment_type,
                 cluster = 'deal_id')

# All:  Treatment = Operational + Since Operational; Controls + Year & Deal FEs
a4 <- lm.cluster(data = mdta, 
                 formula = assets ~ operational + level_fe*operational + 
                   since_operational*level_fe + since_operational*level_fe*operational +
                   area_contracted + area_in_operation + deal_scope +
                   year_fe + deal_id,
                 cluster = 'deal_id')



# All: Treatment = Signed; Controls + No FEs
a5 <- lm.cluster(data = mdta, 
                 formula = assets ~ signed + level_fe*signed + 
                   area_contracted + area_in_operation + deal_scope,
                 cluster = 'deal_id')

# All:  Treatment = Signed; Controls + Year & Deal FEs
a6 <- lm.cluster(data = mdta, 
                 formula = assets ~ signed + level_fe*signed + 
                   area_contracted + area_in_operation + deal_scope +
                   year_fe + deal_id,
                 cluster = 'deal_id')

# All: Treatment = Signed; Controls + Year & Country FEs + Investment Type
a7 <- lm.cluster(data = mdta, 
                 formula = assets ~ signed + level_fe*signed + 
                   area_contracted + area_in_operation + deal_scope +
                   year_fe + country + signed*investment_type,
                 cluster = 'deal_id')

# All: Treatment = Signed + Since Signed; Controls + Year & Deal FEs
a8 <- lm.cluster(data = mdta, 
                 formula = assets ~ signed + level_fe*signed + 
                   since_signed*level_fe + since_signed*level_fe*signed +
                   area_contracted + area_in_operation + deal_scope +
                   year_fe + deal_id,
                 cluster = 'deal_id')




#---------- FOOD AND NON-FOOD AGRICULTURE


# All: Treatment = Operational; Controls + No FEs
b1 <- lm.cluster(data = agriculture_food_nonfood, 
                 formula = assets ~ operational + level_fe*operational + 
                   area_contracted + area_in_operation + deal_scope,
                 cluster = 'deal_id')

# All:  Treatment = Operational; Controls + Year & Deal FEs
b2 <- lm.cluster(data = agriculture_food_nonfood, 
                 formula = assets ~ operational + level_fe*operational + 
                   area_contracted + area_in_operation + deal_scope +
                   year_fe + deal_id,
                 cluster = 'deal_id')

# All: Treatment = Operational; Controls + Year & Country FEs + Investment Type
b3 <- lm.cluster(data = agriculture_food_nonfood, 
                 formula = assets ~ operational + level_fe*operational + 
                   area_contracted + area_in_operation + deal_scope +
                   year_fe + country + operational*investment_type,
                 cluster = 'deal_id')

# All:  Treatment = Operational + Since Operational; Controls + Year & Deal FEs
b4 <- lm.cluster(data = agriculture_food_nonfood, 
                 formula = assets ~ operational + level_fe*operational + 
                   since_operational*level_fe + since_operational*level_fe*operational +
                   area_contracted + area_in_operation + deal_scope +
                   year_fe + deal_id,
                 cluster = 'deal_id')



# All: Treatment = Signed; Controls + No FEs
b5 <- lm.cluster(data = agriculture_food_nonfood, 
                 formula = assets ~ signed + level_fe*signed + 
                   area_contracted + area_in_operation + deal_scope,
                 cluster = 'deal_id')

# All:  Treatment = Signed; Controls + Year & Deal FEs
b6 <- lm.cluster(data = agriculture_food_nonfood, 
                 formula = assets ~ signed + level_fe*signed + 
                   area_contracted + area_in_operation + deal_scope +
                   year_fe + deal_id,
                 cluster = 'deal_id')

# All: Treatment = Signed; Controls + Year & Country FEs + Investment Type
b7 <- lm.cluster(data = agriculture_food_nonfood, 
                 formula = assets ~ signed + level_fe*signed + 
                   area_contracted + area_in_operation + deal_scope +
                   year_fe + country + signed*investment_type,
                 cluster = 'deal_id')

# All: Treatment = Signed + Since Signed; Controls + Year & Deal FEs
b8 <- lm.cluster(data = agriculture_food_nonfood, 
                 formula = assets ~ signed + level_fe*signed +
                   since_signed*level_fe + since_signed*level_fe*signed +
                   area_contracted + area_in_operation + deal_scope +
                   year_fe + deal_id,
                 cluster = 'deal_id')



#---------- AGRO-INDUSTRY

# All: Treatment = Operational; Controls + No FEs
c1 <- lm.cluster(data = agriculture_industrial, 
                 formula = assets ~ operational + level_fe*operational + 
                   area_contracted + area_in_operation + deal_scope,
                 cluster = 'deal_id')

# All:  Treatment = Operational; Controls + Year & Deal FEs
c2 <- lm.cluster(data = agriculture_industrial, 
                 formula = assets ~ operational + level_fe*operational + 
                   area_contracted + area_in_operation + deal_scope +
                   year_fe + deal_id,
                 cluster = 'deal_id')

# All: Treatment = Operational; Controls + Year & Country FEs + Investment Type
c3 <- lm.cluster(data = agriculture_industrial, 
                 formula = assets ~ operational + level_fe*operational + 
                   area_contracted + area_in_operation + deal_scope +
                   year_fe + country + operational*investment_type,
                 cluster = 'deal_id')

# All:  Treatment = Operational + Since Operational; Controls + Year & Deal FEs
c4 <- lm.cluster(data = agriculture_industrial, 
                 formula = assets ~ operational + level_fe*operational + 
                   since_operational*level_fe + since_operational*level_fe*operational +
                   area_contracted + area_in_operation + deal_scope +
                   year_fe + deal_id,
                 cluster = 'deal_id')



# All: Treatment = Signed; Controls + No FEs
c5 <- lm.cluster(data = agriculture_industrial, 
                 formula = assets ~ signed + level_fe*signed + 
                   area_contracted + area_in_operation + deal_scope,
                 cluster = 'deal_id')

# All:  Treatment = Signed; Controls + Year & Deal FEs
c6 <- lm.cluster(data = agriculture_industrial, 
                 formula = assets ~ signed + level_fe*signed + 
                   area_contracted + area_in_operation + deal_scope +
                   year_fe + deal_id,
                 cluster = 'deal_id')

# All: Treatment = Signed; Controls + Year & Country FEs + Investment Type
c7 <- lm.cluster(data = agriculture_industrial, 
                 formula = assets ~ signed + level_fe*signed + 
                   area_contracted + area_in_operation + deal_scope +
                   year_fe + country + signed*investment_type,
                 cluster = 'deal_id')

# All: Treatment = Signed + Since Signed; Controls + Year & Deal FEs
c8 <- lm.cluster(data = agriculture_industrial, 
                 formula = assets ~ signed + level_fe*signed +
                   since_signed*level_fe + since_signed*level_fe*signed +
                   area_contracted + area_in_operation + deal_scope +
                   year_fe + deal_id,
                 cluster = 'deal_id')





# ---------------------- ROBUSTNESS CHECKS ----------------------------


#----------ALL OBSERVATIONS 

# Preferred Model; Treatment = Operational; Years >= 2000
ra1 = mdta %>%
  filter(year >=2000) %>%
  lm.cluster(formula = assets ~ operational + level_fe*operational + 
               area_contracted + area_in_operation + deal_scope +
               year_fe + deal_id,
             cluster = 'deal_id')

# Preferred Model; Treatment = Signed; Years >= 2000
ra2 <- mdta %>%
  filter(year >= 2000) %>%
  lm.cluster(formula = assets ~ signed + level_fe*signed + 
               area_contracted + area_in_operation + deal_scope,
             cluster = 'deal_id')

# Treatment = Operational + Lagged Operational; Controls + Year & Deal FEs
ra3 <- lm.cluster(data = mdta, 
                 formula = assets ~ level_fe*operational + 
                   level_fe*operational_lag_1 + level_fe*operational_lag_2 + 
                   level_fe*operational_lag_3 + level_fe*operational_lead_1 + 
                   level_fe*operational_lead_2 + level_fe*operational_lead_3 +
                   area_contracted + area_in_operation + deal_scope +
                   year_fe + deal_id,
                 cluster = 'deal_id')

# Treatment = Signed + Lagged Signed; Controls + Year & Deal FEs
ra4 <- lm.cluster(data = mdta, 
                 formula = assets ~ level_fe*signed + 
                   level_fe*signed_lag_1 + level_fe*signed_lag_2 + 
                   level_fe*signed_lag_3 + level_fe*signed_lead_1 +
                   level_fe*signed_lead_2 + level_fe*signed_lead_3 +
                   area_contracted + area_in_operation + deal_scope +
                   year_fe + deal_id,
                 cluster = 'deal_id')



#---------- FOOD AGRICULTURE ONLY

# Preferred Model; Treatment = Operational; Years >= 2000
rb1 = agriculture_food_nonfood %>%
  filter(year >=2000) %>%
  lm.cluster(formula = assets ~ operational + level_fe*operational + 
               area_contracted + area_in_operation + deal_scope +
               year_fe + deal_id,
             cluster = 'deal_id')

# Preferred Model; Treatment = Signed; Years >= 2000
rb2 <- agriculture_food_nonfood %>%
  filter(year >= 2000) %>%
  lm.cluster(formula = assets ~ signed + level_fe*signed + 
               area_contracted + area_in_operation + deal_scope,
             cluster = 'deal_id')

# Treatment = Operational + Lagged Operational; Controls + Year & Deal FEs
rb3 <- lm.cluster(data = agriculture_food_nonfood, 
                  formula = assets ~ level_fe*operational + 
                    level_fe*operational_lag_1 + level_fe*operational_lag_2 + 
                    level_fe*operational_lag_3 + level_fe*operational_lead_1 + 
                    level_fe*operational_lead_2 + level_fe*operational_lead_3 +
                    area_contracted + area_in_operation + deal_scope +
                    year_fe + deal_id,
                  cluster = 'deal_id')

# Treatment = Signed + Lagged Signed; Controls + Year & Deal FEs
rb4 <- lm.cluster(data = agriculture_food_nonfood, 
                  formula = assets ~ level_fe*signed + 
                    level_fe*signed_lag_1 + level_fe*signed_lag_2 + 
                    level_fe*signed_lag_3 + level_fe*signed_lead_1 +
                    level_fe*signed_lead_2 + level_fe*signed_lead_3 +
                    area_contracted + area_in_operation + deal_scope +
                    year_fe + deal_id,
                  cluster = 'deal_id')



#---------- AGRO-INDUSTRY

# Preferred Model; Treatment = Operational; Years >= 2000
rc1 = agriculture_industrial %>%
  filter(year >=2000) %>%
  lm.cluster(formula = assets ~ operational + level_fe*operational + 
               area_contracted + area_in_operation + deal_scope +
               year_fe + deal_id,
             cluster = 'deal_id')

# Preferred Model; Treatment = Signed; Years >= 2000
rc2 <- agriculture_industrial %>%
  filter(year >= 2000) %>%
  lm.cluster(formula = assets ~ signed + level_fe*signed + 
               area_contracted + area_in_operation + deal_scope,
             cluster = 'deal_id')

# Treatment = Operational + Lagged Operational; Controls + Year & Deal FEs
rc3 <- lm.cluster(data = agriculture_industrial, 
                  formula = assets ~ level_fe*operational + 
                    level_fe*operational_lag_1 + level_fe*operational_lag_2 + 
                    level_fe*operational_lag_3 + level_fe*operational_lead_1 + 
                    level_fe*operational_lead_2 + level_fe*operational_lead_3 +
                    area_contracted + area_in_operation + deal_scope +
                    year_fe + deal_id,
                  cluster = 'deal_id')

# Treatment = Signed + Lagged Signed; Controls + Year & Deal FEs
rc4 <- lm.cluster(data = agriculture_industrial, 
                  formula = assets ~ level_fe*signed + 
                    level_fe*signed_lag_1 + level_fe*signed_lag_2 + 
                    level_fe*signed_lag_3 + level_fe*signed_lead_1 +
                    level_fe*signed_lead_2 + level_fe*signed_lead_3 +
                    area_contracted + area_in_operation + deal_scope +
                    year_fe + deal_id,
                  cluster = 'deal_id')



#---------- AGRICULTURE FOOD ONLY

# Preferred Model; Treatment = Operational; Years >= 2000
rd1 = agriculture_food %>%
  filter(year >=2000) %>%
  lm.cluster(formula = assets ~ operational + level_fe*operational + 
               area_contracted + area_in_operation + deal_scope +
               year_fe + deal_id,
             cluster = 'deal_id')

# Preferred Model; Treatment = Signed; Years >= 2000
rd2 <- agriculture_food %>%
  filter(year >= 2000) %>%
  lm.cluster(formula = assets ~ signed + level_fe*signed + 
               area_contracted + area_in_operation + deal_scope,
             cluster = 'deal_id')

# Treatment = Operational + Lagged Operational; Controls + Year & Deal FEs
rd3 <- lm.cluster(data = agriculture_food, 
                  formula = assets ~ level_fe*operational + 
                    level_fe*operational_lag_1 + level_fe*operational_lag_2 + 
                    level_fe*operational_lag_3 + level_fe*operational_lead_1 + 
                    level_fe*operational_lead_2 + level_fe*operational_lead_3 +
                    area_contracted + area_in_operation + deal_scope +
                    year_fe + deal_id,
                  cluster = 'deal_id')

# Treatment = Signed + Lagged Signed; Controls + Year & Deal FEs
rd4 <- lm.cluster(data = agriculture_food, 
                  formula = assets ~ level_fe*signed + 
                    level_fe*signed_lag_1 + level_fe*signed_lag_2 + 
                    level_fe*signed_lag_3 + level_fe*signed_lead_1 +
                    level_fe*signed_lead_2 + level_fe*signed_lead_3 +
                    area_contracted + area_in_operation + deal_scope +
                    year_fe + deal_id,
                  cluster = 'deal_id')




# ----------------------- MODEL SUMMARIES ---------------------------

# All Industries 
summary(a1)  # Treatment = Operational; Controls 
summary(a2)  # Treatment = Operational; Controls + Year & Deal FEs
summary(a3)  # Treatment = Operational; Controls + Year & Country FEs + Industry
summary(a4)  # Treatment = Operational; Controls + Year & Deal FEs + Since Operational
summary(a5)  # Treatment = Signed; Controls 
summary(a6)  # Treatment = Signed; Controls + Yera & Deal FEs
summary(a7)  # Treatment = Signed; Controls + Year & Country FEs + Industry
summary(a8)  # Treatment = Signed; Controls + Year & Deal FEs + Since Signed 

summary(ra1)  # A2 on observations from the year 2000 or later
summary(ra2)  # A5 on observations from the year 2000 or later
summary(ra3)  # A4 with since_operational replaced by three periods of lagged values
summary(ra4)  # A8 with since_signed replaced by three periods of lagged values


# Food and Non-Food Agriculture
summary(b1)  # Treatment = Operational; Controls 
summary(b2)  # Treatment = Operational; Controls + Year & Deal FEs
summary(b3)  # Treatment = Operational; Controls + Year & Country FEs + Industry
summary(b4)  # Treatment = Operational; Controls + Year & Deal FEs + Since Operational
summary(b5)  # Treatment = Signed; Controls 
summary(b6)  # Treatment = Signed; Controls + Yera & Deal FEs
summary(b7)  # Treatment = Signed; Controls + Year & Country FEs + Industry
summary(b8)  # Treatment = Signed; Controls + Year & Deal FEs + Since Signed 

summary(rb1)  # A2 on observations from the year 2000 or later
summary(rb2)  # A5 on observations from the year 2000 or later
summary(rb3)  # A4 with since_operational replaced by three periods of lagged values
summary(rb4)  # A8 with since_signed replaced by three periods of lagged values


# Agro-Industrial Developments
summary(c1)  # Treatment = Operational; Controls 
summary(c2)  # Treatment = Operational; Controls + Year & Deal FEs
summary(c3)  # Treatment = Operational; Controls + Year & Country FEs + Industry
summary(c4)  # Treatment = Operational; Controls + Year & Deal FEs + Since Operational
summary(c5)  # Treatment = Signed; Controls 
summary(c6)  # Treatment = Signed; Controls + Yera & Deal FEs
summary(c7)  # Treatment = Signed; Controls + Year & Country FEs + Industry
summary(c8)  # Treatment = Signed; Controls + Year & Deal FEs + Since Signed 

summary(rc1)  # A2 on observations from the year 2000 or later
summary(rc2)  # A5 on observations from the year 2000 or later
summary(rc3)  # A4 with since_operational replaced by three periods of lagged values
summary(rc4)  # A8 with since_signed replaced by three periods of lagged values


# Food Agriculture Only
summary(rd1)  # A2 on subset of only food agriculture
summary(rd2)  # A5 on subset of only food agriculture
summary(rd3)  # A4 on subset of only food agriculture
summary(rd4)  # A8 on subset of only food agriculture





# -------------------------- NOTES / TODO ---------------------------


# B is my preferred inclusion criteria

# It seems that point estimate falls when including country FEs for all developments
# but not when the sample is restricted to agricultural developments. Could be
# that some industries are driving that decline in the point estimate. 

# Check whether there is indeed a problem where deal_id fixed effects creates
# multicollinearity with country FEs + industry FEs.

# Re-check SEs with bootstrapping and randomization inference. 

# Effect appears partially driven by earlier years i.e. Landsat 5 imagery

# Look into using individual FEs + lags -- issues of autocorrelation. 

# Interpretation of A5 -- assets growing prior to being operational, with 
# growth plateauing after becoming operational. Suggestive evidence that growth
# is predominantly in the period immediately before becoming operational, with
# no long-run effect on growth after the initial improvements. Could reflect
# OVB on asset predictions.

# Large growth after signed but no growth prior. Growth seems to taper off after
# being operational. So seems like growth in area around plantation caused by
# period immediately after signing before becoming operational. 
# Ideally we'd know if this is robust to masking the development itself, which 
# can be done partially with a little more time. This is approach taken by Sandro. 
# However, we cannot mask features that extend beyond the LSLA area like road 
# surfacing, which could be a potential source of endogeneity. 

# B4 & B8 are giving unreasonable estimates. Check what's driving that. I think 
# it might be outliers because C8 with just a few more obs is fine.

# See if I can run the models using a for loop to cut down on the risk that
# specifications might not match across models.

