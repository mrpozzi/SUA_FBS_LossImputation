clear all
drop _all
set mem 500m
set more off

					//////////////////////////// ESTIMATION /////////////////////////////
// FOR CEREALS:					
					use "ready for estimations.dta",clear
		* SELECT THE SAMLE *
drop if ratio==0
keep if symb_121=="_" | symb_121=="*" 				

global sample "primary==1 & foodgroup~=15 & foodgroup<=16" 
keep if $sample
drop if year<=1969


****************************************************
levelsof itemcode, local(items)

append using "Artifical Dataset 2011.dta"

//Aggregate Categories with few observations
gen CerealsPulsesD=foodgroup==1 | foodgroup==4
gen RootsTubersSugarCropsD=foodgroup==2 | foodgroup==3
*gen PulsesD=foodgroup==4
gen TreenutsOilCropsCoffeeCocoaD=foodgroup==5  | foodgroup==6 | foodgroup==9
gen VegetablesD=foodgroup==7
gen FruitsD=foodgroup==8
gen AnimalproductsD=foodgroup>=10 & foodgroup<=14 

gen FFV=VegetablesD==1 | FruitsD==1
/*
*gen estgroups=1 if CerealsD==1
gen estgroups=1 if CerealsPulsesD==1
replace estgroups=2 if RootsTubersSugarCropsD==1
*replace estgroups=3 if PulsesD==1
replace estgroups=3 if TreenutsOilCropsCoffeeCocoaD==1
replace estgroups=4 if VegetablesD==1
replace estgroups=5 if FruitsD==1
replace estgroups=6 if AnimalproductsD==1

label def estgroups 1 "CerealsPulsesD" 2 "RootsTubersSugarCropsD" 3  "TreenutsOilCropsCoffeeCocoaD" 4 "VegetablesD" 5 "FruitsD" 6 "AnimalproductsD"
label values estgroups estgroups
*/

gen estgroups=1 if  CerealsPulsesD+TreenutsOilCropsCoffeeCocoaD==1
replace estgroups=2 if RootsTubersSugarCropsD==1
replace estgroups=3 if FFV==1
replace estgroups=4 if AnimalproductsD==1

label def estgroups 1  "Non perishable" 2 "Semi perishable" 3 "Fruits and Fresh Vegetables"   4 "Animal Products"
label values estgroups estgroups

/*
table itemname newregion, c( N countryobs069)

table itemname unsubregionn, c( N countryobs069)
table itemname continentname, c( N countryobs069)


table estgroups newregion, c( N countryobs069)
table estgroups unsubregionn, c( N countryobs069)
*/

/*
table areaname if region==1, c( N countryobs079)
table areaname if region==2, c( N countryobs079)
table areaname if region==3, c( N countryobs079)
table areaname if region==4, c( N countryobs079)
table areaname if region==5, c( N countryobs079)


table areaname unsubregionname if region==1, m c( N countryobs079)
table areaname unsubregionname if region==2,m c( N countryobs079)
table areaname unsubregionname if region==3,m c( N countryobs079)
table areaname unsubregionname if region==4,m c( N countryobs079)
table areaname unsubregionname if region==5,m c( N countryobs079)
table areaname unsubregionname if region==6,m c( N countryobs079)
*/


drop  cereals- other_meat_proc
replace itemname=strtoname(itemname)

gen keepthis=0
foreach c of local items {

replace keepthis=1 if `c'==itemcode
}

keep if keepthis==1
drop keepthis



levelsof itemname, local(names)
foreach c of local names {
levelsof itemcode if itemname=="`c'", local(codes)

gen CT`c'=itemcode==`codes'

}





global commoD "CT*" //
global groupD "RootsTubersSugarCropsD - AnimalproductsD" //

replace newregion="North Afr _ Middle East" if newregion=="Northern Africa" | newregion=="Middle East"
replace newregion="Europe" if continentname=="Europe" & newregion~="Balkan" & newregion~="Eastern Europe"
replace newregion="Eastern Europe" if newregion=="Balkan" | newregion=="Eastern Europe"
replace newregion="N.America Australia NewZealand" if newregion=="Northern America" | newregion=="Australia and New Zealand"

