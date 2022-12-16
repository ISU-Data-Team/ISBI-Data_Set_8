# MRLC data processing
The National Land Cover Database (NLCD) provides nationwide data on land cover and land cover change at a 30m resolution with a 16-class legend based on a modified Anderson Level II classification system.

**ISBI Data Number**: DN_08 (NIT_07)

**Data obtained from (website)**: https://www.mrlc.gov/data

**Date obtained or last updated**: 9/16/2020

**Dataset name**: NLCD Imperviousness (CONUS) All Years

## Dataset description
NLCD imperviousness products represent urban impervious surfaces over every 30-meter pixel in the United States. It consist of two distinct datasets: (a) ***Percent Developed Imperviousnes***, and (b) ***Developed Imperviousness Descriptor***. The first contains data showing percentage of urban development for each pixel, the second identifies types of roads, core urban areas, and energy production sites for each impervious pixel to allow deeper analysis of developed features. Borth datasets are available for 4 years: 2001, 2006, 2011, and 2016.

## Analysis
The goal of the analysis was to estimate percentage of urban area within the watersheds of interest (8 WQI Projects in Iowa). For this analysis we used ***Percent Developed Imperviousnes*** at 30-m resolution (the original resolution).

## Input and output data and variables
The input data (in raster format) contains only one variable, percentage of developed surface evaluated for each pixel. 

There are two output files: **_Percent_WS_Urban.csv_** containing only issential data required by ISBI; and **_results_impervious_ws.csv_** containing additional variables calculated in case needed. 

**_Percent_WS_Urban.csv_**
- `ProjectID`     = Porject ID
- `Year`          = year of measurement
- `Percent_Urban` = percentage of urban area

**_results_impervious_ws.csv_**
- `HUC8`          = name of HUC8 watershed that the AOI (the  watershed project) belongs too 
- `year`          = year of measurement
- `imperv`        = sum of impervious percentages (expresed in decimals) within AOI 
- `imperv_total`  = total number of pixels with non-zero imperviousness within AOI
- `total`         = total number of pixels within AOI
- `perc_imperv`   = percent of impervious surface based on `imperv`
- `perc_imperv_total` = percent of impervious surface based on `imperv_total` (this is reported as `Percent_Urban` for ISBI)

## Manipulations performed on the data
- Data was extracted for each watershed project
- Percent of urban area was calculated as sum of pixels with impervious surface divided by total number of pixels within the AOI
- Final values were converted to percent points and rounded to the nearest 100th (2-decimal places)

## Notes and other issues
Highways, county roads and other impervious elements are also counted as part of urban areas. 

MRLC files are very big in size and take a lot of disk space. If the space is a limiting factor on your machine, it is recommended to download and analyze each data type and year individually.

Data containing all raster layers including land cover, urban imperviousness, etc. for all years have been obtained for Iowa and is stored on CyBOX under **All Files > NRC19 - Watershed progress evaluation > Data > MRLC**. This data can be used if other land cover information is needed.
