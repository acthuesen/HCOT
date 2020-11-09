library(tidyverse)
library(lubridate)

setwd('/PATH/')
getwd()

# tracer data
tracer <- read.csv('./tracerdat.csv', header=TRUE, na.strings = c('#DIV/0!','missing', 'NA', '','0'))

tracer$ttid <- str_remove_all(tracer$ttid, '.raw')

tracer <- tracer %>%
  separate(ttid, into=c('visid','time'), sep='=')
# outputs warning for NaN rows

#change -0 to -1 and +0 to +1
tracer$time <- recode(tracer$time, '+0'='+1')
tracer$time <- recode(tracer$time, '-0'='-1')

# rm '+' from times, replace 'base' with -125, change to numeric
tracer$time <- str_remove(tracer$time, '\\+') #\\ to escape spec char

tracer$time <- recode(tracer$time, base='-125')
tracer$time <- recode(tracer$time, Sidste='-125')

tracer$time <- as.numeric(tracer$time)

# split visid into vis and id, then make the usual "visitid" var that you have in main datasets
tracer$visit <- str_sub(tracer$visid, start=-1)
tracer$visit <- as.factor(tracer$visit)
tracer$id <- str_sub(tracer$visid, 1, 3)

tracer <- tracer %>%
  drop_na(visit) %>%
  droplevels() %>%
  mutate(visitid = paste(visit,id, sep="")) %>% # create a visit id concat var
  select(-visid, -sheetname) #drop this one, can't be used going forward
  
write.csv(tracer, './tracerdat_parsed.csv', row.names=F)
