
<!-- README.md is generated from README.Rmd. Please edit that file -->
*gwasforest*
============

<!-- badges: start -->
<!-- badges: end -->
The goal of ***gwasforest*** is to extract and reform data from GWAS results, and then make a single integrated forest plot containing multiple windows of which each shows the result of individual SNPs (or other items of interest).

Installation
------------

The official release version of ***gwasforest*** can be installed from CRAN with:

``` r
utils::install.packages("gwasforest")
```

The development version of ***gwasforest*** can be installed from GitHub with:

``` r
devtools::install_github("yilixu/gwasforest", ref = "main")
```

Quick Demos
-----------

-   **( 1 )** when **customFilename** (main input) is in dataframe format (with standardized column names):

``` r
library(gwasforest)
set.seed(123)

# generate example data
tempValue = runif(n = 18, min = 0.01, max = 2)
tempStdErr = tempValue / rep(3:5, times = 6)
eg_customFilename = data.frame(paste0("Marker", 1:6), tempValue[1:6], tempStdErr[1:6], tempValue[7:12], tempStdErr[7:12], tempValue[13:18], tempStdErr[13:18], stringsAsFactors = FALSE)
colnames(eg_customFilename) = c("MarkerName", paste0(rep("Study", times = 6), rep(1:3, each = 2), rep(c("__Value", "__StdErr"), times = 3)))
rm(tempValue, tempStdErr)

# take a quick look at the example: main input data (with standardized column names)
print(eg_customFilename)
#>   MarkerName Study1__Value Study1__StdErr Study2__Value Study2__StdErr
#> 1    Marker1     0.5822793     0.19409309     1.0609299      0.3536433
#> 2    Marker2     1.5787272     0.39468180     1.7859139      0.4464785
#> 3    Marker3     0.8238641     0.16477281     1.1073557      0.2214711
#> 4    Marker4     1.7672046     0.58906821     0.9186633      0.3062211
#> 5    Marker5     1.8815299     0.47038247     1.9140984      0.4785246
#> 6    Marker6     0.1006574     0.02013149     0.9121350      0.1824270
#>   Study3__Value Study3__StdErr
#> 1    1.35836556     0.45278852
#> 2    1.14954047     0.28738512
#> 3    0.21482012     0.04296402
#> 4    1.80065169     0.60021723
#> 5    0.49971459     0.12492865
#> 6    0.09369847     0.01873969
```

``` r
# run gwasforest function
eg_returnList = gwasforest(eg_customFilename, stdColnames = TRUE, valueFormat = "Effect", metaStudy = "Study1", colorMode = "duo")
#> [1] "Column names are in the same format as instruction example"
#> [1] "Loading user-provided values"
#> [1] "Start calculating Confidence Interval (non-exponential)"
#> [1] "Based on user's choice, GWAS results output file will not be generated"
#> [1] "All studies except meta study will be set in alphabetical order from top to bottom on the forest plot"
#> Registered S3 methods overwritten by 'ggplot2':
#>   method         from 
#>   [.quosures     rlang
#>   c.quosures     rlang
#>   print.quosures rlang
#> [1] "Based on user's choice, GWAS forest plot file will not be generated"
#> [1] "Run completed, thank you for using gwasforest"
```

-   **( 2 )** when **customFilename** is in dataframe format (without standardized column names), while **customFilename\_studyName** is provided in dataframe format:

``` r
# generate example data
tempValue = runif(n = 18, min = 0.01, max = 2)
tempStdErr = tempValue / rep(3:5, times = 6)
eg_customFilename2 = data.frame(paste0("Marker", 1:6), tempValue[1:6], tempStdErr[1:6], tempValue[7:12], tempStdErr[7:12], tempValue[13:18], tempStdErr[13:18], stringsAsFactors = FALSE)
colnames(eg_customFilename2) = c("MarkerName", paste0(rep("Study", times = 6), rep(1:3, each = 2), sample(LETTERS, 6)))
rm(tempValue, tempStdErr)
eg_customFilename_studyName = data.frame("studyName" = paste0("Study", 1:3), stringsAsFactors = FALSE)

# take a quick look at the example: main input data (without standardized column names)
print(eg_customFilename2)
#>   MarkerName   Study1K   Study1G   Study2U    Study2L    Study3O
#> 1    Marker1 0.6625622 0.2208541 1.3148545 0.43828485 1.92641822
#> 2    Marker2 1.9094623 0.4773656 1.4199756 0.35499391 1.80557510
#> 3    Marker3 1.7801832 0.3560366 1.0926914 0.21853828 1.38450350
#> 4    Marker4 1.3886788 0.4628929 1.1923426 0.39744754 1.59298016
#> 5    Marker5 1.2846086 0.3211521 0.5854279 0.14635697 0.05898123
#> 6    Marker6 1.9885969 0.3977194 0.3027562 0.06055123 0.96081398
#>      Study3J
#> 1 0.64213941
#> 2 0.45139377
#> 3 0.27690070
#> 4 0.53099339
#> 5 0.01474531
#> 6 0.19216280

# take a quick look at the example: custom study name
print(eg_customFilename_studyName)
#>   studyName
#> 1    Study1
#> 2    Study2
#> 3    Study3
```