replace newregion=strtoname(newregion)

levelsof newregion, local(names)
foreach c of local names {

gen `c'D=newregion=="`c'"

}
global subregioD "Central_Asia_to_PakistanD- Eastern_EuropeD Latin_AmericaD- South__east_Asia_and_PacificD"
*************
************* Descriptive Stats
cap drop countryobs*
gen tag=1 if artsample~=1 & newfbs~=1 

bys itemcode areacode tag: egen countryobs= sum(tag)
bys itemcode areacode tag (year): replace countryobs=. if _n~=1 | tag==. 

gen tag2=1 if artsample~=1 

bys itemcode areacode tag2: egen countryobs2= sum(tag2)
bys itemcode areacode tag2 (year): replace countryobs2=. if _n~=1 | tag2==. 

gen tag3=1 if newfbs==1 

bys itemcode areacode tag3: egen countryobs3= sum(tag3)
bys itemcode areacode tag3 (year): replace countryobs3=. if _n~=1 | tag3==. 

*bys itemname: egen countryobs=sum(countryobs~=.)	
*bys region: egen countryobs=sum(countryobs069~=.)	



*********
/*
levelsof foodgroup, local(allcategories) 
foreach g of local allcategories {
ta foodgroup if foodgroup==`g'
table itemname newregion if foodgroup==`g',nol c( N countryobs)
display "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
}
levelsof foodgroup, local(allcategories) 
foreach g of local allcategories {
ta foodgroup if foodgroup==`g'
table itemname newregion if foodgroup==`g',nol c( N countryobs3)
display "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
}

levelsof foodgroup, local(allcategories) 
foreach g of local allcategories {
ta foodgroup if foodgroup==`g'
table itemname if foodgroup==`g' & artsample~=1 & newfbs~=1 
display "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
}
levelsof foodgroup, local(allcategories) 
foreach g of local allcategories {
ta foodgroup if foodgroup==`g'
table itemname if foodgroup==`g' & artsample~=1
display "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
}
table newregion if artsample~=1 & newfbs~=1 
table newregion if artsample~=1
*/
***************



						*** Variable generation ***


*ta region, gen(regionD)
*ta unsubregionname, gen(subregionD)
*ta itemcode, gen(cropD)
*ta symb_121, gen(flagD)



*cap drop *_i
*gen food_i=.

cap drop time* gdp2 lnratio

gen lnratio=ln(ratio+0.05)

/*
gen combine=num_combine/num_agland
gen tractors=num_tractors/num_agland

gen nri_m=nri==.
gen combine_m=combine==.
gen tractors_m=tractors==.
gen yexprice_m=yexprice==.
gen yimprice_m=yimprice==.
gen exprod_m=exprod==.
*/

gen gdp_m=gdp==.
gen pavedroads_m=pavedroads==.
gen mean_temp_m=mean_temp==.
gen mean_precip_m=mean_precip==.
gen sd_temp_m=sd_temp==.
gen sd_precip_m=sd_precip==.

egen missing=rowtotal(gdp_m pavedroads_m mean_temp_m mean_precip_m sd_temp_m)
replace missing=missing>0

recode gdp pavedroads mean_temp mean_precip sd_temp sd_precip /*nri exprod yimprice yexprice combine tractors*/ (.=0)


gen time=year-1960
gen time2=time^2
gen time3=time^3

gen gdp2=gdp^2
gen gdp3=gdp^3

gen mean_temp2=mean_temp^2
gen mean_temp3=mean_temp^3

gen mean_precip2=mean_precip^2
gen mean_precip3=mean_precip^3

gen mean_tempXprecip=mean_temp*mean_precip

/*
gen yimp=yimprice/gdp
gen yexp=yexprice/gdp
*/

***

//LOGARITHMIC EXPLANATORY VARIABLES

