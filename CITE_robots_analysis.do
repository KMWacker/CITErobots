**********************************
** CITE JAE Application: Robots **
******* K.M. Wacker, 2025 ********
**********************************

**********************************
*** OVERVIEW OF FILE STRUCTURE ***
*** 1. Data
*** 2. Analysis
***    CITE implementation around 
***    line 135, scatter around 185
*** 3. Marg. effect calculations
*** 4. Diagnostics
**********************************

*0 setup and path (adjust to your system)
clear all
set more off, perm

* set path for data:
cd "C:\Users\..."
* set path for outputs (figures, regression tables):
global outputpath "C:\Users\...\Outputs"


***************
*** 1. DATA ***
***************

/*** 1a PENN WORLD TABLES ***/
/****************************/

use "https://www.rug.nl/ggdc/docs/pwt100.dta"

* limit to years that match robot spells and keep only variables that are potentially relevant:
keep if year>=2004 & year < 2019
keep countrycode country year rgdpo rgdpna pop emp avh hc ctfp labsh irr pl_i pl_n cn	

*** generate potentially relevant interaction variables H
gen ln_gdp_pc = ln(rgdpo/emp)
label var ln_gdp_pc "ln(GDP per worker) in PPP^O"
gen ln_gdp_na = ln(rgdpna)
gen ln_gdp_pc_na = ln(rgdpna/emp)
label var ln_gdp_pc_na "ln(GDP per worker) from national accounts"
gen ln_labinc_pc = ln((rgdpo*labsh)/emp)
label var ln_labinc_pc "ln(labor income) per worker in PPP^O"	

gen k_l_ratio = cn/emp
label var k_l_ratio "K/L ratio"
gen ln_k_l_ratio = ln(k_l_ratio)
label var ln_k_l_ratio "ln(K/L ratio)"


*compute 'demand' change. If other (GDP) variable should be used: replace in "gen five_yr_*"
encode countrycode, gen(isoctry)
xtset isoctry year
gen five_yr_lgdppc = (ln_gdp_pc + L.ln_gdp_pc + L2.ln_gdp_pc + L3.ln_gdp_pc + L4.ln_gdp_pc)/5
gen d_demand = (five_yr_lgdppc - L10.five_yr_lgdppc)/10

*drop variables that are potentially interesting but not essential
drop rgdpo rgdpna pop emp avh hc cn pl_i pl_n k_l_ratio five_yr_lgdppc isoctry

* make averages over time for panel:
collapse (first) country (mean) ctfp (mean) labsh (mean) irr (mean) ln_k_l_ratio (mean) ln_gdp_pc (last) d_demand, by(countrycode)


/*** 1b MERGE WITH ROBOT DATA ***/
/********************************/

rename countrycode Country

merge 1:m Country using "CITE_robots_firstdiffdata.dta"
keep if _merge==3
drop _merge

keep Country country ctfp labsh irr ln_k_l_ratio ln_gdp_pc sector_code period Sectorcode IFRcountry sectorname_long IndustryFinaldemand pctchg_Robot_density lnEMPN panel_id country_id sector_id d_demand

/* 1c minor adjustments */
xtset panel_id period
gen d_lnEMPN = d.lnEMPN

/* 1d summary stats */
reg d_lnEMPN pctchg_Robot_density i.country_id	/* for sample creation */
gen smpl_main = e(sample)

estpost summarize d_lnEMPN pctchg_Robot_density ln_gdp_pc d_demand if smpl_main==1
esttab using "$outputpath\robot_summary_stats.tex", cells("N(fmt(0)) mean(fmt(3)) sd(fmt(3)) min(fmt(2)) max(fmt(2))") label title("Summary Statistics") replace	

*descriptive scatter graph
twoway (scatter d_lnEMPN pctchg_Robot_density if smpl_main==1 & ln_gdp_pc<11.165, ytitle("{&Delta} ln L") xtitle("{&Delta} Robots") legend(label(1 "lower income") label(3 "higher income") order(1 3) pos(6) col(2)) col(gs3)) (lfit d_lnEMPN pctchg_Robot_density if smpl_main==1 & ln_gdp_pc<11.165, col(gs3) lpat(dash) lwidth(medthick)) (scatter d_lnEMPN pctchg_Robot_density if smpl_main==1 & ln_gdp_pc>=11.165, col(stblue)) (lfit d_lnEMPN pctchg_Robot_density if smpl_main==1 & ln_gdp_pc>=11.165, col(stblue)) 
graph export "$outputpath\robot_descrscatter.pdf", as(pdf) replace

