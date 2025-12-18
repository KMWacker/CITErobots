# CITErobots

This repository documents the STATA code for our "Estimating interaction effects with panel data" application to robotization and employment (with Chris Muris; GitHub: chrismuris).

1. Please download the files CITE_robots_analysis.do and CITE_robots_analysis.dta and save them in a folder.
2. Create a folder "Outputs" within the folder where you stored the .do and .dta file. Key outputs (graphs and tables) will be stored in this folder.
3. Adjust the path in lines 21 and 23 of the .do file (to match your system and folder structure) and save the .do file
4. Run the .do file

A web connection is required for sourcing Penn World Table data in line 33 of the .do file. If you get an error message at that stage, please manually download PWT10.0 dta from the internet and adjust this line to use the downloaded data from your system.

Essential variables in the dataset (CITE_robots_firstdiff.dta) are:

- d_lnEMPN ... log changes in employment numbers (see https://wiiw.ac.at/robots-shoring-patterns-and-employment-what-are-the-linkages-p-7383.html for details)
- pctchg_Robot_density ... percentile change in robot density (see https://wiiw.ac.at/robots-shoring-patterns-and-employment-what-are-the-linkages-p-7383.html for details)
- ln_gdp_pc ... natural log of GDP pc (from PWT)
- d_demand ... demand changes (from PWT)

The code for the simulation study reported in the associated Journal of Applied Econometrics paper is available from my co-author here: https://github.com/chrismuris/CITE-simulation.
