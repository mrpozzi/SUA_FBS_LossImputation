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
	
# *+ output of a table with: predicted loss, lower and upper bound, degree of identification, assigned loss ratios and 
# *+ FAO loss ratios.
# *+ include also non included items (keepthis==0). 	
# outsheet itemname areaname  countrycode  suaratio prediction prediction_lb prediction_ub country_obs using "${foldoutput}/loss_impuation_of_all_crops.csv",replace delimiter(",")
# //	e			
		

