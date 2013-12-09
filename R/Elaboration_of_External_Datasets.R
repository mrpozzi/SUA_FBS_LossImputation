#  CONSTRUCT EXTERNAL DATASETS
# ***Note***	
# This file just prepares several datasets:

# -"SUA_trade_unitvalue.csv":
# Trade data (import and export) from SUA Working System containing prices per quantity for each item.
# This dataset is used to construct item prices.

# -"Directory_ISO vs FAOSTAT country codes.dta":
# Directory of FAOSTAT country codes (areacode) and ISO3 country codes.
# ISO3 codes are needed to merge World Bank data.

# -"World Bank_Share of Paved Roads.dta":
# World Bank data on the share of Paved Roads in a country and a year. Data are not avaialbe for each year.
# If data on paved roads for one year are missing, just the data from the same country of the nearest year are 
# imputed. Better imputation techniques are welcome.

# -"World Bank_Temperature and Precipitation.dta":
# World Bank data on monthly means and std. dev. of temperature and precipitation. These are long
# term data, so they don't vary over time.

# -"World Bank_GDP Data.dta":
# World Bank data on countries GDP from the 60's. GDP is in 2005 dollar (PPP converted GDP was only 
# available from the 1980's). Missing data are imputed by linear regressions, using a 
# simple country-specific linear time trend. Better imputation techniques are welcome.

# -"SUA_TCF loss ratios.dta":
# Contains FAO loss ratios used for calculating "F"-flagged losses. You can find them in the Handbook
# "Technical Conversion Factors for Agricultural Commodities".
# This loss rates called 'suaratios' are only used for descriptive purposes.

# -"SUA_Journal notes for losses.dta":
# Journal notes of the SUA working data. This journal notes should have been already included 
# in the original loss data "sua_waste". For some reason they have been downloaded separetely 
# (Ask Amanda Gordon. She is responsable for downloading the data from the FAOSTAT system.)
 
  
# -"NEW_National FBS data.dta":
# Additional loss data from National FBS and National Statistics Institutes. These data have been
# collected by Rachele Brivio. 
# New loss data are categorized in the same way as the SUA data in "FWS Data Construction.do".
# SUA areaname and itemname are merged to the new data. Unreliable observations are dropped. 


# ***** Commodity prices, derived from trade data *****
# **** Attention. These are import and export prices for each country, without considering quantities. It would be better to calculate the value of worldwide traded commodities and divide it by the quantity of the world trade volume. Need to have data on quantities. Ask Amanda.

tradeSUA <- read.csv("csv/SUA_trade_unitvalue.csv",stringsAsFactors=FALSE)#


### cleaning 
colnames(tradeSUA)[1] <- "AreaCode"
colnames(tradeSUA)[2] <- "ItemCode"
colnames(tradeSUA)[3] <- "ElementCode"

tradeSUA <- tradeSUA[,!1:ncol(tradeSUA)%in%grep("SYMB",colnames(tradeSUA))]
tradeSUA <- tradeSUA[tradeSUA$AreaCode!=298,] # test area

tradeSUA <- reshape(tradeSUA, dir = "long", varying = -(1:3), sep = "_")
tradeSUA <- tradeSUA[,colnames(tradeSUA)!="id"]

tradeSUA$NUM[tradeSUA$NUM==0] <- NA

numVar <-  unique(tradeSUA$ElementCode)
tradeSUA <- do.call(rbind,lapply(unique(tradeSUA$AreaCode),function(area){
	X <- tradeSUA[tradeSUA$AreaCode==area,]
	do.call(rbind,lapply(unique(X$ItemCode),function(item){
		Y <- X[X$ItemCode==item,]
		
		Z <- reshape(Y, dir = "wide",timevar = "ElementCode",sep = "_", v.name = "NUM",idvar="time")
		missingCols <-setdiff(c("AreaCode","ItemCode","time",paste("NUM",numVar,sep="_")),colnames(Z))
			
		if(length(missingCols) > 0L){
			#classMissing <- lapply(A[,missingCols,with = FALSE], class)
			nas <- lapply(rep("numeric",length(missingCols)), as, object = NA)
			Z[,missingCols] <- nas
			}
		return(Z[,c("AreaCode","ItemCode","time",paste("NUM",numVar,sep="_"))])

		}))
	}))