corr pctchg_Robot_density ln_gdp_pc if smpl_main==1
sum pctchg_Robot_density if smpl_main==1 & ln_gdp_pc<11.165
sum pctchg_Robot_density if smpl_main==1 & ln_gdp_pc>=11.165
pwcorr ln_gdp_pc d_demand if smpl_main==1

*check for meaningfulness of assumption 2
bys country_id: sum pctchg_Robot_density if smpl_main==1


*******************
*** 2. ANALYSIS ***
*******************

/* 2a regression test (for consistency with Dijkstra and Wacker, 2025) */

ivreg2 d.lnEMP pctchg_Robot_density i.country_id [aweight=emp_share_sec], partial(i.country_id) cluster(country_id sector_id)	/* identical do Dijkstra and Wacker */
ivreg2 d.lnEMP pctchg_Robot_density i.country_id, partial(i.country_id) cluster(country_id sector_id)	/* unweighted */
ivreg2 d.lnEMP pctchg_Robot_density i.country_id, partial(i.country_id) cluster(country_id)		/* unweighted, single clustering */
reg d_lnEMPN pctchg_Robot_density i.country_id, robust cluster(country_id)	/* same, but with "regress" command */
local effect_simple = _b[pctchg_Robot_density]

/* 2b interaction regressions */

*ITE
reg d_lnEMPN c.pctchg_Robot_density i.country_id, robust cluster(country_id)
estimates store model_baseline, title(Model 1)