``` r
# run gwasforest function
eg_returnList = gwasforest(eg_customFilename2, customFilename_studyName = eg_customFilename_studyName, stdColnames = FALSE, customColnames = c("Value", "StdErr"), valueFormat = "Effect", metaStudy = "Study1", colorMode = "duo")
#> [1] "Column names are grouped by study and in the order of |Value, StdErr|"
#> [1] "Start reforming"
#> [1] "Loading user-provided values"
#> [1] "Start calculating Confidence Interval (non-exponential)"
#> [1] "Based on user's choice, GWAS results output file will not be generated"
#> [1] "As per user's request, all studies except meta study will be set in the original order from top to bottom on the forest plot"
#> [1] "Based on user's choice, GWAS forest plot file will not be generated"
#> [1] "Run completed, thank you for using gwasforest"
```

-   **( 3 )** when **customFilename\_results** is in dataframe format (run either of the two steps above to see the example results):

``` r
# extract results table
eg_customFilename_results = eg_returnList[[1]]

# take a quick look at the example: results table
print(eg_customFilename_results)
#>    MarkerName Value      Upper      Lower StudyName              CI
#> 1     Marker1  0.66 1.09543622 0.22968824    Study1  0.66(0.23-1.1)
#> 2     Marker2  1.91 2.84509877 0.97382575    Study1 1.91(0.97-2.85)
#> 3     Marker3  1.78 2.47801507 1.08235141    Study1 1.78(1.08-2.48)
#> 4     Marker4  1.39 2.29594891 0.48140864    Study1  1.39(0.48-2.3)
#> 5     Marker5  1.28 1.91406675 0.65515037    Study1 1.28(0.66-1.91)
#> 6     Marker6  1.99 2.76812682 1.20906689    Study1 1.99(1.21-2.77)
#> 7     Marker1  1.31 2.17389284 0.45581624    Study2 1.31(0.46-2.17)
#> 8     Marker2  1.42 2.11576369 0.72418757    Study2 1.42(0.72-2.12)
#> 9     Marker3  1.09 1.52102641 0.66435636    Study2 1.09(0.66-1.52)
#> 10    Marker4  1.19 1.97133980 0.41334544    Study2 1.19(0.41-1.97)
#> 11    Marker5  0.59 0.87228754 0.29856822    Study2  0.59(0.3-0.87)
#> 12    Marker6  0.30 0.42143657 0.18407574    Study2  0.3(0.18-0.42)
#> 13    Marker1  1.93 3.18501146 0.66782498    Study3 1.93(0.67-3.19)
#> 14    Marker2  1.81 2.69030690 0.92084330    Study3 1.81(0.92-2.69)
#> 15    Marker3  1.38 1.92722888 0.84177813    Study3 1.38(0.84-1.93)
#> 16    Marker4  1.59 2.63372720 0.55223312    Study3 1.59(0.55-2.63)
#> 17    Marker5  0.06 0.08788204 0.03008043    Study3 0.06(0.03-0.09)
#> 18    Marker6  0.96 1.33745306 0.58417490    Study3 0.96(0.58-1.34)
```

``` r
library(ggplot2)

# render plot, see additional NOTES below
plot(eg_returnList[[2]])
#> Warning: Removed 12 rows containing missing values (geom_text_repel).
```

<img src="man/figures/README-example_plot-1.png" width="100%" />

-   **( 4 ) NOTES**: As shown above, the plot rendered through plot() may suffer from certain issues such as low-resolution and overlapping labels. To overcome these issues and get the genuine plot output from ***gwasforest***, it is recommended to provide a valid **outputFolderPath** so that a better-rendered plot can be created. The below is the genuine plot output created from the same example data:

![](./man/figures/GWASForestPlot_of_6_items_by_3_groups.png)