tradeSUA$year <- tradeSUA$time
tradeSUA$time<-ceiling((tradeSUA$time-1960)/10)
tradeSUA$time[tradeSUA$time==6] <- 5



# !!!!!Attention, these are not global average prices!!!!!


### MOREWORHERE!!!

#average yearly country import prices. 

yimprice <- with(tradeSUA,do.call(rbind,lapply(unique(ItemCode),function(item){
		X <- tradeSUA[tradeSUA$ItemCode==item,]
		data.frame(item,unique(year), yimprice=with(X,tapply(NUM_63,year,function(x){
			# Cut outliers: not sure if we need it or not.... 
			# p5 <-  quantile(x,0.05,na.rm=TRUE)
			# p95 <-  quantile(x,0.95,na.rm=TRUE)
			# x[x<p5] <- p5
			# x[x>p95] <- p95
			mean(x,na.rm=TRUE)
			})),yimprice2=with(X,tapply(NUM_63,time,function(x){
			# Cut outliers: not sure if we need it or not.... 
			# p5 <-  quantile(x,0.05,na.rm=TRUE)
			# p95 <-  quantile(x,0.95,na.rm=TRUE)
			# x[x<p5] <- p5
			# x[x>p95] <- p95
			mean(x,na.rm=TRUE)
			})),row.names=paste(unique(year),item,sep="_"))
		}))[paste(year, ItemCode,sep="_"),])


#average yearly country export prices. 
yexprice <- with(tradeSUA,do.call(rbind,lapply(unique(ItemCode),function(item){
		X <- tradeSUA[tradeSUA$ItemCode==item,]
		data.frame(item,unique(year), yexprice=with(X,tapply(NUM_93,year,function(x){
			# Cut outliers: not sure if we need it or not.... 
			# p5 <-  quantile(x,0.05,na.rm=TRUE)
			# p95 <-  quantile(x,0.95,na.rm=TRUE)
			# x[x<p5] <- p5
			# x[x>p95] <- p95
			mean(x,na.rm=TRUE)
			})),yexprice2=with(X,tapply(NUM_93,time,function(x){
			# Cut outliers: not sure if we need it or not.... 
			# p5 <-  quantile(x,0.05,na.rm=TRUE)
			# p95 <-  quantile(x,0.95,na.rm=TRUE)
			# x[x<p5] <- p5
			# x[x>p95] <- p95
			mean(x,na.rm=TRUE)
			})),row.names=paste(unique(year),item,sep="_"))
		}))[paste(year, ItemCode,sep="_"),])



tradeSUA <- merge(yimprice, yexprice)
## this is for doing a sanity check....
# sanity <- read.dta("trade_unitvalue.dta")
save(tradeSUA,file="SUA_trade_unitvalue.RData")



# ***************** ISO COUNTRY CODES *****************
# This file is used to merge ISO3 codes to FAOSTAT data.



regionsFAO <- read.csv("csv/Directory_ISO vs FAOSTAT country codes.csv")
regionsFAO$unsubregionname <- rep("Others",nrow(regionsFAO))

regionsFAO$unsubregionname[regionsFAO$unsubregioncode==5] <- "South America"
regionsFAO$unsubregionname[regionsFAO$unsubregioncode==11] <- "Western Africa"
regionsFAO$unsubregionname[regionsFAO$unsubregioncode==13] <- "Central America"
regionsFAO$unsubregionname[regionsFAO$unsubregioncode==14] <- "Eastern Africa"
regionsFAO$unsubregionname[regionsFAO$unsubregioncode==15] <- "Northern Africa"
regionsFAO$unsubregionname[regionsFAO$unsubregioncode==17] <- "Middle Africa"
regionsFAO$unsubregionname[regionsFAO$unsubregioncode==18] <- "Southern Africa"
regionsFAO$unsubregionname[regionsFAO$unsubregioncode==21] <- "Northern America"
regionsFAO$unsubregionname[regionsFAO$unsubregioncode==29] <- "Caribbean"

