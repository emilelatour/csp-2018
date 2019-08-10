
#### Gather an imputed data set --------------------------------

# I need to take each imputed data set and gather it (i.e. convert it to long
# formar). This step is need so that I can group_by() and nest() later on. Note
# that this gets a little complicated and I have to do it many times, so making
# a function and storing in a script keeps the main code cleaner.

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


#### make_df_long() --------------------------------

make_df_long <- function(df) { 
  
  # Reshape ELIG, DMAP, and EHR
  df_long <- df %>% 
    tidyr::gather(data = ., 
                  key = "vars", 
                  value = "value", 
                  elig_cervical:ehr_cholest) %>% 
    tidyr::separate(col = vars, 
                    into = c("ehr_dmap_elig", "proc"), 
                    sep = "_", 
                    remove = TRUE) %>% 
    tidyr::spread(data = ., 
                  key = ehr_dmap_elig, 
                  value = value)
  
  # Gather the categories
  df_long <- df_long %>% 
    tidyr::gather(data = ., 
                  key = "cat", 
                  value = "level", 
                  sex, ethnic_cat:age_cat) %>% 
    mutate(cat = case_when(
      cat == "age_cat" ~ "age", 
      cat == "ethnic_cat" ~ "ethnicity", 
      cat == "fpl_cat" ~ "fpl", 
      cat == "lang_cat" ~ "language", 
      cat == "race_cat" ~ "race", 
      TRUE ~ cat
    ))
  
  
  # Pick one category and dummy the category and the levels
  # And bind the all back to the long data
  df_long <- df_long %>% 
    dplyr::filter(cat == "sex") %>% 
    mutate(cat = "all", 
           level = "all") %>% 
    dplyr::bind_rows(., df_long)
  
  df_long %>%
    dplyr::select(n_imp, 
                  study_id,
                  age_start,
                  primary_dept,
                  proc, 
                  cat,
                  level, 
                  elig, 
                  ehr, 
                  dmap
    )
}