gen lngdp=ln(gdp)
gen lnmean_temp=ln(mean_temp)
gen lnmean_precip=ln(mean_precip)
gen lnsd_temp=ln(sd_temp)
gen lnsd_precip=ln(sd_precip)
gen lnmin_temp=ln(min_temp)
gen lnmax_temp=ln(max_temp)
gen lnmin_precip=ln(min_precip)
gen lnmax_precip=ln(max_precip)

gen lnyimprice=ln(yimprice)
gen lnexprice=ln(yexprice)

gen lnmean_tempXprecip=lnmean_temp*lnmean_precip

gen lngdp2=lngdp^2
gen lngdp3=lngdp^3


*CALCULATE SAMPLE WEIGHT
/*
bys itemcode areacode newfbs: egen sweight=sum(1)
replace sweight=1/(sqrt(sweight)) if newfbs==.
replace sweight=1 if newfbs==1 
*/
egen clusterid=group(itemcode areacode)

bys itemcode: egen country_obs= sum(countryobs2~=.)
gen crop_underidentified=countryobs<=1
label var crop_underidentified "For this crop we have only one country observation"

//////////////////////////////
global time "time"
global gdp "gdp gdp2 gdp3"
global pavedroads "pavedroads"

global precipitation "mean_precip"
global precipitation2 "mean_precip mean_precip2"
global precipitation3 "mean_precip mean_precip2 mean_precip3"

global temperature "mean_temp"
global temperature2 "mean_temp mean_temp2 sd_temp"
global temperature3 "mean_temp mean_temp2 mean_temp3 sd_temp"

global minmax_temp "min_temp max_temp"

global tempXprecip "mean_tempXprecip"

global time3I "i.estgroups*time i.estgroups*time2 i.estgroups*time3"

global gdpI "i.estgroups*gdp"

global gdp2I "i.estgroups*gdp i.estgroups*gdp2"

global gdp3I "i.estgroups*gdp i.estgroups*gdp2 i.estgroups*gdp3"

global pavedroadsI "i.estgroups*pavedroads"

global imppriceI "i.estgroups*yimprice"
global exppriceI "i.estgroups*yexprice"

global precipitationI " i.estgroups*mean_precip"
global precipitation2I " i.estgroups*mean_precip i.estgroups*mean_precip2"
global precipitation3I " i.estgroups*mean_precip i.estgroups*mean_precip2 i.estgroups*mean_precip3"

global temperatureI "i.estgroups*mean_temp"
global temperature2I "i.estgroups*mean_temp i.estgroups*mean_temp2"
global temperature3I "i.estgroups*mean_temp i.estgroups*mean_temp2 i.estgroups*mean_temp3"

global minmax_tempI "i.estgroups*min_temp i.estgroups*max_temp"

global tempXprecipI "i.estgroups*mean_tempXprecip"
global tempXsd_tempI "i.estgroups*mean_tempXsd_temp"

global sd_tempI "i.estgroups*sd_temp"
global sd_precipI "i.estgroups*sd_precip"
global regionXfoodgroup "i.estgroups*i.newregion"

//LOG VARIABLES

global lngdpI "i.estgroups*lngdp"
global lngdp2I "i.estgroups*lngdp i.estgroups*lngdp2"
global lngdp3I "i.estgroups*lngdp i.estgroups*lngdp2 i.estgroups*lngdp3"
global lnprecipitationI " i.estgroups*lnmean_precip"
global lntemperatureI "i.estgroups*lnmean_temp"
global lntempXprecipI "i.estgroups*lnmean_tempXprecip"
global lnimppriceI "i.estgroups*lnyimprice"



//FINAL EQUATION ???
global xI "$subregioD $commoD $time3 $pavedroadsI $gdp3I $temperature3I $precipitationI $sd_tempI $tempXprecipI"
//
global xI "$subregioD $commoD $time $pavedroadsI $gdpI $temperatureI $sd_tempI $precipitationI $tempXprecipI"