regionsFAO$unsubregionname[regionsFAO$unsubregioncode==30] <- "Eastern Asia"
regionsFAO$unsubregionname[regionsFAO$unsubregioncode==34] <- "Southern Asia"
regionsFAO$unsubregionname[regionsFAO$unsubregioncode==35] <- "Southeastern Asia"
regionsFAO$unsubregionname[regionsFAO$unsubregioncode==39] <- "Southern Europe"
regionsFAO$unsubregionname[regionsFAO$unsubregioncode==53] <- "Australia and New Zealand"
regionsFAO$unsubregionname[regionsFAO$unsubregioncode==54] <- "Melanesia"

regionsFAO$unsubregionname[regionsFAO$unsubregioncode==57] <- "Micronesia"
regionsFAO$unsubregionname[regionsFAO$unsubregioncode==61] <- "Polynesia"
regionsFAO$unsubregionname[regionsFAO$unsubregioncode==143] <- "Central Asia"
regionsFAO$unsubregionname[regionsFAO$unsubregioncode==145] <- "Western Asia"
regionsFAO$unsubregionname[regionsFAO$unsubregioncode==151] <- "Eastern Europe"
regionsFAO$unsubregionname[regionsFAO$unsubregioncode==154] <- "Northern Europe"

regionsFAO$unsubregionname[regionsFAO$unsubregioncode==155] <- "Western Europe"
regionsFAO$unsubregionname[regionsFAO$unsubregioncode==2] <- "Africa"
regionsFAO$unsubregionname[regionsFAO$unsubregioncode==9] <- "Oceania"
regionsFAO$unsubregionname[regionsFAO$unsubregioncode==19] <- "America"
regionsFAO$unsubregionname[regionsFAO$unsubregioncode==142] <- "Asia"
regionsFAO$unsubregionname[regionsFAO$unsubregioncode==150] <- "Europe"


#colnames(regionsFAO)[8] <- "areacode"
#sort areacode 

#save "Directory_ISO vs FAOSTAT country codes.dta", replace
save(regionsFAO,file="Directory_ISO_vs_FAO_STAT_country_codes.RData")

# ***ISO vs FAOSTAT country codes.dta

# ***************** WB DATA ON PAVED ROADS *****************
# /*I use here a very rude imputation technique. In case a number is missing,
# I just repeat the nearest avaiable number. Since the dataset starts at 1990,
# the data are repeated until 1961. However, in the estimation I will set 
# observations before 1990 to 0 and use a dummy for missing value.*/

pavedRoads <- read.csv("csv/World Bank_Share of Paved Roads data.csv")

#keep countryname countrycode v33- v53
colnames(pavedRoads)[1:2] <- c("CountryName","CountryCode")
colnames(pavedRoads) <- gsub("X","pavedroads",colnames(pavedRoads))

pavedRoads <- reshape(pavedRoads, dir = "long", varying = -(1:2), sep = "")
pavedRoads <- pavedRoads[,colnames(pavedRoads)!="id"]


###FIXTHIS
# gen pavedroads_missing=pavedroads==.
# gen pavedroads_t=.

# # imputation
# forvalues n1=1(1)10 {
# forvalues n2=1(1)10 {

# bys country (year): replace pavedroads_t= ///
# pavedroads[_n-`n1']+((pavedroads[_n+`n2']-pavedroads[_n-`n1'])/(`n1'+`n2'))*`n1' ///
# if pavedroads==. & pavedroads[_n-`n1']~=. & pavedroads[_n+`n2']~=. & pavedroads_t==.


