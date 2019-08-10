

#### calc stats --------------------------------

# Functions to calculate a host of agreement statistics and their associated
# standard errors.

#### Requires --------------------------------

require(pacman)
require(devtools)
require(janitor)
require(tidyverse)
require(forcats)
require(rlang)
require(lubridate)
require(stringr)
require(magrittr)
require(here)
require(vcd)
require(mice)


###############################################################################
#### Function for pooling -----------------------------------------------------

# In order to pool the data and calculate the statistics of interest, I needed
# to create a series of funciton to determine their pooled statistics and 
# variances. They also need to be flexible enough to take the difference strata
# and procedures that would be given to them.


#### Make 2x2 table --------------------------------

# Function to make 2x2 tables and avoids errors when there are zero counts
# for some of the table cells. The dimensions will always be 2x2.

make_table <- function(data_set) {
  
  x <- factor(data_set$ehr, levels = c(0, 1))
  y <- factor(data_set$dmap, levels = c(0, 1))
  table(x, y, dnn = c("ehr", "dmap"))
  
}

#### Calculate the stats and variances --------------------------------

## Calculate statistics ----------------

calc_stats_p <- function(data_set) {
  
  #  EHR should be the first argument given to the table
  #  Then it will appear on the vertical of the 2x2 table
  #  and the correct numbers get assigned the correct labels below.
  
  #  Start of function
  
  df <- data_set
  
  # if (dim(df)[1] != 0) { 
  
    # Create 2x2 table 
    # TABL <- with(df, table(EHR, DMAP))
    # input.table <- TABL
    input.table <- make_table(data_set = df)
    
    n <- sum(input.table)      # Total eligible patients
    a <- input.table['1', '1']  # "Yes" in both sources
    d <- input.table['0', '0']  # "No" in both sources
    b <- input.table['1', '0']  # "Yes" in source 1, on the vertical, "No" in other
    c <- input.table['0', '1']  # "Yes" in source 2, on the horizontal, "No" in other
    
    # Check
    matrix(c(a, b, c, d), ncol = 2)
    
    EHR.n <- a + b              # EHR No.
    EHR.p <- EHR.n / n                # EHR %
    
    DMAP.n <- a + c             # Claims No.
    DMAP.p <- DMAP.n / n          # Claims %
    
    Combo.n <- n - d           # Combined EHR and claims No.
    Combo.p <- Combo.n / n        # Combined EHR and claims %
    
    sens <- a / (a + c)      # Sensitivity
    spec <- d / (b + d)      # Specificity
    
    Po <- (a + d) / n    # Observed proportion of agreement
    Pe <- ((a + c) / n * (a + b) / n) + ((b + d) / n * (c + d) / n)     
    # Expected proportion of agreement
    
    Ppos <- (2 * a) / (n + a - d)   # Proportion of positive agreement
    Pneg <- (2 * d) / (n - a + d)   # Proportion of negative agreement
    #  http://support.sas.com/resources/papers/proceedings09/242-2009.pdf
    
    # Prevalence index
    PI <- abs(a / n - d / n)
    
    # Bias index
    BI <- abs((a + b) / n - (a + c) / n)  
    
    # Kappa stat calc
    # kap <- CalcKappaStats(input.table)  # Kappa statistics
    kap <- vcd::Kappa(input.table)$Weighted[1]
    
    # PABAK calc
    PABAK <- 2 * Po - 1
    # PABAK <- K * (1 - PI^2 + BI^2) + PI^2 - BI^2
    
    # Kappa Max
    # Keep the margin totals fixed, and maximize the count of the cells where
    # both agree (a and d)
    A <- min(a + b, a + c)
    D <- min(c + d, b + d)
    B <- a + b - A
    C <- c + d - D
    
    Kmax <- vcd::Kappa(as.table(matrix(c(A, B, C, D), nrow = 2, byrow = TRUE)))
    Kmax <- Kmax$Weighted[1]  #  Kappa max
    
    rm(A, B, C, D)
    
    # Kappa Min
    # Keep the margin totals fixed, and maximize the count of the cells where
    # both diagree (b and c)
    B <- min(a + b, b + d)
    C <- min(c + d, a + c)
    A <- a + b - B
    D <- c + d - C
    
    Kmin <- vcd::Kappa(as.table(matrix(c(A, B, C, D), nrow = 2, byrow = TRUE)))
    Kmin <- Kmin$Weighted[1]  #  Kappa max
    
    rm(A, B, C, D)
    
    result_p <- data.frame(
      n, a, b, c, d,
      EHR.n, EHR.p,DMAP.n, DMAP.p, Combo.n, Combo.p, 
      sens, spec,
      Po, Pe, Ppos, Pneg, PI, BI, PABAK,
      Kmax, Kmin, kap)
    
    result_p %>% 
      tidyr::gather(., 
                    key = "stat", 
                    value = "Q")
    
  
  
}

