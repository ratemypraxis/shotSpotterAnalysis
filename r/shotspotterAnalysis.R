library(janitor)
library(tidyverse)
library(tidycensus)
library(lubridate)
library(dplyr)
library(ggplot2)

#census_api_key("2a9f615b1e992480fcd104f8b589915e06eed64b", install = TRUE)

#view variables for acs in 2022 
v22 <- load_variables(2022, "acs5", cache = TRUE)

#getting race by status as not latino + total latino + total pop + income
vars <- c(c(totalPop = "B01003_001"),c(income = "B19013_001"), c(white = "B03002_003"),c(black = "B03002_004"),c(latino = "B03002_012"), c(asian = "B03002_006"), c(pi = "B03002_007"),c(native = "B03002_005"), c(other = "B03002_008"), c(mixed = "B03002_009"))

# getting ACS data from Chicago/Cook tracts based on variables above and for the last full year explored in the other dataset
acs_data <- get_acs(geography = "zip code tabulation area", 
                    variables = vars, 
                    year = 2022, 
                    survey = "acs5",
                    county = "Cook County"
                    )

# making the zipcodes readable and relevant to chicago 
acs_data_filtered <- acs_data %>%
  filter(between(as.numeric(GEOID), 60601, 60827))

#cleaning names + removing columns
acs_data_clean <- acs_data_filtered %>%
  rename(zip_code = GEOID) %>%
  group_by(zip_code, variable) %>%
  mutate(md_estimate = median(estimate),
         md_moe = median(moe)) %>%
  ungroup() %>%
  distinct(zip_code, variable, .keep_all = TRUE)

acs_data_clean$zip_code <- as.numeric(as.character(acs_data_clean$zip_code))

#turning race var rows into columns based on geoid+tract
acs_wide <- acs_data_clean %>%
  pivot_wider(
    id_cols = c("zip_code"), 
    names_from = variable, 
    values_from = estimate 
  )

# calculating per capita values
race <- c("white", "black", "latino", "aapi", "native", "other", "mixed")

#merging asian and pacific islanders into aapi
acs_wide <- acs_wide %>%
  mutate(aapi = asian + pi) %>%
  dplyr::select(-asian, -pi)

# Calculate per capita for each race category
race_per_cap <- acs_wide %>%
  mutate(across(race, ~ . / totalPop, .names = "per_capita_{.col}"))

# Select relevant columns
race_per_cap <- race_per_cap %>%
  dplyr::select(zip_code, starts_with("per_capita_"))

# Save the per capita dataset
write_csv(race_per_cap, "chi_zip_race_per_cap.csv")

#bringing in shotspotter data

ss_data_call <- URLencode("https://data.cityofchicago.org/resource/3h7q-7mdb.csv?$query=SELECT%20date%2C%20block%2C%20zip_code%2C%20ward%2C%20community_area%2C%20area%2C%20district%2C%20beat%2C%20street_outreach_organization%2C%20unique_id%2C%20month%2C%20day_of_week%2C%20hour%2C%20incident_type_description%2C%20rounds%2C%20illinois_house_district%2C%20illinois_senate_district%2C%20latitude%2C%20longitude%2C%20location%20ORDER%20BY%20date%20DESC")
ss_data <- read_csv(ss_data_call)

# total shotspotter activity by zip code
ss_alerts_by_zip <- ss_data %>%
  group_by(zip_code) %>%
  summarise(events = n())

# total shotspotter activity by police district
ss_alerts_by_district <- ss_data %>%
  group_by(district) %>%
  summarise(events = n())

# loading in list of zip codes within ShotSpotter activated police districs (created manually in QGIS)
ss_zips <- read_csv("ssZips.csv")

medIncome <- acs_wide %>%
  dplyr::select(zip_code, income)

medIncome <- medIncome %>%
  mutate(zip_code = as.character(zip_code))

#ssZipIncome <- inner_join(ss_zips, medIncome, by = "zipcode")

shotSpotterIncome <- acs_wide %>%
  mutate(shotspotter = if_else(zip_code %in% ss_zips$zipcode, TRUE, FALSE))

ssInc <- shotSpotterIncome %>%
  dplyr::select(zip_code, income, shotspotter)

ssInc <- ssInc[order(ssInc$income), ]

#bar plot 1
colors <- ifelse(ssInc$shotspotter, "#297AB7", "white")
par(family = "Ubuntu Mono", col.axis = "white", col.lab = "white", col.main = "white")
par(bg = "#232227")
barplot(height = ssInc$income, names.arg = rep("", nrow(ssInc)), col = colors, 
        main = "Income & ShotSpotter Usage by Zip Code",
        xlab = "Zip Code", ylab = "Income", space = 0.5, yaxt="n")
grid(col = "darkgrey")
par(las = 1)

ss_all <- left_join(ssInc, race_per_cap, by = "zip_code")

ss_all <- ss_all %>%
  group_by(zip_code) %>%
  summarise(across(everything(), sum))  

ssStats <- ss_all %>%
  mutate(majority_race = case_when(
    per_capita_white > 0.5 ~ "majority White",
    per_capita_black > 0.5 ~ "majority Black",
    per_capita_latino > 0.5 ~ "majority Latino",
    TRUE ~ NA_character_
  )) %>%
  filter(!is.na(majority_race))

ssStats <- ssStats %>%
  select(-starts_with("per_capita_"))

#grouped bar plot 2 
ggplot(ssStats, aes(x = majority_race, fill = factor(shotspotter))) +
  geom_bar(position = ifelse(levels(factor(ssStats$majority_race))[1] == "Latino", "stack", "dodge"), color = "black", stat = "count") +
  theme_minimal() +
  theme(
    plot.background = element_rect(fill = "#232227"),
    panel.grid.major = element_line(color = "white", linetype = "dashed"),
    panel.grid.minor = element_line(color = "white", linetype = "dashed"),
    text = element_text(color = "white", family = "Ubuntu Mono")
  ) +
  scale_fill_manual(values = c("white", "#297AB7"), name = "ShotSpotter", labels = c("False", "True")) +
  labs(
    x = "Majority Race",
    y = "Zips",
    title = "Total Zip Codes by Majority Race and ShotSpotter Usage"
  )
