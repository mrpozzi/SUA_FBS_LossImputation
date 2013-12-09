
                               /////////////////  MERGE EXTERNAL DATASETS  ///////////////////
							   
/*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*
***Note***								   
- First the additional dataset "NEW national FBS data.dta" is added to the the SUA loss data.
- Journal notes are merge
- ISO3 codes are merged
- In older SUA loss data some countries do not exist anymore. It is difficult to get information
about the GDP and climate for these countries. However we don't want to loose the information 
from these countries. So we assign these old countries the characteristic of new countries 
which represent them at most. E.g for Yugoslavia we assing the data of Serbia, for USSR the 
data of Russia, etc.  
-
									   
Also Note: NO EXTERNAL DATA for TAIWAN available. 
           NO EXTERNAL DATA for the YEARS 2011 AND 2012. Values of 2010 
           are filled in into the following years.							   
*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/

clear all
set mem 1150m

*qui{							   
use "SUA_waste reshaped.dta",clear		
*keep if symb_121=="_" | symb_121=="*" 

//add the loss data obtained for data collection
append using  "NEW_National FBS data.dta"
 
drop  cereals- other_meat_proc //redundant variables


//add journal notes
cap drop _merge
sort areacode itemcode year 
merge areacode itemcode year using "SUA_Journal notes for losses.dta", keep(note user value symbol)
drop if _merge==2
drop _merge symbol value

//merge ISO codes and world region classifications							   							  
sort areacode itemcode year
merge areacode using "Directory_ISO vs FAOSTAT country codes.dta", keep(iso3 unsubregioncode unsubregionname continentcode continentname) // Allocate ISO Country Codes

drop if _merge==2

rename iso3 countrycode

//Give countries which don't exist anymore the ISO3 code of the present which represents them the most.
replace countrycode="BEL" if areaname=="Belgium-Luxembourg" 
replace countrycode="CZE" if areaname=="Czechoslovakia" 
replace countrycode="ETH" if areaname=="Ethiopia PDR" 
replace countrycode="PSE" if areaname=="Gaza Strip (Palestine)" 
replace countrycode="SRB" if areaname=="Serbia and Montenegro" 
replace countrycode="RUS" if areaname=="USSR" 
replace countrycode="PSE" if areaname=="West Bank" 
replace countrycode="YEM" if areaname=="Yemen Ar Rp" 
replace countrycode="YEM" if areaname=="Yemen Dem" 
replace countrycode="SRB" if areaname=="Yugoslav SFR" 

drop if areaname=="Test Area" //no real observation

				***********MERGE WORLD BANK DATA**************

sort countrycode year
cap drop _merge
merge countrycode year using "${folddta}/World Bank_Share of Paved Roads data.dta" // Taiwan not in WB roads data.

ta areaname if _merge==1 & year<=2010 // have no Infrastructure Data for these Faostat data
ta country if _merge==2 // no corresponding country in Faostat found
drop country
drop if _merge==2
bys areaname itemname (year): replace pavedroads_original=pavedroads_original[_n-1] if year==2011 | year==2012 
*bys areaname itemname (year): replace pavedroads_missing=pavedroads_missing[_n-1] if year==2011 | year==2012 
bys areaname itemname (year): replace pavedroads=pavedroads[_n-1] if year==2011 | year==2012 
bys areaname itemname (year): replace pavedroads_trend=pavedroads_trend[_n-1] if year==2011 | year==2012 


***********************
					* WB Temperature and climate data
cap drop _merge
sort countrycode
merge countrycode using "World Bank_Temperature and Precipitation data.dta"
drop if _merge==2


							* World Bank GDP
sort countrycode year
cap drop _merge

merge countrycode year using "World Bank_GDP data.dta", keep(gdp gdppredicted countryname)

ta areaname if _merge==1 & year<=2010
ta countryname if _merge==2 & year>=1961
drop if _merge==2

//repeat GDP of 2011 in 2012 (were it was unavailable)
bys areaname itemname (year): replace gdp=gdp[_n-1] if year==2012 
bys areaname itemname (year): replace gdppredicted=gdppredicted[_n-1] if year==2012 

						///////////// MERGE SUA LOSS RATIOS ////////////////

cap drop _merge
sort areacode itemcode year 
merge areacode itemcode year using "SUA_TCF loss ratios.dta", keep(suaratio)
drop if _merge==2
drop _merge


						///////////// MERGE IMPORT AND EXPORT PRICES ////////////////

sort itemcode year 
merge itemcode year using "${folddta}/trade_unitvalue.dta", keep(yimprice yexprice)
drop if _merge==2
drop _merge

sort areacode itemcode year 


   *****************  VARIABLE CONSTRUCTION ****************


				*********** CALCULATE LOSS RATIO *****************
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

 
 
//Construct differences of production. It is used to capture excess production

bys areacode itemcode (year): gen lagged1_num_51=(num_51[_n]-num_51[_n-1])/num_51[_n-1]
bys areacode itemcode (year): gen lagged2_num_51=(num_51[_n-1]-num_51[_n-2])/num_51[_n-2]
bys areacode itemcode (year): gen lagged3_num_51=(num_51[_n-2]-num_51[_n-3])/num_51[_n-3]
bys areacode itemcode (year): gen lagged4_num_51=(num_51[_n-3]-num_51[_n-4])/num_51[_n-4]
bys areacode itemcode (year): gen lagged_num_51=(num_51[_n-4]-num_51[_n-5])/num_51[_n-5]
 
 
 
save "raw waste and external data merged.dta",replace


				***************************************************************************
				///////////////////////////////////////////////////////////////////////////	 					
				***************************************************************************

clear all
use "raw waste and external data merged.dta",clear


//Drop if Losses are missing 
drop if symb_121=="M"  
drop if symb_121=="" | symb_121=="P" //(The meaning of Flag "P" is unknown. However there are only 2 observations.

keep if symb_121=="_"	

drop if ratio==.


save "ready for estimations.dta",replace