# }
# }
# gen prmiss2=pavedroads==. & pavedroads_t==.

# gen pavedroads_i=pavedroads
# replace pavedroads_i=pavedroads_t if pavedroads_t~=.

# gen pavedroads_f=.

# forvalues n=1(1)50 {

# bys country (year): replace pavedroads_f=pavedroads_i[_n+`n'] ///
 # if prmiss2[_n+`n']==0 & prmiss2==1 & prmiss2[_n+`n'-1]==1 & pavedroads_f==.

 # bys country (year): replace pavedroads_f=pavedroads_i[_n-`n'] ///
 # if prmiss2[_n-`n']==0 & prmiss2==1 & prmiss2[_n-`n'+1]==1 & pavedroads_f==.

 
# }

# rename pavedroads pavedroads_original

# gen pavedroads=pavedroads_original
# replace pavedroads=pavedroads_t if pavedroads_t~=.
# replace pavedroads=pavedroads_f if pavedroads_f~=.


# gen pavedroads_trend=pavedroads_t~=.

# drop pavedroads_i pavedroads_t pavedroads_f prmiss2


# sort country
# sort countrycode year
# save "World Bank_Share of Paved Roads data.dta",replace
save(pavedRoads,file="World_Bank_Share_of_Paved_Roads_data.RData")



# ***************** WB DATA ON TEMPERATURE AND PRECIPITATION *****************

tempPrec <- read.csv("csv/World Bank_Temperature and Precipitation data.csv")
colnames(tempPrec)[1] <- "CountryCode"
colnames(tempPrec)[grep("Annual_temp",colnames(tempPrec))] <- "MeanTemp"
colnames(tempPrec)[grep("Annual_precip",colnames(tempPrec))] <- "MeanPrec"

tempPrec$sd_precip <- apply(tempPrec[,grep("precip",colnames(tempPrec))],1,sd)
tempPrec$min_precip <- apply(tempPrec[,grep("precip",colnames(tempPrec))],1,min)
tempPrec$max_precip <- apply(tempPrec[,grep("precip",colnames(tempPrec))],1,max)


tempPrec$sd_temp <- apply(tempPrec[,grep("_temp",colnames(tempPrec),ignore.case=TRUE)],1,sd)
tempPrec$min_temp <- apply(tempPrec[,grep("_temp",colnames(tempPrec),ignore.case=TRUE)],1,min)
tempPrec$max_temp <- apply(tempPrec[,grep("_temp",colnames(tempPrec),ignore.case=TRUE)],1,max)

#keep countrycode mean_* sd_* min_* max_*
# sort countrycode
# save "World Bank_Temperature and Precipitation data.dta",replace
save(tempPrec,file="World_Bank_Temperature_and_Precipitation_data.RData")


# ***************** World Bank GDP Data *****************


dataGDP <- data.frame(read.csv("csv/World Bank_GDP data.csv",stringsAsFactors=FALSE))

colnames(dataGDP) <- gsub("X","GDP",colnames(dataGDP))
colnames(dataGDP)[1] <- "CountryName"
colnames(dataGDP)[2] <- "CountryCode"

dataGDP <- reshape(dataGDP, dir = "long", varying = -(1:2), sep = "")


dataGDP[dataGDP$CountryCode=="ZAR",] <- "COD"
dataGDP[dataGDP$CountryCode=="ROM",] <- "ROU"
dataGDP$GDP <- as.numeric(dataGDP$GDP)

# sort countrycode year

dataGDP$lnGDP <- log(dataGDP$GDP)
modGDP <- lm(lnGDP~CountryCode+time,data=dataGDP)

lngdpp <- predict(modGDP)
gdpPred<-exp(lngdpp)
dataGDP$GDPoriginal <- dataGDP$GDP
dataGDP$GDP[is.na(dataGDP$GDP)]  <- gdpPred[is.na(dataGDP$GDP)]

dataGDP <- subset(dataGDP,time!=2012) #Imputations have some discontinuities. For forecast better use GDP of 2011 

