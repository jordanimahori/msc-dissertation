
# This script estimates my main models and robustness tests, and replicates the 
# tables from my paper (less some minor manual reformatting). 



# --------------------------- ENVIRONMENT ---------------------------

rm(list = ls())
setwd("~/Projects/Dissertation/agro-welfare")

library(sandwich)
library(lmtest)
library(forcats)
library(stargazer)





# ------------------------------ DATA -------------------------------

# Master Data
mdta <- readRDS("data/mdta.RData")
robust <- readRDS("data/robustness/robust.RData")

# Reduced Sample - All Agriculture 
agriculture <- filter(mdta, investment_type == 'Food' |
                        investment_type == 'Livestock' |
                        investment_type == 'Non-food')





# -------------------------- MAIN MODELS ----------------------------


# All Agriculture:  Treatment = Operational; Year & Deal FEs
a1 <- lm(data = agriculture, 
                 formula = assets ~ operational + operational*level_fe + 
                   year_fe + deal_id)

a1_cluster_se <- coeftest(a1, vcov=vcovCL, cluster=~deal_id)



# All Agriculture:  Treatment = Operational; Controls + Year & Deal FEs
a2 <- lm(data = agriculture, 
                 formula = assets ~ operational + operational*level_fe + 
                   area_contracted + area_in_operation + deal_scope +
                   property_rights + government_integrity +
                   year_fe + deal_id)

a2_cluster_se <- coeftest(a2, vcov=vcovCL, cluster=~deal_id)



# All Agriculture: Treatment = Operational; Controls + Year & Deal FEs + Palm Oil
a3 <- lm(data = agriculture, 
                 formula = assets ~ operational + operational*level_fe + 
                   operational*palm_oil + area_contracted + area_in_operation + 
                   property_rights + government_integrity +
                   deal_scope + year_fe + deal_id)

a3_cluster_se <- coeftest(a3, vcov=vcovCL, cluster=~deal_id)



# All Agriculture:  Treatment = Signed; Year & Deal FEs
a4 <- lm(data = agriculture, 
                 formula = assets ~ signed + signed*level_fe + 
                   year_fe + deal_id)

a4_cluster_se <- coeftest(a4, vcov=vcovCL, cluster=~deal_id)



# All Agriculture:  Treatment = Signed; Controls + Year & Deal FEs
a5 <- lm(data = agriculture, 
                 formula = assets ~ signed + signed*level_fe + 
                   area_contracted + area_in_operation + deal_scope + 
                   property_rights + government_integrity +
                   year_fe + deal_id)

a5_cluster_se <- coeftest(a5, vcov=vcovCL, cluster=~deal_id)



# All Agriculture:  Treatment = Signed; Controls + Year & Deal FEs + Palm Oil
a6 <- lm(data = agriculture, 
                 formula = assets ~ signed + signed*level_fe + signed*palm_oil + 
                   area_contracted + area_in_operation + deal_scope + 
                   property_rights + government_integrity +
                   year_fe + deal_id)

a6_cluster_se <- coeftest(a6, vcov=vcovCL, cluster=~deal_id)



# Export models in a single table.
stargazer(a1_cluster_se, a2_cluster_se, a3_cluster_se, a4_cluster_se, 
          a5_cluster_se, a6_cluster_se, 
          type="text",
          title="Main Regression Results",
          font.size="scriptsize", 
          keep=c("signed", "operational", "level_fe", "property_rights", 
                 "government_integrity", "palm_oil"),
          column.labels=c("Signed", "Operational"), 
          column.separate=c(3, 3), 
          dep.var.labels="Mean Household Assets", 
          df=FALSE)





# ---------------------- HETEROGENEITY TESTS ---------------------



# --------- TRANSNATIONAL 

# All Agriculture: Treatment = Operational; Testing Effect of Transnational
h1 <- lm(data = agriculture, 
                 formula = assets ~ operational + operational*level_fe + 
                   operational*deal_scope + operational*palm_oil + area_contracted + area_in_operation + 
                   property_rights + government_integrity +
                   deal_scope + year_fe + deal_id)

h1_cluster_se <- coeftest(h1, vcov=vcovCL, cluster=~deal_id)


