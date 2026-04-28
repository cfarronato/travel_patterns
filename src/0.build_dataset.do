clear all
global x "/Users/flavioporta/Library/CloudStorage/Dropbox/Shared_travel patterns"
cd "$x/raw_data"

import delimited "/Users/flavioporta/Documents/PAPERS/Tourism/meta/TCOMUNI.csv",  stringcols(6) clear  
rename elem_dominio comune_visitato_code
rename d_el_dominio comune_visitato_name
drop if d_morte_el_dom<20501231
bysort comune_visitato_code: gen number = _N
keep if number==1
save comuni.dta, replace 


import delimited "/Users/flavioporta/Documents/PAPERS/Tourism/meta/TFRONTIERE.csv", clear 
rename codice local_interv
rename descrizione aeroporto
save aeroporti.dta, replace 

import delimited "/Users/flavioporta/Documents/PAPERS/Tourism/meta/TMOTIVOVIAGGIO.csv", clear 
*drop if data_fine_val<20501231
rename codice motivo_viaggio
rename descrizione motivo_viaggio_descrizione
save motivo_viag.dta, replace 

import delimited "/Users/flavioporta/Documents/PAPERS/Tourism/meta/TMOTIVOVACANZA.csv", clear 
*drop if data_fine_val<20501231
rename codice motivo_vacanza
rename descrizione motivo_vacanza_descrizione
save motivo_vac.dta, replace 

import delimited "/Users/flavioporta/Documents/PAPERS/Tourism/meta/TSTATI.csv", clear 
drop if d_morte_el_dom<20501231
rename elem_dominio stato_residenza
rename d_el_dominio stato_residenza_nome
drop if missing(stato_residenza_nome)

save stati.dta, replace 

import delimited "/Users/flavioporta/Documents/PAPERS/Tourism/meta/TALLOGGIO.csv", clear 
drop if data_fine_val<20501231
rename codice alloggio_princ_08
rename descrizione alloggio_princ_nome
save alloggio.dta, replace 

import delimited "/Users/flavioporta/Documents/PAPERS/Tourism/meta/TPROVINCE.csv", clear 
rename elem_dominio provincia_visitata 
rename d_el_dominio provincia_visitata_name
save province.dta, replace

import delimited "/Users/flavioporta/Documents/PAPERS/Tourism/meta/TREGIONI.csv", clear 
rename valore_classif regione_visitata 
rename desc_val_class regione_visitata_name
save regioni.dta, replace



clear 
save dataset, emptyok replace 
forval i=2002/2024{
import delimited "/Users/flavioporta/Documents/PAPERS/Tourism/datacsv/stra_princ/stra_`i'_principali.csv", stringcols(1) clear
gen year_survey=`i'
append using dataset
save dataset.dta, replace 
}


use dataset.dta, clear 
gen business_trip=0
replace business_trip=1 if motivo_viaggio_97>13
drop if motivo_viaggio_97==29 | motivo_viaggio_97==25  | motivo_viaggio_97==14 // drop frontalieri, transfer, other reasons 
drop motiv* 

merge m:1 stato_residenza using stati.dta, keepusing(stato_residenza_nome)
keep if _merge==3
drop _merge

rename stato_residenza country_origin_code
rename stato_residenza_nome country_origin_name
order country_origin_code country_origin_name

merge m:1 local_interv using aeroporti.dta, keepusing(aeroporto regione_aeroporto  provincia_aeroporto airportcode)
keep if _merge==3
drop _merge
rename aeroporto place_interview_name 
rename regione_aeroporto airport_region
rename provincia_aeroporto airport_province  
rename airportcode airport_code 
 

merge m:1 alloggio_princ_08 using alloggio.dta, keepusing(alloggio_princ_nome)
keep if _merge==3
drop _merge
drop if alloggio_princ_08==40 // eliminate those who did not spend a night 

gen byte accommodation=0
replace accommodation = 1 if inlist(alloggio_princ_08, 12)
replace accommodation = 2 if inlist(alloggio_princ_08, 3, 17)
label define accommodation_lbl 0 "outsidegood" 1 "hotel" 2 "str", replace
label values accommodation accommodation_lbl

rename alloggio_princ_nome accommodation_name
rename alloggio_princ_08 accommodation_code

 
merge m:1 provincia_visitata using province.dta, keepusing(provincia_visitata_name ref_area)
keep if _merge==3
drop _merge
rename provincia_visitata province_code
rename provincia_visitata_name province_name
rename ref_area province_nuts_code

 
merge m:1 regione_visitata using regioni.dta, keepusing(regione_visitata_name region area)
keep if _merge==3
drop _merge

rename regione_visitata region_code
rename regione_visitata_name region_name
rename region region_nuts_code
 
rename comune_visitato  comune_visitato_code
merge m:1 comune_visitato_code using comuni.dta, keepusing(comune_visitato_name ref_area)
keep if _merge==3
drop _merge

rename comune_visitato_code municipality_code
rename comune_visitato_name municipality_name
rename ref_area municipality_istat_code
order municipality* region_* province_* accommodation* place_interview_name airport* country_origin_code country_origin_name business_trip

drop voto_*


save "$x/raw_data/dataset.dta", replace 



clear 
save dataset2, emptyok replace 
forval i=2002/2024{
import delimited "/Users/flavioporta/Documents/PAPERS/Tourism/datacsv/stra_seco/stra_`i'_secondarie.csv", stringcols(1) clear
gen year_survey=`i'
append using dataset2
save dataset2.dta, replace 
}

use dataset2.dta, clear  
gen num=1
collapse (sum) num, by (chiave)
sum num
drop if num==2
save chiave_ok.dta, replace 

clear
use dataset.dta, clear 
merge m:1 chiave using chiave_ok
keep if _merge==3
drop _merge 
save dataset.dta , replace 

use dataset2.dta, clear 
foreach v of varlist _all {
    rename `v' `v'_seco
}

rename chiave_seco chiave 
merge m:1 chiave using chiave_ok
keep if _merge==3
drop _merge 
save dataset2.dta, replace 

use dataset.dta, clear 
merge 1:1 chiave using dataset2
keep if _merge==3
drop _merge
erase dataset2.dta
erase chiave_ok.dta

replace professione_10=professione_10_seco if missing(professione_10)
replace classe_eta=classe_eta_seco if missing(classe_eta)
drop year_survey_seco professione_10_seco classe_eta_seco
rename professione_10 profession
rename classe_eta ageclass

drop *_seco 

rename fpd_viag weight_people
rename fpd_notti weight_nights

rename fpd_all_t expand_accommodation_expenditure
rename fpd_spesa_fmi expand_total_expenditure

 label variable expand_accommodation_expenditure "it must be divided by weight_people to get the total expenditure of the traveler, divided by weight_nights to get the expenditure per nights "
 label variable expand_total_expenditure "it must be divided by weight_people to get the total expenditure of the traveler, divided by weight_nights to get the expenditure per nights "

drop fpd_all_p fpd_alt_p fpd_ris_p fpd_tr_intes_p fpd_tr_intit_p fpd_tr_it_es_p fpd_turtra_p nr_notti_x_comune progressivo se_aereo_nave_naz spesa_fmi
save dataset.dta, replace 

export delimited using "/Users/flavioporta/Library/CloudStorage/Dropbox/Shared_travel patterns/raw_data/dataset.csv", replace

erase dataset.dta