## Calculate variances (standard errors) -----------------

calc_stats_se <- function(data_set) {
  
  #  EHR should be the first argument given to the table
  #  Then it will appear on the vertical of the 2x2 table
  #  and the correct numbers get assigned the correct labels below.
  
  #  Start of function
  
  df <- data_set
  
  # if (dim(df)[1] != 0) { 
  
  # Create 2x2 table 
  # TABL <- with(df, table(EHR, DMAP))
  # input.table <- TABL
  input.table <- make_table(data_set = df)
    
    n <- sum(input.table)      # Total eligible patients
    a <- input.table['1', '1']  # "Yes" in both sources
    d <- input.table['0', '0']  # "No" in both sources
    b <- input.table['1', '0']  # "Yes" in source 1, on the vertical, "No" in other
    c <- input.table['0', '1']  # "Yes" in source 2, on the horizontal, "No" in other
    
    # Check
    matrix(c(a, b, c, d), ncol = 2)
    
    EHR.n <- 0              # EHR No.
    EHR.p <- 0                # EHR %
    
    DMAP.n <- 0             # Claims No.
    DMAP.p <- 0          # Claims %
    
    Combo.n <- 0           # Combined EHR and claims No.
    Combo.p <- 0        # Combined EHR and claims %
    
    # Sensitivity
    sens <- sqrt((a / (a + b)) * (1 - (a / (a + b))) / (a + b))  
    # Specificity
    spec <- sqrt((c / (c + d)) * (1 - (c / (c + d))) / (c + d))  
    
    # Observed proportion of agreement
    Po <- sqrt(((a + d) / n) * (1 - (a + d) / n) / n)  
    # Expected proportion of agreement
    Pe <- 0  
    
    # Proportion of positive agreement
    Ppos <- sqrt((4 * a * (b + c) * (a + b + c))) / ((a + b) + (a + c))^2   
    
    # Proportion of negative agreement
    Pneg <- sqrt(4 * d * (b + c) * (b + c + d)) / ((b + d) + (c + d))^2   
    
    # Prevalence index
    PI <- 
      sqrt(((a * (n - a)) / n^3) + ((d * (n - d)) / n^3))
    
    # Bias index
    BI <- 
      sqrt((((a + b) * (n - (a + b))) / n^3) + (((a + c) * (n - (a + c))) / n^3))
    
    # Kappa stat calc
    # kap <- CalcKappaStats(input.table)  # Kappa statistics
    kap <- vcd::Kappa(input.table)$Weighted[2]
    
    # PABAK calc
    PABAK <- sqrt(4 * ((a + d) / n) * (1 - (a + d) / n) / n)
    
    # Kappa Max
    # Keep the margin totals fixed, and maximize the count of the cells where
    # both agree (a and d)
    A <- min(a + b, a + c)
    D <- min(c + d, b + d)
    B <- a + b - A
    C <- c + d - D
    
    Kmax <- vcd::Kappa(as.table(matrix(c(A, B, C, D), nrow = 2, byrow = TRUE)))
    Kmax <- Kmax$Weighted[2]  #  Kappa max
    
    rm(A, B, C, D)
    
    # Kappa Min
    # Keep the margin totals fixed, and maximize the count of the cells where
    # both diagree (b and c)
    B <- min(a + b, b + d)
    C <- min(c + d, a + c)
    A <- a + b - B
    D <- c + d - C
    
    Kmin <- vcd::Kappa(as.table(matrix(c(A, B, C, D), nrow = 2, byrow = TRUE)))
    Kmin <- Kmin$Weighted[2]  #  Kappa max
    
    rm(A, B, C, D)
    
    n <- 0
    a <- 0
    b <- 0
    c <- 0
    d <- 0
    
    result_se <- data.frame(
      n, a, b, c, d,
      EHR.n, EHR.p, DMAP.n, DMAP.p, Combo.n, Combo.p, 
      sens, spec,
      Po, Pe, Ppos, Pneg, PI, BI, PABAK,
      Kmax, Kmin, kap)
    
    
    result_se %>% 
      tidyr::gather(., 
                    key = "stat", 
                    value = "U")
    
    
  
}