# All Agriculture: Treatment = Signed; Testing the Effect of Transnational
h2 <- lm(data = agriculture, 
                 formula = assets ~ signed + signed*level_fe + 
                   signed*deal_scope + signed*palm_oil + area_contracted + area_in_operation + 
                   property_rights + government_integrity +
                   deal_scope + year_fe + deal_id)

h2_cluster_se <- coeftest(h2, vcov=vcovCL, cluster=~deal_id)




# ---------- PROPERTY RIGHTS & INSTITUTIONS

# Median Property Rights = 30, about 20% of the sample is below. 
# Median Institutions at 25, about 40% of the sample is below. 

# All Agriculture: Treatment = Operational; Testing the Effect of Property Rights
h3 <- lm(data = agriculture, 
                 formula = assets ~ operational + operational*level_fe + 
                   operational*low_property_rights + operational*palm_oil + area_contracted + area_in_operation + 
                   property_rights + government_integrity +
                   deal_scope + year_fe + deal_id)

h3_cluster_se <- coeftest(h3, vcov=vcovCL, cluster=~deal_id)


# All Agriculture: Treatment = Signed; Testing the Effect of Property Rights
h4 <- lm(data = agriculture, 
                 formula = assets ~ signed + signed*level_fe + 
                   signed*low_property_rights + signed*palm_oil + area_contracted + area_in_operation + 
                   property_rights + government_integrity +
                   deal_scope + year_fe + deal_id)

h4_cluster_se <- coeftest(h4, vcov=vcovCL, cluster=~deal_id)


# All Agriculture: Treatment = Operational; Testing the Effect of Government Integrity
h5 <- lm(data = agriculture, 
                 formula = assets ~ operational + operational*level_fe + 
                   operational*low_government_integrity + operational*palm_oil + area_contracted + area_in_operation + 
                   property_rights + government_integrity +
                   deal_scope + year_fe + deal_id)

h5_cluster_se <- coeftest(h5, vcov=vcovCL, cluster=~deal_id)


# All Agriculture: Treatment = Signed; Testing the Effect of Government Integrity
h6 <- lm(data = agriculture, 
                 formula = assets ~ signed + signed*level_fe + 
                   signed*low_government_integrity + signed*palm_oil + area_contracted + area_in_operation + 
                   property_rights + government_integrity +
                   deal_scope + year_fe + deal_id)

h6_cluster_se <- coeftest(h6, vcov=vcovCL, cluster=~deal_id)




#---------- ALL LAND ACQUISITIONS

# All Acquisitions: Treatment = Operational; Testing the Effects of Investment Type
h7 <- lm(data = mdta, 
                 formula = assets ~ operational + operational*level_fe + 
                   operational*investment_type + area_contracted + area_in_operation + 
                   property_rights + government_integrity +
                   deal_scope + year_fe + deal_id)

h7_cluster_se <- coeftest(h7, vcov=vcovCL, cluster=~deal_id)


# All Acquisitions: Treatment = Signed; Testing the Effects of Investment Type
h8 <- lm(data = mdta, 
                 formula = assets ~ signed + signed*level_fe + 
                   signed*investment_type + area_contracted + area_in_operation + 
                   property_rights + government_integrity +
                   deal_scope + year_fe + deal_id)

h8_cluster_se <- coeftest(h8, vcov=vcovCL, cluster=~deal_id)



# Export models in a single table.
stargazer(h1_cluster_se, h2_cluster_se, h3_cluster_se, h4_cluster_se, 
          h5_cluster_se, h6_cluster_se, h7_cluster_se, h8_cluster_se,
          type="text",
          title="Heterogeneity Analysis Results",
          font.size="scriptsize", 
          keep=c("signed", "signed_1", "signed_2", "signed_3", 
                 "operational", "operational_1", "operational_2", "operational_3"),
          dep.var.labels="Mean Household Assets", 
          df=FALSE)





# ----------------------- ROBUSTNESS TESTS ------------------------



# ---------- DIFFERENT SAMPLE INCLUSION CRITERIA


