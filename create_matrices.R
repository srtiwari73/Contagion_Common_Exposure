rm(list = ls())

library(readxl)
library(R.matlab)
library(dplyr)
library(tidyr)
library(reshape2)

# 1. Create Liabilities matrix (Lex)
# Load Excel files (adjust paths as needed)
liab <- read_excel("All_Banks_Spline.xlsx", sheet = "Lex")
# Ensure data are ordered by date:
liab <- liab %>% arrange(date)
liab <- liab[-(1:40), ]    # remove first 4 date entries


# Extract unique identifiers
banks <- unique(liab$bank)
dates <- unique(liab$date)
n_banks <- length(banks)
n_time <- length(dates)
liab_categories <- c("Demand_Deposits", "SB_Deposits", "Borrow_RBI", "Borrow_Others", "Borrow_Foreign", "Other_Liabilities")
n_liab <- length(liab_categories)

# Create ordering indices
bank_idx <- setNames(1:n_banks, banks)
date_idx <- setNames(1:n_time, dates)

# Reshape data from long to wide with all categories for each bank-date
liab_melt <- melt(liab, id.vars = c("date", "bank"), measure.vars = liab_categories,
                variable.name = "liab_cat", value.name = "value")

# Initialize 3D array L: banks x (H*banks) x dates, filled with zeros
L_array <- array(0, dim = c(n_banks, n_liab*n_banks, n_time))

# Fill L_array
for (t in seq_along(dates)) {
  # current_date <- dates[t]
  liab_date <- liab_melt %>% filter(date == dates[t])
  
  for (b in seq_along(banks)) {
    # bank_name <- banks[b]
    liab_bank <- liab_date %>% filter(bank == banks[b])
    
    for (h in seq_along(liab_categories)) {
      # cat_name <- liab_categories[h]
      val <- liab_bank %>% filter(liab_cat == liab_categories[h]) %>% pull(value)
      if (length(val) == 0) val <- 0
      
      # Column position = (h-1)*N + b
      col_pos <- (b-1)*n_liab + h
      
      L_array[b, col_pos, t] <- val
    }
  }
}

# Save as MATLAB .mat file
writeMat("All_Banks_Lex.mat", Lex = L_array)

###############################################

###############################################
# 2. Create Exogeneous asset matrix (Aex)
exog <- read_excel("All_Banks_Spline.xlsx", sheet = "Aex")
exog <- exog %>% arrange(date)
exog <- exog[-(1:40), ]    # remove first 4 date entries
dates <- unique(exog$date)
n_time <- length(dates)
banks <- unique(exog$bank)
n_banks <- length(banks)

ex_categories <- c("Bonds", "Shares", "Foreign_Assets", "Business_Loans", "Other_Loans", "Term_Loans", "Other_Assets")
n_ex_cat <- length(ex_categories)

# Initialize array N x Kex x T
Aex_mat <- array(NA, dim = c(n_banks, n_ex_cat, n_time), 
               dimnames = list(banks, ex_categories, as.character(dates)))

for (tt in seq_along(dates)) {
  temp <- exog %>% filter(date == dates[tt])
  # Fill each "slice" at time t (across banks and categories)
  Aex_mat[ , , tt] <- as.matrix(temp[, ex_categories])
}

# Aex_mat: banks x ex_categories x time
writeMat("All_Banks_Aex.mat", Aex = Aex_mat)

###############################################
# 3. Create Endogeneous asset matrix (Aen)
endog <- read_excel("All_Banks_Spline.xlsx", sheet = "Aen")
endog <- endog %>% arrange(date)
endog <- endog[-(1:40), ]    # remove first 4 date entries
dates <- unique(endog$date)
n_time <- length(dates)
banks <- unique(endog$bank)
n_banks <- length(banks)

endo_categories <- c("Balance_w_banks", "Loans_to_Banks")
n_endo_cat <- length(endo_categories)

# Initialize array N x Kex x T
Aen_mat <- array(NA, dim = c(n_banks, n_endo_cat, n_time), 
                 dimnames = list(banks, endo_categories, as.character(dates)))

for (tt in seq_along(dates)) {
  temp <- endog %>% filter(date == dates[tt])
  # Fill each "slice" at time t (across banks and categories)
  Aen_mat[ , , tt] <- as.matrix(temp[, endo_categories])
}

# Aex_mat: banks x ex_categories x time
writeMat("All_Banks_Aen.mat", Aen = Aen_mat)
#################################################
# 3. Exposures: For each endogenous asset, create a time series adjacency array
# expos <- read_excel("All_Banks.xlsx", sheet = "Expo")
# expos <- expos %>% arrange(date)
# expos <- expos[-(1:16), ]    # remove first 4 date entries
# # Load exposure data with columns: date, lender_bank, borrower_bank, asset_category, value
# 
# banks <- unique(c(expos$lender_bank, expos$borrower_bank))
# n_banks <- length(banks)
# dates <- sort(unique(expos$date))
# n_time <- length(dates)
# expos_categories <- unique(expos$asset_category)
# n_expos_cat <- length(expos_categories)
# 
# # Initialize array [lender, borrower, asset_cat, time]
# expos_arr <- array(NA, dim = c(n_banks, n_banks, n_expos_cat, n_time),
#                    dimnames = list(lender = banks, borrower = banks, 
#                                    asset_cat = expos_categories, date = as.character(dates)))
# 
# for (t in seq_along(dates)) {
#   temp <- expos %>% filter(date == dates[t])
#   for (cat in seq_along(expos_categories)) {
#     temp_cat <- temp %>% filter(asset_category == expos_categories[cat])
#     # Fill the NxN slice [ , , cat, t]
#     # Iterate over lender and borrower pairs
#     for (l in banks) {
#       for (b in banks) {
#         val <- temp_cat %>% filter(lender_bank == l, borrower_bank == b) %>% pull(value)
#         expos_arr[l, b, cat, t] <- ifelse(length(val) == 1, val, 0)
#       }
#     }
#   }
# }
# 
# # expos_mat: banks x banks x en_categories x time
# writeMat("All_BanksG.mat", G = expos_arr)