# save "World Bank_GDP data.dta",replace
save(dataGDP,file="World_Bank_GDP_data.RData")

# ***************** SUA LOSS RATIOS *****************

lossRatio <- read.csv("csv/SUA_TCF loss ratios.csv")
colnames(lossRatio)[8] <- "fixedSUAratio"
colnames(lossRatio) <- gsub("X","suaRatio",colnames(lossRatio))

lossRatio[,9:ncol(lossRatio)] <- apply(lossRatio[,9:ncol(lossRatio)],2,function(x){
	x[is.na(x)] <- lossRatio$fixedSUAratio[is.na(x)]
	return(x)
	})
	
lossRatio <- reshape(lossRatio, dir = "long", varying = -(1:8), sep = "")

lossRatio$suaRatioChanged<-(lossRatio$suaRatio!=lossRatio$fixedSUAratio)
#sort areacode itemcode year
#save "SUA_TCF loss ratios.dta",replace
save(lossRatio,file="SUA_TCF_loss_ratios.RData")
   
#***************** SUA LOSS RATIOS JOURNAL NOTES *****************
journalLoss <- data.frame(read.csv("csv/SUA_Journal notes for losses.csv",stringsAsFactors=FALSE))

journalLoss$Symbol[journalLoss$Symbol==""] <- "_"

save(journalLoss,file="SUA_Journal_notes_for_losses.RData")

####FIXTHIS
# bys areacode itemcode year (versionno): gen nversions=_N 
# bys areacode itemcode year (versionno): keep if _n==_N

#save "SUA_Journal notes for losses.dta",replace


# *****************READ IN NEW NATIONAL FBS DATA*****************

fbsData <- read.csv("csv/NEW_National FBS data.csv")
colnames(fbsData) <- c("Country","AreaCode","year","ItemCode","MacroCategory" ,"ItemName","NUM_51","NUM_61","NUM_91","NUM_71" ,"Opening.stocks","ClosingStock","NUM_121","LossRatio","Seed","Notes","ReferenceNumber","X","Mis","X1")
fbsData <- subset(fbsData,ItemName!="Palay")

fbsData$ItemCode <- as.numeric(fbsData$ItemCode)
fbsData$NUM_51 <- as.numeric(fbsData$NUM_51)
fbsData$NUM_61 <- as.numeric(fbsData$NUM_61)
fbsData$NUM_71 <- as.numeric(fbsData$NUM_71)
fbsData$NUM_91 <- as.numeric(fbsData$NUM_91)
fbsData$NUM_121 <- as.numeric(fbsData$NUM_121)

fbsData$ItemCode[fbsData$ItemCode==1067]<-1062

# *****Categorize them exactly as the SUA Loss data:
fbsData$foodgroup <- labelFoods(fbsData$ItemCode)

# //add itemnames
# merge itemcode using "Directory_List of FAOSTAT itemcodes and names.dta", keep(itemname)
# cap drop if _merge==2


# //add areanames
# cap drop areaname
# sort areacode
# merge areacode using "Directory_List of FAOSTAT areanames and codes.dta", keep(areaname)
# cap drop if _merge==2

fbsData <- fbsData[!is.na(fbsData$ItemCode),] 

# gen newfbs=1
# gen symb_121="_"

# *****
# //Calculate loss ratio to detect unreliable cases. 

fbsData <- transform(fbsData,ratio=(round(20*100*NUM_121/(NUM_51+NUM_61+NUM_71))/20)*(NUM_71>=0)+(round(20*100*NUM_121/(NUM_51+NUM_61))/20)*(NUM_71<0) )

fbsData <- subset(fbsData,!is.na(ratio)&(ratio<=50)&(ratio!=0))

#*****

# drop if areaname=="Mauritius" | areaname=="Haiti" //because unreliable

# sort year areacode itemcode 

# save "NEW_National FBS data.dta", replace

save(fbsData,file="NEW_National_FBS_data.dta")