# Food Agriculture Only: Treatment = Operational
r1 <- agriculture %>%
  filter(investment_type == 'Food' | investment_type == 'Livestock') %>%
  lm(formula = assets ~ operational + operational*level_fe + 
               operational*palm_oil + area_contracted + area_in_operation + 
               property_rights + government_integrity +
               deal_scope + year_fe + deal_id)

r1_cluster_se <- coeftest(r1, vcov=vcovCL, cluster=~deal_id)


# Food Agriculture Only: Treatment = Signed
r2 <- agriculture %>%
  filter(investment_type == 'Food' | investment_type == 'Livestock') %>%
  lm(formula = assets ~ signed + signed*level_fe + 
               signed*palm_oil + area_contracted + area_in_operation + 
               property_rights + government_integrity +
               deal_scope + year_fe + deal_id)

r2_cluster_se <- coeftest(r2, vcov=vcovCL, cluster=~deal_id)



# All Agriculture: Treatment = Operational, No Palm Oil
r3 <- agriculture %>%
  filter(palm_oil != 1) %>%
  lm(formula = assets ~ operational + operational*level_fe + 
               area_contracted + area_in_operation + property_rights + 
               government_integrity + deal_scope + year_fe + deal_id)

r3_cluster_se <- coeftest(r3, vcov=vcovCL, cluster=~deal_id)



# All Agriculture: Treatment = Operational, No Palm Oil
r4 <- agriculture %>%
  filter(palm_oil != 1) %>%
  lm(formula = assets ~ signed + signed*level_fe + 
               area_contracted + area_in_operation + property_rights + 
               government_integrity + deal_scope + year_fe + deal_id)

r4_cluster_se <- coeftest(r4, vcov=vcovCL, cluster=~deal_id)



# All Agriculture: Treatment = Operational, Year >= 2000
r5 <- agriculture %>%
  filter(year >= 2000) %>%
  lm(formula = assets ~ operational + operational*level_fe + 
               operational*palm_oil + area_contracted + area_in_operation + 
               property_rights + government_integrity +
               deal_scope + year_fe + deal_id)

r5_cluster_se <- coeftest(r5, vcov=vcovCL, cluster=~deal_id)



# All Agriculture: Treatment = Signed, Year >= 2000
r6 <- agriculture %>%
  filter(year >= 2000) %>%
  lm(formula = assets ~ signed + signed*level_fe + 
               signed*palm_oil + area_contracted + area_in_operation + 
               property_rights + government_integrity +
               deal_scope + year_fe + deal_id)


r6_cluster_se <- coeftest(r6, vcov=vcovCL, cluster=~deal_id)



# Export models in a single table.
stargazer(r1_cluster_se, r3_cluster_se, r5_cluster_se, 
          r2_cluster_se, r4_cluster_se, r6_cluster_se, 
          type="text",
          title="Reduced Sample Rebustness Tests Results",
          font.size="scriptsize", 
          keep=c("signed", "operational", "level_fe", "property_rights", 
                 "government_integrity", "palm_oil"),
          column.labels=c("Signed", "Operational"), 
          column.separate=c(3, 3), 
          dep.var.labels="Mean Household Assets", 
          df=FALSE)




# ----------- PLACEBO TESTS

placebo <- agriculture
placebo$year_signed_1 <- agriculture$year_signed - 3
placebo$year_operational_1 <- agriculture$year_operational - 3
placebo$year_signed_2 <- agriculture$year_signed - 6
placebo$year_operational_2 <- agriculture$year_operational - 6
placebo$year_signed_3 <- agriculture$year_signed - 9
placebo$year_operational_3 <- agriculture$year_operational - 9


placebo$signed_1 <- ifelse(placebo$year_signed_1 <= placebo$year, 1, 0)
placebo$operational_1 <- ifelse(placebo$year_operational_1 <= placebo$year, 1, 0)
placebo$signed_2 <- ifelse(placebo$year_signed_2 <= placebo$year, 1, 0)
placebo$operational_2 <- ifelse(placebo$year_operational_2 <= placebo$year, 1, 0)
placebo$signed_3 <- ifelse(placebo$year_signed_3 <= placebo$year, 1, 0)
placebo$operational_3 <- ifelse(placebo$year_operational_3 <= placebo$year, 1, 0)



