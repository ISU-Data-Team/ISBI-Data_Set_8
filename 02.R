library(tidyverse)

df <- read_csv('Data/Output_Data/Percent_WS_Urban.csv')

df %>%
  ggplot(aes(Year, Percent_Urban, col = ProjectID)) +
  geom_point(size = 4) +
  geom_line(size = 1.5, alpha = 0.75) +
  scale_x_continuous(breaks = c(2001, 2006, 2011, 2016)) +
  labs(x = NULL, y = 'Urban Area (%)',
       title = 'Percent of Urban Area within the Project Watershed') +
  theme_light() +
  theme(text = element_text(size = 18),
        plot.title = element_text(size = 24, hjust = 0.5))
ggsave('Fig/Percent_Urban.png', width = 12, height = 10)