#### Pool function ------------------------------------

## Example ----------------

# imp <- mice(nhanes)
# m <- imp$m
# Q <- rep(NA, m)
# U <- rep(NA, m)
# for (i in 1:m) {
#   Q[i] <- mean(complete(imp, i)$bmi)
#   U[i] <- var(complete(imp, i)$bmi) / nrow(nhanes)  # (standard error of estimate)^2
# }
# pool.scalar(Q, U, method = "rubin")   # Rubin 1987
# pool.scalar(Q, U, n = nrow(nhanes), k = 1)  # Barnard-Rubin 1999

# $m
# [1] 5
# 
# $qhat
# [1] 27.584 26.884 27.360 26.500 26.396
# 
# $u
# [1] 0.7977560 0.5377227 0.6002000 0.6964333 0.6694160
# 
# $qbar
# [1] 26.9448
# 
# $ubar
# [1] 0.6603056
# 
# $b
# [1] 0.2709232
# 
# $t
# [1] 0.9854134
# 
# $r
# [1] 0.4923597
# 
# $df
# [1] 36.74871
# 
# $fmi
# [1] 0.363636
# 
# $lambda
# [1] 0.3299202



mi_pool <- function(df) {
  
  Q <- df[["Q"]]
  U <- df[["U"]]
  
  mice::pool.scalar(Q, U, method = "rubin") %>%    # Rubin 1987
    as.data.frame(.) %>% 
    dplyr::select(-qhat, -u) %>% 
    dplyr::slice(1) 
    
    
    
  # if (output == "qbar") {  
  #   
  #   # pooled univariate estimate
  #   
  #   return(result$qbar)
  #   
  # } else if (output == "ubar") {
  #   
  #   # mean of the variances (i.e. the pooled within-imputation variance)
  #   
  #   return(result$ubar)
  #   
  # } else if (output == "b") {
  #   
  #   # between-imputation variance
  #   
  #   return(result$b)
  #   
  # } else if (output == "t") {
  #   
  #   # total variance of the pooled estimated
  #   
  #   return(result$t)
  #   
  # } else if (output == "r") {
  #   
  #   # relative increase in variance due to nonresponse
  #   
  #   return(result$r)
  #   
  # } else if (output == "df") {
  #   
  #   # degrees of freedom for t reference distribution
  #   
  #   return(result$df)
  #   
  # } else if (output == "fmi") {
  #   
  #   # fraction missing information due to nonresponse
  #   
  #   return(result$fmi)
  #   
  # } else if (output == "lambda") {
  #   
  #   # proportion of variation due to nonresponse
  #   
  #   return(result$lambda)
  #   
  # }
  # 
  
  
}


#### Test --------------------------------

# imp <- imp_full
# 
# m <- imp$m
# 
# Qa <- rep(NA, m)
# Ua <- rep(NA, m)
# 
# for (i in 1:m) {
# Qa[i] <- calc_stats_p(complete(imp, i), 
#                      procedure = "cervical", 
#                      strata = ">138% FPL", 
#                      stat = "n")
# 
# Ua[i] <- calc_stats_se(complete(imp, i), 
#                      procedure = "cervical", 
#                      strata = ">138% FPL", 
#                      stat = "n")
# }
# 
# pool.scalar(Qa, Ua, method = "rubin")
# 
# 
# 
# class(Qa)
# # [1] "list"
# Qa
# # > Qa
# # [[1]]
# # [1] 210
# # 
# # [[2]]
# # [1] 215
# # 
# # [[3]]
# # [1] 224
# # 
# # [[4]]
# # [1] 209
# # 
# # [[5]]
# # [1] 209
# 
# class(complete(imp, 1))
# 
# 
# 
# imp <- mice(nhanes)
# m <- imp$m
# Q <- rep(NA, m)
# U <- rep(NA, m)
# for (i in 1:m) {
#   Q[i] <- mean(complete(imp, i)$bmi)
#   U[i] <- var(complete(imp, i)$bmi) / nrow(nhanes)  # (standard error of estimate)^2
# }
# 
# # > class(Q)
# # [1] "numeric
# # > class(U)
# # [1] "numeric
# Q
# # [1] 26.604 25.692 27.032 25.792 26.892
# pool.scalar(Q, U, method = "rubin")   # Rubin 1987
# 
# unlist(Qa)



