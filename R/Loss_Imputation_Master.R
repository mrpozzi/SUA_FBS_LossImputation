# /*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*
# ***Note***	 
# This R-file executes all R-files in the right order and finally produces the 
# loss imputations. First you need to create a directory for running the procedure.  
# Afterwards you write the directory path of the folder you created in the global  
# "folder". In this folder you need to copy the following folders and datasets  
# to run all the procedure: 
 
# - "${folder}\dta" ... in this folder stores data which are constructed in Stata. 
# It is empty at the beginning. Files will be constructed by the do-files. 
 
 
# - "${folder}\do" ... all do-files, including this do-file, is stored here. 
# Contains the following do-files:  
# 1) "FWS_Data_Construction.R",  
# 2) "Elaboration_of_External_Datasets.R", 
# 3) "Merge_External_Datasets_to_FWS_Data.R",   
# 4) "Create Artificial Dataset for Loss Imputation.do" // every commodities for each country 
# 5) "FWS_Estimation_and_Imputation_Unified_Approach.R", 
# 6) "Loss_Imputation_Master.R" 
 
 
# - "${folder}\csv" ... all raw data are stored here. For description of the 
# csv-files see comments in "Elaboration of External Datasets.do": 
# 1) "SUA_waste.csv" 
# 2) "SUA_TCF loss ratios.csv" 
# 3) "SUA_Journal notes for losses.csv" 
# 4) "SUA_trade_unitvalue.csv" 
# 5) "Directory_ISO vs FAOSTAT country codes.csv" 
# 6) "World Bank_Share of Paved Roads data.csv" 
# 7) "World Bank_Temperature and Precipitation data.csv" 
# 8) "World Bank_GDP data.csv" 
# 9) "NEW_National FBS data.csv" 
 
# - "${folder}\output"   
# Here you find the excel sheet with the imputated losses. 
 
# For more details about the specific do-files, see notes of the single dofiles. 
# *~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/ 
 
 
rm(list=ls())
gc()

source("commodities.R")

# Classifies items into item groups and reshapes the data. 
cat("FWS data construction\n")
source("FWS_Data_Construction.R") 

# Elaborates the additional loss dataset, data from World Bank and other files. 
cat("\nElaborate additional loss datasets\n")
source("Elaboration_of_External_Datasets.R") 


# Constructs the final dataset for estimation. 
cat("\nMerge external datasets to FWS data\n")
source("Merge_External_Datasets_to_FWS_Data.do") 

# Constructs dataset for prediction. 
cat("\nConstruct dataset for prediction\n")
source("Create_Artificial_Dataset_for_Loss_Imputation.R") 

# Estimates losses and produces table of imputed loss rates.    
cat("\nEstimate losses and produce table of imputed loss rates\n")
source("FWS_Estimation_and_Imputation_Unified_Approach.do") 
