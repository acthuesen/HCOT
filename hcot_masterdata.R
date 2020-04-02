#This creates (a) master dataset(s) for HCOT study
#This version is updated April 2020
#Ammend as new datasources (tracer etc. is included)


### DEPENDENCIES ###
library(tidyverse)
library(lubridate)
library(MESS)


### WORKING DIR ###
setwd('YOURPATH')


### IMPORT DATA ###
# hcot ap = anthropometry
hcot_ap <- read.table('./ss/HCOT_dag 1_A-C.txt', sep=",", header=TRUE)

# hcot_bw = birth weight
hcot_bw <- read.table('./ss/HCOT_FV.txt', sep=",", header=TRUE)

# hcot_tr = training randomization
hcot_tr <- read.table('./ss/HCOT_randomization.txt', sep="\t", header=TRUE)

# hcot_bd = bone density dexa data
hcot_bd <- read.table('./ss/HCOT_DXA BMD_A-C.txt', sep=",", header=TRUE)

# hcot_vf = visceral fat mass dexa data
hcot_vf <- read.table('./ss/HCOT_DXA VF_A-C.txt', sep=",", header=TRUE)

# hcot_wb = whole body composition dexa data
hcot_wb <- read.table('./ss/HCOT_DXA Whole_A-C.txt', sep=",", header=TRUE) 

# hcot_lf = liver fat data from MRI
hcot_lf <- read.table('./ss/HCOT_MRI_A-C_long.txt', sep=",", header=TRUE)

# hcot_vm = vo2max data
hcot_vm <- read.table('./ss/HCOT_VO2max_A-C.txt', sep=",", header=TRUE)

# hcot_bl = biochemistry for baseline
hcot_bl <- read.table('./ss/HCOT_lab_A-C.txt', sep=",", header=T, check.names = F, na.strings = c("", " ")) 
# check.names=F when importing from txt due to +/- in headers

# hcot_mr = VAT from MRI
hcot_mr <- read.table('./ss/VAT_MRI.txt', sep="\t", header=T)


### WRANGLE DATA ###
# ANTHROPOMETRY
hcot_ap <- hcot_ap %>%
  select(-c(takenekg_day1:takenfood_day1)) %>% # remove vars that are just checkboxes
  mutate(dob_day1 = parse_date_time(dob_day1, "dmyHMS")) %>% # parse dob
  mutate(date_day1 = parse_date_time(date_day1, "dmyHMS")) %>% # parse date
  mutate(bmi_day1 = weight_day1/(height_day1/100)^2) %>% # calculate BMI
  mutate(sysbp_day1 = (sysbp2_day1+sysbp1_day1)/2) %>% # average sys BP 
  select(-sysbp2_day1, -sysbp1_day1) %>% # remove raw sys BP vars
  mutate(diabp_day1 = (diabp2_day1+diabp1_day1)/2) %>% # same for dia BP
  select(-diabp2_day1, -diabp1_day1) %>% 
  mutate(pulsebp_day1 = (pulsebp2_day1+pulsebp1_day1)/2) %>% # same for pulse
  select(-pulsebp1_day1, -pulsebp2_day1) %>%
  mutate(WHR_day1 = navelcirc_day1/hipcirc_day1) %>% # calc WHR 
  mutate(age_day1 = time_length(interval(dob_day1, date_day1), "years")) %>% # calc current age (interval between date and dob)
  select(-date_day1, -dob_day1) %>% # rm date and dob (not needed prospectively)
  mutate(map_day1 = diabp_day1+((1/3)*(sysbp_day1-diabp_day1))) %>% # calc MAP
  mutate(id = str_pad(id, 3, pad="0")) %>% # make id 3 chr
  mutate(id = as.character(id)) # make id chr

# BIRTH WEIGHT
hcot_bw <- hcot_bw %>%
  mutate(id = str_pad(id, 3, pad="0")) %>% # make id 3 chr
  mutate(id = as.character(id)) # make id chr

