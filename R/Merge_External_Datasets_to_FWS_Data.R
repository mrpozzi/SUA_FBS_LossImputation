# /////////////////  MERGE EXTERNAL DATASETS  ///////////////////
							   
# /*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*
# ***Note***								   
# - First the additional dataset "NEW national FBS data.dta" is added to the the SUA loss data.
# - Journal notes are merge
# - ISO3 codes are merged
# - In older SUA loss data some countries do not exist anymore. It is difficult to get information
# about the GDP and climate for these countries. However we don't want to loose the information 
# from these countries. So we assign these old countries the characteristic of new countries 
# which represent them at most. E.g for Yugoslavia we assing the data of Serbia, for USSR the 
# data of Russia, etc.  
# -
									   
# Also Note: NO EXTERNAL DATA for TAIWAN available. 
           # NO EXTERNAL DATA for the YEARS 2011 AND 2012. Values of 2010 
           # are filled in into the following years.							   
# *~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/

cat("Load SUA waste data\n")
load("SUA_waste.RData") # wasteSUA
#*keep if symb_121=="_" | symb_121=="*" 

# //add the loss data obtained for data collection
# append using  "NEW_National FBS data.dta"
cat("Add the loss data obtained for data collection\n")
finalDataset <- merge(wasteSUA, fbsData,all=FALSE)
rm(wasteSUA)

finalDataset <- finalDataset[,!colnames(finalDataset)%in%c("cereals","other_meat_proc")]


# add journal notes
cat("Add journal notes\n")
load("SUA_Journal_notes_for_losses.RData") # journalLoss


finalDataset <- merge(finalDataset, journalLoss[,c("note","user","value","symbol")],all=FALSE)
rm(journalLoss)
finalDataset <- finalDataset[,!colnames(finalDataset)%in%c("value","symbol")]


# merge ISO codes and world region classifications
cat("Merge ISO codes and world region classifications\n")
load("Directory_ISO_vs_FAO_STAT_country_codes.RData")

finalDataset <- merge(finalDataset, regionsFAO[,c("iso3","unsubregioncode","unsubregionname","continentcode","continentname")],all=FALSE)
# sort areacode itemcode year

colnames(finalDataset)[colnames(finalDataset)=="iso3"] <- "CountryCode"

# Give countries which don't exist anymore the ISO3 code of the present which represents them the most.
finalDataset$CountryCode[finalDataset$AreaName=="Belgium-Luxembourg"]  <- "BEL"
finalDataset$CountryCode[finalDataset$AreaName=="Czechoslovakia"]  <- "CZE"
finalDataset$CountryCode[finalDataset$AreaName=="Ethiopia PDR"]  <- "ETH"
finalDataset$CountryCode[finalDataset$AreaName=="Gaza Strip (Palestine)"]  <- "PSE"
finalDataset$CountryCode[finalDataset$AreaName=="Serbia and Montenegro"]  <- "SRB"
finalDataset$CountryCode[finalDataset$AreaName=="USSR"]  <- "RUS"
finalDataset$CountryCode[finalDataset$AreaName=="West Bank"]  <- "PSE"
finalDataset$CountryCode[finalDataset$AreaName=="Yemen Ar Rp"]  <- "YEM"
finalDataset$CountryCode[finalDataset$AreaName=="Yemen Dem"]  <- "YEM"
finalDataset$CountryCode[finalDataset$AreaName=="Yugoslav SFR"]  <- "SRB"
finalDataset <- finalDataset[finalDataset$AreaName!="Test Area"] # no real observation

#***********MERGE WORLD BANK DATA**************

# sort countrycode year
cat("Merge World Bank Data\n")
load("World_Bank_Share_of_Paved_Roads_data.RData")

finalDataset <- merge(finalDataset, pavedRoads, all=FALSE) # Taiwan not in WB roads data.

# bys areaname itemname (year): replace pavedroads_original=pavedroads_original[_n-1] if year==2011 | year==2012 
# *bys areaname itemname (year): replace pavedroads_missing=pavedroads_missing[_n-1] if year==2011 | year==2012 
# bys areaname itemname (year): replace pavedroads=pavedroads[_n-1] if year==2011 | year==2012 
# bys areaname itemname (year): replace pavedroads_trend=pavedroads_trend[_n-1] if year==2011 | year==2012 

#********************* WB Temperature and climate data
cat("Add Climate data\n")
load("World_Bank_Temperature_and_Precipitation_data.RData")
finalDataset <- merge(finalDataset, tempPrec, all=FALSE)


#* World Bank GDP
cat("Add World Bank GDP data\n")
load("World_Bank_GDP_data.RData")
finalDataset <- merge(finalDataset, dataGDP[,c("GDPoriginal","GDP","CountryName")], all=FALSE)


#///////////// MERGE SUA LOSS RATIOS ////////////////
cat("Add SUA loss ratios\n")
load("SUA_TCF_loss_ratios.RData")
finalDataset <- merge(finalDataset, lossRatio[,"suaratio"], all=FALSE)


