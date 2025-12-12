# CITErobots

This repository documents the STATA code for our "Estimating interaction effects with panel data" application to robotization and employment (with Chris Muris; chrismuris).

The CITE_robot_analysis file requires adjustment of the file path to your system in the beginning. Place the CITE_robots_firstdiffdata.dta file in the respective folder.
To run the file, a web connection is required (for sourcing Penn World Table data).

Essential variables in the dataset are:
d_lnEMPN 
pctchg_Robot_density 
ln_gdp_pc


The code for the simulation study reported in the associated Journal of Applied Econometrics paper is available from my co-author here: https://github.com/chrismuris/CITE-simulation.