# TRAINING RANDOMIZATION
hcot_tr <- hcot_tr %>%
  select(-bwcat) %>% # bwcat unnecessary since is already derived from bw file (official source)
  rename(randomization = rando) %>% # rename variable to something better
  mutate(id = str_pad(id, 3, pad="0")) %>% # pad id to 3 chr
  mutate(id = as.character(id)) %>% # id as chr
  mutate(randomization = fct_collapse(randomization, #consolidate alternate spellings
                                      "Training"=c("Træning","træning","Træning ","træning "), 
                                      "Control"=c("Kontrol ","kontrol ")))

# DEXA DATA
hcot_bd <- hcot_bd %>%
  select(Patient.ID, Total.BMD, dexavis) %>% # select only relevant vars
  mutate(Total.BMD = Total.BMD/1000) %>% # change unit on BMD (bone mineral density)
  rename(id = Patient.ID, visit = dexavis, total_BMD = Total.BMD) %>% # rename vars to be consistent with main df
  mutate(id = str_pad(id, 3, pad="0")) %>% # pad id
  mutate(id = as.character(id)) %>% # id as chr
  mutate(visit = fct_recode(visit, "M"="Midtvejs")) %>% # recode midway visit to be consistent with one-chr naming convention
  mutate(visitid = paste(visit,id, sep="")) # create a visit id concat var

hcot_vf <- hcot_vf %>%
  select(VAT.masse, VAT.volumen, dexavis, Patient.ID) %>% # select only relevant vars
  rename(id = Patient.ID, visit = dexavis, vat_mass = VAT.masse, vat_volume = VAT.volumen) %>% # rename vars for consistency
  mutate(id = str_pad(id, 3, pad="0")) %>% # pad id
  mutate(id = as.character(id)) %>% # id as chr
  mutate(visit = fct_recode(visit, "M"="Midtvejs")) %>% # recode midway visit
  mutate(visitid = paste(visit,id, sep="")) # concat visit + id

hcot_wb <- hcot_wb %>%
  mutate(android_tissuefatpercentage = Android.Fedtmasse/Android.Vævsmasse*100) %>% # calc andriod tissue fat %
  mutate(gynoid_tissuefatpercentage = Gynoid.Fedtmasse/Gynoid.Vævsmasse*100) %>% # calc gynoid tissue fat %
  mutate(AG_fatratio = Android.Fedtmasse/Gynoid.Fedtmasse) %>% # calc android/gynoid fat mass ratio
  select( # select relevant vars
    Patient.ID, 
    dexavis, 
    AG_fatratio,
    android_tissuefatpercentage, 
    gynoid_tissuefatpercentage, 
    Total.Fedtmasse, 
    Total.Fedtfri.masse_excl_bone, 
    Total.Væv..Fedt) %>%
  rename( # rename for consistensy and comprehension
    id = Patient.ID, 
    visit = dexavis, 
    fatmass_total = Total.Fedtmasse, 
    leanmass_total = Total.Fedtfri.masse_excl_bone, 
    total_tissuefatpercetage = Total.Væv..Fedt) %>%
  mutate(fatmass_total = fatmass_total/1000) %>% # change units on fat mass
  mutate(leanmass_total = leanmass_total/1000) %>% # change unit on lean mass
  mutate(id = str_pad(id, 3, pad="0")) %>% # pad id
  mutate(id = as.character(id)) %>% # id as chr
  mutate(visit = fct_recode(visit, "M"="Midtvejs")) %>% # recode midway visit
  mutate(visitid = paste(visit,id, sep="")) # concat visit + id

# join dexa data
hcot_dx <- full_join(hcot_bd,hcot_vf, by=c("id","visit","visitid"))
hcot_dx <- full_join(hcot_dx,hcot_wb, by=c("id","visit","visitid"))

# MRI LIVER
hcot_lf <- hcot_lf %>%
  select(-Id1) %>% # remove Id1 (løbenummer)
  rename(liverfatpercent = Percent_fat) %>% # rename var for comprehension
  mutate(id = str_pad(id, 3, pad="0")) %>% # pad id 
  mutate(id = as.character(id)) %>% # id as chr
  mutate(visitid = paste(visit,id, sep="")) # concat visit + id

