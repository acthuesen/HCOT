#This script cleans data from a lunar prodigy bone densitometry scanner

#The exported data comes in 2-4 .txt files depending on options and software version.  
#Filenames that only contain the "root" of the filename are bone densitometry data. 
#Filenames that contain 'Comp' or 'Komp' are body composition data.
#Filenames that contain 'CoreScan' are measurements of visceral fat mass. 

#Data exported (at least in Europe) have ',' as decimal seps and '.' as thousands seps. 
#However, the export also stores units with the values
#e.g. '3.010,6 cm^3' or '22,84 %' 
#The use of units is completely inconsistent. 
#Additionally, the body composition data has duplicated variable names 
#i.e. the first instance of fat free mass (column index BE-BW; 56-74) is fat free mass EXCLUDING bone mass, 
#second instance of fat free mass (column index CQ-DI; 94-112) is fat free mass INCLUDING bone. 
#Note that tissue mass is tissue + fat (so fat free mass instance 1 + fat mass)
#Also worth noting that the 'total mass' variables are approximations, as the exported data seem to be rounded to one decimal rather than true sums. 

#This script imports the data, fixes these issues, and saves a "clean" file version

import pandas as pd
import glob
import os

#Return list of dir content
files = glob.glob("DIRECTORYPATH*.txt")
#For all files in dir load data
for file in files: 
	dat = pd.read_table(file, encoding='utf-16', header='infer', thousands='.', decimal=',')
	#Add suffixes for the incorrectly labelled vars
	if 'Komp' in file: 
		in_colnames = [(i,i+'_incl_bone') for i in dat.iloc[:,94:113].columns.values]
		ex_colnames = [(i,i+'_excl_bone') for i in dat.iloc[:,56:75].columns.values]
		dat.rename(columns = dict(in_colnames), inplace = True)	
		dat.rename(columns = dict(ex_colnames), inplace = True)
	for column in dat: #should only work on objects i.e. those vars where units and values are stored together
			if dat[column].dtypes == 'O':
				dat[column] = dat[column].astype('str')
				#remove units
				dat[column] = dat[column].map(lambda x: x.rstrip('kg%cm\u00b3'))
				#remove thousand seps
				dat[column] = dat[column].str.replace('.','')
				#replace decimal (, with .)
				dat[column] = dat[column].str.replace(',','.')
	#Split extension from path
	des = os.path.splitext(file)[0]
	#New path
	desty = des + '_clean.csv'
	#Save
	dat.to_csv(desty, index=False, encoding='utf-8-sig') #-sig for æøå