global xI "$subregioD $commoD $time $pavedroadsI $gdp3I $temperatureI $sd_tempI $precipitationI $tempXprecipI $tempXsd_temp $minmax_tempI $imppriceI"
global lnxI "$subregioD $commoD $time $pavedroadsI $lngdp3I i.estgroups*max_temp $lnimppriceI"

*reg lnratio $subregioD $commoD time time2 time3 gdp gdp2 gdp3 gdp_m nri nri2 nri_m  pavedroads pavedroads_m if $ifcond,vce(robust) 
*reg lnratio $subregioD $commoD time time2 time3 penn_gdp penn_gdp2 penn_gdp3 penn_gdp_m nri nri2 nri_m  pavedroads pavedroads_m if $ifcond,vce(robust) 

global ifcond "year>1969 & ratio~=0"
global ifcond "year>1969 & ratio~=0 & missing==0"

cap drop prediction*

xi:reg lnratio $lnxI if $ifcond,cluster(clusterid) 
predict prediction if missing==0
*predict prediction
predict prediction_se if missing==0, stdp
gen prediction_lb = prediction - invnormal(0.975)*prediction_se
gen prediction_ub = prediction + invnormal(0.975)*prediction_se
replace prediction=exp(prediction)
replace prediction_lb=exp(prediction_lb)
replace prediction_ub=exp(prediction_ub)
replace prediction_se=exp(prediction_se)

levelsof foodgroup, local(foodgroup)
foreach n of local foodgroup {
ta foodgroup if foodgroup==`n'
su prediction if foodgroup==`n' & artsample==1,d
centile prediction if foodgroup==`n' & artsample==1, centile(99)
local p=`r(c_1)'
ta areaname if prediction>=`p' & prediction<. & foodgroup==`n' & artsample==1
ta itemname if prediction>=`p' & prediction<. & foodgroup==`n' & artsample==1
replace prediction=`p' if prediction>`p' & prediction<. & foodgroup==`n' & artsample==1
}
ta itemname if prediction>80 & artsample==1 & prediction<.
ta areaname if prediction>80 & artsample==1 & prediction<.
/*
forvalues n=1(1)4 {
su prediction if estgroup==`n' & artsample==1,d
centile prediction if estgroup==`n' & artsample==1, centile(98)
local p=`r(c_1)'
ta areaname if prediction>=`p' & prediction<. & estgroup==`n' & artsample==1
ta itemname if prediction>=`p' & prediction<. & estgroup==`n' & artsample==1
replace prediction=`p' if prediction>`p' & prediction<. & estgroup==`n' & artsample==1
}
*/
/*
*Validation:
twoway (scatter prediction ratio if $ifcond) (line ratio ratio), name(prediction,replace) 

*Factor analysis +++(add confidence intervals!)
cd "$foldgr"
twoway function y= _b[time] * x + _b[time2] * x^2 + _b[time3] * x^3, range(11 51) name(time, replace) title("Time") 

twoway function y= _b[gdp] * x + _b[gdp2] * x^2 + _b[gdp3] * x^3, range(600 50000) name(gdp, replace) title("GDP") 

twoway function y= _b[mean_temp] * x + _b[mean_temp2] * x^2 + _b[mean_temp3] * x^3, range(0 30) name(temp, replace) title("Temperature") 

*twoway function y= _b[nri] * x + _b[nri2] * x^2 + _b[nri3] * x^3, range(0 2000) name(nri, replace) title("NRI") nodraw
cd "$folder"
*/
table foodgroup if $ifcond & artsample~=1, c(mean ratio mean prediction)
table itemname if  $ifcond, c(mean ratio mean prediction)
table foodgroup if artsample==1, c(mean prediction)
table itemname newregion if artsample==1, c(mean prediction)

keep if artsample==1
	
*+ output of a table with: predicted loss, lower and upper bound, degree of identification, assigned loss ratios and 
*+ FAO loss ratios.
*+ include also non included items (keepthis==0). 	
outsheet itemname areaname  countrycode  suaratio prediction prediction_lb prediction_ub country_obs using "${foldoutput}/loss_impuation_of_all_crops.csv",replace delimiter(",")
//	e			
		

