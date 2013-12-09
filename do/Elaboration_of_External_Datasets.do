                   /////////////////  CONSTRUCT EXPTERNAL DATASETS  ///////////////////
/*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*
***Note***	
This file just prepares several datasets:

-"SUA_trade_unitvalue.csv":
Trade data (import and export) from SUA Working System containing prices per quantity for each item.
This dataset is used to construct item prices.

-"Directory_ISO vs FAOSTAT country codes.dta":
Directory of FAOSTAT country codes (areacode) and ISO3 country codes.
ISO3 codes are needed to merge World Bank data.

-"World Bank_Share of Paved Roads.dta":
World Bank data on the share of Paved Roads in a country and a year. Data are not avaialbe for each year.
If data on paved roads for one year are missing, just the data from the same country of the nearest year are 
imputed. Better imputation techniques are welcome.

-"World Bank_Temperature and Precipitation.dta":
World Bank data on monthly means and std. dev. of temperature and precipitation. These are long
term data, so they don't vary over time.

-"World Bank_GDP Data.dta":
World Bank data on countries GDP from the 60's. GDP is in 2005 dollar (PPP converted GDP was only 
available from the 1980's). Missing data are imputed by linear regressions, using a 
simple country-specific linear time trend. Better imputation techniques are welcome.

-"SUA_TCF loss ratios.dta":
Contains FAO loss ratios used for calucating "F"-flagged losses. You can find them in the Handbook
"Technical Conversion Factors for Agricultural Commodities".
This loss rates called 'suaratios' are only used for descriptive purposes.

-"SUA_Journal notes for losses.dta":
Journal notes of the SUA working data. This journal notes should have been already included 
in the original loss data "sua_waste". For some reason they have been downloaded separetely 
(Ask Amanda Gordon. She is responsable for downloading the data from the FAOSTAT system.)
 
-"NEW_National FBS data.dta":
Additional loss data from National FBS and National Statistics Institutes. These data have been
collected by Rachele Brivio. 
New loss data are categorized in the same way as the SUA data in "FWS Data Construction.do".
SUA areaname and itemname are merged to the new data. Unreliable observations are dropped. 

*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/					
		***** Commodity prices, derived from trade data *****
**** Attention. These are import and export prices for each country, without considering
*    quanities. It would be better to calculate the value of worldwide traded commodities
*    and divide it by the quantity of the world trade volume. Need to have data on quantities. Ask
*    Amanda.
		
insheet using "${foldcsv}/SUA_trade_unitvalue.csv",clear names
rename ele elementcode
rename item itemcode
rename area areacode
drop symb_*
drop if areacode==298 //test area
reshape long num_ , i(itemcode  areacode elementcode) j(year)
replace num_=. if num_==0
reshape wide num_ , i(itemcode  areacode year) j(elementcode)


//
gen time=ceil((year-1960)/10)
replace time=5 if time==6

//Cut outliers. 

bys itemcode year: egen p5= pctile(num_63), p(5)  
bys itemcode year: egen p95= pctile(num_63), p(95)
replace num_63=p5 if num_63<p5 
replace num_63=p95 if num_63>p95 
drop p5 p95
bys itemcode year: egen p5= pctile(num_93), p(5)  
bys itemcode year: egen p95= pctile(num_93), p(95)
replace num_93=p5 if num_93<p5 
replace num_93=p95 if num_93>p95 
drop p5 p95

bys itemcode year: egen yimprice=mean(num_63) //average yearly country import prices. 
*!!!!!Attention, these are not global average prices!!!!!
bys itemcode year: egen yexprice=mean(num_93)	


bys itemcode time: egen yimprice2=mean(num_63)
bys itemcode time: egen yexprice2=mean(num_93)		


replace yimprice=yimprice2 if yimprice==.		
replace yexprice=yexprice2 if yexprice==.		


bys itemcode year: drop if _n>1
keep  itemcode year yimprice yexprice
sort itemcode year

save "${folddta}/trade_unitvalue.dta",replace

//	***** List of FAOSTAT areanames and areacodes *****
//*This file is used to merge areanames to some datasets. 	
//insheet using "${foldcsv}/Directory_List_of_FAOSTAT_areanames_and_codes.csv",clear names
//rename faoareaname areaname
//rename faoareacode areacode
//sort areacode
//save "Directory_List of FAOSTAT areanames and codes.dta",replace

	


				***************** ISO COUNTRY CODES *****************
*This file is used to merge ISO3 codes to FAOSTAT data.

insheet using "${foldcsv}/Directory_ISO vs FAOSTAT country codes.csv",clear

gen unsubregionname="South America" if unsubregioncode==5
replace unsubregionname="Western Africa" if unsubregioncode==11
replace unsubregionname="Central America" if unsubregioncode==13
replace unsubregionname="Eastern Africa" if unsubregioncode==14
replace unsubregionname="Northern Africa" if unsubregioncode==15
replace unsubregionname="Middle Africa" if unsubregioncode==17
replace unsubregionname="Southern Africa" if unsubregioncode==18
replace unsubregionname="Northern America" if unsubregioncode==21
replace unsubregionname="Caribbean" if unsubregioncode==29
replace unsubregionname="Eastern Asia" if unsubregioncode==30
replace unsubregionname="Southern Asia" if unsubregioncode==34
replace unsubregionname="Southeastern Asia" if unsubregioncode==35
replace unsubregionname="Southern Europe" if unsubregioncode==39
replace unsubregionname="Australia and New Zealand" if unsubregioncode==53
replace unsubregionname="Melanesia" if unsubregioncode==54
replace unsubregionname="Micronesia" if unsubregioncode==57
replace unsubregionname="Polynesia" if unsubregioncode==61
replace unsubregionname="Central Asia" if unsubregioncode==143
replace unsubregionname="Western Asia" if unsubregioncode==145
replace unsubregionname="Eastern Europe" if unsubregioncode==151
replace unsubregionname="Northern Europe" if unsubregioncode==154
replace unsubregionname="Western Europe" if unsubregioncode==155

gen continentname="Africa" if continentcode==2
replace continentname="Oceania" if continentcode==9
replace continentname="America" if continentcode==19
replace continentname="Asia" if continentcode==142
replace continentname="Europe" if continentcode==150


rename faoareacode areacode

replace faoareaname=trim(faoareaname)
sort areacode 
save "Directory_ISO vs FAOSTAT country codes.dta", replace
	***ISO vs FAOSTAT country codes.dta

				***************** WB DATA ON PAVED ROADS *****************
/*I use here a very rude imputation technique. In case a number is missing,
I just repeat the nearest avaiable number. Since the dataset starts at 1990,
the data are repeated until 1961. However, in the estimation I will set 
observations before 1990 to 0 and use a dummy for missing value.*/
insheet using "${foldcsv}/World Bank_Share of Paved Roads data.csv",clear names
keep countryname countrycode v33- v53