# All Agriculture: Treatment = Operational; Controls + Year & Deal FEs + Palm Oil
p1 <- lm(data = placebo, 
                 formula = assets ~ operational + operational*level_fe + 
                   operational*palm_oil + area_contracted + area_in_operation + 
                   property_rights + government_integrity +
                   deal_scope + year_fe + deal_id)

p1_cluster_se <- coeftest(p1, vcov=vcovCL, cluster=~deal_id)


# All Agriculture:  Treatment = Signed; Controls + Year & Deal FEs + Palm Oil
p2 <- lm(data = placebo, 
                 formula = assets ~ signed + signed*level_fe + signed*palm_oil + 
                   area_contracted + area_in_operation + deal_scope + 
                   property_rights + government_integrity +
                   year_fe + deal_id)

p2_cluster_se <- coeftest(p2, vcov=vcovCL, cluster=~deal_id)


# All Agriculture: Treatment = Operational; Controls + Year & Deal FEs + Palm Oil
p3 <- lm(data = placebo, 
                 formula = assets ~ operational_1 + operational_1*level_fe + 
                   operational_1*palm_oil + area_contracted + area_in_operation + 
                   property_rights + government_integrity +
                   deal_scope + year_fe + deal_id)

p3_cluster_se <- coeftest(p3, vcov=vcovCL, cluster=~deal_id)


# All Agriculture:  Treatment = Signed; Controls + Year & Deal FEs + Palm Oil
p4 <- lm(data = placebo, 
                 formula = assets ~ signed_1 + signed_1*level_fe + signed_1*palm_oil + 
                   area_contracted + area_in_operation + deal_scope + 
                   property_rights + government_integrity +
                   year_fe + deal_id)

p4_cluster_se <- coeftest(p4, vcov=vcovCL, cluster=~deal_id)


# All Agriculture: Treatment = Operational; Controls + Year & Deal FEs + Palm Oil
p5 <- lm(data = placebo, 
                 formula = assets ~ operational_2 + operational_2*level_fe + 
                   operational_2*palm_oil + area_contracted + area_in_operation + 
                   property_rights + government_integrity +
                   deal_scope + year_fe + deal_id)

p5_cluster_se <- coeftest(p5, vcov=vcovCL, cluster=~deal_id)


# All Agriculture:  Treatment = Signed; Controls + Year & Deal FEs + Palm Oil
p6 <- lm(data = placebo, 
                 formula = assets ~ signed_2 + signed_2*level_fe + signed_2*palm_oil + 
                   area_contracted + area_in_operation + deal_scope + 
                   property_rights + government_integrity +
                   year_fe + deal_id)

p6_cluster_se <- coeftest(p6, vcov=vcovCL, cluster=~deal_id)


# All Agriculture: Treatment = Operational; Controls + Year & Deal FEs + Palm Oil
p7 <- lm(data = placebo, 
                 formula = assets ~ operational_3 + operational_3*level_fe + 
                   operational_3*palm_oil + area_contracted + area_in_operation + 
                   property_rights + government_integrity +
                   deal_scope + year_fe + deal_id)

p7_cluster_se <- coeftest(p7, vcov=vcovCL, cluster=~deal_id)


# All Agriculture:  Treatment = Signed; Controls + Year & Deal FEs + Palm Oil
p8 <- lm(data = placebo, 
                 formula = assets ~ signed_3 + signed_3*level_fe + signed_3*palm_oil + 
                   area_contracted + area_in_operation + deal_scope + 
                   property_rights + government_integrity +
                   year_fe + deal_id)

p8_cluster_se <- coeftest(p8, vcov=vcovCL, cluster=~deal_id)



# Export models in a single table.
stargazer(p1, p2, p3, p4, p5, p6, p7, p8,
          type="text",
          title="Placebo Test Results",
          font.size="scriptsize", 
          keep=c("signed", "signed_1", "signed_2", "signed_3", 
                 "operational", "operational_1", "operational_2", "operational_3"),
          column.labels=c("None", "1 Period", "2 Periods", "3 Periods", "End"), 
          column.separate=c(1, 1, 1, 1, 4), 
          dep.var.labels="Mean Household Assets", 
          df=FALSE)

