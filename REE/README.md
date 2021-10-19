# REE
A semi-generalized resting energy expenditure calculation

This is a short script that calculates various parameters of a resting energy expenditure/indirect calorimetry test performed on a cosmed device.

Data from the device is output in .xlsx files. The output file consists of two data tables within the same spreadsheet, one for information on test parameters and participant pii, and another which contains individual measurements/observations. Observations are made every 10 seconds. A full test takes approximately 15 minutes divided into a ~5 min run-in phase and a ~10 min rest phase. Gas measurements are highly variable, i.e. yawning/talking/moving while influence results, as such the average of the non-run-in phase is the desired outcome. 

This script

A) Selects rest phase

B) Calculates averages of variables of interest

C) Writes averages to a new destination