# VO2MAX DATA
hcot_vm <- hcot_vm %>%
  select(ID, VO2_20sec_max, VCO2_20sec_max, RQ_20sec_max, fitness_lvl, mocvis) %>% # rm unnecessary vars
  rename(id = ID, visit = mocvis) %>% # rename vars to something comprehensible 
  mutate(id = str_pad(id, 3, pad="0")) %>% # pad id
  mutate(id = as.character(id)) %>% # id as chr
  mutate(visit = fct_recode(visit, "M"="Midtvejs")) %>% # consistency
  mutate(visitid = paste(visit,id, sep="")) # concat vis id

# BIOCHEMISTRY
hcot_bl <- hcot_bl %>%
  mutate(`ins-127_day2` = gsub("<7", 3.5, `ins-127_day2`)) %>% # rm limits of detection, replace by half of LoD
  mutate(`ins-126_day2` = gsub("<7", 3.5, `ins-126_day2`)) %>% 
  mutate(`ins-125_day2` = gsub("<7", 3.5, `ins-125_day2`)) %>%
  mutate(`cpep-127_day2` = gsub("<50", 25, `cpep-127_day2`)) %>%
  mutate(`cpep-126_day2` = gsub("<50", 25, `cpep-126_day2`)) %>%
  mutate(`cpep-125_day2` = gsub("<50", 25, `cpep-125_day2`)) %>%
  mutate(`ins-127_day2` = as.numeric(`ins-127_day2`)) %>% # change to numeric vars
  mutate(`ins-126_day2` = as.numeric(`ins-126_day2`)) %>%
  mutate(`ins-125_day2` = as.numeric(`ins-125_day2`)) %>%
  mutate(`cpep-127_day2` = as.numeric(`cpep-127_day2`)) %>%
  mutate(`cpep-126_day2` = as.numeric(`cpep-126_day2`)) %>%
  mutate(`cpep-125_day2` = as.numeric(`cpep-125_day2`))

# since rowwise ops causes downstream problems: 
# sep rpt measures, transform to long, then to tidy, and merge back into org data:
srm.hcot_bl <- hcot_bl %>%
  select(visitid, 
         `glu-127_day2`, `glu-126_day2`, `glu-125_day2`,
         `ins-127_day2`, `ins-126_day2`, `ins-125_day2`,
         `cpep-127_day2`, `cpep-126_day2`, `cpep-125_day2`) %>%
  gather(var, val, -visitid) %>%
  separate(var, c("var","time"), "-") %>%
  spread(var, val) %>%
  group_by(visitid) %>%
  summarise(
    bas_glu = mean(glu, na.rm=T),
    bas_ins = mean(ins, na.rm=T),
    bas_cpe = mean(cpep, na.rm=T)
  ) 
hcot_bl <- full_join(hcot_bl, srm.hcot_bl, by="visitid")

# get vars that are relevant for a baseline biochem dataset, amend as needed
hcot_bl <- hcot_bl %>%
  select(visit, id, visitid, bas_glu, bas_ins, bas_cpe, a1c_day2, cholesterol_day2, hdl_day2, ldl_day2, triglyc_day2, alat_day2, 
         asat_day2, ggt_day2, factiiviix_day2) %>% # sel rlv vars
  mutate(id = str_pad(id, 3, pad="0")) %>% # pad id
  mutate(id = as.character(id)) %>% # id as chr
  mutate(homa_ir = (bas_glu*bas_ins)/22.5) # calc homa

# for long format blood samples (i.e. repeated c-pep etc. measures)
hcot_mt <- read.table('./ss/HCOT_lab_A-C.txt', sep=",", header=T, check.names = F, na.strings = c("", " ")) 
hcot_mt <- hcot_mt %>%
  select(matches('glu|cpep|ins'), id, visitid, visit, -glufroma1c_day2)

colnames(hcot_mt) <- gsub("_day2", "", colnames(hcot_mt))
colnames(hcot_mt) <- gsub("cpep", "cpe", colnames(hcot_mt))

