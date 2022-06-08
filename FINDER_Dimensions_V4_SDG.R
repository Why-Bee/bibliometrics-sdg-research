### INTRODUCTION ##########################################################

# Finder_Dimensions_V4_SDG
# An initial script to query the Dimensions API. Modified and refined to query for Sustainable Development Goals.
# May 2022
# Jeff Demaine
# Modified by Yash Bhatia 
# Following the instructions at: https://github.com/massimoaria/dimensionsR

# Usage: *IMPORTANT: Run all functions in dsApi2dfRev to define them!* 
# Enter your DSAuth token in the field below, specify your query using query.string, and run.
# Output(s): Master Data Frame 'Mprim' created by concatenating all results for all SDGs, list of child dataframes 'listofframes', bibliometrix analysis on Mprim 'result', comma-separated value file 'QueryResults_Dimensions.csv' to easily read and analyze Mprim.

### PACKAGES ##############################################################

install.packages("dimensionsR")
install.packages("bibliometrix")

library(dimensionsR)
library(bibliometrix)

### API TOKEN #############################################################

# Running this program requires an account with Dimensions API access, and the API token of that account.
# For access to the Dimensions API, visit https://ds.digital-science.com/NoCostAgreement

token.string <- "BC7F5884A2D445EAA189A8A2DBF3E1FB" #replace this with your Dimensions API token
tokens <- dsAuth(key = token.string)


### QUERIES AND REQUESTS ###############################################################

# Notes: This query string is written in Dimensions Structured Language (DSL). For more information on DSL, visit https://docs.dimensions.ai/dsl/

query.string <- "search publications where (year in [ 2018 : 2022 ]) and (type in [\"article\"]) and research_orgs.id = \"grid.25073.33\" and (category_sdg.name = \"1 No Poverty\") return publications[basics + extras + categories + concepts]"

# Template for building queries:

# "search publications return publications"

# "search publications in title_abstract_only for \"library\" 
#                        where (year in [2010:2018])
#                        and (type in [\"article\", \"grant\"])
#                        and (research_orgs.name ~ \"McMaster University\")
# return publications [type + basics + extras]"

res <- dsApiRequest(token = tokens, query = query.string, limit = 0, verbose = TRUE)
res$total_count # This query does not return any results, as it has limit = 0. Its purpose is to test how many results will be obtained.
D <- dsApiRequest(token = tokens, query = query.string, limit = res$total_count, verbose = TRUE)
#The output data is in the form of a list

Mprim <- dsApi2dfRev(D) # Convert the Dimensions XML list into an R data frame. This dataframe will store every single result from the query in the below For loop, appended using rbind()
head(Mprim) 
listofframes = list(Mprim) #list of all dataframes (should have 16 dataframes, one for each query).

 for (x in 2:16) #For loop, to get every SDG separately queried
 {
   curr_sdg <- 40000 + x #Internally, the category ID for SDGs is 40000 plus the SDG number, going from 1 to 17.
   query.string <- paste("search publications where (year in [2018:2022]) and (type in [\"article\"]) and (research_orgs.id = \"grid.25073.33\") and (category_sdg.id = ",toString(curr_sdg),") return publications[basics + category_sdg]", sep = '')
   query.string #The query string has been constructed using paste, to add the custom SDG ID parameter as described above
   res <- dsApiRequest(token = tokens, query = query.string, limit = 0, verbose = TRUE)
   D <- dsApiRequest(token = tokens, query = query.string, step = 200, limit = res$total_count)
   M <- dsApi2dfRev(D) #Note: M here stores the query results of the current SDG query
   Mprim <- rbind(Mprim, M) #Joining the results of current query to the master results table
   append(listofframes, M) #appending the current data frame to the list of dataframes
 }

### OUTPUTS ############################################################################

# Output as a csv file:
write.csv(Mprim, file = "~/QueryResults_Dimensions.csv", append = FALSE, quote = TRUE, sep = ",", qmethod = "double")

# Analyze with bibliometrix package:
M_main <- convert2df(D, dbsource = "dimensions", format = "api")

results <- biblioAnalysis(M_main)
summary(results)

### NOTES ##############################################################################

# The data frame Mprim contains many results without a clear separator between each query. To efficiently find queries of particular SDGs, the field category_sdg has been appended to the dataframe. 
# As all data of the same SDG is adjacent in Mprim, this makes it easier to read and extract SDGs from the frame by finding start and end positions of a particular SDG, using category_sdg
# The list of dataframes listofframes is created to facilitate further backend usage in R, as the individual SDGs can be worked on by accessing the elements in the list.