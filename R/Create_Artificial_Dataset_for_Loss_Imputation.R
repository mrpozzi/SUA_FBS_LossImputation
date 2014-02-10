# ////////// GENERATE IMPUTATION SAMPLE  ////////////////
# /*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*
# ***Note***
# This do-file creates a dataset which is needed to to predict rates.
# After losses are estimated, the estimation parameters are used to calulate
# point estimates and standard errors on the basis of this dataset.  

# The do-file builds a dataset with all countries (without old countries like USSR etc.)
# and items of the SUA Working System. All country and item specific characteristics (GDP,
# climate data, etc.) which are used in the estimation are merged the data. 
# We use the year of 2011 as the reference year for prediction. For later years we don't have 
# GDP data. 
# *~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/

# non so se leggere il csv o partire dai dati manipolati: chiedi...
cat("loading SUA_waste.csv\n")
wasteSUA <- read.csv("csv/SUA_waste.csv",stringsAsFactors=FALSE)
load("SUA_waste.RData")

# secondo me questo e inutile...
# gen year=2011 //2011 is the reference year. Country characteristics of this year are merged.
# # keep areaname itemname area item ele year num_2011 symb_2011
# keep if ele==51 | ele==61

# *drop remaining old countries:
wasteSUA <- wasteSUA[!wasteSUA$areaname%in%c("China ex.int","Czechoslovakia","Ethiopia PDR","Gaza Strip (Palestine)","Netherlands Antilles","Serbia and Montenegro","USSR","Yemen Ar Rp","Yemen Dem","Yugoslav SFR"),] 

# *not sure if drop these
wasteSUA <- wasteSUA[!wasteSUA$areaname%in%c("Belgium-Luxembourg","Gaza Strip (Palestine)","West Bank"),]
                        

# *levelsof areacode, local(acodes)
rename area areacode
levelsof item, local(icodes)

#che vuol dire questo?
# bys areacode: keep if _n==1

wasteSUA <- wasteSUA[!wasteSUA$areaname%in%c("EU(12)ex.int","EU(15)ex.int","EU(25)ex.int","EU(27)ex.int","Test Area"),]
# *drop if areaname=="Belgium-Luxembourg" 
 
 
keep year areacode areaname 

# foreach i in `icodes' { 
# gen item`i'=1 
# } 
# foreach n in 51 71 61 91 121 { 
# gen symb_`n'="" 
# gen num_`n'=.  
# } 
 
 
 
reshape long item, i(areacode) j(itemcode) 
drop item 
 
gen artsample=1 
save "artifical dataset temp1.dta",replace 
 
//               Merge external data 
 
*prepare file to use country information 
use "raw waste and external data merged.dta",clear 
bys areacode year: keep if _n==1 
drop if year~=2011 
keep areacode year countrycode continentcode unsubregioncode unsubregionname continentname pavedroads gdp region newregion mean_temp sd_temp mean_precip sd_precip min_temp max_temp 
sort areacode year 
save "external data by year and country for artifical dataset.dta",replace 
*prepare file to match itemprices 
use "raw waste and external data merged.dta",clear 
bys itemcode year: keep if _n==1 
drop if year~=2011 
keep itemcode itemname year yimprice yexprice 
sort itemcode year 
save "external data by year and item for artifical dataset.dta",replace 
 
 
use "artifical dataset temp1.dta",clear 
 
 
*match country information 
sort areacode year 
merge areacode year using "external data by year and country for artifical dataset.dta" 
drop if _merge==2 
drop _merge 
 
*match itemprices and itemnames 
sort itemcode year 
merge itemcode year using "external data by year and item for artifical dataset.dta" 
drop if _merge==2 
drop _merge 
 
 
 //Construct estimation variables 
*Label the items 
###
gen primary=. 
foreach g in $allprimaryfood $allprimarynonfood { 
replace primary=1 if itemcode==`g' 
} 
gen processed=. 
foreach g in $allprocessedfood $allprocessednonfood { 
replace processed=1 if itemcode==`g' 
} 
gen food=. 
foreach g in $allfood { 
replace food=1 if itemcode==`g' 
} 
replace primary=0 if processed==1 
replace processed=0 if primary==1 
replace food=0 if food==. & primary~=. & processed~=. 
 
global prim_derived "cereals roots_tubers sugarcrops pulses treenuts oilcrops vegetables fruits stimulants_spices milk eggs offals slaugtherfats meat liveanimals hides_skins" 
global processed "bran flour sugar vegoils_fats alcohol cheese husked_milledrice starch" 
global fodder_nonfood "fodder_prim nonfoodcrops" 
 
cap label drop food 
label def food 0 "" 
gen foodgroup=. 
local n=1 
 
foreach g in $prim_derived { 
gen `g'=0 
foreach foodnumber of num ${all`g'} { 
replace `g'=1 if itemcode==`foodnumber' & primary==1 
} 
replace foodgroup=`n' if `g'==1  & primary==1 
label def food `n' "`g'",add 
local n=`n'+1 
} 
 
foreach g in $processed { 
gen `g'=0 
foreach foodnumber of num ${all`g'} { 
replace `g'=1 if itemcode==`foodnumber' & processed==1 
}

replace foodgroup=`n' if `g'==1  & processed==1 
label def food `n' "`g'",add 
local n=`n'+1 
} 
 
foreach g in $fodder_nonfood { 
gen `g'=0 
foreach foodnumber of num ${all`g'} { 
replace `g'=1 if itemcode==`foodnumber'  
} 
replace foodgroup=`n' if `g'==1 
label def food `n' "`g'",add 
local n=`n'+1 
} 
 
foreach g in milk fruits vegetables cereals meat { 
gen other_`g'_proc=0 
foreach foodnumber of num ${all`g'} { 
replace other_`g'_proc=1 if itemcode==`foodnumber' & foodgroup==. 
} 
replace foodgroup=`n' if other_`g'_proc==1 & foodgroup==. 
label def food `n' "other_`g'_proc",add 
local n=`n'+1 
} 
 
replace foodgroup=99 if foodgroup==. 
label def food 99 "Other/Still needs to be classified",add 
label value foodgroup food 
 
save "Artifical Dataset 2011 temp.dta", replace 
************************************************** 
 
						///////////// ADD SUA FLAGS TO THE ARTSAMPLE //////////////// 
												 
use "sua data_waiting for elaboration.dta",clear 
 
drop  num_1961- symb_2010 num_2012- other_meat_proc 
 
rename num_2011 num_ 
rename symb_2011 symb_ 

reshape wide num_ symb_ , i(itemcode itemname areacode areaname) j(elementcode) 
 
append using "Artifical Dataset 2011 temp.dta" 
recode artsample (.=0) 
foreach i in 51 61 71 91 121 { 
bys areacode itemcode (artsample): replace symb_`i'=symb_`i'[_n-1] if _n==2 
bys areacode itemcode (artsample): replace num_`i'=num_`i'[_n-1] if _n==2 
 
} 
//Check if the Artsample is complete! There might be some items or countries missing. 
 
keep if artsample==1 
********** 
//////////// MERGE SUA LOSS RATIOS //////////////// 
 
cap drop _merge 
sort areacode itemcode year  
merge areacode itemcode year using "SUA_TCF loss ratios.dta", keep(suaratio) 
drop if _merge==2 
drop _merge 
 
//////////// MERGE ITEMNAMES //////////////// 
 
drop itemname 
sort itemcode 
merge itemcode using "Directory_List of FAOSTAT itemcodes and names.dta" 
cap drop if _merge==2 
drop _merge 
 
 
save "Artifical Dataset 2011.dta", replace 
 