forvalues i =1961(1)1989{
gen pavedroads`i'=.
}

forvalues i = 33(1)53{
local y=`i'+1957
rename v`i' pavedroads`y'
}

rename countryname country

reshape  long pavedroads, i(country countrycode) j(year)

gen pavedroads_missing=pavedroads==.
gen pavedroads_t=.


forvalues n1=1(1)10 {
forvalues n2=1(1)10 {

bys country (year): replace pavedroads_t= ///
pavedroads[_n-`n1']+((pavedroads[_n+`n2']-pavedroads[_n-`n1'])/(`n1'+`n2'))*`n1' ///
if pavedroads==. & pavedroads[_n-`n1']~=. & pavedroads[_n+`n2']~=. & pavedroads_t==.


}
}
gen prmiss2=pavedroads==. & pavedroads_t==.

gen pavedroads_i=pavedroads
replace pavedroads_i=pavedroads_t if pavedroads_t~=.

gen pavedroads_f=.

forvalues n=1(1)50 {

bys country (year): replace pavedroads_f=pavedroads_i[_n+`n'] ///
 if prmiss2[_n+`n']==0 & prmiss2==1 & prmiss2[_n+`n'-1]==1 & pavedroads_f==.

 bys country (year): replace pavedroads_f=pavedroads_i[_n-`n'] ///
 if prmiss2[_n-`n']==0 & prmiss2==1 & prmiss2[_n-`n'+1]==1 & pavedroads_f==.

 
}

rename pavedroads pavedroads_original

gen pavedroads=pavedroads_original
replace pavedroads=pavedroads_t if pavedroads_t~=.
replace pavedroads=pavedroads_f if pavedroads_f~=.


gen pavedroads_trend=pavedroads_t~=.

drop pavedroads_i pavedroads_t pavedroads_f prmiss2


sort country
sort countrycode year
save "World Bank_Share of Paved Roads data.dta",replace

				***************** WB DATA ON TEMPERATURE AND PRECIPITATION *****************
insheet using "${foldcsv}/World Bank_Temperature and Precipitation data.csv",clear names
rename iso_3digit countrycode
rename annual_temp mean_temp
rename annual_precip mean_precip

egen sd_precip = rowsd(jan_precip-dec_precip)
egen min_precip = rowmin(jan_precip-dec_precip)
egen max_precip = rowmax(jan_precip-dec_precip)

egen sd_temp = rowsd(jan_temp-dec_temp)
egen min_temp = rowmin(jan_temp-dec_temp)
egen max_temp = rowmax(jan_temp-dec_temp)

keep countrycode mean_* sd_* min_* max_*
sort countrycode
save "World Bank_Temperature and Precipitation data.dta",replace
  

				***************** World Bank GDP Data *****************


insheet using  "${foldcsv}/World Bank_GDP data.csv",clear na
forvalues n=3(1)55 {
local y=`n'+1957
rename v`n' gdp`y'
}
reshape long gdp, i(countrycode) j(year)

replace countrycode="COD" if countrycode=="ZAR"
replace countrycode="ROU" if countrycode=="ROM"

sort countrycode year

gen lngdp=ln(gdp)
xi: reg lngdp i.countrycode*year
predict lngdpp
gen gdppred=exp(lngdpp)
rename gdp gdp_original
gen gdp=gdp_original
replace gdp=gdppred if gdp_original==.
label var gdp "Real and Predicted Values of GDP"
drop lngdpp gdppred _I*
gen gdppredicted=gdp_original==.

drop if year==2012 //Imputations have some discontinuities. For forecast better use GDP of 2011 
save "World Bank_GDP data.dta",replace
    ****World Bank GDP Data

				***************** SUA LOSS RATIOS *****************

insheet using "${foldcsv}/SUA_TCF loss ratios.csv",clear names
rename v8 fixedsuaratio

forvalues n =9(1)58 {
local y=`n'+1952
rename v`n' suaratio`y'
replace suaratio`y'=fixedsuaratio if suaratio`y'==.
}

reshape long suaratio, i(areacode itemcode) j(year)

gen suaratiochanged=suaratio~=fixedsuaratio
sort areacode itemcode year
save "SUA_TCF loss ratios.dta",replace

   
				***************** SUA LOSS RATIOS JOURNAL NOTES *****************
insheet using "${foldcsv}/SUA_Journal notes for losses.csv",clear names
bys areacode itemcode year (versionno): gen nversions=_N 
bys areacode itemcode year (versionno): keep if _n==_N

replace symbol="_" if symbol==""

save "SUA_Journal notes for losses.dta",replace

**************************************************
//now sort directory for FWS data.
insheet using "$foldcsv/SUA_waste.csv",clear
rename area areacode
bys areacode: drop if _n>1
keep areacode areaname
sort areacode 

save "Directory_List of FAOSTAT areanames and codes.dta", replace

***************** LIST OF ITEMCODES AND ITEMNAMES *****************
insheet using "$foldcsv/SUA_waste.csv",clear
rename item itemcode
bys itemcode: drop if _n>1
keep itemcode itemname
sort itemcode
save "Directory_List of FAOSTAT itemcodes and names.dta", replace


*****************READ IN NEW NATIONAL FBS DATA*****************
insheet using "${foldcsv}/NEW_National FBS data.csv",clear

drop if commodity=="Palay" //drop because unreliable


rename  commoditycode itemcode
destring itemcode,replace
rename   countrycode areacode
rename commodity itemname
rename production num_51
rename imports num_61
rename exports num_91
rename stockvariation num_71
rename losses num_121


destring num_51 num_61 num_71 num_91 num_121,replace 

keep itemcode year areacode itemname num_*

replace itemcode=1062 if itemcode==1067

*****Categorize them exactly as the SUA Loss data:

* CROPS
global allcereals "15	16	17	18	19	20	21	22	23	24	27	28	29	31	32	33	34	35	37	38	41	44	45	46	47	48	49	50	56	57	58	59	61	63	64	68	71	72	73	75	76	77	79	80	81	83	84	85	89	90	91	92	94	95	96	97	98	99	101	103	104	105	108	110	111	112	113	114	115	846"
global allroots_tubers "116	117	118	119	120	121	122	125	126	127	128	129	135	136	137	149	150	151"
global allsugarcrops "154	155	156	157	160	161	162	163	164	165	166	167	168	169	170	171	172	173	174	175"
global allpulses "176	181	187	191	195	197	201	203	205	210	211	212	213"
global alltreenuts "216 217	220	221	222	223	225	234"
global alloilcrops "36	60	236	237	238	242	243	244	245	246	249	250	251	252	253	256	257	258	259	260	261	262	263	264	265	266	267	268	269	270	271	272	273	274	275	276	277	278	280	281	282	289	290	291	292	293	294	295	296	297	298	299	306	307	311	312	313	314	329	331	332	333	334	335	336	337	338	339	340	341	343"
global allvegetables "358	366	367	372	373	378	388	389	390	391	392	393	394	397	399	401	402	403	406	407	414	417	420	423	426	430	446	447	448	449	450	451	463	464	465	466	469	471	472	473	474	475	476"
global allfruits "461	486	489	490	491	492	495	496	497	498	499	507	509	510	512	513	514	515	518	519	521	523	526	527	530	531	534	536	537	538	539	541	542	544	547	549	550	552	554	558	560	561	562	566	567	568	569	570	571	572	574	575	576	577	580	583	584	587	591	592	600	603	604	619	620	622	623	624	625	626"
global allstimulants_spices "224	226	459	656	657	658	659	660	661	662	663	664	665	666	667	671	674	677	687	689	692	693	698	702	711	720	723"

* LIVESTOCK
global alloffals "868	948	978	1018	1036	1059	1074	1075	1081	1098	1128	1159	1167"
global allslaugtherfats "869	871	949	979	1019	1037	1040	1043	1065	1066	1129	1160	1168	1222	1225	1243"
global allmeat "867	870	872	873	874	875	877	947	977	1017	1035	1038	1039	1041	1042	1058	1060	1061	1069	1073	1080	1089	1097	1108	1111	1127	1141	1151	1158	1163	1164	1166	1172"
global allliveanimals "866	946	976	1016	1034	1057	1068	1072	1079	1083	1096	1107	1110	1126	1140	1150	1157	1171	1181" 
global allmilk "882	883	885	886	887	888	889	890	891	892	893	894	895	896	897	898	899	900	901	903	904	905	908	909	917	951	952	953	954	955	982	983	984	985	1020	1021	1022	1023	1130"
global alleggs "916	1062	1063	1064	1091"

//  PROCESSED COMMODIDITIES ONLY (WITHOUT PRIMARY)

global allflour "16		38		48		58		72		80		84		90		95		98		104		111		115		117		126		150		212		295		343		624"
global allhusked_milledrice "28 29 31"
global allbran "17	35	47	59	73	77	81	85	91	96	99	105	112	213" //not only cereal. also pulses.
global allstarch "23		34		64		119		129"
global allsugar "154	155	162	163	164	165	166	167	168	169	170	171	172	173	174	175"
//sugar without primary sugar crops
global allvegoils_fats "36	60	237	244	252	257	258	261	264	266	268	271	274	276	278	281	290	293	297	313	331	334	337	340" 
// vegoils_fats without Stillingia Oil[307] and Vegetable Tallow[306] (is a primary oilcrop)
global allalcohol "26	39	51	66	82	86	517	563	564	565	632	634" 
global allcheese "901	904	905	955	984	1021"
global allhides_skins "919	920	921	922	927	928	929	930	957	958	959	995	996	997	998	999	1002	1025	1026	1027	1028	1044	1045	1046	1047	1102	1103	1104	1105	1109	1112	1133	1134	1135	1136	1146	1213	1214	1215	1216	1217"

//  FODDER AND NONFOOD

global allfodder_prim "636	637	638	639	640	641	642	643	644	645	646	647	648	649	651	655"
global allnonfoodcrops "767	778	780	782	789	800	809	813	821	826	836"
//nonfoodcrops without stimulants like tea etc.[656	667	671	674	]
*************************************************************************

//  GENERAL CATEGORIES

global allprimaryfood "15	27	44	56	68	71	75	79	83	89	92	94	97	101	103	108	116	122	125	135	136	137	149	156	157	161	176	181	187	191	195	197	201	203	205	210	211	216	217	220	221	222	223	224	225	226	234	236	242	249	256	260	263	267	270	280	289	292	296	299	311	329	339	358	366	367	372	373	378	388	393	394	397	399	401	402	403	406	407	414	417	420	423	426	430	446	449	459	461	463	486	489	490	495	497	507	512	515	521	523	526	530	531	534	536	541	542	544	547	549	550	552	554	558	560	567	568	569	571	572	574	577	587	591	592	600	603	619	629	630	636	637	638	639	640	641	643	644	645	646	647	648	649	650	651	655	661	671	674	677	687	689	692	693	698	702	711	720	723	748	857	858	859	860	861	866	867	868	869	871	882	946	947	948	949	951	976	977	978	979	982	1016	1017	1018	1019	1020	1034	1035	1036	1037	1040	1057	1058	1059	1062	1065	1068	1069	1072	1073	1074	1075	1079	1080	1081	1083	1089	1091	1096	1097	1098	1107	1108	1110	1111	1126	1127	1128	1129	1130	1140	1141	1150	1151	1157	1158	1159	1160	1163	1166	1167	1168	1171	1176	1182	1501	1514	1527	1540	1553	1562	1570	1579	1587	1594"
//primaryfood without oil of palms[257] (should be in processed!)
global allprocessedfood "16	17	18	19	20	21	22	23	24	26	28	29	31	32	33	34	35	36	37	38	39	41	45	46	47	48	49	50	51	57	58	59	60	61	63	64	66	72	73	76	77	80	81	82	84	85	86	90	91	95	96	98	99	104	105	109	110	111	112	113	114	115	117	118	119	120	121	126	127	128	129	150	151	154	155	160	162	163	164	165	166	167	168	169	170	171	172	173	174	175	212	213	229	230	231	232	233	235	237	238	243	244	245	246	247	250	251	252	253	257	258	259	261	262	264	268	269	271	272	273	274	281	282	290	291	293	294	295	297	298	312	313	314	331	332	340	341	343	389	390	391	392	447	448	450	451	460	464	465	466	469	471	472	473	474	475	476	491	492	496	498	499	509	510	513	514	517	518	519	527	537	538	539	561	562	563	564	565	566	570	575	576	580	583	584	604	620	622	623	624	625	626	628	631	633	634	652	653	654	660	662	663	664	665	666	672	840	841	842	843	845	846	849	850	855	862	870	872	873	874	875	876	877	878	883	885	886	887	888	889	890	891	892	893	894	895	896	897	898	899	900	901	903	904	905	908	909	910	916	917	952	953	954	955	983	984	985	1021	1022	1023	1039	1041	1042	1043	1060	1061	1063	1064	1066	1164	1172	1173	1175	1225	1232	1241	1242	1243	1259	1267	1274	1275	1502	1503	1504	1505	1506	1507	1515	1516	1517	1518	1519	1520	1528	1529	1530	1531	1532	1533	1541	1542	1543	1544	1545	1546	1554	1555	1556	1557	1563	1564	1565	1571	1572	1573	1574	1580	1583	1588	1590	1595	1596"
global allprimarynonfood "265	275	277	306	307 333	336	635	656	667	754	767	773	777	778	780	782	788	789	800	809	813	821	826	836	839	919	927	957	987	995	999	1002	1025	1030	1031	1044	1100	1102	1109	1112	1133	1146	1181	1183	1185	1187	1195	1213	1218	1219	1291	1292	1293	1294	1295	1296"
// primarynonfood without  (is in processed)
global allprocessednonfood "266	276	278	334	335	337	338	632	657	658	659	737	753	755	768	769	770	774	828	829	831	837	920	921	922	928	929	930	958	959	988	994	996	997	998	1007	1008	1009	1026	1027	1028	1045	1046	1047	1103	1104	1105	1134	1135	1136	1186	1214	1215	1216	1217	1221	1222	1276	1277	1508	1509	1510	1511	1521	1522	1523	1524	1534	1535	1536	1537	1547	1548	1549	1550	1558	1559	1566	1567	1575	1576	1581	1582	1584	1589	1591"
// processednonfood without Stillingia Oil[307] and Vegetable Tallow[306] (is in primary)
*****
global allfood "15	16	17	18	19	20	21	22	23	24	26	27	28	29	31	32	33	34	35	36	37	38	39	41	44	45	46	47	48	49	50	51	56	57	58	59	60	61	63	64	66	68	71	72	73	75	76	77	79	80	81	82	83	84	85	86	89	90	91	92	94	95	96	97	98	99	101	103	104	105	108	109	110	111	112	113	114	115	116	117	118	119	120	121	122	125	126	127	128	129	135	136	137	149	150	151	154	155	156	157	160	161	162	163	164	165	166	167	168	169	170	171	172	173	174	175	176	181	187	191	195	197	201	203	205	210	211	212	213	216	217	220	221	222	223	224	225	226	229	230	231	232	233	234	235	236	237	238	239	240	241	242	243	244	245	246	247	249	250	251	252	253	256	257	258	259	260	261	262	263	264	267	268	269	270	271	272	273	274	280	281	282	289	290	291	292	293	294	295	296	297	298	299	311	312	313	314	329	331	332	339	340	341	343	358	366	367	372	373	378	388	389	390	391	392	393	394	397	399	401	402	403	406	407	414	417	420	423	426	430	446	447	448	449	450	451	459	460	461	463	464	465	466	469	471	472	473	474	475	476	486	489	490	491	492	495	496	497	498	499	507	509	510	512	513	514	515	517	518	519	521	523	526	527	530	531	534	536	537	538	539	541	542	544	547	549	550	552	554	558	560	561	562	563	564	565	566	567	568	569	570	571	572	574	575	576	577	580	583	584	587	591	592	600	603	604	619	620	622	623	624	625	626	628	629	630	631	633	634	636	637	638	639	640	641	643	644	645	646	647	648	649	650	651	652	653	654	655	660	661	662	663	664	665	666	671	672	674	677	687	689	692	693	698	702	711	720	723	748	840	841	842	843	845	846	849	850	855	857	858	859	860	861	862	866	867	868	869	870	871	872	873	874	875	876	877	878	882	883	885	886	887	888	889	890	891	892	893	894	895	896	897	898	899	900	901	903	904	905	907	908	909	910	916	917	944	945	946	947	948	949	951	952	953	954	955	972	973	976	977	978	979	982	983	984	985	1012	1013	1016	1017	1018	1019	1020	1021	1022	1023	1032	1033	1034	1035	1036	1037	1038	1039	1040	1041	1042	1043	1055	1056	1057	1058	1059	1060	1061	1062	1063	1064	1065	1066	1068	1069	1070	1071	1072	1073	1074	1075	1077	1078	1079	1080	1081	1083	1084	1085	1087	1088	1089	1091	1094	1095	1096	1097	1098	1107	1108	1110	1111	1120	1121	1122	1123	1124	1125	1126	1127	1128	1129	1130	1137	1138	1140	1141	1144	1145	1150	1151	1154	1155	1157	1158	1159	1160	1161	1162	1163	1164	1166	1167	1168	1171	1172	1173	1175	1176	1182	1225	1232	1241	1242	1243	1259	1267	1274	1275	1501	1502	1503	1504	1505	1506	1507	1514	1515	1516	1517	1518	1519	1520	1527	1528	1529	1530	1531	1532	1533	1540	1541	1542	1543	1544	1545	1546	1553	1554	1555	1556	1557	1562	1563	1564	1565	1570	1571	1572	1573	1574	1579	1580	1583	1587	1588	1590	1594	1595	1596"
				
									
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


//add itemnames
cap drop itemname
sort itemcode
merge itemcode using "Directory_List of FAOSTAT itemcodes and names.dta", keep(itemname)
cap drop if _merge==2
drop _merge

//add areanames
cap drop areaname
sort areacode
merge areacode using "Directory_List of FAOSTAT areanames and codes.dta", keep(areaname)
cap drop if _merge==2
drop _merge

keep if itemcode~=. 

gen newfbs=1
gen symb_121="_"

*****
//Calculate loss ratio to detect unreliable cases. 

recode num_71 (.=0)
cap drop ratio*
gen num61=num_61
gen num71=num_71
recode num61 num71 (.=0)

gen ratio=round(20*100*num_121/(num_51+num61+num71))/20 if num71>=0
replace ratio=round(20*100*num_121/(num_51+num61))/20 if num71<0 
drop num61 num71

drop if ratio==.
drop if ratio>50
drop if ratio==0
drop ratio
*****

drop if areaname=="Mauritius" | areaname=="Haiti" //because unreliable

sort year areacode itemcode 

save "NEW_National FBS data.dta", replace

