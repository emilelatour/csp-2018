Example of work to impute, analyze, and pool agreement statistics
================
Emile Latour
2018-02-15

Simulate a data set
===================

Due to the sensitive nature of electronic health record (EHR) data, in order to provide a data set for a reproducible example, I wrote code below to simulate a data set that can be used with the rest of the code in this example. The only similarities to the original data are the variable names and the data categories.

Note that the eligibility requirements for screening services are based on sex, age, and medical history. I do not simulate medical history and so the eligibility here is based only on sex and age.

The proportions of screenings in the data were chosen to try to simulate some data that would make for interesting example with the rest of the code. The proportions of missingness are similar to the actual work that I presented in that I did a little bit of rounding before simulation.

Disclaimer: All the data in this example is simulated from the following code. Any similarities to the original data set or any other existing data is purely by chance alone.

Simulate the data
-----------------

``` r
source(here::here("src", "simulate-data-set.R"))

valdata <- make_sim_data(n_rows = 14000, seed = seed_for_imp)
```

Do some checks and take a glimpse
---------------------------------

``` r
dplyr::glimpse(valdata)
```

    Observations: 14,000
    Variables: 42
    $ study_id         <int> 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14...
    $ sex              <fct> F, F, M, M, F, M, M, M, M, F, M, F, F, F, M, ...
    $ age_start        <int> 56, 36, 38, 64, 64, 49, 52, 32, 21, 41, 46, 5...
    $ primary_dept     <fct> 026, 031, 035, 035, 027, 017, 022, 022, 029, ...
    $ ethnic_cat       <fct> NH White, NH White, Hispanic, NH Other, NH Wh...
    $ lang_cat         <fct> English, English, English, English, English, ...
    $ race_cat         <fct> Black, White, White, White, White, White, Whi...
    $ fpl_cat          <fct> <=138% FPL, <=138% FPL, NA, <=138% FPL, <=138...
    $ age_cat          <fct> [51,65), [35,51), [35,51), [51,65), [51,65), ...
    $ elig_cervical    <fct> 1, 1, 0, 0, 1, 0, 0, 0, 0, 1, 0, 1, 1, 1, 0, ...
    $ elig_breast      <fct> 1, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 1, 1, 1, 0, ...
    $ elig_colon       <fct> 1, 0, 0, 1, 1, 0, 1, 0, 0, 0, 0, 1, 1, 1, 0, ...
    $ elig_colonoscopy <fct> 1, 0, 0, 1, 1, 0, 1, 0, 0, 0, 0, 1, 1, 1, 0, ...
    $ elig_flexsig     <fct> 1, 0, 0, 1, 1, 0, 1, 0, 0, 0, 0, 1, 1, 1, 0, ...
    $ elig_fobt        <fct> 1, 0, 0, 1, 1, 0, 1, 0, 0, 0, 0, 1, 1, 1, 0, ...
    $ elig_bmi         <fct> 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, ...
    $ elig_flu         <fct> 1, 0, 0, 1, 1, 0, 1, 0, 0, 0, 0, 1, 1, 1, 0, ...
    $ elig_chlam       <fct> 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, ...
    $ elig_smoking     <fct> 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, ...
    $ elig_cholest     <fct> 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, ...
    $ dmap_cervical    <fct> 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, ...
    $ dmap_breast      <fct> 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, ...
    $ dmap_colon       <fct> 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, ...
    $ dmap_colonoscopy <fct> 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, ...
    $ dmap_flexsig     <fct> 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, ...
    $ dmap_fobt        <fct> 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, ...
    $ dmap_bmi         <fct> 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, ...
    $ dmap_flu         <fct> 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, ...
    $ dmap_chlam       <fct> 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, ...
    $ dmap_smoking     <fct> 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, ...
    $ dmap_cholest     <fct> 1, 0, 1, 0, 0, 1, 0, 1, 0, 1, 1, 1, 0, 0, 1, ...
    $ ehr_cervical     <fct> 0, 1, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, ...
    $ ehr_breast       <fct> 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, ...
    $ ehr_colon        <fct> 1, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, ...
    $ ehr_colonoscopy  <fct> 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, ...
    $ ehr_flexsig      <fct> 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, ...
    $ ehr_fobt         <fct> 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, ...
    $ ehr_bmi          <fct> 1, 1, 0, 1, 1, 1, 1, 0, 1, 0, 1, 1, 1, 1, 1, ...
    $ ehr_flu          <fct> 1, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, ...
    $ ehr_chlam        <fct> 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, ...
    $ ehr_smoking      <fct> 1, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, ...
    $ ehr_cholest      <fct> 0, 0, 1, 1, 0, 0, 0, 1, 0, 0, 0, 1, 1, 1, 0, ...

EDA / explore missingness
=========================

Table One
---------

A quick table one to look at the demographics of the sample data.

``` r
#### Create a table one --------------------------------
# Table one summary stats using the tableone package

tab1 <- tableone::CreateTableOne(
  vars = c("sex", "race_cat", "ethnic_cat", "lang_cat", "fpl_cat", "age_cat"), 
  data = valdata, 
  factorVars = 
    c("sex", "race_cat", "ethnic_cat", "lang_cat", "fpl_cat", "age_cat"), 
  includeNA = TRUE
)

#### print_table_one --------------------------------
# A helper function to print the table one object to my preference.

print_table_one <- . %>% 
  print(., 
        showAllLevels = TRUE, 
        printToggle = FALSE, 
        noSpaces = TRUE
        ) %>% 
  as.data.frame(.) %>% 
  tibble::rownames_to_column(., var = "rowname") %>% 
  knitr::kable(booktabs = TRUE, 
               longtable = TRUE, 
               col.names = c("", names(.)[-1])) %>% 
  kableExtra::kable_styling(full_width = FALSE, 
                            latex_options = c("repeat_header")) %>% 
  kableExtra::column_spec(1, width = "10em")

#### Print table one --------------------------------

tab1 %>% 
  print_table_one
```

|                 | level          | Overall      |
|-----------------|:---------------|:-------------|
| n               |                | 14000        |
| sex (%)         | F              | 9144 (65.3)  |
|                 | M              | 4856 (34.7)  |
| race\_cat (%)   | AIAN           | 256 (1.8)    |
|                 | API            | 680 (4.9)    |
|                 | Black          | 1363 (9.7)   |
|                 | Multiple Races | 141 (1.0)    |
|                 | White          | 10542 (75.3) |
|                 | NA             | 1018 (7.3)   |
| ethnic\_cat (%) | Hispanic       | 1355 (9.7)   |
|                 | NH Other       | 2097 (15.0)  |
|                 | NH White       | 9855 (70.4)  |
|                 | NA             | 693 (5.0)    |
| lang\_cat (%)   | English        | 11897 (85.0) |
|                 | Other          | 1391 (9.9)   |
|                 | Spanish        | 712 (5.1)    |
| fpl\_cat (%)    | &lt;=138% FPL  | 10548 (75.3) |
|                 | &gt;138% FPL   | 700 (5.0)    |
|                 | NA             | 2752 (19.7)  |
| age\_cat (%)    | \[19,35)       | 4666 (33.3)  |
|                 | \[35,51)       | 4666 (33.3)  |
|                 | \[51,65)       | 4668 (33.3)  |

Visualizing missingness in the data set
---------------------------------------