reg d_lnEMPN c.pctchg_Robot_density c.pctchg_Robot_density#c.ln_gdp_pc i.country_id, robust cluster(country_id)
estimates store model_ite2, title(Model 2)
local effect_ite_base = _b[pctchg_Robot_density]
local effect_ite_interact = _b[c.pctchg_Robot_density#c.ln_gdp_pc]

reg d_lnEMPN c.pctchg_Robot_density c.pctchg_Robot_density#c.d_demand i.country_id, robust cluster(country_id)
estimates store model_ite3, title(Model 3)

reg d_lnEMPN c.pctchg_Robot_density c.pctchg_Robot_density#c.ln_gdp_pc c.pctchg_Robot_density#c.d_demand i.country_id, robust cluster(country_id)
estimates store model_ite4, title(Model 4)

reg d_lnEMPN c.pctchg_Robot_density c.pctchg_Robot_density#c.ln_gdp_pc c.pctchg_Robot_density#c.d_demand c.pctchg_Robot_density#c.ln_k_l_ratio i.country_id, robust cluster(country_id)
estimates store model_ite5, title(Model 5)

*CITE

* CITE (unbalanced)

bysort country_id: generate unique_id = 1 if _n == 1	/* so we can refer to ONE observation within panel unit */
gen CITE_b1 = .
gen CITE_se1 = .
qui reg d_lnEMPN c.pctchg_Robot_density#i.country_id i.country_id, robust cluster(country_id) nocon
levelsof country_id if e(sample), local(levels)
foreach l of local levels {
    replace CITE_b1 = _b[pctchg_Robot_density#`l'.country_id] if country_id==`l'
	replace CITE_se1 = _se[pctchg_Robot_density#`l'.country_id] if country_id==`l'
}

reg CITE_b1 if unique_id==1, robust
estimates store model_cite_baseline, title(Model 6)

*hist CITE_b1 if unique_id==1, graphregion(color(white)) xtitle({&kappa}{sub:1} CITE)
*graph export CITE_fe_hist.pdf, as(pdf) replace
*sum delta1_cite if unique_id==1, det

reg CITE_b1 ln_gdp_pc if unique_id==1, robust
estimates store model_cite2, title(Model 7)
local effect_cite_base = _b[_cons]
local effect_cite_interact = _b[ln_gdp_pc]

reg CITE_b1 d_demand if unique_id==1, robust
estimates store model_cite3, title(Model 8)

reg CITE_b1 ln_gdp_pc d_demand if unique_id==1, robust
estimates store model_cite4, title(Model 9)

reg CITE_b1 ln_gdp_pc d_demand ln_k_l_ratio if unique_id==1, robust
estimates store model_cite5, title(Model 10)

*Summarize results
estout model_baseline model_ite2 model_ite3 model_ite4, cells(b(star fmt(3)) se(par fmt(2))) stats(r2 N) legend starlevels(* 0.1 ** 0.05 *** 0.01) keep(pctchg_Robot_density c.pctchg_Robot_density#c.ln_gdp_pc c.pctchg_Robot_density#c.d_demand)

esttab model_baseline model_ite2 model_ite3 model_ite4 using "$outputpath\robot_ite_results.tex", cells(b(star fmt(3)) se(par fmt(2))) stats(r2 N) legend starlevels(* 0.1 ** 0.05 *** 0.01) keep(pctchg_Robot_density c.pctchg_Robot_density#c.ln_gdp_pc c.pctchg_Robot_density#c.d_demand) replace

estout model_cite_baseline model_cite2 model_cite3 model_cite4, cells(b(star fmt(3)) se(par fmt(2))) stats(r2 N) legend starlevels(* 0.1 ** 0.05 *** 0.01) keep(_cons ln_gdp_pc d_demand)

esttab model_cite_baseline model_cite2 model_cite3 model_cite4 using "$outputpath\robot_cite_results.tex", cells(b(star fmt(3)) se(par fmt(2))) stats(r2 N) legend starlevels(* 0.1 ** 0.05 *** 0.01) keep(_cons ln_gdp_pc d_demand) replace

twoway (scatter CITE_b1 ln_gdp_pc if unique_id==1, mlab(country_id) mcol(gs5) mlabcol(gs5)) (function y = `effect_simple', ra(ln_gdp_pc)) (function y = `effect_ite_base' + `effect_ite_interact'*x, ra(ln_gdp_pc) clpat(shortdash) clwidth(medthick)) (function y = `effect_cite_base' + `effect_cite_interact'*x, ra(ln_gdp_pc) clpat(longdash) clwidth(medthick) clcolor(blue) legend(lab(2 "no interaction") lab(3 "ITE") lab(4 "CITE") order(2 3 4) pos(6) cols(3)) xtitle("ln GDP p.c.") ytitle({&delta} ln employment / {&delta} robot adoption))
graph export "$outputpath\robot_coefscatter.pdf", as(pdf) replace


		***CREATE MARGINS GRAPH with confidence band
		preserve
		keep if unique_id==1
		
		reg CITE_b1 ln_gdp_pc if unique_id==1, robust
		matrix b_fx=e(b)					/* retrieve beta coefficients */
		matrix V_fx=e(V)					/* retrieve variance-covariance matrix */
		scalar kappa0_fx = b_fx[1,2]		/* retrieve main effect */
		scalar kappa1_fx = b_fx[1,1]		/* retrieve interaction effect */
		scalar varkap0_fx = V_fx[2,2]		/* retrieve variance of main effect */
		scalar varkap1_fx = V_fx[1,1]		/* retrieve variance of interaction effect */
		scalar covar01_fx = V_fx[1,2]		/* retrieve covariance of both */
		scalar list kappa0_fx kappa1_fx varkap0_fx varkap1_fx covar01_fx

		*selecting range and scale for marginal effects
		gen MVZ_fx = ((_n +20)/ 4.5)		/* some formula for meaningful steps for x axis */
		replace MVZ_fx = . if MVZ_fx > 12	/* set upper limit of x axis */
		replace MVZ_fx = . if MVZ_fx < 9.77	/* set lower limit of x axis */
		sum MVZ_fx							/* check if values meaningful */
		
		*setting marginal fx line (first derivative of dep. var. w.r.t. x1)
		gen conbx_fx = kappa0_fx+kappa1_fx*MVZ_fx
		*standard deviation of estimate
		gen consx_fx = sqrt(varkap0_fx + varkap1_fx*(MVZ_fx^2) + 2*covar01_fx*MVZ_fx)

		*building 90% confidence interval
		gen ax_fx = 1.645*consx_fx				/* builds confidence area for 90% CI */
		gen upperx_fx = conbx_fx + ax_fx 		/* centers confidence area around marginal fx line (upper band) */
		gen lowerx_fx = conbx_fx - ax_fx		/* centers confidence area around marginal fx line (lower band) */

graph twoway (rarea upperx_fx lowerx_fx MVZ_fx, clpattern(dash) fcolor(gs14) lcolor(gs14)) ///
(scatter CITE_b1 ln_gdp_pc if unique_id==1, mlab(country_id) mcol(gs5) mlabcol(gs5)) (function y = `effect_simple', ra(ln_gdp_pc) clcolor(red)) (function y = `effect_ite_base' + `effect_ite_interact'*x, ra(ln_gdp_pc) clpat(longdash) clwidth(medthick) clcolor(green)) (function y = `effect_cite_base' + `effect_cite_interact'*x, ra(ln_gdp_pc) clpat(solid) clwidth(medthick) clcolor(gs0) legend(lab(1 "CITE 90% confidence band") lab(3 "no interaction") lab(4 "ITE") lab(5 "CITE") order(5 1 4 3) pos(6) cols(4)) xtitle("ln GDP p.c.") ytitle({&delta} ln employment / {&delta} robot adoption))

	/*  *Graph alternative (dashed-line C.I. instead of gray area):
	graph twoway (scatter CITE_b1 ln_gdp_pc if unique_id==1, mlab(country_id) mcol(gs5) mlabcol(gs5)) (function y = `effect_simple', ra(ln_gdp_pc)) (function y = `effect_ite_base' + `effect_ite_interact'*x, ra(ln_gdp_pc) clpat(shortdash) clwidth(medthick)) (function y = `effect_cite_base' + `effect_cite_interact'*x, ra(ln_gdp_pc) clpat(longdash) clwidth(medthick) clcolor(blue) legend(lab(2 "no interaction") lab(3 "ITE") lab(4 "CITE") order(2 3 4) pos(6) cols(3)) xtitle("ln GDP p.c.") ytitle({&delta} ln employment / {&delta} robot adoption)) (line conbx_fx MVZ_fx, clpattern(solid) clwidth(medium) clcolor(black)) (line upperx_fx MVZ_fx, clpattern(dash) clwidth(thin) clcolor(black)) (line lowerx_fx MVZ_fx, clpattern(dash) clwidth(thin) clcolor(black)) */

graph export "$outputpath\robot_coefscatter.pdf", as(pdf) replace

		restore

*************************
** 3. MARGINAL EFFECTs **
*************************

sum ln_gdp_pc if smpl_main==1 & Country=="BGR"
sum ln_gdp_pc if smpl_main==1 & Country=="DEU"
sum ln_gdp_pc if smpl_main==1 & Country=="USA"

qui reg d_lnEMPN c.pctchg_Robot_density c.pctchg_Robot_density#c.ln_gdp_pc i.country_id, robust cluster(country_id)
di 0.5*(_b[pctchg_Robot_density] + _b[c.pctchg_Robot_density#c.ln_gdp_pc]*10.5)	/*BGR*/
di 0.5*(_b[pctchg_Robot_density] + _b[c.pctchg_Robot_density#c.ln_gdp_pc]*11.4)	/*DEU*/
di 0.5*(_b[pctchg_Robot_density] + _b[c.pctchg_Robot_density#c.ln_gdp_pc]*11.7)	/*USA*/

qui reg CITE_b1 ln_gdp_pc if unique_id==1, robust
di 0.5*(_b[_cons] + _b[ln_gdp_pc]*10.5)	/*BGR*/
di 0.5*(_b[_cons] + _b[ln_gdp_pc]*11.4)	/*DEU*/
di 0.5*(_b[_cons] + _b[ln_gdp_pc]*11.7)	/*USA*/

********************
** 4. DIAGNOSTICs **
********************

* --> visual inspection of graph suggests quadratic -->:
reg CITE_b1 c.ln_gdp_pc##c.ln_gdp_pc if unique_id==1, robust
reg CITE_b1 c.ln_gdp_pc##c.ln_gdp_pc ln_k_l_ratio if unique_id==1, robust

reg CITE_b1 ln_gdp_pc if unique_id==1
lvr2plot, mlab(Country)
predict cite_cooksdist, cooksd
brow Country cite_cooksdist if unique_id==1 & cite_cooksdist > (4/(35-2))

reg CITE_b1 ln_gdp_pc if unique_id==1 & cite_cooksdist < (4/(35-2))
reg d_lnEMPN c.pctchg_Robot_density c.pctchg_Robot_density#c.ln_gdp_pc i.country_id if cite_cooksdist < (4/(35-2)), robust cluster(country_id)
