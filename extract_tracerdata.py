import pandas as pd
import openpyxl as op
import os

os.chdir(setwd)

wb = op.load_workbook('Charlotte Glucose+Glycerol_210220.xlsx', data_only=True) #data_only flag so formulas are evaluated
wb.remove(wb['Inf1'])
wb.remove(wb['Inf2'])
tracerdat = pd.DataFrame(columns=['ttid', 
                           'endogenous_glucose_ra', 
                           'total_glucose_ra', 
                           'oral_glucose_ra', 
                           'total_glucose_rd', 
                           'glycerol_ra', 
                           'glycerol_rd'])
for sheet in wb.sheetnames:
    ws = wb[sheet]
    df = pd.DataFrame(ws.values)
    ttid = df.iloc[55:91][1]
    ttid.reset_index(drop=True, inplace=True, name='ttid')
    endogenous_glucose_ra = df.iloc[55:91][10]
    endogenous_glucose_ra.reset_index(drop=True, inplace=True, name='endogenous_glucose_ra')
    total_glucose_ra = df.iloc[55:91][11]
    total_glucose_ra.reset_index(drop=True, inplace=True, name='total_glucose_ra')
    oral_glucose_ra = df. iloc[55:91][12]
    oral_glucose_ra.reset_index(drop=True, inplace=True, name='oral_glucose_ra')
    total_glucose_rd = df.iloc[55:91][13]
    total_glucose_rd.reset_index(drop=True, inplace=True, name='total_glucose_rd')
    glycerol_ra = df.iloc[104:140][4]
    glycerol_ra.reset_index(drop=True, inplace=True, name='glycerol_ra')
    glycerol_rd = df.iloc[104:140][5]
    glycerol_rd.reset_index(drop=True, inplace=True, name='glycerol_rd')
    calc_vals = pd.concat([ttid, 
                           endogenous_glucose_ra, 
                           total_glucose_ra, 
                           oral_glucose_ra, 
                           total_glucose_rd, 
                           glycerol_ra, 
                           glycerol_rd], 
                          axis=1)
    calc_vals['sheetname'] = sheet
    tracerdat = tracerdat.append(calc_vals, sort=True)
tracerdat.to_csv(r'tracerdat.csv') 