#///////////// MERGE IMPORT AND EXPORT PRICES ////////////////
cat("Add SUA trade unitvalue\n")
load("SUA_trade_unitvalue.RData")
finalDataset <- merge(finalDataset, tradeSUA[,c("yimprice","yexprice")], all=FALSE)



#*****************  VARIABLE CONSTRUCTION ****************


#*********** CALCULATE LOSS RATIO *****************

finalDataset <- transform(finalDataset,ratio=(NUM_71>=0)round(20*100*NUM_121/(NUM_51+NUM_61+NUM_71))/20 + (NUM_71<0)*round(20*100*NUM_121/(NUM_51+NUM_61))/20)
finalDataset[finalDataset$ratio>100] <- NA # unfeasible losses

# ***************
finalDataset <- transform(finalDataset, region= 1*(unsubregionname=="Southern Africa" | unsubregionname=="Middle Africa" | unsubregionname=="Eastern Africa" | unsubregionname=="Western Africa" )+2*(unsubregionname=="Northern Africa" | unsubregionname=="Western Asia" ) +
# /*Northern Africa and Middle East*/
3 * (unsubregionname=="South America" |unsubregionname=="Central America" |unsubregionname=="Caribbean" ) + 4 * (unsubregionname=="Southern Europe" |unsubregionname=="Western Europe" |unsubregionname=="Northern Europe" |unsubregionname=="Northern America" | unsubregionname=="Australia and New Zealand" ) +
# /*Industrialized Countries: Europe without Eastern Europe, Northern America, Japan, Australia and New Zealand*/
5*(unsubregionname=="Central Asia" | unsubregionname=="Eastern Europe") + 
# /*Eastern Europe and Central Asia*/
6 * (unsubregionname=="Southern Asia" |unsubregionname=="Southeastern Asia"  | unsubregionname=="Eastern Asia" | unsubregionname=="Micronesia" |unsubregionname=="Polynesia" |unsubregionname=="Melanesia" ) +
# /*All Asia, without Middle East, Central Asia and Japan. + Small Pacific Islands */
4 * (areacode==110)) # // =Japan. Goes to rich countries

label def region 1 "SSA" 2 "NAf&MEast" 3 "Car,S&CeAm" 4 "INDUST" 5 "EaEU&CAs" 6 "S,SE,EAs&Pac." 
label value region region

finalDataset$newregion <- finalDataset$unsubregionname
finalDataset$newregion[finalDataset$unsubregionn%in%c("Caribbean","Central America","South America")] <- "Latin America" 
finalDataset$newregion[finalDataset$unsubregionn%in%c("Southern Africa","Eastern Africa","Middle Africa","Western Africa")|finalDataset$areaname=="Sudan (former)"] <- "SSA" 
finalDataset$newregion[finalDataset$unsubregionn=="Western Asia"] <-"Middle East" 
finalDataset$newregion[finalDataset$unsubregionn%in%c("Central Asia","Iran","Afghanistan","Pakistan")]
<-"Central Asia to Pakistan"
finalDataset$newregion[finalDataset$unsubregionn%in%c("Southern Asia","Southeastern Asia","Micronesia","Polynesia","Melanesia")]<-"South/-east Asia and Pacific"
finalDataset$newregion[finalDataset$unsubregionn%in%c("Albania","Bosnia and Herzegovina","Croatia","Montenegro","Serbia","Slovenia","The former Yugoslav Republic of Macedonia")]<- "Balkan"

 
 
# Construct differences of production. It is used to capture excess production
###TODO
# bys areacode itemcode (year): gen lagged1_num_51=(num_51[_n]-num_51[_n-1])/num_51[_n-1]
# bys areacode itemcode (year): gen lagged2_num_51=(num_51[_n-1]-num_51[_n-2])/num_51[_n-2]
# bys areacode itemcode (year): gen lagged3_num_51=(num_51[_n-2]-num_51[_n-3])/num_51[_n-3]
# bys areacode itemcode (year): gen lagged4_num_51=(num_51[_n-3]-num_51[_n-4])/num_51[_n-4]
# bys areacode itemcode (year): gen lagged_num_51=(num_51[_n-4]-num_51[_n-5])/num_51[_n-5]
 
 
save(finalDataset ,"raw_waste_and_external_data_merged.RData")

#***************************************************************************

rm(list=ls()); gc()
load("raw_waste_and_external_data_merged.RData")


# Drop if Losses are missing
 
# keep if symb_121=="_"	
finalDataset <- subset(finalDataset, SYMB_121!="M")
finalDataset <- subset(finalDataset, SYMB_121!="P") # The meaning of Flag "P" is unknown. However there are only 2 observations.
finalDataset <- subset(finalDataset, SYMB_121!="")
finalDataset <- subset(finalDataset,!is.na(ratio))
finalDataset <- subset(finalDataset,!is.na(ratio))

# save "ready for estimations.dta",replace
save(finalDataset,file="ready_for_estimations.RData")