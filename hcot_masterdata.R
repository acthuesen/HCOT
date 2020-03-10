#This creates (a) master dataset(s) for HCOT study
#Ammend as new datasources (tracer etc. is included)

  ### DEPENDENCIES ###
library(tidyverse)
library(readxl)
library(lubridate)
library(MESS)


	### IMPORT DATA ###
# various datasources below
# replace wd with your wd
# hcot_ap = anthropometry
hcot_ap <- read.table('wd/HCOT_dag 1_A-C.txt', sep=",", header=TRUE)

# hcot_bw = birth weight
hcot_bw <- read.table('wd/HCOT_FV.txt', sep=",", header=TRUE)

# hcot_tr = training randomization
hcot_tr <- read.table('wd/HCOT_randomization.txt', sep="\t", header=TRUE)

# hcot_bd = bone density dexa data
hcot_bd <- read.table('wd/HCOT_DXA BMD_A-C.txt', sep=",", header=TRUE)

# hcot_vf = visceral fat mass dexa data
hcot_vf <- read.table('wd/HCOT_DXA VF_A-C.txt', sep=",", header=TRUE)

# hcot_lf = liver fat data from MRI
hcot_lf <- read.table('wd/HCOT_MRI_A-C_long.txt', sep=",", header=TRUE)

# hcot_bl = biochemistry for baseline
hcot_bl <- read_excel('wd/Dag 2 A-C_lab.xlsx')

# hcot_bl_long = biochemistry for long (repeated import of above)
hcot_bl_long <- read_excel('wd/Dag 2 A-C_lab.xlsx')

# hcot_wb = whole body composition dexa data
hcot_wb <- read.table('wd/HCOT_DXA Whole_A-C.txt', sep=",", header=TRUE) 

# hcot_vm = vo2max data
hcot_vm <- read.table('wd/HCOT_VO2max_A-C.txt', sep=",", header=TRUE)


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

# data structure
str(hcot_ap)


# BIRTH WEIGHT
hcot_bw <- hcot_bw %>%
  mutate(id = str_pad(id, 3, pad="0")) %>% # make id 3 chr
  mutate(id = as.character(id)) # make id chr

# data structure
str(hcot_bw)

# MERGE
# hcot = main df
hcot <- left_join(hcot_ap, hcot_bw, by="id")

# data structure 
str(hcot)


# TRAINING RANDOMIZATION
hcot_tr <- hcot_tr %>%
  select(-bwcat) %>% # bwcat unnecessary since is already derived from bw file (official source)
  rename(randomization = rando) %>% # rename variable to something better
  mutate(id = str_pad(id, 3, pad="0")) %>% # pad id to 3 chr
  mutate(id = as.character(id)) %>% # id as chr
  mutate(randomization = fct_collapse(randomization, #consolidate alternate spellings
                                      "Training"=c("Træning","træning","Træning ","træning "), 
                                      "Control"=c("Kontrol ","kontrol ")))

# data str
str(hcot_tr)

# MERGE
# merge into main df
hcot <- left_join(hcot, hcot_tr, by="id") 

# df str
str(hcot)


# DEXA DATA
hcot_bd <- hcot_bd %>%
  select(Patient.ID, Total.BMD, dexavis) %>% # select only relevant vars
  mutate(Total.BMD = Total.BMD/1000) %>% # change unit on BMD (bone mineral density)
  rename(id = Patient.ID, visit = dexavis, total_BMD = Total.BMD) %>% # rename vars to be consistent with main df
  mutate(id = str_pad(id, 3, pad="0")) %>% # pad id
  mutate(id = as.character(id)) %>% # id as chr
  mutate(visit = fct_recode(visit, "M"="Midtvejs")) %>% # recode midway visit to be consistent with one-chr naming convention
  mutate(visitid = paste(visit,id, sep="")) # create a visit id concat var

# df str
str(hcot_bd)

hcot_vf <- hcot_vf %>%
  select(VAT.masse, VAT.volumen, dexavis, Patient.ID) %>% # select only relevant vars
  rename(id = Patient.ID, visit = dexavis, vat_mass = VAT.masse, vat_volume = VAT.volumen) %>% # rename vars for consistency
  mutate(id = str_pad(id, 3, pad="0")) %>% # pad id
  mutate(id = as.character(id)) %>% # id as chr
  mutate(visit = fct_recode(visit, "M"="Midtvejs")) %>% # recode midway visit
  mutate(visitid = paste(visit,id, sep="")) # concat visit + id

