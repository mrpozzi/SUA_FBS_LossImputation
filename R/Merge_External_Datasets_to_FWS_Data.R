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

load("SUA_waste.RData") # wasteSUA
#*keep if symb_121=="_" | symb_121=="*" 

# //add the loss data obtained for data collection
# append using  "NEW_National FBS data.dta"

finalDataset <- merge(wasteSUA, fbsData,all=FALSE)
rm(wasteSUA)

finalDataset <- finalDataset[,!colnames(finalDataset)%in%c("cereals","other_meat_proc")]
#drop  cereals- other_meat_proc //redundant variables


# add journal notes
load("SUA_Journal_notes_for_losses.RData") # journalLoss


finalDataset <- merge(finalDataset, journalLoss[,c("note","user","value","symbol")],all=FALSE)
rm(journalLoss)
finalDataset <- finalDataset[,!colnames(finalDataset)%in%c("value","symbol")]


# merge ISO codes and world region classifications							   		
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

load("World_Bank_Share_of_Paved_Roads_data.RData")

finalDataset <- merge(finalDataset, pavedRoads, all=FALSE) # Taiwan not in WB roads data.

# bys areaname itemname (year): replace pavedroads_original=pavedroads_original[_n-1] if year==2011 | year==2012 
# *bys areaname itemname (year): replace pavedroads_missing=pavedroads_missing[_n-1] if year==2011 | year==2012 
# bys areaname itemname (year): replace pavedroads=pavedroads[_n-1] if year==2011 | year==2012 
# bys areaname itemname (year): replace pavedroads_trend=pavedroads_trend[_n-1] if year==2011 | year==2012 

#********************* WB Temperature and climate data
# sort countrycode
load("World_Bank_Temperature_and_Precipitation_data.RData")
finalDataset <- merge(finalDataset, tempPrec, all=FALSE)


#* World Bank GDP
# sort countrycode year


load("World_Bank_GDP_data.RData")
finalDataset <- merge(finalDataset, dataGDP[,c("GDPoriginal","GDP","CountryName")], all=FALSE)


# ta areaname if _merge==1 & year<=2010
# ta countryname if _merge==2 & year>=1961
# drop if _merge==2

# //repeat GDP of 2011 in 2012 (were it was unavailable)
# bys areaname itemname (year): replace gdp=gdp[_n-1] if year==2012 
# bys areaname itemname (year): replace gdppredicted=gdppredicted[_n-1] if year==2012 

#///////////// MERGE SUA LOSS RATIOS ////////////////


# sort areacode itemcode year 
merge areacode itemcode year using "SUA_TCF loss ratios.dta", keep(suaratio)

load("SUA_TCF_loss_ratios.RData")
finalDataset <- merge(finalDataset, lossRatio[,"suaratio"], all=FALSE)


#///////////// MERGE IMPORT AND EXPORT PRICES ////////////////

# sort itemcode year 
load("SUA_trade_unitvalue.RData")
finalDataset <- merge(finalDataset, tradeSUA[,c("yimprice","yexprice")], all=FALSE)
# keep(yimprice yexprice)


# sort areacode itemcode year 


#*****************  VARIABLE CONSTRUCTION ****************


#*********** CALCULATE LOSS RATIO *****************
recode num_71 (.=0)
cap drop ratio*
gen num61=num_61
gen num71=num_71
recode num61 num71 (.=0)

gen ratio=round(20*100*num_121/(num_51+num61+num71))/20 if num71>=0
replace ratio=round(20*100*num_121/(num_51+num61))/20 if num71<0 
drop num61 num71

replace ratio=. if ratio>100 // unfeasible losses

***************

gen region=1 if unsubregionname=="Southern Africa" | unsubregionname=="Middle Africa" | unsubregionname=="Eastern Africa" | unsubregionname=="Western Africa" 
replace region=2 if unsubregionname=="Northern Africa" | unsubregionname=="Western Asia" 
/*Northern Africa and Middle East*/
replace region=3 if unsubregionname=="South America" |unsubregionname=="Central America" |unsubregionname=="Caribbean" 
replace region=4 if unsubregionname=="Southern Europe" |unsubregionname=="Western Europe" |unsubregionname=="Northern Europe" |unsubregionname=="Northern America" | unsubregionname=="Australia and New Zealand" 
/*Industrialized Countries: Europe without Eastern Europe, Northern America, Japan, Australia and New Zealand*/
replace region=5 if unsubregionname=="Central Asia" | unsubregionname=="Eastern Europe"
/*Eastern Europe and Central Asia*/
replace region=6 if unsubregionname=="Southern Asia" |unsubregionname=="Southeastern Asia"  | unsubregionname=="Eastern Asia" | unsubregionname=="Micronesia" |unsubregionname=="Polynesia" |unsubregionname=="Melanesia" 
/*All Asia, without Middle East, Central Asia and Japan. + Small Pacific Islands */
replace region=4 if areacode==110 // =Japan. Goes to rich countries

label def region 1 "SSA" 2 "NAf&MEast" 3 "Car,S&CeAm" 4 "INDUST" 5 "EaEU&CAs" 6 "S,SE,EAs&Pac." 
label value region region

gen newregion=unsubregionname

replace newregion="Latin America" if unsubregionn=="Caribbean"|unsubregionn=="Central America"|unsubregionn=="South America"
replace newregion="SSA" if unsubregionn=="Southern Africa" | unsubregionn=="Eastern Africa"| unsubregionn=="Middle Africa" | unsubregionn=="Western Africa"
replace newregion="SSA" if areaname=="Sudan (former)" 
replace newregion="Middle East" if newregion=="Western Asia"
replace newregion="Central Asia to Pakistan" if newregion=="Central Asia" | areaname=="Iran"| areaname=="Afghanistan"| areaname=="Pakistan"
replace newregion="South/-east Asia and Pacific" if newregion=="Southern Asia" | newregion=="Southeastern Asia" | newregion=="Micronesia"| newregion=="Polynesia"| newregion=="Melanesia"
replace newregion="Balkan" if areaname=="Albania" | areaname=="Bosnia and Herzegovina" | ///
 areaname=="Croatia" | areaname=="Montenegro" | areaname=="Serbia"  | areaname=="Slovenia" | /// 
 areaname=="The former Yugoslav Republic of Macedonia"

 
 
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