###################################################
# 4. Capital ratio matrix (lambda)
caprat <- read_excel("All_Banks_Spline.xlsx", sheet = "lambda")
caprat <- caprat %>% arrange(date)
caprat <- caprat[-(1:4), ]    # remove first 4 date entries

caprat_mat <- as.matrix(caprat[,-11]) # Exclude date column
writeMat("All_Banks_lambda.mat", lambda = caprat_mat)
###################################################
# 5. Change in Capital ratio matrix (d_lambda)
dcaprat <- read_excel("All_Banks_Spline.xlsx", sheet = "d_lambda")
dcaprat <- dcaprat %>% arrange(date)
dcaprat <- dcaprat[-(1:4), ]    # remove first 4 date entries

dcaprat_mat <- as.matrix(dcaprat[,-11]) # Exclude date column
writeMat("All_Banks_d_lambda.mat", d_lambda = dcaprat_mat)

###################################################
# 6. Risky assets matrix (RA)
risk <- read_excel("All_Banks_Spline.xlsx", sheet = "RA")
risk <- risk %>% arrange(date)
risk <- risk[-(1:4), ]    # remove first 4 date entries

risk_mat <- as.matrix(risk[,-11]) # Exclude date column
writeMat("All_Banks_RA.mat", RA = risk_mat)
###################################################
# 7. change in Risky assets matrix (d_RA)
drisk <- read_excel("All_Banks_Spline.xlsx", sheet = "d_RA")
drisk <- drisk %>% arrange(date)
drisk <- drisk[-(1:4), ]    # remove first 4 date entries

drisk_mat <- as.matrix(drisk[,-11]) # Exclude date column
writeMat("All_Banks_d_RA.mat", d_RA = drisk_mat)

###################################################
# # 8. connectedess matrix
# connect <- read_excel("All_Banks.xlsx", sheet = "D_mb")
# connect <- connect %>% arrange(date)
# connect <- connect[-(1:8), ]    # Remove first 4 date values 
# 
# banks_connect <- unique(c(connect$emitter, connect$receiver))
# n_banks_connect <- length(banks_connect)
# dates <- sort(unique(connect$date))
# n_time <- length(dates)
# 
# # Initialize array [emitter, receiver, time]
# connect_arr <- array(NA, dim = c(n_banks_connect, n_banks_connect, n_time),
#                    dimnames = list(emitter = banks_connect, receiver = banks_connect, 
#                                    date = as.character(dates)))
# 
# for (t in seq_along(dates)) {
#   temp <- connect %>% filter(date == dates[t])
#     # temp_cat <- temp %>% filter(asset_category == expos_categories[cat])
#     # Fill the NxN slice [ , , t]
#     # Iterate over lender and borrower pairs
#     for (e in banks) {
#       for (r in banks) {
#         val <- temp %>% filter(emitter == e, receiver == r) %>% pull(value)
#         connect_arr[e, r, t] <- ifelse(length(val) == 1, val, 0)
#       }
#     }
# }
# 
# # expos_mat: banks x banks x en_categories x time
# writeMat("All_Banks_D_MB.mat", D_MB = connect_arr)

#########################################
# 9. Theta (Selection matrix for systematic shocks)
theta <- read_excel("All_Banks_Spline.xlsx", sheet = "Theta")

theta_mat <- as.matrix(theta[,-1]) # Exclude names column
writeMat("All_Banks_Theta.mat", Theta = theta_mat)

#########################################
# 10. S (Selection matrix for marketable illiquid assets)
S <- read_excel("All_Banks_Spline.xlsx", sheet = "S")

S_mat <- as.matrix(S[,-1]) # Exclude names column
writeMat("All_Banks_S.mat", S = S_mat)

#########################################
# 11. Weights (for illiquid marketable assets)
W <- read_excel("All_Banks_Spline.xlsx", sheet = "W")
W <- W %>% arrange(date)
W <- W[-(1:80), ]    # remove first 4 date entries

banks_W <- unique(c(W$bank))
n_banks_W <- length(banks_W)
cat_W <- unique(c(W$asset_type))
n_cat_W <- length(cat_W)
dates <- sort(unique(W$date))
n_time <- length(dates)

# Initialize array [emitter, receiver, time]
W_arr <- array(NA, dim = c(n_cat_W, n_banks_W, n_time),
                     dimnames = list(asset_type = cat_W, bank = banks_W, 
                                     date = as.character(dates)))

for (t in seq_along(dates)) {
  temp <- W %>% filter(date == dates[t])
  # temp_cat <- temp %>% filter(asset_category == expos_categories[cat])
  # Fill the NxN slice [ , , t]
  # Iterate over lender and borrower pairs
  for (c in cat_W) {
    for (b in banks_W) {
      val <- temp %>% filter(asset_type == c, bank == b) %>% pull(weight)
      W_arr[c, b, t] <- ifelse(length(val) == 1, val, 0)
    }
  }
}

# expos_mat: banks x banks x en_categories x time
writeMat("All_Banks_W.mat", W = W_arr)


