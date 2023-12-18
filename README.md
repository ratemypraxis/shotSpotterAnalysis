# Analysis of ShotSpotter data in Chicago
[Written piece linked here](https://medium.com/@sh4712/is-ai-over-policing-chicagos-communities-of-color-3d2c2374695e)

## Data Sources
[Shotspotter Activity](https://data.cityofchicago.org/Public-Safety/Violence-Reduction-Shotspotter-Alerts/3h7q-7mdb/data_preview) from Chicago Data Portal  
[Zip Code Boundary shapefile](https://data.cityofchicago.org/Facilities-Geographic-Boundaries/Boundaries-ZIP-Codes/gdcf-axmw) from Chicago Data Portal  
[Police District Boundary shapefile](https://data.cityofchicago.org/Public-Safety/Boundaries-Police-Districts-current-/fthy-xz3r) from Chicago Data Portal  
[2022 5-year ACS data](https://www.census.gov/programs-surveys/acs/) from Census  

## R Process
I prepared some csv datasets in R before bringing things to QGIS, my R project and script with inline comments detailing the process can be found within this repo. 

## QGIS Process
I started with a tabular join of a Zip Code boundary file and R prepared CSV containing data on race by zip code. From this combination I used the Symbiology menu to create a graduated map visualization. The Chicago Open Data portal only details which Chicago Police Districts have the ShotSpotter program, which is not a geography supported in ACS/tidycensus data. I chose Zip Code as it visually seemed the closest and brought in shapefiles for both Chicago Police District and Zip Code boundaries. I then changed the symbiology of both shapefiles to only show an outline for each boundary, a different bright color for both. I made use of the expression editor to only keep data/mapping for districts involved in the ShotSpotter program in the Police District file before going into the Zip Code file to manually select and delete each Zip Code that fell out of bounds of one of the specified Police Districts. Lastly I chose to overlay the resulting edited shapefile with outline only Symbiology above the aformentioned graduated mapping. 
  
Upon exporting both charts and map and keys from QGIS print layout I brought them into Slides to make them snazzy, find [a link to the Slides doc here](https://docs.google.com/presentation/d/1lv-3Z-1-kMUn-iE24sKyP6i_71vZEgIcOb7TiR2y83A/edit?usp=sharing).
