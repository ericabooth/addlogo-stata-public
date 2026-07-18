*==============================================================*
* example_addlogo.do  --  demo & smoke-test for addlogo
*
* Run from inside the repo folder AFTER installing an image
* engine (see README). Uses the shipped placeholder logo.
*==============================================================*
clear all
set more off
set graphics off          // batch-safe; graphs still build & export

* use the repo copy of the command (no net install needed to try it)
adopath ++ "`c(pwd)'"

* a graph you might make any day
sysuse auto, clear
twoway (scatter price mpg, mcolor(navy%60))                    ///
       (lfit price mpg, lcolor(cranberry) lwidth(medthick)),   ///
       title("Price vs. mileage")                              ///
       subtitle("1978 automobile data")                        ///
       note("Source: auto.dta")                                ///
       ytitle("Price (USD)") xtitle("Mileage (mpg)")           ///
       name(g1, replace)

* stamp the placeholder logo, bottom-right (the default position)
addlogo, logo("`c(pwd)'/testlogo.png") ///
    saving("`c(pwd)'/example_out.png") name(g1) replace
display as text "  -> r(file)  = " as result "`r(file)'"
display as text "  -> r(engine)= " as result "`r(engine)'"

* a second placement: top-left, larger, slightly transparent
addlogo, logo("`c(pwd)'/testlogo.png") ///
    saving("`c(pwd)'/example_out_nw.png") ///
    name(g1) position(nw) scale(.18) opacity(.85) replace

display as result _n "== example_addlogo.do finished: wrote example_out.png + example_out_nw.png =="