str(hcot_vf)

hcot_wb <- hcot_wb %>%
  mutate(android_tissuefatpercentage = Android.Fedtmasse/Android.Vævsmasse*100) %>% # calc andriod tissue fat %
  mutate(gynoid_tissuefatpercentage = Gynoid.Fedtmasse/Gynoid.Vævsmasse*100) %>% # calc gynoid tissue fat %
  mutate(AG_fatratio = Android.Fedtmasse/Gynoid.Fedtmasse) %>% # calc android/gynoid fat mass ratio
  mutate(trunktotrat = Krop.Fedtmasse/Total.Fedtmasse) %>%
  mutate(legtotrat = Ben.Fedtmasse/Total.Fedtmasse) %>%
  mutate(legtrunkrat = Krop.Fedtmasse/Ben.Fedtmasse) %>%
  select( # select relevant vars
    Patient.ID, 
    dexavis, 
    AG_fatratio,
    android_tissuefatpercentage, 
    gynoid_tissuefatpercentage, 
    Total.Fedtmasse, 
    Total.Fedtfri.masse_excl_bone, 
    Total.Væv..Fedt,
    trunktotrat,
    legtotrat,
    legtrunkrat) %>%
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

# df str
str(hcot_wb)

# join dexa data
hcot_dx <- full_join(hcot_bd,hcot_vf, by=c("id","visit","visitid"))
hcot_dx <- full_join(hcot_dx,hcot_wb, by=c("id","visit","visitid"))

# df str
str(hcot_dx)

nrow(hcot_dx) # number of obs in dexa data
sum(hcot_dx$visit=='M') #number of midway visits
nrow(hcot_dx) - sum(hcot_dx$visit=='M') # expected number of obs if midway are removed

# Only run this if you want midway visits removed
hcot_dx <- hcot_dx %>%
  filter(visit != "M") %>%
  droplevels()

# df str
str(hcot_dx)

# MERGE
# join
hcot <- full_join(hcot, hcot_dx, by=c("id","visit","visitid"))

str(hcot)

# LIVERFAT
hcot_lf <- hcot_lf %>%
  select(-Id1) %>% # remove Id1 (løbenummer)
  rename(liverfatpercent = Percent_fat) %>% # rename var for comprehension
  mutate(id = str_pad(id, 3, pad="0")) %>% # pad id 
  mutate(id = as.character(id)) %>% # id as chr
  mutate(visitid = paste(visit,id, sep="")) # concat visit + id

# df str
str(hcot_lf)

# MERGE
hcot <- left_join(hcot, hcot_lf, by=c("id","visit","visitid"))

#df str
str(hcot)


# VO2 MAX TESTS
hcot_vm <- hcot_vm %>%
  select(ID, VO2_20sec_max, VCO2_20sec_max, RQ_20sec_max, fitness_lvl, mocvis) %>% # rm unnecessary vars
  rename(id = ID, visit = mocvis) %>% # rename vars to something comprehensible 
  mutate(id = str_pad(id, 3, pad="0")) %>% # pad id
  mutate(id = as.character(id)) %>% # id as chr
  mutate(visit = fct_recode(visit, "M"="Midtvejs")) %>% # consistency
  mutate(visitid = paste(visit,id, sep="")) # concat vis id

# df str
str(hcot_vm)

nrow(hcot_vm) # number of obs in vm data
sum(hcot_vm$visit=='M') #number of midway visits
nrow(hcot_vm) - sum(hcot_vm$visit=='M') # expected number of obs if midway are removed

# midway visits removed, only run if you want them removed
hcot_vm <- hcot_vm %>%
  filter(visit != "M") %>%
  droplevels()

# df str
str(hcot_vm)

# MERGE
hcot <- full_join(hcot, hcot_vm, by=c("id","visit","visitid"))

# df str
str(hcot)


