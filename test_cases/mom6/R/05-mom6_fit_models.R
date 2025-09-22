# ------------------------------------------------------------------------------
# 05-mom6_fit_model.R
#
# Adapted R script (i.e., 08-glorys_fit_models.R)
# from Julia Indivero's oxygen skill testing repo to skill test MOM6 oxygen 
# outputs against the Joint U.S.-Canada Pacific Hake Acoustic Trawl Survey in 
# situ data
# https://github.com/jindivero/o2-sdm-paper#
#
# Step 5: Fit GLMM to MOM6 output and calculate RMSE against hake survey data
#
# Created by Julia Indivero
# Adapted: Aug 14th, 2025 by Olivia Gemmell, UW
#
# ------------------------------------------------------------------------------

library(sdmTMB)
library(dplyr)
library(Metrics)
library(ggplot2)
library(tidyr)
library(rnaturalearth)
library(sf)
library(ggpubr)
library(visreg)
library(tidync)
library(marmap)
library(bestNormalize)
library(readr)
# remotes::install_github("pbs-assess/sdmTMBextra", dependencies = TRUE)
library(sdmTMBextra)

# set root directory
root_dir <- "test_cases/mom6/"

#Load functions
# source("bin/skill_test_mom6/R/util_funs.R")
source(paste0(root_dir, "R/helper_funs.R"))


# load regional polygons
regions.hull <- readRDS(paste0(root_dir, "data/regions_hull.rds"))

# setup up mapping ####
map_data <- rnaturalearth::ne_countries(scale = "large",
                                        returnclass = "sf",
                                        continent = "North America")

us_coast_proj <- sf::st_transform(map_data, crs = 32610)

# for barrier mesh
# crop to study area
# Define bounding box (xmin, ymin, xmax, ymax)
bbox <- st_bbox(c(xmin = -135, ymin = 30, xmax = -115, ymax = 55), crs = st_crs(map_data))
map_cropped <- st_crop(map_data, bbox)
us_coast_km <- map_cropped
us_coast_km <- sf::st_transform(us_coast_km, crs = 32610)
# convert to km
st_geometry(us_coast_km) <- st_geometry(us_coast_km) / 1000


#Load oxygen data
dat <- readRDS(paste0(root_dir, "data/all_o2_dat_region.rds"))

#Make depth 0 NA
dat$depth <- ifelse(dat$depth==0, NA, dat$depth)

#Remove any rows with missing data
dat <- dat %>%
  drop_na(depth, o2, temp, sigma0, month, X, Y, year)

#Set minimum sigma
minsigma0 <- 24
dat$sigma0[dat$sigma0 <= minsigma0] <- minsigma0

#Log depth
dat$depth_ln <- log(dat$depth)

# make month a factor
dat$month <- factor(dat$month, levels = 6:9)

#Save model outputs?
savemodel=F
#Plot models and save?
plotmodel = F


#Scale?
scale <- TRUE
if(scale==T){
  dat$o2 <- dat$o2/100
}

# transform response?
transform <- "none"


#Run model fit
rmse_bc_cc <- mom6_fit(dat = dat, 
                       test_region = "bc_cc", 
                       root_dir = root_dir,
                       scale = TRUE,
                       transform = "none",
                       barrier_mesh = FALSE)

# ------------------------------------------------------------------------------
# look at results
# ------------------------------------------------------------------------------
# Load region data
preds_all <- read_rds(file = paste0(root_dir, "data/mom6/mom6_bc_cc.rds"))
preds_all <- preds_all[preds_all$depth <= 500, ]
preds_all <- preds_all[preds_all$o2 >= 0, ]
preds_all$depth_ln <- log(preds_all$depth)

if(transform == "quantile"){
  # Apply ordered quantile normalization to o2 column
  bn <- orderNorm(preds_all$o2)
}


rmse_bc_cc$rmse_summary

### 2011
# Calculate dharma residuals 
mod <- rmse_bc_cc$models$m_2011
sim_resids <- simulate(mod, nsim = 500, type = "mle-mvn")
dharma_residuals(sim_resids, mod)
# print out the figure 
rmse_bc_cc$figures$fig_2011
# Plot response curve
# plot doesnt show shaded error ribbons because depths was fit with a smoother 
# and random fields are turned off in the predict function to isolate the depth
# effect 
plot_depth_response(mod = mod,
                    transform = "none",
                    scale = TRUE,
                    preds_all = preds_all,
                    year = 2011,
                    month_fixed = 2,
                    n = 250,
                    include_random_fields = FALSE)
# Visualize the depth effect with ggeffects
ggeffects::ggpredict(mod, "depth_ln [all]") |> plot()
# Visualize depth effect with visreg: (see ?visreg_delta)
visreg::visreg(mod, xvar = "depth_ln") # link space; randomized quantile residuals
visreg::visreg(fit, xvar = "depth", scale = "response")
visreg::visreg(fit, xvar = "depth", scale = "response", gg = TRUE, rug = FALSE)

# save
ggsave(paste0(root_dir, "output/plots/mom6_bc_cc_resp_curve_2011.pdf"))



### 2012
# Calculate dharma residuals 
mod <- rmse_bc_cc$models$m_2012
sim_resids <- simulate(mod, nsim = 500, type = "mle-mvn")
dharma_residuals(sim_resids, mod)
plot(sim_resids)
# print out the figure 
rmse_bc_cc$figures$fig_2012
# Plot response curve
plot_depth_response(mod = mod,
                    transform = "none",
                    scale = TRUE,
                    preds_all = preds_all,
                    year = 2012,
                    month_fixed = 2,
                    n = 250,
                    include_random_fields = FALSE)
# save
ggsave(paste0(root_dir, "output/plots/mom6_bc_cc_resp_curve_2012.pdf"))


### 2013
# Calculate dharma residuals 
mod <- rmse_bc_cc$models$m_2013
sim_resids <- simulate(mod, nsim = 500, type = "mle-mvn")
dharma_residuals(sim_resids, mod)
plot(sim_resids)
# print out the figure 
rmse_bc_cc$figures$fig_2013


### 2015
# Calculate dharma residuals 
mod <- rmse_bc_cc$models$m_2015
sim_resids <- simulate(mod, nsim = 500, type = "mle-mvn")
dharma_residuals(sim_resids, mod)
plot(sim_resids)
# print out the figure 
rmse_bc_cc$figures$fig_2015