hcot_mt <- hcot_mt %>% 
  gather(var, val, `glu-127`:`cpe+300`)

hcot_mt$time <- substr(hcot_mt$var, 4,9)
hcot_mt$var <- substr(hcot_mt$var, 1,3)

hcot_mt$time <- as.numeric(hcot_mt$time)

hcot_mt <- hcot_mt %>%
  mutate(val = gsub("<7", 3.5, val)) %>%
  mutate(val = gsub("<50", 25, val)) 

hcot_mt$val <- as.numeric(hcot_mt$val)

hcot_mt <- hcot_mt %>%
  mutate(id = str_pad(id, 3, pad="0")) %>% # pad id
  mutate(id = as.character(id)) # id as chr

hcot_mt <- hcot_mt %>%
  spread(var, val)

# In order for aggregate results from MMTT to be put into "baseline" dataset, calculate AUCs
auc_a <- hcot_mt %>%
  filter(visit=="A") %>%
  group_by(id) %>%
  summarize(AUC_glu = auc(time, glu, type = "spline"),
            AUC_cpe = auc(time, cpe, type = "spline"),
            AUC_ins = auc(time, ins, type = "spline")) %>%
  mutate(visit = "A") %>%
  mutate(visitid = paste(visit,id, sep="")) # concat id vis
auc_b <- hcot_mt %>%
  filter(visit=="B") %>%
  group_by(id) %>%
  summarize(AUC_glu = auc(time, glu, type = "spline"),
            AUC_cpe = auc(time, cpe, type = "spline"),
            AUC_ins = auc(time, ins, type = "spline")) %>%
  mutate(visit = "B") %>%
  mutate(visitid = paste(visit,id, sep="")) # concat id vis
auc_c <- hcot_mt %>%
  filter(visit=="C") %>%
  group_by(id) %>%
  summarize(AUC_glu = auc(time, glu, type = "spline"),
            AUC_cpe = auc(time, cpe, type = "spline"),
            AUC_ins = auc(time, ins, type = "spline")) %>%
  mutate(visit = "C") %>%
  mutate(visitid = paste(visit,id, sep="")) # concat id vis
auc <- rbind(auc_a, auc_b, auc_c)

# MRI VAT
hcot_mr <- hcot_mr %>%
  select(id, visit, mri_vat) %>%
  mutate(id = str_pad(id, 3, pad="0")) %>% # pad id
  mutate(id = as.character(id)) %>% # id as chr
  mutate(visitid = paste(visit,id, sep="")) # concat vis id


### MERGE STUFF ###
# dexa + anthropometry
hcot <- full_join(hcot_ap, hcot_dx, by=c("id","visit","visitid"))
dim(hcot) 

#liver fat
hcot <- left_join(hcot, hcot_lf, by=c("id","visit","visitid"))
dim(hcot) 

#vo2max
hcot <- full_join(hcot, hcot_vm, by=c("id","visit","visitid"))
dim(hcot) 

#biochem (only wideformat)
hcot <- full_join(hcot, hcot_bl, by=c("id","visit","visitid"))
dim(hcot) 

#mri
hcot <- full_join(hcot, hcot_mr, by=c("id","visit","visitid"))
dim(hcot) 

#auc
hcot <- full_join(hcot, auc, by=c("id","visit","visitid"))

# birthweight
hcot <- left_join(hcot, hcot_bw, by="id")
dim(hcot) 

# training randomization
hcot <- left_join(hcot, hcot_tr, by="id") 
dim(hcot) 

# df str
str(hcot)


# Make a "missing obs" table
hcot %>%
  select(visit, id, visitid, 
         height_day1, weight_day1, age_day1, WHR_day1, map_day1, #day 1
         bwcat, # bw
         randomization, # rando
         leanmass_total, # dexa
         liverfatpercent, # liver mri
         fitness_lvl, # fitness test
         bas_glu, # MT
         mri_vat) %>% # comp mri
  mutate_if(is.numeric, funs(replace(., .>0, 1))) %>%
  filter(visit != "M") %>% # take out midway (lots of missing vars)
  filter(!complete.cases(.))