# BLOOD SAMPLES
# hcot_bl only contains baseline blood samples, not samples from the MMTT
# See below for MMTT results
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
  mutate(`cpep-125_day2` = as.numeric(`cpep-125_day2`)) %>%
  rowwise() %>%
  mutate(bas_glu = mean(c(`glu-127_day2`, `glu-126_day2`, `glu-125_day2`))) %>% # calc means of three repeated measurements
  mutate(bas_ins = mean(c(`ins-127_day2`, `ins-126_day2`, `ins-125_day2`))) %>% 
  mutate(bas_cpe = mean(c(`cpep-127_day2`, `cpep-126_day2`, `cpep-125_day2`)))

hcot_bl <- hcot_bl %>%
  select(visit, id, bas_glu, bas_ins, bas_cpe, a1c_day2, cholesterol_day2, hdl_day2, ldl_day2, triglyc_day2, alat_day2
         , asat_day2, ggt_day2, factiiviix_day2) %>% # sel rlv vars
  mutate(id = str_pad(id, 3, pad="0")) %>% # pad id
  mutate(id = as.character(id)) %>% # id as chr
  mutate(visitid = paste(visit,id, sep="")) %>% # concat id vis
  mutate(homa_ir = (bas_glu*bas_ins)/22.5) # calc homa

# df str
str(hcot_bl)

hcot <- full_join(hcot, hcot_bl, by=c("id","visit","visitid"))

# df str
str(hcot)


# MMTT
# for long format blood samples (i.e. repeated c-pep etc. measures) from the MMTT
hcot_bl_long <- hcot_bl_long %>%
  select(matches('glu|cpep|ins'), id, visitid, visit, -glufroma1c_day2) # select only glu, cpep, ins

colnames(hcot_bl_long) <- gsub("_day2", "", colnames(hcot_bl_long)) # remove suffix
colnames(hcot_bl_long) <- gsub("cpep", "cpe", colnames(hcot_bl_long)) # rename cpep to cpe because i like it better

hcot_bl_long <- hcot_bl_long %>% 
  gather(var, val, `glu-127`:`cpe+300`) # transform from wide to long

hcot_bl_long$time <- substr(hcot_bl_long$var, 4,9) #extract time from var string
hcot_bl_long$var <- substr(hcot_bl_long$var, 1,3) #extract var (glu|cpep|ins) from var string (replaces)

hcot_bl_long$time <- as.numeric(hcot_bl_long$time) # time as numeric

hcot_bl_long <- hcot_bl_long %>%
  mutate(val = gsub("<7", 3.5, val)) %>% # rm limits of detection, replace by half of LoD 
  mutate(val = gsub("<50", 25, val)) 

hcot_bl_long$val <- as.numeric(hcot_bl_long$val) # val as numeric

str(hcot_bl_long)

hcot_bl_halflong <- hcot_bl_long %>% #Transform to dataset where glu|cpep|ins are each own variable
  spread(var, val)

str(hcot_bl_halflong)

# In order for aggregate results from MMTT to be put into "baseline" dataset, calculate AUCs
auc_a <- hcot_bl_halflong %>%
  filter(visit=="A") %>%
  group_by(id) %>%
  summarize(AUC_glu = auc(time, glu, type = "spline"),
            AUC_cpe = auc(time, cpe, type = "spline"),
            AUC_ins = auc(time, ins, type = "spline")) %>%
  mutate(visit = "A") %>%
  mutate(visitid = paste(visit,id, sep="")) # concat id vis
auc_b <- hcot_bl_halflong %>%
  filter(visit=="B") %>%
  group_by(id) %>%
  summarize(AUC_glu = auc(time, glu, type = "spline"),
            AUC_cpe = auc(time, cpe, type = "spline"),
            AUC_ins = auc(time, ins, type = "spline")) %>%
  mutate(visit = "B") %>%
mutate(visitid = paste(visit,id, sep="")) # concat id vis
auc_c <- hcot_bl_halflong %>%
  filter(visit=="C") %>%
  group_by(id) %>%
  summarize(AUC_glu = auc(time, glu, type = "spline"),
            AUC_cpe = auc(time, cpe, type = "spline"),
            AUC_ins = auc(time, ins, type = "spline")) %>%
  mutate(visit = "C") %>%
  mutate(visitid = paste(visit,id, sep="")) # concat id vis
auc <- rbind(auc_a, auc_b, auc_c)

# df str
str(auc)

# MERGE
hcot <- full_join(hcot, auc, by=c("id","visit","visitid"))
