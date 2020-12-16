import pandas as pd
import numpy as np
import glob
import os

files = glob.glob(dir) #dir with all dexa files
for file in files:
	if not 'ptdata' in file:
		dxa = pd.read_csv(file)
		dat = pd.read_table('L:\\LovbeskyttetMapper\\HCOF\\Data\\id_date\\dates.txt', sep='\t')
		dxa['Scanningsdato'] = pd.to_datetime(dxa['Scanningsdato'], format='%d-%m-%Y')
		dat['date_day1'] = pd.to_datetime(dat['date_day1'])
		dat['date_day2'] = pd.to_datetime(dat['date_day2'])
		dat['A'] = pd.to_datetime(dat['A'])
		dat['B'] = pd.to_datetime(dat['B'])
		dat['C'] = pd.to_datetime(dat['C'])

#Create function for time in range 
#https://stackoverflow.com/questions/10747974/how-to-check-if-the-current-time-is-in-range-in-python
		def time_in_range(start, end, x):
			if start <= end:
				return start <= x <= end
			else:
				return start <= x or x <= end

		merged = dat.merge(dxa, left_on='id', right_on='Patient ID', how='outer')
		merged['dexavis'] = np.nan

		for i in range(len(merged)):
			if time_in_range(merged.loc[i,'B']+pd.DateOffset(days=14),merged.loc[i,'C']-pd.DateOffset(days=14),merged.loc[i,'Scanningsdato'])==True:
				merged.loc[i,'dexavis'] = "Midtvejs"

		for i in range(len(merged)):
			if time_in_range(merged.loc[i,'date_day1']-pd.DateOffset(days=7),merged.loc[i,'date_day1']+pd.DateOffset(days=7),merged.loc[i,'Scanningsdato'])==True:
				merged.loc[i,'dexavis'] = merged.loc[i,'visit']

		merged = merged[pd.notnull(merged['dexavis'])]
		merged = merged.drop_duplicates(subset=['dexavis','id'])
		merged = merged.drop(['id','visit','date_day1','date_day2','A','B','C'], axis=1)
		#save
		des = os.path.splitext(file)[0]
		desty = des + '_matched.xlsx'
		writer = pd.ExcelWriter(desty)
		merged.to_excel(writer,'Sheet1',index=False)
		writer.save()
