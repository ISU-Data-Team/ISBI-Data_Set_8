library(readxl)
library(tidyverse)
library(raster)
library(rgdal)
select <- dplyr::select



# Read Watershed Project --------------------------------------------------

# read watershed project info
huc12_ws <- 
  read_excel("../Iowa_Cities/Input_Data/Watershed_Projects.xlsx") %>%
  filter(IncludeYN == 'Y') %>%
  select(ProjectID, ProjectName, HUC8Name, HUC12ID = `Included Watersheds (12-digit)`) %>%
  mutate(HUC12ID = str_split(HUC12ID, pattern = ',\n')) %>%
  unnest(HUC12ID)

huc8_ws <-
  huc12_ws %>%
  mutate(HUC8ID = str_sub(HUC12ID, 1, 8)) %>%
  distinct(HUC8ID, HUC8Name, ProjectID, ProjectName)


# creat a list of IDs for HUC8 and HUC12 watershed that have the projects
huc12s <- huc12_ws$HUC12ID
huc8s <- huc12s %>% str_sub(1, 8) %>% unique()


# read shapefiles of watersheds and counties
PATH <- '../Iowa_Cities/Input_Data/Project-Boundaries/Shapefiles/'

huc8_ia <- 
  shapefile(paste0(PATH, 'Iowa_HUC8_Watersheds/wbdhu8_a_ia.shp'))

huc12_ia <-
  shapefile(paste0(PATH, 'WBD_HU_12_IA/WBD_HU_12_IA.shp')) %>%
  spTransform(crs(huc8_ia))

counties_ia <-
  shapefile(paste0(PATH, 'Iowa_Counties/Iowa_USCounties_Clip.shp'))


# select HUC8 and HUC12 watershed of interest
my_huc8s <- huc8_ia[huc8_ia$HUC8 %in% huc8s, c('HUC8', 'NAME', 'STATES', 'AREASQKM', 'AREAACRES')]
my_huc12s <- huc12_ia[huc12_ia$HUC_12 %in% huc12s, c('HUC_8', 'HUC_12', 'STATES', 'ACRES', 'HU_12_NAME')]

# aggregate counties into state
state_ia <- aggregate(counties_ia)
# aggregate huc12s into project
my_projects  <- aggregate(my_huc12s, by = 'HUC_8')


# Plot the map of Iowa with HUC8 watersheds and WS Project boundaries
plot(state_ia)
plot(my_huc8s, add = TRUE)
plot(my_huc12s, add = TRUE, border = 'skyblue1', lwd = 0.5)
plot(my_projects, add = TRUE, border = 'skyblue2', lwd = 2)


# Read MRLC Raster Data ---------------------------------------------------
# list all MRLC files with imperviousness data
MRLC_files <- list.files('Data/Input_Data/Urban_Imperviousness/NLCD_Impervious_L48_20190405_full_zip/',
           pattern = '*Impervious_L48.*img', full.names = TRUE)


# function to calculate percent of impervious surface within AOI
# NOTE: imperviousness products represent urban impervious surfaces as a percentage of developed surface over every 30-meter pixel
calc_impervious <- function(FILE, PROJECT) {
  us_imperv <- raster(FILE)
  my_ws <- PROJECT %>%
    spTransform(crs(us_imperv))
  my_imperv <- crop(us_imperv, my_ws) %>%
    mask(my_ws) 
  data <-
    freq(my_imperv) %>%
    as_tibble() %>%
    filter(!is.na(value)) %>%
    mutate(imperv = value * count / 100) %>%
    summarise(imperv = sum(imperv),
              imperv_total = sum(count[value > 0]),
              total = sum(count)) %>%
    mutate(perc_imperv = imperv/total*100,
           perc_imperv_total = imperv_total/total*100,
           HUC8 = my_ws$HUC_8,
           year = str_sub(names(us_imperv), 6, 9))
  return(data)
}

# calculate percent impervious for all ws projects and years
temp <- vector('list')
df <- vector('list')
for (i in MRLC_files) {
  for (j in 1:8) {
    temp[[j]] <- calc_impervious(i, my_projects[j, ])
  }
  df[[i]] <- bind_rows(temp)
}

bind_rows(df) %>%
  select(HUC8, year, everything()) %>%
  write_csv('Data/Output_Data/results_impervious_ws.csv')

bind_rows(df) %>%
  mutate(perc_imperv_total = round(perc_imperv_total, 2)) %>%
  left_join(huc8_ws, by = c('HUC8' = 'HUC8ID')) %>%
  select(ProjectID, Year = year, Percent_Urban = perc_imperv_total) %>%
  write_csv('Data/Output_Data/Percent_WS_Urban.csv')


# plot
bind_rows(df) %>%
  mutate(year = as.numeric(year)) %>%
  ggplot(aes(year, perc_imperv_total, col = HUC8)) +
  geom_point() +
  geom_line()

# developing function
us_imperv <- raster(MRLC_files[1])
my_ws <- my_projects[1, ] %>%
  spTransform(crs(us_imperv))
my_imperv <- crop(us_imperv, my_ws) %>%
  mask(my_ws) 
freq(my_imperv) %>%
  as_tibble() %>%
  filter(!is.na(value)) %>%
  mutate(imperv = value * count / 100) %>%
  summarise(imperv = sum(imperv),
            imperv_count = sum(count[value > 0]),
            total = sum(count)) %>%
  mutate(perc_imperv = imperv/total*100,
         HUC8 = my_ws$HUC_8,
         year = str_sub(names(us_imperv), 6, 9))

# vizualize
plot(my_imperv,
     main = 'Watershed Project')
plot(my_ws, add = TRUE, border = 'white')

my_projects[1, ] %>%
  spTransform(crs(us_imperv)) %>%
  crop(us_imperv, .) %>%
  mask(my_ws) %>%
  as.data.frame(xy = TRUE) %>%
  ggplot() + 
  geom_raster(aes(x = x, y = y, fill = NLCD_2001_Impervious_L48_20190405)) + 
  scale_fill_viridis_c(name = 'Percent Impervious', na.value = 'white') +
  labs(x = NULL, y = NULL, 
       title = '13WQI-003',
       subtitle = 'Central Turkey River Nutrient Reduction Demonstration Project ') +
  theme_light() +
  coord_sf() +
  theme(axis.text = element_blank(),
        axis.ticks = element_blank(),
        plot.title = element_text(size = 16, hjust = 0.5),
        plot.subtitle = element_text(size = 12, hjust = 0.5))
ggsave('Fig/Percent_Impervious_13WQI-003.png', 
       width = 12, height = 10)






