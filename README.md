# CITErobots

This repository documents the STATA code for our "Estimating interaction effects with panel data" application to robotization and employment (with Chris Muris; GitHub: chrismuris).

1. Please download the files CITE_robots_analysis.do and CITE_robots_analysis.dta and save them in a folder.
2. Create a Output
3. Adjust the path in line 21 and 23 and save the .do file
The CITE_robot_analysis file requires adjustment of the file path to your system in the beginning. Place the CITE_robots_firstdiffdata.dta file in the respective folder.
To run the file, a web connection is required (for sourcing Penn World Table data).

Essential variables in the dataset (CITE_robots_firstdiff.dta) are:

- d_lnEMPN ... log changes in employment numbers (see https://wiiw.ac.at/robots-shoring-patterns-and-employment-what-are-the-linkages-p-7383.html for details)
- pctchg_Robot_density ... percentile change in robot density (see https://wiiw.ac.at/robots-shoring-patterns-and-employment-what-are-the-linkages-p-7383.html for details)
- ln_gdp_pc ... natural log of GDP pc (from PWT)
- d_demand ... demand changes (from PWT)

The code for the simulation study reported in the associated Journal of Applied Econometrics paper is available from my co-author here: https://github.com/chrismuris/CITE-simulation.