The table one above shows that there are missing data in the variables `race_cat`, `ethnic_cat`, and `fpl_cat`. When beginning to think about how to handle the missing data in your project, visualization is a great place to begin. The [`naniar`](https://cran.r-project.org/web/packages/naniar/index.html) and the [`visdat`](https://cran.r-project.org/web/packages/visdat/index.html) packages provide helpful plots.

### The `vis_miss()` plot

In the figure below, we get an overview of the missing values in the data set. Missing are shown in black and observed values are shown in gray. We see that there are only 3 variables in the data set with missing values.

``` r
naniar::vis_miss(valdata)
```

![](mice-work_2018-02-05_files/figure-markdown_github/unnamed-chunk-3-1.png)

We can also get a numeric percent missing for the variables.

``` r
miss_var_summary(valdata) %>% 
  head(., n = 10)
```

    # A tibble: 10 x 4
       variable      n_miss pct_miss n_miss_cumsum
       <chr>          <int>    <dbl>         <int>
     1 study_id           0     0                0
     2 sex                0     0                0
     3 age_start          0     0                0
     4 primary_dept       0     0                0
     5 ethnic_cat       693     4.95           693
     6 lang_cat           0     0              693
     7 race_cat        1018     7.27          1711
     8 fpl_cat         2752    19.7           4463
     9 age_cat            0     0             4463
    10 elig_cervical      0     0             4463

### Setting `cluster = TRUE`

It can also be useful to look at the missingness plot with the values clustered. This gives a sense of how many values are missing in one row. Many rows with multiple missing values can be problematic when trying to do imputation.

I'm only going to show this plot for a few variables since we saw above that many were completely observed.

``` r
valdata %>% 
  dplyr::select(race_cat, ethnic_cat, fpl_cat, lang_cat, sex, age_cat) %>% 
  naniar::vis_miss(., 
                   cluster = TRUE)
```

![](mice-work_2018-02-05_files/figure-markdown_github/unnamed-chunk-5-1.png)

### The `VIM` package

The [`VIM`](https://cran.r-project.org/web/packages/VIM/VIM.pdf) package also has many helpful tools for visualizing missing values. I really like their combination bar plot and aggregation plot.

Here I have filtered the data to just those with missing values; I think that this helps the plot to be more clear. The bar plot on the left shows the proportion of missing values in each variable. The aggregation plot on the right shows the combinations of missing (dark gray) and observed (light gray) values that exist in the data.

``` r
valdata %>% 
  dplyr::select(race_cat, ethnic_cat, fpl_cat) %>% 
  VIM::aggr(., 
            col = c("gray", "gray29"), 
            numbers = TRUE, 
            sortVars = TRUE, 
            labels = names(.), 
            cex.axis = .7, 
            gap = 3, 
            ylab = c("Histogram of missing data","Pattern"))
```

![](mice-work_2018-02-05_files/figure-markdown_github/unnamed-chunk-6-1.png)


     Variables sorted by number of missings: 
       Variable      Count
        fpl_cat 0.19657143
       race_cat 0.07271429
     ethnic_cat 0.04950000

Numerical summaries
-------------------

``` r
mssng_pattern <- valdata %>% 
  dplyr::select(race_cat, ethnic_cat, fpl_cat) %>% 
  mice::md.pattern(.) %>% 
  as.data.frame() %>% 
  tibble::as_tibble(.) %>% 
  tibble::rownames_to_column(., var = "count") %>% 
  dplyr::rename(., 
                # new = old
                num_available = V4)

mssng_pattern %>% 
  kable(.)
```

| count |  ethnic\_cat|  race\_cat|  fpl\_cat|  num\_available|
|:------|------------:|----------:|---------:|---------------:|
| 9905  |            1|          1|         1|               0|
| 781   |            1|          0|         1|               1|
| 524   |            0|          1|         1|               1|
| 2432  |            1|          1|         0|               1|
| 38    |            0|          0|         1|               2|
| 189   |            1|          0|         0|               2|
| 121   |            0|          1|         0|               2|
| 10    |            0|          0|         0|               3|
|       |          693|       1018|      2752|            4463|

See Stef Van Buuren's vignette for more in depth interpretation of the table above. There's a lot of good info there. How I interpret it is to pay attention to the 1's and 0's in the main body of the table. They correspond to what is observed (1) and missing (0) for the variables listed in the top row.

So the first row of all 1's means that all listed variables are observed; the count to the left shows the number of rows in the data set that fit this description. The last row of all 0's means that all variables are missing; similar that the count on the left shows the number of rows in the data set that are missing for all the variables shown. Then all the 1's and 0's in between represent some combination of missingness among the variables.

The `naniar` package has summary that is a little simpler and gives some of the same information. But not as much detail as the `md.pattern()` in the `mice` package.

``` r
valdata %>% 
  naniar::miss_case_table(.) %>% 
  kable(.)
```

|  n\_miss\_in\_case|  n\_cases|   pct\_miss|
|------------------:|---------:|-----------:|
|                  0|      9905|  70.7500000|
|                  1|      3737|  26.6928571|
|                  2|       348|   2.4857143|
|                  3|        10|   0.0714286|

### Number of observations per pattern of missing pairs

``` r
mssng_pairs <- valdata %>% 
  dplyr::select(ethnic_cat, race_cat, fpl_cat) %>% 
  mice::md.pairs(.)

mssng_pairs
```

    $rr
               ethnic_cat race_cat fpl_cat
    ethnic_cat      13307    12337   10686
    race_cat        12337    12982   10429
    fpl_cat         10686    10429   11248

    $rm
               ethnic_cat race_cat fpl_cat
    ethnic_cat          0      970    2621
    race_cat          645        0    2553
    fpl_cat           562      819       0

    $mr
               ethnic_cat race_cat fpl_cat
    ethnic_cat          0      645     562
    race_cat          970        0     819
    fpl_cat          2621     2553       0

    $mm
               ethnic_cat race_cat fpl_cat
    ethnic_cat        693       48     131
    race_cat           48     1018     199
    fpl_cat           131      199    2752

Four missingness patterns:

-   `rr` both are observed,
-   `rm` first variable is observed, the second is missing,
-   `mr` first variable is missing, the second is observed, and
-   `mm` both variable are missing.

### Proportion of usable cases

Measures how many cases with missing data on the target variable actually have observed values on the predictor. The proportion will be low if both target and predictor are missing on the same cases.

``` r
prop_usable_cases <- valdata %>% 
  dplyr::select(ethnic_cat, race_cat, fpl_cat) %>% 
  mice::md.pairs(.)

with(prop_usable_cases, 
     round(mr / (mr + mm), digits = 3))
```

               ethnic_cat race_cat fpl_cat
    ethnic_cat      0.000    0.931   0.811
    race_cat        0.953    0.000   0.805
    fpl_cat         0.952    0.928   0.000

Target on the vertical axis (i.e. left), predictor on the horizontal (i.e. top).

Interpret: Of the records with values for `ethnic_cat`, xx% have observed information on `race_cat` and xx% have observed information on `fplp_cat`. Etc.

This gives a sense of what variables may be good to include/exclude in the imputation model. Higher % indicates more information and likely good predictor; lower % indicates that the variables are missing for the same observations and may not be good predictor.

### Number of incomplete cases

More recent advice on how many imputations to perform suggests a rule of thumb that the number of imputations should be similar to the percentage of cases that are incomplete. So, not just as a part of the EDA, it is important to know the number of incomplete cases to inform the specification of the imputation model later.

An incomplete case would be an observation (or row) with at least one missing value. There are a number of ways to get at this information, but the `naniar` package makes it super easy.

``` r
n_missing <- naniar::miss_case_prop(valdata)
n_missing
```

    [1] 0.2925

So we know that in the data set 29.2% of observations have missing values. I round this up to 30 to select the number of imputations to perform.

Imputation
==========

Below I show some of the set up that I went through to perform the multiple imputations using the `mice` package in R. Some resources were absolutely indispensable in my set up and learning:

-   the [`mice` package documentation](https://cran.r-project.org/web/packages/mice/mice.pdf)
-   the [vignette](https://www.jstatsoft.org/article/view/v045i03/v45i03.pdf) from the Journal of Statistical Software (December 2011, Volume 45, Issue 3)
-   [Flexible Imputation of Missing Data](https://www.crcpress.com/Flexible-Imputation-of-Missing-Data/van-Buuren/p/book/9781439868249) by Stef van Buuren

Also, since my work was done, [online resources](https://cran.r-project.org/web/packages/mice/vignettes/resources.html) have been added.

For more information about MICE: Multivariate Imputation by Chained Equations, sometimes called Fully Conditional Specification, I highly recommend any of the materials (code or books) or published papers by Stef van Buuren. Much can be found through his website, [www.multiple-imputation.com](http://www.stefvanbuuren.nl/mi/).

Some set up
-----------

Here I am just going to define the number of imputations and the number of iterations to objects for use in later code. This is just a convenience step so that I only have to update these values in one place if I want to change them later.

The default number of imputations in the `mice` software is 5. Based on the exploration of the missingness above, we saw that they number of imputations suggested is much higher. Here in this example, I am going to keep it set at the default 5, just to limit the computation time if someone want to run this code on their own.

In practice, my suggestion would be to "tune" the imputation using a lower number like the default setting. Then once the imputation model is set, perform you final or near final imputations using the higher number as suggested by recent literature.

As far as iterations go, they tend to converge rather quickly with the `mice` algorithm. My advice is to run them out long enough to see whether there is convergence or not, while not getting super bogged down with computation time.

Here I am going to continue to use the software default of 5 for our example. In my actual work, I used 20. In your practice I would suggest to try to use 10 to 20.

``` r
imp_num <- 5  # number of imputations, dflt = 5
iter_num <- 5  # number of iterations, dflt = 5
```

We can also tel the `mice` software to run an "initial" empty imputation. The only effect of this is to give us some objects in R to work with as we go through the steps. See below where I run the initial imputation. Note that the maximum number of iterations (`maxit`) is set to zero.

``` r
init <- mice::mice(valdata, maxit = 0)
meth <- init$method
predM <- init$predictorMatrix
# print(ini)
```

The `init` object contains lots of information that we will work with as we go forward. Of interest for now though is the method selected for the variables. This is the form of the imputation model for the variables to be imputed.

``` r
meth
```

            study_id              sex        age_start     primary_dept 
                  ""               ""               ""               "" 
          ethnic_cat         lang_cat         race_cat          fpl_cat 
           "polyreg"               ""        "polyreg"         "logreg" 
             age_cat    elig_cervical      elig_breast       elig_colon 
                  ""               ""               ""               "" 
    elig_colonoscopy     elig_flexsig        elig_fobt         elig_bmi 
                  ""               ""               ""               "" 
            elig_flu       elig_chlam     elig_smoking     elig_cholest 
                  ""               ""               ""               "" 
       dmap_cervical      dmap_breast       dmap_colon dmap_colonoscopy 
                  ""               ""               ""               "" 
        dmap_flexsig        dmap_fobt         dmap_bmi         dmap_flu 
                  ""               ""               ""               "" 
          dmap_chlam     dmap_smoking     dmap_cholest     ehr_cervical 
                  ""               ""               ""               "" 
          ehr_breast        ehr_colon  ehr_colonoscopy      ehr_flexsig 
                  ""               ""               ""               "" 
            ehr_fobt          ehr_bmi          ehr_flu        ehr_chlam 
                  ""               ""               ""               "" 
         ehr_smoking      ehr_cholest 
                  ""               "" 

We see that the software made no choice for the variables without missing data. For those with missing data, based on the type of variable, it makes some default choices. We can override these later.

We also get the default matrix of predictors that the software chose. This is an object of 1's and 0's. For those variables with no missing and that we won't be imputing, the values are zero. Here is a glimpse of just those that we intend to impute.

``` r
predM[rowSums(predM) > 0, ]
```

               study_id sex age_start primary_dept ethnic_cat lang_cat
    ethnic_cat        1   1         1            1          0        1
    race_cat          1   1         1            1          1        1
    fpl_cat           1   1         1            1          1        1
               race_cat fpl_cat age_cat elig_cervical elig_breast elig_colon
    ethnic_cat        1       1       1             0           1          1
    race_cat          0       1       1             0           1          1
    fpl_cat           1       0       1             0           1          1
               elig_colonoscopy elig_flexsig elig_fobt elig_bmi elig_flu
    ethnic_cat                0            0         0        0        0
    race_cat                  0            0         0        0        0
    fpl_cat                   0            0         0        0        0
               elig_chlam elig_smoking elig_cholest dmap_cervical dmap_breast
    ethnic_cat          1            0            1             1           1
    race_cat            1            0            1             1           1
    fpl_cat             1            0            1             1           1
               dmap_colon dmap_colonoscopy dmap_flexsig dmap_fobt dmap_bmi
    ethnic_cat          1                1            1         1        1
    race_cat            1                1            1         1        1
    fpl_cat             1                1            1         1        1
               dmap_flu dmap_chlam dmap_smoking dmap_cholest ehr_cervical
    ethnic_cat        1          1            1            1            1
    race_cat          1          1            1            1            1
    fpl_cat           1          1            1            1            1
               ehr_breast ehr_colon ehr_colonoscopy ehr_flexsig ehr_fobt
    ethnic_cat          1         1               1           1        1
    race_cat            1         1               1           1        1
    fpl_cat             1         1               1           1        1
               ehr_bmi ehr_flu ehr_chlam ehr_smoking ehr_cholest
    ethnic_cat       1       1         1           1           1
    race_cat         1       1         1           1           1
    fpl_cat          1       1         1           1           1

Specify the imputation model
----------------------------

Here I will follow the 7 steps that van Buuren suggests in order to set up the algorithm. See his writings for more details than I will go into here.

### Step 1 - Decide if the missing at random (MAR) assumption is reasonable

In this example, we randomly assigned missing values. So here, it kind of has to be reasonable. In practice though, this can be challenging to know for sure which is why the exploration of the data and the missingness is such an important step to take as I showed above.

Assuming MAR is typically a reasonable place to start. There is literature on sensitivity analysis with the imputations to examine if this assumption is met. And there are techniques to model the missing mechanism with the imputation if there is violation. This work is outside the scope of what I hope to share here.

### Step 2 - Decide on the form of the imputation model

We want to decide the form of the model used to impute the missing values of each variable. This can be specified on a variable by variable basis. We saw above from the `meth` object that the software made default decisions for us.

**FPL** -- logistic regression (`logreg`), for factor with 2 levels.

**Race** -- Multinomial logit regression (`polyreg`), factor with &gt; 2 levels.

**Ethnicity** -- Multinomial logit regression (`polyreg`), factor with &gt; 2 levels.

I am going to overwrite those just to show how it is done. By overwriting the meth object we can force the algorithm to use this later.

``` r
meth[c("ethnic_cat")] <- "polyreg"
meth[c("race_cat")] <- "polyreg"
meth[c("fpl_cat")] <- "logreg"
meth
```

            study_id              sex        age_start     primary_dept 
                  ""               ""               ""               "" 
          ethnic_cat         lang_cat         race_cat          fpl_cat 
           "polyreg"               ""        "polyreg"         "logreg" 
             age_cat    elig_cervical      elig_breast       elig_colon 
                  ""               ""               ""               "" 
    elig_colonoscopy     elig_flexsig        elig_fobt         elig_bmi 
                  ""               ""               ""               "" 
            elig_flu       elig_chlam     elig_smoking     elig_cholest 
                  ""               ""               ""               "" 
       dmap_cervical      dmap_breast       dmap_colon dmap_colonoscopy 
                  ""               ""               ""               "" 
        dmap_flexsig        dmap_fobt         dmap_bmi         dmap_flu 
                  ""               ""               ""               "" 
          dmap_chlam     dmap_smoking     dmap_cholest     ehr_cervical 
                  ""               ""               ""               "" 
          ehr_breast        ehr_colon  ehr_colonoscopy      ehr_flexsig 
                  ""               ""               ""               "" 
            ehr_fobt          ehr_bmi          ehr_flu        ehr_chlam 
                  ""               ""               ""               "" 
         ehr_smoking      ehr_cholest 
                  ""               "" 

### Step 3 - Decide the set of predictors to include in the imputation model

What variables to include in the multiple imputation model?

The advice is to include as many relevant variables as possible. One should include all variables that are in your scientific model of interest that will be used after imputation. Also variables that are related to the missingness of the variables you are imputing. Van Buuren has more advice here.

Including as many predictors as possible makes the MAR assumption more reasonable. But with larger data sets, this is not advisable for computation purposes. Van Buuren suggests that 15 to 25 variables will work well. He also offers advice to cull that list.

My case is interesting. I am not doing modelling; I am calculating scalar statistics of agreement. Also, my data set isn't really too large (41 variables once you ignore study ID which isn't too important for imputation purposes).

To aid in these decisions the `mice` package has a function that produces a "quick predictor matrix" that is useful for dealing with data sets with large number of variables. The software chooses by calculating two correlations with the available cases, taking the larger, and seeing if it meets a minimum threshold. Type `?quickpred` in the R console for better description.

Below I run the `quickpred()` to see what the software chooses. Only show the matrix below for those records with &gt; 1 rows or columns

``` r
predGuess <- valdata %>% 
  mice::quickpred(.)

predGuess[rowSums(predGuess) > 0, colSums(predGuess) > 0]
```

    <0 x 0 matrix>

Hmm. As I am working through this example with the simulated data, the software did not choose any. In my actual work, it discovered about 2 to 3 important predictors for each variable.

Since we randomly generated each variable *independently*, there should not be a high correlation between them. So as surprised as I was at first, this really does makes sense.

In my actual work, I went to the lead investigator for insight into the data set and suggestions on which variables would be informative. The code chunk below shows how I took the list that they provided and modified the `predM` object.

``` r
# Store the names of the variables in an object
var_names <- dput(names(valdata))
```

    c("study_id", "sex", "age_start", "primary_dept", "ethnic_cat", 
    "lang_cat", "race_cat", "fpl_cat", "age_cat", "elig_cervical", 
    "elig_breast", "elig_colon", "elig_colonoscopy", "elig_flexsig", 
    "elig_fobt", "elig_bmi", "elig_flu", "elig_chlam", "elig_smoking", 
    "elig_cholest", "dmap_cervical", "dmap_breast", "dmap_colon", 
    "dmap_colonoscopy", "dmap_flexsig", "dmap_fobt", "dmap_bmi", 
    "dmap_flu", "dmap_chlam", "dmap_smoking", "dmap_cholest", "ehr_cervical", 
    "ehr_breast", "ehr_colon", "ehr_colonoscopy", "ehr_flexsig", 
    "ehr_fobt", "ehr_bmi", "ehr_flu", "ehr_chlam", "ehr_smoking", 
    "ehr_cholest")

``` r
# create another vector of the names selected by the investigator
pi_list <-
  c("fpl_cat", "race_cat", "ethnic_cat", "lang_cat", "age_start", "sex", 
    "primary_dept", "ehr_cervical", "ehr_breast", "ehr_colon", 
    "ehr_colonoscopy", "dmap_breast", "dmap_colonoscopy", "ehr_cholest", 
    "dmap_cholest", "elig_cholest", "ehr_flexsig", "ehr_fobt", "ehr_bmi", 
    "ehr_flu", "ehr_chlam", "ehr_smoking", "dmap_cervical", "dmap_colon", 
    "dmap_flexsig", "dmap_fobt", "dmap_bmi", "dmap_flu", "dmap_chlam", 
    "elig_cervical", "elig_breast", "elig_colon", "elig_bmi", "elig_flu", 
    "elig_chlam", "elig_smoking")
```

Note that the investigator had me exclude the variables, `elig_colonoscopy`, `elig_flexsig`, and `elig_fobt`, because these have the exact same information as `elig_colon`. The eligibility for all these screenings is the same.

We also did not include `dmap_smoking` because there was little to no information here.

Also, we included `age_start` as a continuous variable and did not include the categorical version of this variable, `age_cat`, hoping to get more information.

``` r
# Make a vector of the variable names that we want to include.
vars_to_include <- var_names[(var_names %in% pi_list)]

# adjust the default prediction matrix for the variables we want to include
pred <- predM    # Set equal to the orginal pred matrix
pred[, ] <- 0    # change to all zeroes to clean it out
pred[, vars_to_include] <- 1     # Set to 1 for variables that we want
diag(pred) <- 0    # set the diagonal to zero (can't predict itself)

# take a glimpse
head(pred[, 1:10], n = 10)
```

                  study_id sex age_start primary_dept ethnic_cat lang_cat
    study_id             0   1         1            1          1        1
    sex                  0   0         1            1          1        1
    age_start            0   1         0            1          1        1
    primary_dept         0   1         1            0          1        1
    ethnic_cat           0   1         1            1          0        1
    lang_cat             0   1         1            1          1        0
    race_cat             0   1         1            1          1        1
    fpl_cat              0   1         1            1          1        1
    age_cat              0   1         1            1          1        1
    elig_cervical        0   1         1            1          1        1
                  race_cat fpl_cat age_cat elig_cervical
    study_id             1       1       0             1
    sex                  1       1       0             1
    age_start            1       1       0             1
    primary_dept         1       1       0             1
    ethnic_cat           1       1       0             1
    lang_cat             1       1       0             1
    race_cat             0       1       0             1
    fpl_cat              1       0       0             1
    age_cat              1       1       0             1
    elig_cervical        1       1       0             0

Note that there are 1s in the matrix for variables that we will not be imputing. This will have no impact.

In the actual work, I made 3 scenarios:

1.  Full list of variables chosen by the investigator
2.  Reduced list of about half the number
3.  Very reduced list based on the defaults from the software (2-3)

Here in this example to keep it simple, I will just work with the full list. But the other scenarios could be created by adjusting the predictor matrix similar to above.

### Step 4 - Decide how to impute variables that are functions of other (incomplete) variables

Transformations, sum scores, etc. were not used in this data set so not much to consider here. In some cases, there can be a lot to think about particularly if a variable is transformed solely to meet the normality assumption in a regression model. So do a literature review if this issue applies to you.

In my example, I mentioned above that I am including continous `age_start` instead of the categorical age. `fpl_cat` is a variable that is derived from a continuous value that had missingness. We considered to included the continuous value, but decided that it is more relevant to our question to look at binary `fpl_cat`.

### Step 5 - Decide the order to impute the variables

The defualt in the software goes by appearance in the data set left to right. It can be overwritten per the user's direction. This becomes more of an issue if there is a longitudinal nature to the data set where missingness at an earlier time point would affect the missingness later. So impute early to later.

I examined the imputation order by magnitude of missingness: low to high and high to low. There did not seem to be a difference in performance or convergence, nor an impact to the estimates. In the actual work, we decided to impute from highest percent missing to lowest.

The code `init$visitSequence` gives the variables to be imputed and their column positions that were chosen by the software by default. Shown in the next chunk.

``` r
init$visitSequence
```

    ethnic_cat   race_cat    fpl_cat 
             5          7          8 

I override this with the following to order things as: FPL -&gt; Race -&gt; Ethnicity

``` r
visit_order <- c(init$visitSequence[["fpl_cat"]], 
                 init$visitSequence[["race_cat"]], 
                 init$visitSequence[["ethnic_cat"]])
visit_order
```

    [1] 8 7 5

### Step 6 - Decide the number of iterations

This is to ensure convergence. The default is 5. 10 to 20 are recommended. In actual practice, we chose 20. Here I will keep it set at 5 as defined above to keep the computation strain low.

``` r
iter_num
```

    [1] 5

### Step 7 - Decide on the number of multiply imputed data sets

The rule of thumb from more recent authors is that the number of imputations should be similar to the percentage of cases (observations) that are incomplete (at least 5).

The software default is 5 and we will use that for this example to keep computation time low. We had set this previously above.

``` r
imp_num
```

    [1] 5

Run the algorithm
-----------------

All the setup work has been done and considerations made. Using the specifications that saved in objects above, we will run the `mice` command to impute the data sets.

Note that I wrap this in the command `system.time()` to see how long it runs.

``` r
system.time(
imp_full <- 
  mice::mice(data = valdata, 
             m = imp_num,  # number of imputations, dflt = 5
             method = meth,  # specify the method
             predictorMatrix = pred, 
             visitSequence = visit_order, 
             seed = seed_for_imp, 
             maxit = iter_num,  # number of iterations, dflt = 5
             print = FALSE
             )
)
```

       user  system elapsed 
     312.94    0.91  317.00 

That's elapsed time in seconds.

### Plot of convergence

We plot the values of mean and standard deviation for each variable by number of iteration. We want to look for mixing of the lines and we do not want to see any trend.

``` r
plot(imp_full, c("ethnic_cat", "race_cat", "fpl_cat"))
```

![](mice-work_2018-02-05_files/figure-markdown_github/unnamed-chunk-25-1.png)

Calculating results and pooling
===============================

Now that we have out imputed data sets, we want to analyze each of them and then pool the results.

When pooling results, the `mice` software has tools to help whether pooling model results or scalar estimates. Things get messy quickly because I am calculating a number of agreement statistics, for 11 procedures, with 7 categorical variables, and each categorical variable has a number of levels.

When I first did these steps, I wrote many nested for loops. While this worked and it ran, it was slow and a little bit like a black box. A wise person once said that if you you find yourself using nested for loops in R then you should consider using the functions from the `purrr` package. They were right. I didn't compare speed with the previous approach, but the way I present here has clear points where you can check that things make sense. This advantage makes the choice clear for me.

The first step in wrangling the results is to get the separate imputed data sets into one data frame with a variable to track which imputation number the data came from.

``` r
# Create an empty list
mylist <- list() 

# Put the imputed sets into the list
for (i in 1:imp_full$m) {
  mylist[[i]] <- mice::complete(imp_full, i)
}

# mylist[[1]]

# Take the list and stack the data sets into a data frame
# with an indication for the number of imputed data set
output <- dplyr::bind_rows(mylist, .id = "n_imp")

# This would do the same thing, maybe faster, but the above has the added 
# benefit of easily adding the number of the imputation so that I can track 
# things. Either way, I chose the one above as my preference.
# df <- do.call(rbind, mylist)
# df

# Check it out that the dimensions make sense and spot check the data
dplyr::glimpse(output)
```

    Observations: 70,000
    Variables: 43
    $ n_imp            <chr> "1", "1", "1", "1", "1", "1", "1", "1", "1", ...
    $ study_id         <int> 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14...
    $ sex              <fct> F, F, M, M, F, M, M, M, M, F, M, F, F, F, M, ...
    $ age_start        <int> 56, 36, 38, 64, 64, 49, 52, 32, 21, 41, 46, 5...
    $ primary_dept     <fct> 026, 031, 035, 035, 027, 017, 022, 022, 029, ...
    $ ethnic_cat       <fct> NH White, NH White, Hispanic, NH Other, NH Wh...
    $ lang_cat         <fct> English, English, English, English, English, ...
    $ race_cat         <fct> Black, White, White, White, White, White, Whi...
    $ fpl_cat          <fct> <=138% FPL, <=138% FPL, <=138% FPL, <=138% FP...
    $ age_cat          <fct> [51,65), [35,51), [35,51), [51,65), [51,65), ...
    $ elig_cervical    <fct> 1, 1, 0, 0, 1, 0, 0, 0, 0, 1, 0, 1, 1, 1, 0, ...
    $ elig_breast      <fct> 1, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 1, 1, 1, 0, ...
    $ elig_colon       <fct> 1, 0, 0, 1, 1, 0, 1, 0, 0, 0, 0, 1, 1, 1, 0, ...
    $ elig_colonoscopy <fct> 1, 0, 0, 1, 1, 0, 1, 0, 0, 0, 0, 1, 1, 1, 0, ...
    $ elig_flexsig     <fct> 1, 0, 0, 1, 1, 0, 1, 0, 0, 0, 0, 1, 1, 1, 0, ...
    $ elig_fobt        <fct> 1, 0, 0, 1, 1, 0, 1, 0, 0, 0, 0, 1, 1, 1, 0, ...
    $ elig_bmi         <fct> 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, ...
    $ elig_flu         <fct> 1, 0, 0, 1, 1, 0, 1, 0, 0, 0, 0, 1, 1, 1, 0, ...
    $ elig_chlam       <fct> 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, ...
    $ elig_smoking     <fct> 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, ...
    $ elig_cholest     <fct> 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, ...
    $ dmap_cervical    <fct> 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, ...
    $ dmap_breast      <fct> 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, ...
    $ dmap_colon       <fct> 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, ...
    $ dmap_colonoscopy <fct> 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, ...
    $ dmap_flexsig     <fct> 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, ...
    $ dmap_fobt        <fct> 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, ...
    $ dmap_bmi         <fct> 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, ...
    $ dmap_flu         <fct> 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, ...
    $ dmap_chlam       <fct> 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, ...
    $ dmap_smoking     <fct> 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, ...
    $ dmap_cholest     <fct> 1, 0, 1, 0, 0, 1, 0, 1, 0, 1, 1, 1, 0, 0, 1, ...
    $ ehr_cervical     <fct> 0, 1, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, ...
    $ ehr_breast       <fct> 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, ...
    $ ehr_colon        <fct> 1, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, ...
    $ ehr_colonoscopy  <fct> 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, ...
    $ ehr_flexsig      <fct> 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, ...
    $ ehr_fobt         <fct> 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, ...
    $ ehr_bmi          <fct> 1, 1, 0, 1, 1, 1, 1, 0, 1, 0, 1, 1, 1, 1, 1, ...
    $ ehr_flu          <fct> 1, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, ...
    $ ehr_chlam        <fct> 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, ...
    $ ehr_smoking      <fct> 1, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, ...
    $ ehr_cholest      <fct> 0, 0, 1, 1, 0, 0, 0, 1, 0, 0, 0, 1, 1, 1, 0, ...

``` r
# dim(output)
# head(output)
# tail(output)
```

Then I gather the data into a tidy format so that I can group by category or imputation number or whatever I want really. I employ a user written function because it's a little bit of work to do this.

``` r
source(here::here("src", "make_df_long.R"))
output_long <- make_df_long(df = output)
```

We can check that this works by grouping by category and checking that the sums and counts of some of the variables match.

``` r
output_long %>% 
  group_by(cat) %>% 
  summarise(
    n = n(), 
    ELIG = sum(as.numeric(elig), na.rm = TRUE), 
    EHR = sum(as.numeric(ehr), na.rm = TRUE), 
    DMAP = sum(as.numeric(dmap), na.rm = TRUE), 
    id = sum(as.numeric(study_id), na.rm = TRUE), 
    age = sum(age_start, na.rm = TRUE)
  )
```

    # A tibble: 7 x 7
      cat            n   ELIG    EHR  DMAP         id      age
      <chr>      <int>  <dbl>  <dbl> <dbl>      <dbl>    <int>
    1 age       770000 409265 207210 85300 5390385000 32438175
    2 all       770000 409265 207210 85300 5390385000 32438175
    3 ethnicity 770000 409265 207210 85300 5390385000 32438175
    4 fpl       770000 409265 207210 85300 5390385000 32438175
    5 language  770000 409265 207210 85300 5390385000 32438175
    6 race      770000 409265 207210 85300 5390385000 32438175
    7 sex       770000 409265 207210 85300 5390385000 32438175

I now want the data to be grouped by (1) procedure, (2) category, (3) level, and (4) imputation number.

``` r
output_nested <- output_long %>% 
  group_by(proc, cat, level, n_imp) %>% 
  nest()

output_nested %>% 
  head(., n = 10)
```

    # A tibble: 10 x 5
       proc     cat   level n_imp data                 
       <chr>    <chr> <chr> <chr> <list>               
     1 cervical all   all   1     <tibble [14,000 x 6]>
     2 cervical all   all   2     <tibble [14,000 x 6]>
     3 cervical all   all   3     <tibble [14,000 x 6]>
     4 cervical all   all   4     <tibble [14,000 x 6]>
     5 cervical all   all   5     <tibble [14,000 x 6]>
     6 breast   all   all   1     <tibble [14,000 x 6]>
     7 breast   all   all   2     <tibble [14,000 x 6]>
     8 breast   all   all   3     <tibble [14,000 x 6]>
     9 breast   all   all   4     <tibble [14,000 x 6]>
    10 breast   all   all   5     <tibble [14,000 x 6]>

``` r
# df_nested$data[[1]]
# head(df_nested$data[[1]])
# tail(df_nested$data[[1]])
```

We now have a nested column of the data by the groups and imputations that we want. Next, we need to calculate two columns: Q - the estimates, and U - their standard errors. These needed user written functions to make the process automated and efficient.

``` r
source(here::here("src", "calc-stats.R"))
output_nested %<>% 
  mutate(Q = purrr::map(.x = data, .f = calc_stats_p), 
         U = purrr::map(.x = data, .f = calc_stats_se))

output_nested %>% 
  head(., n = 10)
```

    # A tibble: 10 x 7
       proc     cat   level n_imp data                  Q           U         
       <chr>    <chr> <chr> <chr> <list>                <list>      <list>    
     1 cervical all   all   1     <tibble [14,000 x 6]> <data.fram~ <data.fra~
     2 cervical all   all   2     <tibble [14,000 x 6]> <data.fram~ <data.fra~
     3 cervical all   all   3     <tibble [14,000 x 6]> <data.fram~ <data.fra~
     4 cervical all   all   4     <tibble [14,000 x 6]> <data.fram~ <data.fra~
     5 cervical all   all   5     <tibble [14,000 x 6]> <data.fram~ <data.fra~
     6 breast   all   all   1     <tibble [14,000 x 6]> <data.fram~ <data.fra~
     7 breast   all   all   2     <tibble [14,000 x 6]> <data.fram~ <data.fra~
     8 breast   all   all   3     <tibble [14,000 x 6]> <data.fram~ <data.fra~
     9 breast   all   all   4     <tibble [14,000 x 6]> <data.fram~ <data.fra~
    10 breast   all   all   5     <tibble [14,000 x 6]> <data.fram~ <data.fra~

``` r
# output_nested$Q[[1]]
# output_nested$U[[1]]
```

Next, we want to unnest the results from calculating the statistics and the standard errors.

``` r
output_nested %<>% 
  tidyr::unnest(Q, U) %>% 
  dplyr::select(-stat1) %>% 
  mutate_at(.vars = vars(Q, U), 
            .funs = funs(as.numeric))

output_nested %>% 
  head(., n = 10)
```

    # A tibble: 10 x 7
       proc     cat   level n_imp stat            Q     U
       <chr>    <chr> <chr> <chr> <chr>       <dbl> <dbl>
     1 cervical all   all   1     n       14000         0
     2 cervical all   all   1     a         827         0
     3 cervical all   all   1     b        1859         0
     4 cervical all   all   1     c        1981         0
     5 cervical all   all   1     d        9333         0
     6 cervical all   all   1     EHR.n    2686         0
     7 cervical all   all   1     EHR.p       0.192     0
     8 cervical all   all   1     DMAP.n   2808         0
     9 cervical all   all   1     DMAP.p      0.201     0
    10 cervical all   all   1     Combo.n  4667         0

We want to re-`group_by` the data by procedure, category, level, and type of statistic. This step gives us the nested estimates and variances for all the imputed sets which we can now pool the resuls.

``` r
output_nested %<>% 
  group_by(proc, cat, level, stat) %>% 
  nest()
```

Pool and unnest. Note that my user written function `mi_pool` is really just a wrapper for the `pool.scalar()` function in the `mice` package.

``` r
output_nested %<>% 
  mutate(pooled = purrr::map(.x = data, .f = mi_pool))

output_nested %>% 
  head(., n = 10)
```

    # A tibble: 10 x 6
       proc     cat   level stat    data             pooled          
       <chr>    <chr> <chr> <chr>   <list>           <list>          
     1 cervical all   all   n       <tibble [5 x 3]> <tibble [1 x 9]>
     2 cervical all   all   a       <tibble [5 x 3]> <tibble [1 x 9]>
     3 cervical all   all   b       <tibble [5 x 3]> <tibble [1 x 9]>
     4 cervical all   all   c       <tibble [5 x 3]> <tibble [1 x 9]>
     5 cervical all   all   d       <tibble [5 x 3]> <tibble [1 x 9]>
     6 cervical all   all   EHR.n   <tibble [5 x 3]> <tibble [1 x 9]>
     7 cervical all   all   EHR.p   <tibble [5 x 3]> <tibble [1 x 9]>
     8 cervical all   all   DMAP.n  <tibble [5 x 3]> <tibble [1 x 9]>
     9 cervical all   all   DMAP.p  <tibble [5 x 3]> <tibble [1 x 9]>
    10 cervical all   all   Combo.n <tibble [5 x 3]> <tibble [1 x 9]>

Unnest the pooled results, we see that for each procedure, by category, by strata, we have for each statistic, the results that the pooling in `mice` provides.

``` r
output_nested %<>% 
  unnest(pooled)

output_nested %>% 
  dplyr::select(-data) %>% 
  dplyr::glimpse(.)
```

    Observations: 4,807
    Variables: 13
    $ proc   <chr> "cervical", "cervical", "cervical", "cervical", "cervic...
    $ cat    <chr> "all", "all", "all", "all", "all", "all", "all", "all",...
    $ level  <chr> "all", "all", "all", "all", "all", "all", "all", "all",...
    $ stat   <chr> "n", "a", "b", "c", "d", "EHR.n", "EHR.p", "DMAP.n", "D...
    $ m      <int> 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5...
    $ qbar   <dbl> 14000.000000000, 827.000000000, 1859.000000000, 1981.00...
    $ ubar   <dbl> 0.000000000, 0.000000000, 0.000000000, 0.000000000, 0.0...
    $ b      <dbl> 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0...
    $ t      <dbl> 0.000000000, 0.000000000, 0.000000000, 0.000000000, 0.0...
    $ r      <dbl> NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, ...
    $ df     <dbl> NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, ...
    $ fmi    <dbl> NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, ...
    $ lambda <dbl> NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, ...

The value `qbar` is the pooled post-imputation estimate that we are most interested. See the `mice` documenation for information on the rest. So if we just want to get those results for all the agreement statistics:

Annoyingly the variables are in alphabetical order when they are unnnested, so I add an extra `select` command to order them

``` r
output_nested %>% 
  dplyr::select(proc:stat, qbar) %>% 
  tidyr::spread(., key = stat, value = qbar) %>% 
  dplyr::select(
    "proc", "cat", "level", 
    "n", "a", "b", "c", "d", 
    "EHR.n", "EHR.p", "DMAP.n", "DMAP.p", "Combo.n", "Combo.p", 
    "Po", "Pe", 
    "Ppos", "Pneg", "sens", "spec", 
    "kap", "Kmax", "Kmin", 
    "BI", "PI", "PABAK"
  ) %>% 
  knitr::kable(
    booktabs = TRUE, 
    digits = 2
  )
```

| proc        | cat       | level          |        n|       a|        b|       c|        d|    EHR.n|  EHR.p|  DMAP.n|  DMAP.p|  Combo.n|  Combo.p|    Po|    Pe|  Ppos|  Pneg|  sens|  spec|    kap|  Kmax|   Kmin|    BI|    PI|  PABAK|
|:------------|:----------|:---------------|--------:|-------:|--------:|-------:|--------:|--------:|------:|-------:|-------:|--------:|--------:|-----:|-----:|-----:|-----:|-----:|-----:|------:|-----:|------:|-----:|-----:|------:|
| bmi         | age       | \[19,35)       |   4666.0|   170.0|   3788.0|    32.0|    676.0|   3958.0|   0.85|   202.0|    0.04|   3990.0|     0.86|  0.18|  0.18|  0.08|  0.26|  0.84|  0.15|   0.00|  0.02|  -0.09|  0.80|  0.11|  -0.64|
| bmi         | age       | \[35,51)       |   4666.0|   159.0|   3792.0|    32.0|    683.0|   3951.0|   0.85|   191.0|    0.04|   3983.0|     0.85|  0.18|  0.18|  0.08|  0.26|  0.83|  0.15|   0.00|  0.02|  -0.08|  0.81|  0.11|  -0.64|
| bmi         | age       | \[51,65)       |   4668.0|   213.0|   3760.0|    34.0|    661.0|   3973.0|   0.85|   247.0|    0.05|   4007.0|     0.86|  0.19|  0.19|  0.10|  0.26|  0.86|  0.15|   0.00|  0.02|  -0.11|  0.80|  0.10|  -0.63|
| bmi         | all       | all            |  14000.0|   542.0|  11340.0|    98.0|   2020.0|  11882.0|   0.85|   640.0|    0.05|  11980.0|     0.86|  0.18|  0.18|  0.09|  0.26|  0.85|  0.15|   0.00|  0.02|  -0.09|  0.80|  0.11|  -0.63|
| bmi         | ethnicity | Hispanic       |   1426.8|    51.0|   1156.4|     8.4|    211.0|   1207.4|   0.85|    59.4|    0.04|   1215.8|     0.85|  0.18|  0.18|  0.08|  0.27|  0.86|  0.15|   0.00|  0.02|  -0.09|  0.80|  0.11|  -0.63|
| bmi         | ethnicity | NH Other       |   2209.0|    79.8|   1795.2|    19.2|    314.8|   1875.0|   0.85|    99.0|    0.04|   1894.2|     0.86|  0.18|  0.18|  0.08|  0.26|  0.81|  0.15|   0.00|  0.02|  -0.09|  0.80|  0.11|  -0.64|
| bmi         | ethnicity | NH White       |  10364.2|   411.2|   8388.4|    70.4|   1494.2|   8799.6|   0.85|   481.6|    0.05|   8870.0|     0.86|  0.18|  0.18|  0.09|  0.26|  0.85|  0.15|   0.00|  0.02|  -0.10|  0.80|  0.10|  -0.63|
| bmi         | fpl       | &lt;=138% FPL  |  13111.2|   510.6|  10599.2|    93.8|   1907.6|  11109.8|   0.85|   604.4|    0.05|  11203.6|     0.85|  0.18|  0.18|  0.09|  0.26|  0.84|  0.15|   0.00|  0.02|  -0.10|  0.80|  0.11|  -0.63|
| bmi         | fpl       | &gt;138% FPL   |    888.8|    31.4|    740.8|     4.2|    112.4|    772.2|   0.87|    35.6|    0.04|    776.4|     0.87|  0.16|  0.16|  0.08|  0.23|  0.88|  0.13|   0.00|  0.01|  -0.08|  0.83|  0.09|  -0.68|
| bmi         | language  | English        |  11897.0|   457.0|   9647.0|    81.0|   1712.0|  10104.0|   0.85|   538.0|    0.05|  10185.0|     0.86|  0.18|  0.18|  0.09|  0.26|  0.85|  0.15|   0.00|  0.02|  -0.09|  0.80|  0.11|  -0.64|
| bmi         | language  | Other          |   1391.0|    47.0|   1125.0|    12.0|    207.0|   1172.0|   0.84|    59.0|    0.04|   1184.0|     0.85|  0.18|  0.19|  0.08|  0.27|  0.80|  0.16|   0.00|  0.02|  -0.09|  0.80|  0.12|  -0.63|
| bmi         | language  | Spanish        |    712.0|    38.0|    568.0|     5.0|    101.0|    606.0|   0.85|    43.0|    0.06|    611.0|     0.86|  0.20|  0.19|  0.12|  0.26|  0.88|  0.15|   0.00|  0.02|  -0.13|  0.79|  0.09|  -0.61|
| bmi         | race      | AIAN           |    277.2|     9.8|    227.6|     1.0|     38.8|    237.4|   0.86|    10.8|    0.04|    238.4|     0.86|  0.18|  0.17|  0.08|  0.25|  0.91|  0.15|   0.00|  0.01|  -0.08|  0.82|  0.10|  -0.65|
| bmi         | race      | API            |    731.4|    36.0|    592.8|     2.0|    100.6|    628.8|   0.86|    38.0|    0.05|    630.8|     0.86|  0.19|  0.18|  0.11|  0.25|  0.95|  0.15|   0.01|  0.02|  -0.11|  0.81|  0.09|  -0.63|
| bmi         | race      | Black          |   1463.4|    55.6|   1188.8|     9.4|    209.6|   1244.4|   0.85|    65.0|    0.04|   1253.8|     0.86|  0.18|  0.18|  0.08|  0.26|  0.86|  0.15|   0.00|  0.02|  -0.09|  0.81|  0.11|  -0.64|
| bmi         | race      | Multiple Races |    154.8|     0.0|    136.0|     0.0|     18.8|    136.0|   0.88|     0.0|    0.00|    136.0|     0.88|  0.12|  0.12|  0.00|  0.22|   NaN|  0.12|   0.00|  0.00|   0.00|  0.88|  0.12|  -0.76|
| bmi         | race      | White          |  11373.2|   440.6|   9194.8|    85.6|   1652.2|   9635.4|   0.85|   526.2|    0.05|   9721.0|     0.85|  0.18|  0.18|  0.09|  0.26|  0.84|  0.15|   0.00|  0.02|  -0.10|  0.80|  0.11|  -0.63|
| bmi         | sex       | F              |   9144.0|   332.0|   7421.0|    62.0|   1329.0|   7753.0|   0.85|   394.0|    0.04|   7815.0|     0.85|  0.18|  0.18|  0.08|  0.26|  0.84|  0.15|   0.00|  0.02|  -0.09|  0.80|  0.11|  -0.64|
| bmi         | sex       | M              |   4856.0|   210.0|   3919.0|    36.0|    691.0|   4129.0|   0.85|   246.0|    0.05|   4165.0|     0.86|  0.19|  0.19|  0.10|  0.26|  0.85|  0.15|   0.00|  0.02|  -0.11|  0.80|  0.10|  -0.63|
| breast      | age       | \[19,35)       |   4666.0|     0.0|      0.0|     0.0|   4666.0|      0.0|   0.00|     0.0|    0.00|      0.0|     0.00|  1.00|  1.00|   NaN|  1.00|   NaN|  1.00|    NaN|   NaN|    NaN|  0.00|  1.00|   1.00|
| breast      | age       | \[35,51)       |   4666.0|   358.0|    504.0|   479.0|   3325.0|    862.0|   0.18|   837.0|    0.18|   1341.0|     0.29|  0.79|  0.70|  0.42|  0.87|  0.43|  0.87|   0.29|  0.98|  -0.22|  0.01|  0.64|   0.58|
| breast      | age       | \[51,65)       |   4668.0|   471.0|    768.0|   742.0|   2687.0|   1239.0|   0.27|  1213.0|    0.26|   1981.0|     0.42|  0.68|  0.61|  0.38|  0.78|  0.39|  0.78|   0.16|  0.99|  -0.36|  0.01|  0.47|   0.35|
| breast      | all       | all            |  14000.0|   829.0|   1272.0|  1221.0|  10678.0|   2101.0|   0.15|  2050.0|    0.15|   3322.0|     0.24|  0.82|  0.75|  0.40|  0.90|  0.40|  0.89|   0.29|  0.99|  -0.17|  0.00|  0.70|   0.64|
| breast      | ethnicity | Hispanic       |   1426.8|    70.6|    139.0|   154.0|   1063.2|    209.6|   0.15|   224.6|    0.16|    363.6|     0.25|  0.79|  0.74|  0.33|  0.88|  0.31|  0.88|   0.20|  0.96|  -0.18|  0.01|  0.70|   0.59|
| breast      | ethnicity | NH Other       |   2209.0|   142.6|    194.2|   191.0|   1681.2|    336.8|   0.15|   333.6|    0.15|    527.8|     0.24|  0.83|  0.74|  0.43|  0.90|  0.43|  0.90|   0.32|  0.99|  -0.18|  0.00|  0.70|   0.65|
| breast      | ethnicity | NH White       |  10364.2|   615.8|    938.8|   876.0|   7933.6|   1554.6|   0.15|  1491.8|    0.14|   2430.6|     0.23|  0.82|  0.75|  0.40|  0.90|  0.41|  0.89|   0.30|  0.98|  -0.17|  0.01|  0.71|   0.65|
| breast      | fpl       | &lt;=138% FPL  |  13111.2|   789.2|   1198.0|  1143.2|   9980.8|   1987.2|   0.15|  1932.4|    0.15|   3130.4|     0.24|  0.82|  0.75|  0.40|  0.90|  0.41|  0.89|   0.30|  0.98|  -0.18|  0.00|  0.70|   0.64|
| breast      | fpl       | &gt;138% FPL   |    888.8|    39.8|     74.0|    77.8|    697.2|    113.8|   0.13|   117.6|    0.13|    191.6|     0.22|  0.83|  0.77|  0.34|  0.90|  0.34|  0.90|   0.25|  0.97|  -0.15|  0.01|  0.74|   0.66|
| breast      | language  | English        |  11897.0|   712.0|   1097.0|  1045.0|   9043.0|   1809.0|   0.15|  1757.0|    0.15|   2854.0|     0.24|  0.82|  0.75|  0.40|  0.89|  0.41|  0.89|   0.29|  0.98|  -0.18|  0.00|  0.70|   0.64|
| breast      | language  | Other          |   1391.0|    86.0|    116.0|   119.0|   1070.0|    202.0|   0.15|   205.0|    0.15|    321.0|     0.23|  0.83|  0.75|  0.42|  0.90|  0.42|  0.90|   0.32|  0.99|  -0.17|  0.00|  0.71|   0.66|
| breast      | language  | Spanish        |    712.0|    31.0|     59.0|    57.0|    565.0|     90.0|   0.13|    88.0|    0.12|    147.0|     0.21|  0.84|  0.78|  0.35|  0.91|  0.35|  0.91|   0.26|  0.99|  -0.14|  0.00|  0.75|   0.67|
| breast      | race      | AIAN           |    277.2|    13.6|     27.2|    31.8|    204.6|     40.8|   0.15|    45.4|    0.16|     72.6|     0.26|  0.79|  0.74|  0.31|  0.87|  0.30|  0.88|   0.19|  0.94|  -0.18|  0.02|  0.69|   0.57|
| breast      | race      | API            |    731.4|    45.4|     61.2|    63.6|    561.2|    106.6|   0.15|   109.0|    0.15|    170.2|     0.23|  0.83|  0.75|  0.42|  0.90|  0.42|  0.90|   0.32|  0.98|  -0.17|  0.00|  0.71|   0.66|
| breast      | race      | Black          |   1463.4|    88.2|    141.6|   108.8|   1124.8|    229.8|   0.16|   197.0|    0.13|    338.6|     0.23|  0.83|  0.75|  0.41|  0.90|  0.45|  0.89|   0.31|  0.91|  -0.17|  0.02|  0.71|   0.66|
| breast      | race      | Multiple Races |    154.8|     5.8|     17.0|    13.8|    118.2|     22.8|   0.15|    19.6|    0.13|     36.6|     0.24|  0.80|  0.76|  0.27|  0.88|  0.29|  0.87|   0.16|  0.91|  -0.16|  0.02|  0.73|   0.60|
| breast      | race      | White          |  11373.2|   676.0|   1025.0|  1003.0|   8669.2|   1701.0|   0.15|  1679.0|    0.15|   2704.0|     0.24|  0.82|  0.75|  0.40|  0.90|  0.40|  0.89|   0.30|  0.99|  -0.17|  0.00|  0.70|   0.64|
| breast      | sex       | F              |   9144.0|   829.0|   1272.0|  1221.0|   5822.0|   2101.0|   0.23|  2050.0|    0.22|   3322.0|     0.36|  0.73|  0.65|  0.40|  0.82|  0.40|  0.82|   0.22|  0.98|  -0.29|  0.01|  0.55|   0.45|
| breast      | sex       | M              |   4856.0|     0.0|      0.0|     0.0|   4856.0|      0.0|   0.00|     0.0|    0.00|      0.0|     0.00|  1.00|  1.00|   NaN|  1.00|   NaN|  1.00|    NaN|   NaN|    NaN|  0.00|  1.00|   1.00|
| cervical    | age       | \[19,35)       |   4666.0|   252.0|    646.0|   649.0|   3119.0|    898.0|   0.19|   901.0|    0.19|   1547.0|     0.33|  0.72|  0.69|  0.28|  0.83|  0.28|  0.83|   0.11|  1.00|  -0.24|  0.00|  0.61|   0.44|
| cervical    | age       | \[35,51)       |   4666.0|   291.0|    625.0|   667.0|   3083.0|    916.0|   0.20|   958.0|    0.21|   1583.0|     0.34|  0.72|  0.68|  0.31|  0.83|  0.30|  0.83|   0.14|  0.97|  -0.25|  0.01|  0.60|   0.45|
| cervical    | age       | \[51,65)       |   4668.0|   284.0|    588.0|   665.0|   3131.0|    872.0|   0.19|   949.0|    0.20|   1537.0|     0.33|  0.73|  0.69|  0.31|  0.83|  0.30|  0.84|   0.15|  0.95|  -0.24|  0.02|  0.61|   0.46|
| cervical    | all       | all            |  14000.0|   827.0|   1859.0|  1981.0|   9333.0|   2686.0|   0.19|  2808.0|    0.20|   4667.0|     0.33|  0.73|  0.68|  0.30|  0.83|  0.29|  0.83|   0.13|  0.97|  -0.24|  0.01|  0.61|   0.45|
| cervical    | ethnicity | Hispanic       |   1426.8|    56.8|    197.8|   229.0|    943.2|    254.6|   0.18|   285.8|    0.20|    483.6|     0.34|  0.70|  0.69|  0.21|  0.82|  0.20|  0.83|   0.03|  0.93|  -0.23|  0.02|  0.62|   0.40|
| cervical    | ethnicity | NH Other       |   2209.0|   124.0|    304.0|   320.8|   1460.2|    428.0|   0.19|   444.8|    0.20|    748.8|     0.34|  0.72|  0.68|  0.28|  0.82|  0.28|  0.83|   0.11|  0.98|  -0.25|  0.01|  0.60|   0.43|
| cervical    | ethnicity | NH White       |  10364.2|   646.2|   1357.2|  1431.2|   6929.6|   2003.4|   0.19|  2077.4|    0.20|   3434.6|     0.33|  0.73|  0.68|  0.32|  0.83|  0.31|  0.84|   0.15|  0.98|  -0.25|  0.01|  0.61|   0.46|
| cervical    | fpl       | &lt;=138% FPL  |  13111.2|   772.0|   1736.6|  1849.2|   8753.4|   2508.6|   0.19|  2621.2|    0.20|   4357.8|     0.33|  0.73|  0.69|  0.30|  0.83|  0.29|  0.83|   0.13|  0.97|  -0.24|  0.01|  0.61|   0.45|
| cervical    | fpl       | &gt;138% FPL   |    888.8|    55.0|    122.4|   131.8|    579.6|    177.4|   0.20|   186.8|    0.21|    309.2|     0.35|  0.71|  0.67|  0.30|  0.82|  0.29|  0.83|   0.12|  0.97|  -0.26|  0.01|  0.59|   0.43|
| cervical    | language  | English        |  11897.0|   704.0|   1578.0|  1680.0|   7935.0|   2282.0|   0.19|  2384.0|    0.20|   3962.0|     0.33|  0.73|  0.68|  0.30|  0.83|  0.30|  0.83|   0.13|  0.97|  -0.24|  0.01|  0.61|   0.45|
| cervical    | language  | Other          |   1391.0|    83.0|    186.0|   209.0|    913.0|    269.0|   0.19|   292.0|    0.21|    478.0|     0.34|  0.72|  0.68|  0.30|  0.82|  0.28|  0.83|   0.12|  0.95|  -0.25|  0.02|  0.60|   0.43|
| cervical    | language  | Spanish        |    712.0|    40.0|     95.0|    92.0|    485.0|    135.0|   0.19|   132.0|    0.19|    227.0|     0.32|  0.74|  0.70|  0.30|  0.84|  0.30|  0.84|   0.14|  0.99|  -0.23|  0.00|  0.62|   0.47|
| cervical    | race      | AIAN           |    277.2|    17.0|     36.8|    45.8|    177.6|     53.8|   0.19|    62.8|    0.23|     99.6|     0.36|  0.70|  0.67|  0.29|  0.81|  0.27|  0.83|   0.10|  0.90|  -0.26|  0.03|  0.58|   0.40|
| cervical    | race      | API            |    731.4|    42.4|     91.6|    96.4|    501.0|    134.0|   0.18|   138.8|    0.19|    230.4|     0.32|  0.74|  0.70|  0.31|  0.84|  0.31|  0.85|   0.15|  0.98|  -0.23|  0.01|  0.63|   0.49|
| cervical    | race      | Black          |   1463.4|    98.2|    206.8|   206.0|    952.4|    305.0|   0.21|   304.2|    0.21|    511.0|     0.35|  0.72|  0.67|  0.32|  0.82|  0.32|  0.82|   0.14|  0.99|  -0.26|  0.00|  0.58|   0.44|
| cervical    | race      | Multiple Races |    154.8|    13.0|     25.6|    21.4|     94.8|     38.6|   0.25|    34.4|    0.22|     60.0|     0.39|  0.70|  0.64|  0.36|  0.80|  0.38|  0.79|   0.16|  0.92|  -0.31|  0.03|  0.53|   0.39|
| cervical    | race      | White          |  11373.2|   656.4|   1498.2|  1611.4|   7607.2|   2154.6|   0.19|  2267.8|    0.20|   3766.0|     0.33|  0.73|  0.69|  0.30|  0.83|  0.29|  0.84|   0.13|  0.97|  -0.24|  0.01|  0.61|   0.45|
| cervical    | sex       | F              |   9144.0|   827.0|   1859.0|  1981.0|   4477.0|   2686.0|   0.29|  2808.0|    0.31|   4667.0|     0.51|  0.58|  0.58|  0.30|  0.70|  0.29|  0.71|   0.00|  0.97|  -0.43|  0.01|  0.40|   0.16|
| cervical    | sex       | M              |   4856.0|     0.0|      0.0|     0.0|   4856.0|      0.0|   0.00|     0.0|    0.00|      0.0|     0.00|  1.00|  1.00|   NaN|  1.00|   NaN|  1.00|    NaN|   NaN|    NaN|  0.00|  1.00|   1.00|
| chlam       | age       | \[19,35)       |   4666.0|   202.0|    205.0|   348.0|   3911.0|    407.0|   0.09|   550.0|    0.12|    755.0|     0.16|  0.88|  0.82|  0.42|  0.93|  0.37|  0.95|   0.36|  0.83|  -0.11|  0.03|  0.79|   0.76|
| chlam       | age       | \[35,51)       |   4666.0|     0.0|      0.0|     0.0|   4666.0|      0.0|   0.00|     0.0|    0.00|      0.0|     0.00|  1.00|  1.00|   NaN|  1.00|   NaN|  1.00|    NaN|   NaN|    NaN|  0.00|  1.00|   1.00|
| chlam       | age       | \[51,65)       |   4668.0|     0.0|      0.0|     0.0|   4668.0|      0.0|   0.00|     0.0|    0.00|      0.0|     0.00|  1.00|  1.00|   NaN|  1.00|   NaN|  1.00|    NaN|   NaN|    NaN|  0.00|  1.00|   1.00|
| chlam       | all       | all            |  14000.0|   202.0|    205.0|   348.0|  13245.0|    407.0|   0.03|   550.0|    0.04|    755.0|     0.05|  0.96|  0.93|  0.42|  0.98|  0.37|  0.98|   0.40|  0.85|  -0.03|  0.01|  0.93|   0.92|
| chlam       | ethnicity | Hispanic       |   1426.8|    18.6|     18.2|    35.4|   1354.6|     36.8|   0.03|    54.0|    0.04|     72.2|     0.05|  0.96|  0.94|  0.41|  0.98|  0.34|  0.99|   0.39|  0.80|  -0.03|  0.01|  0.94|   0.92|
| chlam       | ethnicity | NH Other       |   2209.0|    35.6|     35.6|    68.8|   2069.0|     71.2|   0.03|   104.4|    0.05|    140.0|     0.06|  0.95|  0.92|  0.41|  0.98|  0.34|  0.98|   0.38|  0.80|  -0.04|  0.02|  0.92|   0.91|
| chlam       | ethnicity | NH White       |  10364.2|   147.8|    151.2|   243.8|   9821.4|    299.0|   0.03|   391.6|    0.04|    542.8|     0.05|  0.96|  0.94|  0.43|  0.98|  0.38|  0.98|   0.41|  0.86|  -0.03|  0.01|  0.93|   0.92|
| chlam       | fpl       | &lt;=138% FPL  |  13111.2|   194.0|    194.4|   327.2|  12395.6|    388.4|   0.03|   521.2|    0.04|    715.6|     0.05|  0.96|  0.93|  0.43|  0.98|  0.37|  0.98|   0.41|  0.85|  -0.04|  0.01|  0.93|   0.92|
| chlam       | fpl       | &gt;138% FPL   |    888.8|     8.0|     10.6|    20.8|    849.4|     18.6|   0.02|    28.8|    0.03|     39.4|     0.04|  0.96|  0.95|  0.34|  0.98|  0.28|  0.99|   0.32|  0.78|  -0.03|  0.01|  0.95|   0.93|
| chlam       | language  | English        |  11897.0|   169.0|    166.0|   292.0|  11270.0|    335.0|   0.03|   461.0|    0.04|    627.0|     0.05|  0.96|  0.94|  0.42|  0.98|  0.37|  0.99|   0.41|  0.84|  -0.03|  0.01|  0.93|   0.92|
| chlam       | language  | Other          |   1391.0|    21.0|     24.0|    40.0|   1306.0|     45.0|   0.03|    61.0|    0.04|     85.0|     0.06|  0.95|  0.93|  0.40|  0.98|  0.34|  0.98|   0.37|  0.84|  -0.04|  0.01|  0.92|   0.91|
| chlam       | language  | Spanish        |    712.0|    12.0|     15.0|    16.0|    669.0|     27.0|   0.04|    28.0|    0.04|     43.0|     0.06|  0.96|  0.93|  0.44|  0.98|  0.43|  0.98|   0.41|  0.98|  -0.04|  0.00|  0.92|   0.91|
| chlam       | race      | AIAN           |    277.2|     3.0|      4.4|     8.4|    261.4|      7.4|   0.03|    11.4|    0.04|     15.8|     0.06|  0.95|  0.93|  0.32|  0.98|  0.26|  0.98|   0.30|  0.78|  -0.03|  0.01|  0.93|   0.91|
| chlam       | race      | API            |    731.4|    14.0|     12.2|    14.0|    691.2|     26.2|   0.04|    28.0|    0.04|     40.2|     0.05|  0.96|  0.93|  0.52|  0.98|  0.50|  0.98|   0.50|  0.97|  -0.04|  0.00|  0.93|   0.93|
| chlam       | race      | Black          |   1463.4|    24.2|     27.0|    42.2|   1370.0|     51.2|   0.03|    66.4|    0.05|     93.4|     0.06|  0.95|  0.92|  0.41|  0.98|  0.36|  0.98|   0.39|  0.87|  -0.04|  0.01|  0.92|   0.91|
| chlam       | race      | Multiple Races |    154.8|     1.0|      0.0|     6.4|    147.4|      1.0|   0.01|     7.4|    0.05|      7.4|     0.05|  0.96|  0.95|  0.24|  0.98|  0.14|  1.00|   0.23|  0.23|  -0.01|  0.04|  0.95|   0.92|
| chlam       | race      | White          |  11373.2|   159.8|    161.4|   277.0|  10775.0|    321.2|   0.03|   436.8|    0.04|    598.2|     0.05|  0.96|  0.94|  0.42|  0.98|  0.37|  0.99|   0.40|  0.84|  -0.03|  0.01|  0.93|   0.92|
| chlam       | sex       | F              |   9144.0|   202.0|    205.0|   348.0|   8389.0|    407.0|   0.04|   550.0|    0.06|    755.0|     0.08|  0.94|  0.90|  0.42|  0.97|  0.37|  0.98|   0.39|  0.84|  -0.05|  0.02|  0.90|   0.88|
| chlam       | sex       | M              |   4856.0|     0.0|      0.0|     0.0|   4856.0|      0.0|   0.00|     0.0|    0.00|      0.0|     0.00|  1.00|  1.00|   NaN|  1.00|   NaN|  1.00|    NaN|   NaN|    NaN|  0.00|  1.00|   1.00|
| cholest     | age       | \[19,35)       |   4666.0|   689.0|   1048.0|  1076.0|   1853.0|   1737.0|   0.37|  1765.0|    0.38|   2813.0|     0.60|  0.54|  0.53|  0.39|  0.64|  0.39|  0.64|   0.03|  0.99|  -0.60|  0.01|  0.25|   0.09|
| cholest     | age       | \[35,51)       |   4666.0|   727.0|   1117.0|  1135.0|   1687.0|   1844.0|   0.40|  1862.0|    0.40|   2979.0|     0.64|  0.52|  0.52|  0.39|  0.60|  0.39|  0.60|  -0.01|  0.99|  -0.66|  0.00|  0.21|   0.03|
| cholest     | age       | \[51,65)       |   4668.0|   761.0|   1088.0|  1109.0|   1710.0|   1849.0|   0.40|  1870.0|    0.40|   2958.0|     0.63|  0.53|  0.52|  0.41|  0.61|  0.41|  0.61|   0.02|  0.99|  -0.66|  0.00|  0.20|   0.06|
| cholest     | all       | all            |  14000.0|  2177.0|   3253.0|  3320.0|   5250.0|   5430.0|   0.39|  5497.0|    0.39|   8750.0|     0.62|  0.53|  0.52|  0.40|  0.62|  0.40|  0.62|   0.01|  0.99|  -0.64|  0.00|  0.22|   0.06|
| cholest     | ethnicity | Hispanic       |   1426.8|   220.6|    337.6|   350.0|    518.6|    558.2|   0.39|   570.6|    0.40|    908.2|     0.64|  0.52|  0.52|  0.39|  0.60|  0.39|  0.61|  -0.01|  0.98|  -0.65|  0.01|  0.21|   0.04|
| cholest     | ethnicity | NH Other       |   2209.0|   362.6|    487.4|   502.6|    856.4|    850.0|   0.38|   865.2|    0.39|   1352.6|     0.61|  0.55|  0.52|  0.42|  0.63|  0.42|  0.64|   0.06|  0.99|  -0.63|  0.01|  0.22|   0.10|
| cholest     | ethnicity | NH White       |  10364.2|  1593.8|   2428.0|  2467.4|   3875.0|   4021.8|   0.39|  4061.2|    0.39|   6489.2|     0.63|  0.53|  0.52|  0.39|  0.61|  0.39|  0.61|   0.01|  0.99|  -0.64|  0.00|  0.22|   0.06|
| cholest     | fpl       | &lt;=138% FPL  |  13111.2|  2050.2|   3037.8|  3107.2|   4916.0|   5088.0|   0.39|  5157.4|    0.39|   8195.2|     0.63|  0.53|  0.52|  0.40|  0.62|  0.40|  0.62|   0.02|  0.99|  -0.64|  0.01|  0.22|   0.06|
| cholest     | fpl       | &gt;138% FPL   |    888.8|   126.8|    215.2|   212.8|    334.0|    342.0|   0.38|   339.6|    0.38|    554.8|     0.62|  0.52|  0.53|  0.37|  0.61|  0.37|  0.61|  -0.02|  0.98|  -0.62|  0.01|  0.23|   0.04|
| cholest     | language  | English        |  11897.0|  1846.0|   2776.0|  2824.0|   4451.0|   4622.0|   0.39|  4670.0|    0.39|   7446.0|     0.63|  0.53|  0.52|  0.40|  0.61|  0.40|  0.62|   0.01|  0.99|  -0.64|  0.00|  0.22|   0.06|
| cholest     | language  | Other          |   1391.0|   211.0|    303.0|   323.0|    554.0|    514.0|   0.37|   534.0|    0.38|    837.0|     0.60|  0.55|  0.53|  0.40|  0.64|  0.40|  0.65|   0.04|  0.97|  -0.60|  0.01|  0.25|   0.10|
| cholest     | language  | Spanish        |    712.0|   120.0|    174.0|   173.0|    245.0|    294.0|   0.41|   293.0|    0.41|    467.0|     0.66|  0.51|  0.52|  0.41|  0.59|  0.41|  0.58|  -0.01|  1.00|  -0.70|  0.00|  0.18|   0.03|
| cholest     | race      | AIAN           |    277.2|    50.6|     55.2|    63.8|    107.6|    105.8|   0.38|   114.4|    0.41|    169.6|     0.61|  0.57|  0.52|  0.46|  0.64|  0.44|  0.66|   0.10|  0.94|  -0.66|  0.03|  0.21|   0.14|
| cholest     | race      | API            |    731.4|   115.8|    192.0|   137.6|    286.0|    307.8|   0.42|   253.4|    0.35|    445.4|     0.61|  0.55|  0.52|  0.41|  0.63|  0.46|  0.60|   0.05|  0.84|  -0.61|  0.07|  0.23|   0.10|
| cholest     | race      | Black          |   1463.4|   214.2|    341.6|   367.0|    540.6|    555.8|   0.38|   581.2|    0.40|    922.8|     0.63|  0.52|  0.52|  0.38|  0.60|  0.37|  0.61|  -0.02|  0.96|  -0.63|  0.02|  0.22|   0.03|
| cholest     | race      | Multiple Races |    154.8|    16.6|     31.4|    38.8|     68.0|     48.0|   0.31|    55.4|    0.36|     86.8|     0.56|  0.55|  0.55|  0.32|  0.66|  0.30|  0.68|  -0.02|  0.89|  -0.50|  0.05|  0.33|   0.09|
| cholest     | race      | White          |  11373.2|  1779.8|   2632.8|  2712.8|   4247.8|   4412.6|   0.39|  4492.6|    0.40|   7125.4|     0.63|  0.53|  0.52|  0.40|  0.61|  0.40|  0.62|   0.01|  0.99|  -0.64|  0.01|  0.22|   0.06|
| cholest     | sex       | F              |   9144.0|  1427.0|   2104.0|  2176.0|   3437.0|   3531.0|   0.39|  3603.0|    0.39|   5707.0|     0.62|  0.53|  0.52|  0.40|  0.62|  0.40|  0.62|   0.02|  0.98|  -0.64|  0.01|  0.22|   0.06|
| cholest     | sex       | M              |   4856.0|   750.0|   1149.0|  1144.0|   1813.0|   1899.0|   0.39|  1894.0|    0.39|   3043.0|     0.63|  0.53|  0.52|  0.40|  0.61|  0.40|  0.61|   0.01|  1.00|  -0.64|  0.00|  0.22|   0.06|
| colon       | age       | \[19,35)       |   4666.0|     0.0|      0.0|     0.0|   4666.0|      0.0|   0.00|     0.0|    0.00|      0.0|     0.00|  1.00|  1.00|   NaN|  1.00|   NaN|  1.00|    NaN|   NaN|    NaN|  0.00|  1.00|   1.00|
| colon       | age       | \[35,51)       |   4666.0|    25.0|     56.0|    62.0|   4523.0|     81.0|   0.02|    87.0|    0.02|    143.0|     0.03|  0.97|  0.96|  0.30|  0.99|  0.29|  0.99|   0.28|  0.96|  -0.02|  0.00|  0.96|   0.95|
| colon       | age       | \[51,65)       |   4668.0|   434.0|    948.0|  1028.0|   2258.0|   1382.0|   0.30|  1462.0|    0.31|   2410.0|     0.52|  0.58|  0.58|  0.31|  0.70|  0.30|  0.70|   0.00|  0.96|  -0.44|  0.02|  0.39|   0.15|
| colon       | all       | all            |  14000.0|   459.0|   1004.0|  1090.0|  11447.0|   1463.0|   0.10|  1549.0|    0.11|   2553.0|     0.18|  0.85|  0.81|  0.30|  0.92|  0.30|  0.92|   0.22|  0.97|  -0.12|  0.01|  0.78|   0.70|
| colon       | ethnicity | Hispanic       |   1426.8|    56.0|    109.2|    87.2|   1174.4|    165.2|   0.12|   143.2|    0.10|    252.4|     0.18|  0.86|  0.81|  0.36|  0.92|  0.39|  0.91|   0.29|  0.92|  -0.12|  0.02|  0.78|   0.72|
| colon       | ethnicity | NH Other       |   2209.0|    59.0|    157.6|   195.8|   1796.6|    216.6|   0.10|   254.8|    0.12|    412.4|     0.19|  0.84|  0.81|  0.25|  0.91|  0.23|  0.92|   0.16|  0.91|  -0.12|  0.02|  0.79|   0.68|
| colon       | ethnicity | NH White       |  10364.2|   344.0|    737.2|   807.0|   8476.0|   1081.2|   0.10|  1151.0|    0.11|   1888.2|     0.18|  0.85|  0.81|  0.31|  0.92|  0.30|  0.92|   0.22|  0.96|  -0.12|  0.01|  0.78|   0.70|
| colon       | fpl       | &lt;=138% FPL  |  13111.2|   430.0|    943.4|  1017.4|  10720.4|   1373.4|   0.10|  1447.4|    0.11|   2390.8|     0.18|  0.85|  0.81|  0.30|  0.92|  0.30|  0.92|   0.22|  0.97|  -0.12|  0.01|  0.78|   0.70|
| colon       | fpl       | &gt;138% FPL   |    888.8|    29.0|     60.6|    72.6|    726.6|     89.6|   0.10|   101.6|    0.11|    162.2|     0.18|  0.85|  0.81|  0.30|  0.92|  0.29|  0.92|   0.22|  0.93|  -0.12|  0.01|  0.78|   0.70|
| colon       | language  | English        |  11897.0|   395.0|    850.0|   939.0|   9713.0|   1245.0|   0.10|  1334.0|    0.11|   2184.0|     0.18|  0.85|  0.81|  0.31|  0.92|  0.30|  0.92|   0.22|  0.96|  -0.12|  0.01|  0.78|   0.70|
| colon       | language  | Other          |   1391.0|    48.0|     93.0|    96.0|   1154.0|    141.0|   0.10|   144.0|    0.10|    237.0|     0.17|  0.86|  0.82|  0.34|  0.92|  0.33|  0.93|   0.26|  0.99|  -0.11|  0.00|  0.80|   0.73|
| colon       | language  | Spanish        |    712.0|    16.0|     61.0|    55.0|    580.0|     77.0|   0.11|    71.0|    0.10|    132.0|     0.19|  0.84|  0.81|  0.22|  0.91|  0.23|  0.90|   0.13|  0.95|  -0.12|  0.01|  0.79|   0.67|
| colon       | race      | AIAN           |    277.2|     9.6|     17.2|    20.6|    229.8|     26.8|   0.10|    30.2|    0.11|     47.4|     0.17|  0.86|  0.82|  0.34|  0.92|  0.32|  0.93|   0.26|  0.93|  -0.11|  0.01|  0.79|   0.73|
| colon       | race      | API            |    731.4|    16.6|     48.6|    53.0|    613.2|     65.2|   0.09|    69.6|    0.10|    118.2|     0.16|  0.86|  0.83|  0.25|  0.92|  0.24|  0.93|   0.17|  0.96|  -0.10|  0.01|  0.82|   0.72|
| colon       | race      | Black          |   1463.4|    34.6|    105.6|   115.4|   1207.8|    140.2|   0.10|   150.0|    0.10|    255.6|     0.17|  0.85|  0.82|  0.24|  0.92|  0.23|  0.92|   0.15|  0.96|  -0.11|  0.01|  0.80|   0.70|
| colon       | race      | Multiple Races |    154.8|     2.6|     13.8|    17.0|    121.4|     16.4|   0.11|    19.6|    0.13|     33.4|     0.22|  0.80|  0.79|  0.14|  0.89|  0.13|  0.90|   0.03|  0.90|  -0.13|  0.02|  0.77|   0.60|
| colon       | race      | White          |  11373.2|   395.6|    818.8|   884.0|   9274.8|   1214.4|   0.11|  1279.6|    0.11|   2098.4|     0.18|  0.85|  0.80|  0.32|  0.92|  0.31|  0.92|   0.23|  0.97|  -0.12|  0.01|  0.78|   0.70|
| colon       | sex       | F              |   9144.0|   303.0|    673.0|   712.0|   7456.0|    976.0|   0.11|  1015.0|    0.11|   1688.0|     0.18|  0.85|  0.81|  0.30|  0.92|  0.30|  0.92|   0.22|  0.98|  -0.12|  0.00|  0.78|   0.70|
| colon       | sex       | M              |   4856.0|   156.0|    331.0|   378.0|   3991.0|    487.0|   0.10|   534.0|    0.11|    865.0|     0.18|  0.85|  0.81|  0.31|  0.92|  0.29|  0.92|   0.22|  0.95|  -0.12|  0.01|  0.79|   0.71|
| colonoscopy | age       | \[19,35)       |   4666.0|     0.0|      0.0|     0.0|   4666.0|      0.0|   0.00|     0.0|    0.00|      0.0|     0.00|  1.00|  1.00|   NaN|  1.00|   NaN|  1.00|    NaN|   NaN|    NaN|  0.00|  1.00|   1.00|
| colonoscopy | age       | \[35,51)       |   4666.0|     4.0|     24.0|    23.0|   4615.0|     28.0|   0.01|    27.0|    0.01|     51.0|     0.01|  0.99|  0.99|  0.15|  0.99|  0.15|  0.99|   0.14|  0.98|  -0.01|  0.00|  0.99|   0.98|
| colonoscopy | age       | \[51,65)       |   4668.0|    42.0|    423.0|   441.0|   3762.0|    465.0|   0.10|   483.0|    0.10|    906.0|     0.19|  0.81|  0.82|  0.09|  0.90|  0.09|  0.90|  -0.01|  0.98|  -0.11|  0.00|  0.80|   0.63|
| colonoscopy | all       | all            |  14000.0|    46.0|    447.0|   464.0|  13043.0|    493.0|   0.04|   510.0|    0.04|    957.0|     0.07|  0.93|  0.93|  0.09|  0.97|  0.09|  0.97|   0.06|  0.98|  -0.04|  0.00|  0.93|   0.87|
| colonoscopy | ethnicity | Hispanic       |   1426.8|     3.0|     50.8|    53.0|   1320.0|     53.8|   0.04|    56.0|    0.04|    106.8|     0.07|  0.93|  0.93|  0.05|  0.96|  0.05|  0.96|   0.02|  0.98|  -0.04|  0.00|  0.92|   0.85|
| colonoscopy | ethnicity | NH Other       |   2209.0|     5.0|     47.6|    78.4|   2078.0|     52.6|   0.02|    83.4|    0.04|    131.0|     0.06|  0.94|  0.94|  0.07|  0.97|  0.06|  0.98|   0.05|  0.77|  -0.03|  0.01|  0.94|   0.89|
| colonoscopy | ethnicity | NH White       |  10364.2|    38.0|    348.6|   332.6|   9645.0|    386.6|   0.04|   370.6|    0.04|    719.2|     0.07|  0.93|  0.93|  0.10|  0.97|  0.10|  0.97|   0.07|  0.98|  -0.04|  0.00|  0.93|   0.87|
| colonoscopy | fpl       | &lt;=138% FPL  |  13111.2|    42.8|    409.8|   431.0|  12227.6|    452.6|   0.03|   473.8|    0.04|    883.6|     0.07|  0.94|  0.93|  0.09|  0.97|  0.09|  0.97|   0.06|  0.98|  -0.04|  0.00|  0.93|   0.87|
| colonoscopy | fpl       | &gt;138% FPL   |    888.8|     3.2|     37.2|    33.0|    815.4|     40.4|   0.05|    36.2|    0.04|     73.4|     0.08|  0.92|  0.92|  0.08|  0.96|  0.09|  0.96|   0.04|  0.91|  -0.04|  0.01|  0.91|   0.84|
| colonoscopy | language  | English        |  11897.0|    40.0|    378.0|   410.0|  11069.0|    418.0|   0.04|   450.0|    0.04|    828.0|     0.07|  0.93|  0.93|  0.09|  0.97|  0.09|  0.97|   0.06|  0.96|  -0.04|  0.00|  0.93|   0.87|
| colonoscopy | language  | Other          |   1391.0|     4.0|     47.0|    37.0|   1303.0|     51.0|   0.04|    41.0|    0.03|     88.0|     0.06|  0.94|  0.94|  0.09|  0.97|  0.10|  0.97|   0.06|  0.89|  -0.03|  0.01|  0.93|   0.88|
| colonoscopy | language  | Spanish        |    712.0|     2.0|     22.0|    17.0|    671.0|     24.0|   0.03|    19.0|    0.03|     41.0|     0.06|  0.95|  0.94|  0.09|  0.97|  0.11|  0.97|   0.07|  0.88|  -0.03|  0.01|  0.94|   0.89|
| colonoscopy | race      | AIAN           |    277.2|     0.2|     19.2|     7.2|    250.6|     19.4|   0.07|     7.4|    0.03|     26.6|     0.10|  0.90|  0.91|  0.01|  0.95|  0.02|  0.93|  -0.03|  0.53|  -0.04|  0.04|  0.90|   0.81|
| colonoscopy | race      | API            |    731.4|     1.0|     23.4|    22.4|    684.6|     24.4|   0.03|    23.4|    0.03|     46.8|     0.06|  0.94|  0.94|  0.04|  0.97|  0.04|  0.97|   0.01|  0.95|  -0.03|  0.00|  0.93|   0.87|
| colonoscopy | race      | Black          |   1463.4|     8.2|     43.4|    40.8|   1371.0|     51.6|   0.04|    49.0|    0.03|     92.4|     0.06|  0.94|  0.93|  0.16|  0.97|  0.17|  0.97|   0.13|  0.96|  -0.04|  0.00|  0.93|   0.88|
| colonoscopy | race      | Multiple Races |    154.8|     0.0|     10.4|     4.4|    140.0|     10.4|   0.07|     4.4|    0.03|     14.8|     0.10|  0.90|  0.91|  0.00|  0.95|  0.00|  0.93|  -0.04|  0.58|  -0.04|  0.04|  0.90|   0.81|
| colonoscopy | race      | White          |  11373.2|    36.6|    350.6|   389.2|  10596.8|    387.2|   0.03|   425.8|    0.04|    776.4|     0.07|  0.93|  0.93|  0.09|  0.97|  0.09|  0.97|   0.06|  0.95|  -0.04|  0.00|  0.93|   0.87|
| colonoscopy | sex       | F              |   9144.0|    30.0|    293.0|   296.0|   8525.0|    323.0|   0.04|   326.0|    0.04|    619.0|     0.07|  0.94|  0.93|  0.09|  0.97|  0.09|  0.97|   0.06|  1.00|  -0.04|  0.00|  0.93|   0.87|
| colonoscopy | sex       | M              |   4856.0|    16.0|    154.0|   168.0|   4518.0|    170.0|   0.04|   184.0|    0.04|    338.0|     0.07|  0.93|  0.93|  0.09|  0.97|  0.09|  0.97|   0.06|  0.96|  -0.04|  0.00|  0.93|   0.87|
| flexsig     | age       | \[19,35)       |   4666.0|     0.0|      0.0|     0.0|   4666.0|      0.0|   0.00|     0.0|    0.00|      0.0|     0.00|  1.00|  1.00|   NaN|  1.00|   NaN|  1.00|    NaN|   NaN|    NaN|  0.00|  1.00|   1.00|
| flexsig     | age       | \[35,51)       |   4666.0|     0.0|     16.0|    18.0|   4632.0|     16.0|   0.00|    18.0|    0.00|     34.0|     0.01|  0.99|  0.99|  0.00|  1.00|  0.00|  1.00|   0.00|  0.94|   0.00|  0.00|  0.99|   0.99|
| flexsig     | age       | \[51,65)       |   4668.0|    10.0|    199.0|   216.0|   4243.0|    209.0|   0.04|   226.0|    0.05|    425.0|     0.09|  0.91|  0.91|  0.05|  0.95|  0.04|  0.96|   0.00|  0.96|  -0.05|  0.00|  0.91|   0.82|
| flexsig     | all       | all            |  14000.0|    10.0|    215.0|   234.0|  13541.0|    225.0|   0.02|   244.0|    0.02|    459.0|     0.03|  0.97|  0.97|  0.04|  0.98|  0.04|  0.98|   0.03|  0.96|  -0.02|  0.00|  0.97|   0.94|
| flexsig     | ethnicity | Hispanic       |   1426.8|     1.2|     18.4|    32.0|   1375.2|     19.6|   0.01|    33.2|    0.02|     51.6|     0.04|  0.96|  0.96|  0.05|  0.98|  0.04|  0.99|   0.03|  0.74|  -0.02|  0.01|  0.96|   0.93|
| flexsig     | ethnicity | NH Other       |   2209.0|     2.2|     31.0|    39.2|   2136.6|     33.2|   0.02|    41.4|    0.02|     72.4|     0.03|  0.97|  0.97|  0.06|  0.98|  0.05|  0.99|   0.04|  0.89|  -0.02|  0.00|  0.97|   0.94|
| flexsig     | ethnicity | NH White       |  10364.2|     6.6|    165.6|   162.8|  10029.2|    172.2|   0.02|   169.4|    0.02|    335.0|     0.03|  0.97|  0.97|  0.04|  0.98|  0.04|  0.98|   0.02|  0.99|  -0.02|  0.00|  0.97|   0.94|
| flexsig     | fpl       | &lt;=138% FPL  |  13111.2|     9.8|    206.2|   220.2|  12675.0|    216.0|   0.02|   230.0|    0.02|    436.2|     0.03|  0.97|  0.97|  0.04|  0.98|  0.04|  0.98|   0.03|  0.97|  -0.02|  0.00|  0.97|   0.93|
| flexsig     | fpl       | &gt;138% FPL   |    888.8|     0.2|      8.8|    13.8|    866.0|      9.0|   0.01|    14.0|    0.02|     22.8|     0.03|  0.97|  0.97|  0.02|  0.99|  0.01|  0.99|   0.01|  0.77|  -0.01|  0.01|  0.97|   0.95|
| flexsig     | language  | English        |  11897.0|    10.0|    181.0|   201.0|  11505.0|    191.0|   0.02|   211.0|    0.02|    392.0|     0.03|  0.97|  0.97|  0.05|  0.98|  0.05|  0.98|   0.03|  0.95|  -0.02|  0.00|  0.97|   0.94|
| flexsig     | language  | Other          |   1391.0|     0.0|     21.0|    20.0|   1350.0|     21.0|   0.02|    20.0|    0.01|     41.0|     0.03|  0.97|  0.97|  0.00|  0.99|  0.00|  0.98|  -0.01|  0.98|  -0.01|  0.00|  0.97|   0.94|
| flexsig     | language  | Spanish        |    712.0|     0.0|     13.0|    13.0|    686.0|     13.0|   0.02|    13.0|    0.02|     26.0|     0.04|  0.96|  0.96|  0.00|  0.98|  0.00|  0.98|  -0.02|  1.00|  -0.02|  0.00|  0.96|   0.93|
| flexsig     | race      | AIAN           |    277.2|     1.0|      6.6|     3.0|    266.6|      7.6|   0.03|     4.0|    0.01|     10.6|     0.04|  0.97|  0.96|  0.17|  0.98|  0.25|  0.98|   0.16|  0.69|  -0.02|  0.01|  0.96|   0.93|
| flexsig     | race      | API            |    731.4|     0.0|     13.6|    11.0|    706.8|     13.6|   0.02|    11.0|    0.02|     24.6|     0.03|  0.97|  0.97|  0.00|  0.98|  0.00|  0.98|  -0.02|  0.89|  -0.02|  0.00|  0.97|   0.93|
| flexsig     | race      | Black          |   1463.4|     0.0|     17.8|    30.4|   1415.2|     17.8|   0.01|    30.4|    0.02|     48.2|     0.03|  0.97|  0.97|  0.00|  0.98|  0.00|  0.99|  -0.02|  0.73|  -0.02|  0.01|  0.97|   0.93|
| flexsig     | race      | Multiple Races |    154.8|     0.0|      4.2|     3.2|    147.4|      4.2|   0.03|     3.2|    0.02|      7.4|     0.05|  0.95|  0.95|  0.00|  0.98|  0.00|  0.97|  -0.02|  0.86|  -0.02|  0.01|  0.95|   0.90|
| flexsig     | race      | White          |  11373.2|     9.0|    172.8|   186.4|  11005.0|    181.8|   0.02|   195.4|    0.02|    368.2|     0.03|  0.97|  0.97|  0.05|  0.98|  0.05|  0.98|   0.03|  0.96|  -0.02|  0.00|  0.97|   0.94|
| flexsig     | sex       | F              |   9144.0|     4.0|    151.0|   151.0|   8838.0|    155.0|   0.02|   155.0|    0.02|    306.0|     0.03|  0.97|  0.97|  0.03|  0.98|  0.03|  0.98|   0.01|  1.00|  -0.02|  0.00|  0.97|   0.93|
| flexsig     | sex       | M              |   4856.0|     6.0|     64.0|    83.0|   4703.0|     70.0|   0.01|    89.0|    0.02|    153.0|     0.03|  0.97|  0.97|  0.08|  0.98|  0.07|  0.99|   0.06|  0.88|  -0.02|  0.00|  0.97|   0.94|
| flu         | age       | \[19,35)       |   4666.0|     0.0|      0.0|     0.0|   4666.0|      0.0|   0.00|     0.0|    0.00|      0.0|     0.00|  1.00|  1.00|   NaN|  1.00|   NaN|  1.00|    NaN|   NaN|    NaN|  0.00|  1.00|   1.00|
| flu         | age       | \[35,51)       |   4666.0|    42.0|     73.0|    67.0|   4484.0|    115.0|   0.02|   109.0|    0.02|    182.0|     0.04|  0.97|  0.95|  0.38|  0.98|  0.39|  0.98|   0.36|  0.97|  -0.02|  0.00|  0.95|   0.94|
| flu         | age       | \[51,65)       |   4668.0|   658.0|   1229.0|   973.0|   1808.0|   1887.0|   0.40|  1631.0|    0.35|   2860.0|     0.61|  0.53|  0.53|  0.37|  0.62|  0.40|  0.60|   0.00|  0.88|  -0.60|  0.05|  0.25|   0.06|
| flu         | all       | all            |  14000.0|   700.0|   1302.0|  1040.0|  10958.0|   2002.0|   0.14|  1740.0|    0.12|   3042.0|     0.22|  0.83|  0.77|  0.37|  0.90|  0.40|  0.89|   0.28|  0.92|  -0.15|  0.02|  0.73|   0.67|
| flu         | ethnicity | Hispanic       |   1426.8|    69.4|    143.2|    96.6|   1117.6|    212.6|   0.15|   166.0|    0.12|    309.2|     0.22|  0.83|  0.77|  0.37|  0.90|  0.42|  0.89|   0.27|  0.86|  -0.15|  0.03|  0.73|   0.66|
| flu         | ethnicity | NH Other       |   2209.0|   113.0|    199.0|   169.8|   1727.2|    312.0|   0.14|   282.8|    0.13|    481.8|     0.22|  0.83|  0.77|  0.38|  0.90|  0.40|  0.90|   0.28|  0.94|  -0.16|  0.01|  0.73|   0.67|
| flu         | ethnicity | NH White       |  10364.2|   517.6|    959.8|   773.6|   8113.2|   1477.4|   0.14|  1291.2|    0.12|   2251.0|     0.22|  0.83|  0.77|  0.37|  0.90|  0.40|  0.89|   0.28|  0.92|  -0.15|  0.02|  0.73|   0.67|
| flu         | fpl       | &lt;=138% FPL  |  13111.2|   654.6|   1212.6|   971.0|  10273.0|   1867.2|   0.14|  1625.6|    0.12|   2838.2|     0.22|  0.83|  0.77|  0.37|  0.90|  0.40|  0.89|   0.28|  0.92|  -0.15|  0.02|  0.73|   0.67|
| flu         | fpl       | &gt;138% FPL   |    888.8|    45.4|     89.4|    69.0|    685.0|    134.8|   0.15|   114.4|    0.13|    203.8|     0.23|  0.82|  0.76|  0.36|  0.90|  0.40|  0.88|   0.26|  0.90|  -0.16|  0.02|  0.72|   0.64|
| flu         | language  | English        |  11897.0|   597.0|   1115.0|   885.0|   9300.0|   1712.0|   0.14|  1482.0|    0.12|   2597.0|     0.22|  0.83|  0.77|  0.37|  0.90|  0.40|  0.89|   0.28|  0.92|  -0.15|  0.02|  0.73|   0.66|
| flu         | language  | Other          |   1391.0|    76.0|    115.0|   104.0|   1096.0|    191.0|   0.14|   180.0|    0.13|    295.0|     0.21|  0.84|  0.77|  0.41|  0.91|  0.42|  0.91|   0.32|  0.97|  -0.15|  0.01|  0.73|   0.69|
| flu         | language  | Spanish        |    712.0|    27.0|     72.0|    51.0|    562.0|     99.0|   0.14|    78.0|    0.11|    150.0|     0.21|  0.83|  0.78|  0.31|  0.90|  0.35|  0.89|   0.21|  0.86|  -0.14|  0.03|  0.75|   0.65|
| flu         | race      | AIAN           |    277.2|    14.2|     35.0|    20.8|    207.2|     49.2|   0.18|    35.0|    0.13|     70.0|     0.25|  0.80|  0.74|  0.34|  0.88|  0.41|  0.86|   0.22|  0.80|  -0.17|  0.05|  0.70|   0.60|
| flu         | race      | API            |    731.4|    39.6|     58.0|    56.2|    577.6|     97.6|   0.13|    95.8|    0.13|    153.8|     0.21|  0.84|  0.77|  0.41|  0.91|  0.41|  0.91|   0.32|  0.98|  -0.15|  0.01|  0.74|   0.69|
| flu         | race      | Black          |   1463.4|    63.0|    121.2|   100.2|   1179.0|    184.2|   0.13|   163.2|    0.11|    284.4|     0.19|  0.85|  0.79|  0.36|  0.91|  0.39|  0.91|   0.28|  0.93|  -0.13|  0.01|  0.76|   0.70|
| flu         | race      | Multiple Races |    154.8|     8.4|      9.8|    17.6|    119.0|     18.2|   0.12|    26.0|    0.17|     35.8|     0.23|  0.82|  0.75|  0.38|  0.90|  0.32|  0.92|   0.28|  0.79|  -0.16|  0.05|  0.71|   0.65|
| flu         | race      | White          |  11373.2|   574.8|   1078.0|   845.2|   8875.2|   1652.8|   0.15|  1420.0|    0.12|   2498.0|     0.22|  0.83|  0.77|  0.37|  0.90|  0.40|  0.89|   0.28|  0.91|  -0.16|  0.02|  0.73|   0.66|
| flu         | sex       | F              |   9144.0|   465.0|    839.0|   695.0|   7145.0|   1304.0|   0.14|  1160.0|    0.13|   1999.0|     0.22|  0.83|  0.77|  0.38|  0.90|  0.40|  0.89|   0.28|  0.93|  -0.16|  0.02|  0.73|   0.66|
| flu         | sex       | M              |   4856.0|   235.0|    463.0|   345.0|   3813.0|    698.0|   0.14|   580.0|    0.12|   1043.0|     0.21|  0.83|  0.77|  0.37|  0.90|  0.41|  0.89|   0.27|  0.89|  -0.15|  0.02|  0.74|   0.67|
| fobt        | age       | \[19,35)       |   4666.0|     0.0|      0.0|     0.0|   4666.0|      0.0|   0.00|     0.0|    0.00|      0.0|     0.00|  1.00|  1.00|   NaN|  1.00|   NaN|  1.00|    NaN|   NaN|    NaN|  0.00|  1.00|   1.00|
| fobt        | age       | \[35,51)       |   4666.0|    19.0|     64.0|    29.0|   4554.0|     83.0|   0.02|    48.0|    0.01|    112.0|     0.02|  0.98|  0.97|  0.29|  0.99|  0.40|  0.99|   0.28|  0.73|  -0.01|  0.01|  0.97|   0.96|
| fobt        | age       | \[51,65)       |   4668.0|   199.0|   1191.0|   510.0|   2768.0|   1390.0|   0.30|   709.0|    0.15|   1900.0|     0.41|  0.64|  0.64|  0.19|  0.76|  0.28|  0.70|  -0.01|  0.59|  -0.25|  0.15|  0.55|   0.27|
| fobt        | all       | all            |  14000.0|   218.0|   1255.0|   539.0|  11988.0|   1473.0|   0.11|   757.0|    0.05|   2012.0|     0.14|  0.87|  0.85|  0.20|  0.93|  0.29|  0.91|   0.13|  0.65|  -0.08|  0.05|  0.84|   0.74|
| fobt        | ethnicity | Hispanic       |   1426.8|    25.6|    135.8|    60.6|   1204.8|    161.4|   0.11|    86.2|    0.06|    222.0|     0.16|  0.86|  0.84|  0.21|  0.92|  0.30|  0.90|   0.14|  0.67|  -0.09|  0.05|  0.83|   0.72|
| fobt        | ethnicity | NH Other       |   2209.0|    39.0|    173.8|    95.4|   1900.8|    212.8|   0.10|   134.4|    0.06|    308.2|     0.14|  0.88|  0.85|  0.22|  0.93|  0.29|  0.92|   0.16|  0.76|  -0.08|  0.04|  0.84|   0.76|
| fobt        | ethnicity | NH White       |  10364.2|   153.4|    945.4|   383.0|   8882.4|   1098.8|   0.11|   536.4|    0.05|   1481.8|     0.14|  0.87|  0.85|  0.19|  0.93|  0.29|  0.90|   0.13|  0.63|  -0.07|  0.05|  0.84|   0.74|
| fobt        | fpl       | &lt;=138% FPL  |  13111.2|   209.6|   1174.8|   509.2|  11217.6|   1384.4|   0.11|   718.8|    0.05|   1893.6|     0.14|  0.87|  0.85|  0.20|  0.93|  0.29|  0.91|   0.14|  0.66|  -0.08|  0.05|  0.84|   0.74|
| fobt        | fpl       | &gt;138% FPL   |    888.8|     8.4|     80.2|    29.8|    770.4|     88.6|   0.10|    38.2|    0.04|    118.4|     0.13|  0.88|  0.87|  0.13|  0.93|  0.22|  0.91|   0.08|  0.58|  -0.06|  0.06|  0.86|   0.75|
| fobt        | language  | English        |  11897.0|   188.0|   1083.0|   465.0|  10161.0|   1271.0|   0.11|   653.0|    0.05|   1736.0|     0.15|  0.87|  0.85|  0.20|  0.93|  0.29|  0.90|   0.13|  0.65|  -0.08|  0.05|  0.84|   0.74|
| fobt        | language  | Other          |   1391.0|    23.0|    117.0|    50.0|   1201.0|    140.0|   0.10|    73.0|    0.05|    190.0|     0.14|  0.88|  0.86|  0.22|  0.93|  0.32|  0.91|   0.16|  0.66|  -0.07|  0.05|  0.85|   0.76|
| fobt        | language  | Spanish        |    712.0|     7.0|     55.0|    24.0|    626.0|     62.0|   0.09|    31.0|    0.04|     86.0|     0.12|  0.89|  0.88|  0.15|  0.94|  0.23|  0.92|   0.10|  0.65|  -0.06|  0.04|  0.87|   0.78|
| fobt        | race      | AIAN           |    277.2|     9.4|     24.8|    14.8|    228.2|     34.2|   0.12|    24.2|    0.09|     49.0|     0.18|  0.86|  0.81|  0.32|  0.92|  0.39|  0.90|   0.24|  0.81|  -0.11|  0.04|  0.79|   0.71|
| fobt        | race      | API            |    731.4|    13.4|     59.6|    30.4|    628.0|     73.0|   0.10|    43.8|    0.06|    103.4|     0.14|  0.88|  0.85|  0.23|  0.93|  0.31|  0.91|   0.17|  0.73|  -0.08|  0.04|  0.84|   0.75|
| fobt        | race      | Black          |   1463.4|    19.2|    144.0|    58.8|   1241.4|    163.2|   0.11|    78.0|    0.05|    222.0|     0.15|  0.86|  0.85|  0.16|  0.92|  0.25|  0.90|   0.09|  0.62|  -0.08|  0.06|  0.84|   0.72|
| fobt        | race      | Multiple Races |    154.8|     1.0|      9.0|     7.4|    137.4|     10.0|   0.06|     8.4|    0.05|     17.4|     0.11|  0.89|  0.89|  0.11|  0.94|  0.12|  0.94|   0.05|  0.91|  -0.06|  0.01|  0.88|   0.79|
| fobt        | race      | White          |  11373.2|   175.0|   1017.6|   427.6|   9753.0|   1192.6|   0.10|   602.6|    0.05|   1620.2|     0.14|  0.87|  0.85|  0.19|  0.93|  0.29|  0.91|   0.13|  0.65|  -0.08|  0.05|  0.84|   0.75|
| fobt        | sex       | F              |   9144.0|   151.0|    811.0|   355.0|   7827.0|    962.0|   0.11|   506.0|    0.06|   1317.0|     0.14|  0.87|  0.85|  0.21|  0.93|  0.30|  0.91|   0.14|  0.67|  -0.08|  0.05|  0.84|   0.74|
| fobt        | sex       | M              |   4856.0|    67.0|    444.0|   184.0|   4161.0|    511.0|   0.11|   251.0|    0.05|    695.0|     0.14|  0.87|  0.85|  0.18|  0.93|  0.27|  0.90|   0.11|  0.63|  -0.07|  0.05|  0.84|   0.74|
| smoking     | age       | \[19,35)       |   4666.0|   204.0|   4225.0|    15.0|    222.0|   4429.0|   0.95|   219.0|    0.05|   4444.0|     0.95|  0.09|  0.09|  0.09|  0.09|  0.93|  0.05|   0.00|  0.01|  -0.10|  0.90|  0.00|  -0.82|
| smoking     | age       | \[35,51)       |   4666.0|   236.0|   4187.0|    11.0|    232.0|   4423.0|   0.95|   247.0|    0.05|   4434.0|     0.95|  0.10|  0.10|  0.10|  0.10|  0.96|  0.05|   0.00|  0.01|  -0.11|  0.89|  0.00|  -0.80|
| smoking     | age       | \[51,65)       |   4668.0|   239.0|   4189.0|    10.0|    230.0|   4428.0|   0.95|   249.0|    0.05|   4438.0|     0.95|  0.10|  0.10|  0.10|  0.10|  0.96|  0.05|   0.00|  0.01|  -0.11|  0.90|  0.00|  -0.80|
| smoking     | all       | all            |  14000.0|   679.0|  12601.0|    36.0|    684.0|  13280.0|   0.95|   715.0|    0.05|  13316.0|     0.95|  0.10|  0.10|  0.10|  0.10|  0.95|  0.05|   0.00|  0.01|  -0.11|  0.90|  0.00|  -0.81|
| smoking     | ethnicity | Hispanic       |   1426.8|    55.6|   1298.2|     1.6|     71.4|   1353.8|   0.95|    57.2|    0.04|   1355.4|     0.95|  0.09|  0.09|  0.08|  0.10|  0.97|  0.05|   0.00|  0.00|  -0.08|  0.91|  0.01|  -0.82|
| smoking     | ethnicity | NH Other       |   2209.0|   106.0|   1989.0|     5.0|    109.0|   2095.0|   0.95|   111.0|    0.05|   2100.0|     0.95|  0.10|  0.10|  0.10|  0.10|  0.95|  0.05|   0.00|  0.01|  -0.11|  0.90|  0.00|  -0.81|
| smoking     | ethnicity | NH White       |  10364.2|   517.4|   9313.8|    29.4|    503.6|   9831.2|   0.95|   546.8|    0.05|   9860.6|     0.95|  0.10|  0.10|  0.10|  0.10|  0.95|  0.05|   0.00|  0.01|  -0.11|  0.90|  0.00|  -0.80|
| smoking     | fpl       | &lt;=138% FPL  |  13111.2|   641.4|  11804.4|    32.8|    632.6|  12445.8|   0.95|   674.2|    0.05|  12478.6|     0.95|  0.10|  0.10|  0.10|  0.10|  0.95|  0.05|   0.00|  0.01|  -0.11|  0.90|  0.00|  -0.81|
| smoking     | fpl       | &gt;138% FPL   |    888.8|    37.6|    796.6|     3.2|     51.4|    834.2|   0.94|    40.8|    0.05|    837.4|     0.94|  0.10|  0.10|  0.09|  0.11|  0.92|  0.06|   0.00|  0.01|  -0.10|  0.89|  0.02|  -0.80|
| smoking     | language  | English        |  11897.0|   583.0|  10712.0|    28.0|    574.0|  11295.0|   0.95|   611.0|    0.05|  11323.0|     0.95|  0.10|  0.10|  0.10|  0.10|  0.95|  0.05|   0.00|  0.01|  -0.11|  0.90|  0.00|  -0.81|
| smoking     | language  | Other          |   1391.0|    68.0|   1250.0|     3.0|     70.0|   1318.0|   0.95|    71.0|    0.05|   1321.0|     0.95|  0.10|  0.10|  0.10|  0.10|  0.96|  0.05|   0.00|  0.01|  -0.11|  0.90|  0.00|  -0.80|
| smoking     | language  | Spanish        |    712.0|    28.0|    639.0|     5.0|     40.0|    667.0|   0.94|    33.0|    0.05|    672.0|     0.94|  0.10|  0.10|  0.08|  0.11|  0.85|  0.06|  -0.01|  0.01|  -0.10|  0.89|  0.02|  -0.81|
| smoking     | race      | AIAN           |    277.2|     9.2|    254.8|     0.0|     13.2|    264.0|   0.95|     9.2|    0.03|    264.0|     0.95|  0.08|  0.08|  0.07|  0.09|  1.00|  0.05|   0.00|  0.00|  -0.07|  0.92|  0.01|  -0.84|
| smoking     | race      | API            |    731.4|    35.2|    656.6|     4.2|     35.4|    691.8|   0.95|    39.4|    0.05|    696.0|     0.95|  0.10|  0.10|  0.10|  0.10|  0.89|  0.05|  -0.01|  0.01|  -0.11|  0.89|  0.00|  -0.81|
| smoking     | race      | Black          |   1463.4|    77.2|   1313.0|     1.6|     71.6|   1390.2|   0.95|    78.8|    0.05|   1391.8|     0.95|  0.10|  0.10|  0.11|  0.10|  0.98|  0.05|   0.00|  0.01|  -0.10|  0.90|  0.00|  -0.80|
| smoking     | race      | Multiple Races |    154.8|     5.6|    139.6|     0.0|      9.6|    145.2|   0.94|     5.6|    0.04|    145.2|     0.94|  0.10|  0.09|  0.07|  0.12|  1.00|  0.06|   0.00|  0.00|  -0.07|  0.90|  0.03|  -0.80|
| smoking     | race      | White          |  11373.2|   551.8|  10237.0|    30.2|    554.2|  10788.8|   0.95|   582.0|    0.05|  10819.0|     0.95|  0.10|  0.10|  0.10|  0.10|  0.95|  0.05|   0.00|  0.01|  -0.11|  0.90|  0.00|  -0.81|
| smoking     | sex       | F              |   9144.0|   436.0|   8250.0|    23.0|    435.0|   8686.0|   0.95|   459.0|    0.05|   8709.0|     0.95|  0.10|  0.10|  0.10|  0.10|  0.95|  0.05|   0.00|  0.01|  -0.11|  0.90|  0.00|  -0.81|
| smoking     | sex       | M              |   4856.0|   243.0|   4351.0|    13.0|    249.0|   4594.0|   0.95|   256.0|    0.05|   4607.0|     0.95|  0.10|  0.10|  0.10|  0.10|  0.95|  0.05|   0.00|  0.01|  -0.11|  0.89|  0.00|  -0.80|

Well, the procedures and the categories need should be arranged differently for formal presentation. But that's pretty straightforward so I hope that you forgive me for stopping here. Thanks for reading!

Check the run time
==================

I saved an object above when this all started to run. Now I want to see how long it took.

``` r
end_time <- Sys.time()

lubridate::as.period(
  lubridate::interval(start_time, end_time)
  )
```

    [1] "7M 40.9540002346039S"
