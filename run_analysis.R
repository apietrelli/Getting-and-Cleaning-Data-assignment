require(knitr)
require(markdown)

# Change this directory
setwd("~/Documents/Coursera_DataScience/3-Getting_cleaning_Data/Getting-and-Cleaning-Data-Assignment")
#
knit("run_analysis.Rmd")
markdownToHTML("run_analysis.md", "run_analysis.html")