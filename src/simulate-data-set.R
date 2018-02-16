
#### Simulate a shareable data set --------------------------------

# I want to make a fake data set from the original so that it can be uploaded
# and shared on GitHub for the CSP conference.
#
# This function accomplishes this aim.


### Requires --------------------------------

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

#### make_sim_data() --------------------------------

make_sim_data <- function(n_rows, seed) { 
  
  #### Set the seed --------------------------------
  
  set.seed(seed)
  
  #### Set the variable names --------------------------------
  
  var_names <- c("study_id",
                 "sex",
                 "age_start",
                 "primary_dept",
                 "ethnic_cat",
                 "lang_cat",
                 "race_cat",
                 "fpl_cat",
                 "age_cat",
                 "elig_cervical",
                 "elig_breast",
                 "elig_colon",
                 "elig_colonoscopy",
                 "elig_flexsig",
                 "elig_fobt",
                 "elig_bmi",
                 "elig_flu",
                 "elig_chlam",
                 "elig_smoking",
                 "elig_cholest",
                 "dmap_cervical",
                 "dmap_breast",
                 "dmap_colon",
                 "dmap_colonoscopy",
                 "dmap_flexsig",
                 "dmap_fobt",
                 "dmap_bmi",
                 "dmap_flu",
                 "dmap_chlam",
                 "dmap_smoking",
                 "dmap_cholest",
                 "ehr_cervical",
                 "ehr_breast",
                 "ehr_colon",
                 "ehr_colonoscopy",
                 "ehr_flexsig",
                 "ehr_fobt",
                 "ehr_bmi",
                 "ehr_flu",
                 "ehr_chlam",
                 "ehr_smoking",
                 "ehr_cholest"
  )
  
  
  #### Make an empty tibble --------------------------------
  
  ## Pre-set the number of rows for the data set ----------------
  
  size <- n_rows
  
  ## Create tibble with NA's ----------------
  
  valdata <- tibble::as.tibble(matrix(NA, 
                                      nrow = size, 
                                      ncol = length(var_names)))
  names(valdata) <- var_names
  
  
  #### Make the demographic data --------------------------------
  
  ## Function to help make factor variables ----------------
  
  make_factor <- function(levels, size, replace = TRUE, prob = NULL) { 
    
    if (is.null(prob)) { 
      
      factor(sample(levels, size, replace))
      
    } else {
      
      factor(sample(levels, size, replace, prob))
    }
  }
  
  ## Make the demographic data ----------------
  # Note that the proportions for the demographic categories are made up and
  # decided upon by me. I intended for them to be similar in magnitude to the
  # original study data, but different enough that they could not be compared to 
  # or construed to be original values. Variables with percent missing are the 
  # same ones as my previous work, but the percent missing is slightly different 
  # with rounding.
  
  # 3 group sizes for age groups
  a <- floor(size / 3)
  b <- a
  c <- size - a - b
  
  valdata %<>% 
    mutate(
      study_id = seq(1:size), 
      sex = make_factor(levels = c("F", "M"), 
                        size = size, 
                        prob = c(0.65, 0.35)), 
      age_start = c(sample(c(19:34), size = a, replace = TRUE), 
                    sample(c(35:50), size = b, replace = TRUE), 
                    sample(c(51:64), size = c, replace = TRUE)
      ), 
      age_start = sample(age_start, 
                         size = size, 
                         replace = FALSE), 
      age_cat = cut(age_start, 
                    breaks = c(19, 35, 51, 65), 
                    right = FALSE), 
      primary_dept = make_factor(levels = 
                                   stringr::str_pad(c(1:40), 3, pad = "0"), 
                                 size = size), 
      ethnic_cat = make_factor(levels = 
                                 c("Hispanic", "NH White", "NH Other", NA), 
                               size = size, 
                               prob = c(0.10, 0.70, 0.15, 0.05)), 
      lang_cat = make_factor(levels = c("English", "Spanish", "Other"), 
                             size = size, 
                             prob = c(0.85, 0.05, 0.10)), 
      race_cat = make_factor(
        levels = c("API", "AIAN", "Black", "White", "Multiple Races", NA), 
        size = size, 
        prob = c(0.05, 0.02, 0.10, 0.75, 0.01, 0.07)), 
      fpl_cat = make_factor(levels = c("<=138% FPL", ">138% FPL", NA), 
                            size = size, 
                            prob = c(0.75, 0.05, 0.20))
    )
  
  # drop variabls no longer needed
  rm(a, b, c)
  
  
  #### Make the eligibility variables --------------------------------
  # The original study paper outlined the criteria to be eligible for certain
  # screening services. They tended to be based on sex, age, and medical 
  # history. I will not be generating variables for the relevant medical 
  # history for eligibility. For the purpose of this simulated data set, I will 
  # base eligibility only on sex and age.
  
  # 1 = eligible
  # 0 = not eligible
  
  # Function to convert to factors 
  make_factor2 <- function(var) {
    factor(var, levels = c("1", "0"))
  }
  
  valdata %<>% 
    mutate(
      elig_cervical = 
        ifelse(sex == "F" & age_start >= 19 & age_start <= 64, 1, 0), 
      elig_breast = 
        ifelse(sex == "F" & age_start >= 40, 1, 0), 
      elig_colon = 
        ifelse(age_start >= 50, 1, 0), 
      elig_colonoscopy = 
        ifelse(age_start >= 50, 1, 0), 
      elig_flexsig = 
        ifelse(age_start >= 50, 1, 0), 
      elig_fobt = 
        ifelse(age_start >= 50, 1, 0),  
      elig_bmi = 1, 
      elig_flu = 
        ifelse(age_start >= 50, 1, 0), 
      elig_chlam = 
        ifelse(sex == "F" & age_start >= 19 & age_start <= 24, 1, 0), 
      elig_smoking = 1, 
      elig_cholest = 
        ifelse(age_start >= 20, 1, 0)) %>% 
    mutate_at(.vars = vars(elig_cervical:elig_cholest), 
              .funs = funs(make_factor2))
  
  
  #### Make factor screening variables --------------------------------
  # A patient must be elgible to recieve a screening service. Those that are
  # eligible based on the step above will be randomly assigned 1/0 (screened/not
  # screened); those that are not elgible will be assigned 0 (not screened).
  
  ## Function to help make the screening data ----------------
  # Split the data set into eligible and not eligible. Randomly assign
  # screen/not-screened to those that are eligible. Not screened to those that 
  # are not elgibile. Combine the split data sets.
  
  # Returns a data frame / tibble.
  
  make_screening <- function(df, 
                             elig_var, 
                             dmp_scr, 
                             ehr_scr, 
                             dmp_prob, 
                             ehr_prob) { 
    
    elig_enq <- enquo(elig_var)
    dmp_enq <- enquo(dmp_scr)
    dmp_name <- quo_name(dmp_enq)
    ehr_enq <- enquo(ehr_scr)
    ehr_name <- quo_name(ehr_enq)
    
    num_elig <- df %>% 
      dplyr::filter(!! elig_enq == 1) %>% 
      dplyr::count(!! elig_enq) %>% 
      dplyr::pull()
    
    num_not_elig <- df %>% 
      dplyr::filter(!! elig_enq != 1) %>% 
      dplyr::count(!! elig_enq) %>% 
      dplyr::pull()
    
    df_elig <- df %>% 
      dplyr::filter(!! elig_enq == 1) %>% 
      mutate(
        !! dmp_name := rbinom(n = num_elig, size = 1, prob = dmp_prob), 
        !! ehr_name := rbinom(n = num_elig, size = 1, prob = ehr_prob), 
        !! dmp_name := factor(!! dmp_enq, levels = c(1, 0)), 
        !! ehr_name := factor(!! ehr_enq, levels = c(1, 0))
      )
    
    df_not_elig <- df %>% 
      dplyr::filter(!! elig_enq != 1) %>% 
      mutate(
        !! dmp_name := 0, 
        !! ehr_name := 0, 
        !! dmp_name := factor(!! dmp_enq, levels = c(1, 0)), 
        !! ehr_name := factor(!! ehr_enq, levels = c(1, 0))
      )
    
    df_elig %>% 
      dplyr::bind_rows(., df_not_elig) %>% 
      dplyr::arrange(., study_id)
    
  }
  
  ## Make the screenings values ----------------
  
  valdata <- make_screening(df = valdata, 
                            elig_var = elig_cervical, 
                            dmp_scr = dmap_cervical, 
                            ehr_scr = ehr_cervical, 
                            dmp_prob = 0.30, 
                            ehr_prob = 0.30)
  
  valdata <- make_screening(df = valdata, 
                            elig_var = elig_breast, 
                            dmp_scr = dmap_breast, 
                            ehr_scr = ehr_breast, 
                            dmp_prob = 0.40, 
                            ehr_prob = 0.40)
  
  valdata <- make_screening(df = valdata, 
                            elig_var = elig_colon, 
                            dmp_scr = dmap_colon, 
                            ehr_scr = ehr_colon, 
                            dmp_prob = 0.30, 
                            ehr_prob = 0.30)
  
  valdata <- make_screening(df = valdata, 
                            elig_var = elig_colonoscopy, 
                            dmp_scr = dmap_colonoscopy, 
                            ehr_scr = ehr_colonoscopy, 
                            dmp_prob = 0.10, 
                            ehr_prob = 0.10)
  
  valdata <- make_screening(df = valdata, 
                            elig_var = elig_flexsig, 
                            dmp_scr = dmap_flexsig, 
                            ehr_scr = ehr_flexsig, 
                            dmp_prob = 0.05, 
                            ehr_prob = 0.05)
  
  valdata <- make_screening(df = valdata, 
                            elig_var = elig_fobt, 
                            dmp_scr = dmap_fobt, 
                            ehr_scr = ehr_fobt, 
                            dmp_prob = 0.15, 
                            ehr_prob = 0.30)
  
  valdata <- make_screening(df = valdata, 
                            elig_var = elig_bmi, 
                            dmp_scr = dmap_bmi, 
                            ehr_scr = ehr_bmi, 
                            dmp_prob = 0.05, 
                            ehr_prob = 0.85)
  
  valdata <- make_screening(df = valdata, 
                            elig_var = elig_flu, 
                            dmp_scr = dmap_flu, 
                            ehr_scr = ehr_flu, 
                            dmp_prob = 0.35, 
                            ehr_prob = 0.40)
  
  valdata <- make_screening(df = valdata, 
                            elig_var = elig_chlam, 
                            dmp_scr = dmap_chlam, 
                            ehr_scr = ehr_chlam, 
                            dmp_prob = 0.50, 
                            ehr_prob = 0.40)
  
  valdata <- make_screening(df = valdata, 
                            elig_var = elig_smoking, 
                            dmp_scr = dmap_smoking, 
                            ehr_scr = ehr_smoking, 
                            dmp_prob = 0.05, 
                            ehr_prob = 0.95)
  
  valdata <- make_screening(df = valdata, 
                            elig_var = elig_cholest, 
                            dmp_scr = dmap_cholest, 
                            ehr_scr = ehr_cholest, 
                            dmp_prob = 0.40, 
                            ehr_prob = 0.40)
  
  
  #### Return the data set --------------------------------
  
  valdata
  
}




