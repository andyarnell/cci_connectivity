
################################################
### Analysis on Lookup Table: to choose species -- 16/06###
################################################


##### set workspace to folder R  ####
# setwd("//Users//andreacbaquero//Documents//R//wcmc//") ## on my mac

setwd("C:/Users/scienceintern/Documents/AndreaCB/Analysis/scratch/") # on wcmc pc
getwd()

##### 1. LOAD in LookUpTable (lut) and do data check with names and structure ####
lut<-read.table(file="LUT_new_0609.txt", header=TRUE)
names(lut)
#str(lut) 

##View(lut)


##### EDIT dataframe (lut) >> (sublut) ###

###Keep only num and glc2000code columns (sublut)##
## foranalysis of glccode combination and frequency ##

sublut<-lut[c(1,4)]
##View(sublut)
#str(sublut)

sublut<-unique(sublut)

### convert to factors ##
sublut$num<-factor(sublut$num)
sublut$GLC2000code<-factor(sublut$GLC2000code)
#str(sublut)

##### write table
#write.table(sublut,"C:/Users/scienceintern/Documents/AndreaCB/Analysis/scratch/sublut.txt",col.names=T,row.names=F,sep="\t")


##### 2. WHAT MIKE DID to create strings for each combination of hab pref#####
### (agg.sublut)

agg.sublut = data.frame(sublut$num)
agg.sublut$comb.GLC2000code = ""
for(i in 1:dim(sublut)[1])
{
  agg.sublut$comb.GLC2000code[i] = paste(sort(sublut$GLC2000code[sublut$num == agg.sublut$sublut.num[i]]),sep=",",collapse = ",")
  
}


##View(agg.sublut)

### Keep only UNIQUE elements ###
agg.sublut<-unique(agg.sublut)

##### write table
#write.table(agg.sublut,"C:/Users/scienceintern/Documents/AndreaCB/Analysis/scratch/agg.sublut_0610.txt",col.names=T,row.names=F,sep="\t")

##### 3. Create table with FREQUENCY of combinations based on agg.sublut #####
t.GLC.duplicates = table(agg.sublut$comb.GLC2000code)[order(-table(agg.sublut$comb.GLC2000code))]

##View (t.GLC.duplicates)
#str(t.GLC.duplicates)
#dim(t.GLC.duplicates)

#### write table
##write.table(t.GLC.duplicates,"C:/Users/scienceintern/Documents/AndreaCB/Analysis/scratch/t.GLC.duplicates_0610.txt",col.names=T,row.names=F,sep="\t")


###########################################

##### 4. Create a new sublut dataframe (catlut)  with habitat codes ####
### forest == f, all shrub== s, all crop== c, water==w, artificial == a ###

#setwd("C:/Users/scienceintern/Documents/AndreaCB/Analysis/scratch")
#sublut<-read.table(file="sublut.txt", header=TRUE)
names(sublut)
#str(sublut)
sublut$num<-as.factor(sublut$num)

library(car)
catlut<-sublut
##View(catlut)
str(catlut)

catlut$GLC2000code <- as.character(catlut$GLC2000code)


catlut$GLC2000code<-recode(catlut$GLC2000code,"c('1','2','3','4','5','6','7','8','9','10')='f'")
catlut$GLC2000code<-recode(catlut$GLC2000code,"c('11','12','13','14','15')='s'")
catlut$GLC2000code<-recode(catlut$GLC2000code,"c('16','17','18','23')='c'")
catlut$GLC2000code<-recode(catlut$GLC2000code,"c('19')='b'")
catlut$GLC2000code<-recode(catlut$GLC2000code,"c('20','21')='w'")
catlut$GLC2000code<-recode(catlut$GLC2000code,"c('22')='a'")

catlut<-unique(catlut)

##View(catlut)

##### write table
##write.table(catlut,"C:/Users/scienceintern/Documents/AndreaCB/Analysis/scratch/LUT_habitatCAT.txt",col.names=T,row.names=F,sep="\t")

##########################

##### 5. RESHAPE catlut // Column into data frame (reshaped)#####

# setwd("C:/Users/scienceintern/Documents/AndreaCB/Analysis/scratch")
# catlut<-read.table(file="LUT_habitatCAT.txt", header=TRUE)
#names(catlut)
#str(catlut)


library(reshape2)
#View(catlut)
catlut$value<- 1
#View(catlut)

reshaped<-dcast(catlut,catlut$num ~ catlut$GLC2000code,value.var="value",sum) ## sum adds 0 instead of na's on missing values

#View(reshaped)


##reshaped$17== 1 ## this was for when running sublut and an issue with 17 (??) 

####  CUT glccode a /b/ C --> mix (reshaped)--> (reshaped2)  ###

#reshaped<-read.table(file="reshaped.txt", header=TRUE)

names(reshaped)
reshaped$mix <- ifelse(reshaped$b==1,1,ifelse(reshaped$a==1,1,ifelse(reshaped$c==1,1,0))) ## fuse a,b,c

reshaped<-reshaped[c(1,5,6,7,8)] ## eliminate columns a,b,c
#View(reshaped)
colnames(reshaped)[1] <- "num"

##### 6. RESHAPED to LONG, back to catlut with column mix but not a,b,c #####

long<-melt(reshaped,id.vars=c("num"))
#View(long)
names(long)

long<-long[!(long$value==0),] # remove rows that have value=0 for one of the codes

long<-long[c(1,2)]## eliminate value column
#View(long)
names(long)
catlut<-long
names(catlut)
colnames(catlut)[2] <- "GLC2000code"
colnames(catlut)[1] <- "num"
#View(catlut)

#### write table catlut-mix = c,b,a are mixed in one
##write.table(catlut,"C:/Users/scienceintern/Documents/AndreaCB/Analysis/scratch/catlut-mix.txt",col.names=T,row.names=F,sep="\t")


##########################

##### 7. Create strings for each combination of hab pref / CODED (catlut)-> (agg.catlut) ######

agg.catlut = data.frame(catlut$num)
agg.catlut$comb.GLC2000code = ""
for(i in 1:dim(catlut)[1])
{
  agg.catlut$comb.GLC2000code[i] = paste(sort(catlut$GLC2000code[catlut$num == agg.catlut$catlut.num[i]]),sep=",",collapse = ",")
  
}


#View(agg.catlut)

### Keep only UNIQUE elements ###
agg.catlut<-unique(agg.catlut)

#### write table
#write.table(agg.catlut,"C:/Users/scienceintern/Documents/AndreaCB/Analysis/scratch/agg.catlut_0616.txt",col.names=T,row.names=F,sep="\t")

##### 8. Create table with FREQUENCY of combinations based on agg.catlut####
freqCatlut = table(agg.catlut$comb.GLC2000code)[order(-table(agg.catlut$comb.GLC2000code))]

#View (freqCatlut)

#### write table
##write.table(freqCatlut,"C:/Users/scienceintern/Documents/AndreaCB/Analysis/scratch/freqCatlut_0616.txt",col.names=T,row.names=F,sep="\t")

####################################################



##########################.#########################
###  II. MERGE ALL INFO TO MAKE UBER TABLE ####

##### 9. LOAD and EDIT LookUpTable with num, binomial and level2 (lut) >> (splist_l2)  ####

# setwd("//Users//andreacbaquero//Documents//R//wcmc//") ## on my mac

#setwd("C:/Users/scienceintern/Documents/AndreaCB/Analysis/scratch/") # on wcmc pc


##### LOAD in LookUpTable (lut) and do data check with names and structure ##
#lut<-read.table(file="LUT_new_0609.txt", header=TRUE)
names(lut)
str(lut) 

#View(lut)

### EDIT dataframe (lut) >> (splist_l2) ###

###Keep  num binomail and level2 columns (sublut)##
## for analysis of glccode combination and frequency ##

splist_l2<-lut[c(1,2,3)]
#View(splist_l2)
str(splist_l2)
names(splist_l2)

##### 10. MERGE (splist_l2) with (reshaped) with GLC values ---> (splist_2)#####
## all= TRUE to get all rows merged, even if not intersect.. will get NAs on missing data #

names(splist_l2)
#View(splist_l2)
names(reshaped)

splist_2<-merge(splist_l2, reshaped, by.x="num", by.y="num", all=TRUE)

#View(splist_2)
names(splist_2)
##str(splist_2)
splist_2<-unique(splist_2) # remove duplicates
splist_2$num<-as.factor(splist_2$num)

#### write table
#write.table(splist_2,"C:/Users/scienceintern/Documents/AndreaCB/Analysis/scratch/splist_2_0616.txt",col.names=T,row.names=F,sep="\t")


##### 11. ADD COLUMN to (splist_2) with string of habitat preferences from (agg.catlut) -> (splist_3) #####
#setwd("C:/Users/scienceintern/Documents/AndreaCB/Analysis/scratch/") # on wcmc pc

##### LOAD in agg.catlut ###
#agg.catlut<-read.table(file="agg.catlut_0616.txt", header=TRUE)
names(agg.catlut)
#str(agg.catlut) 

#View(agg.catlut)

# LOAD in splist_2
#splist_2<-read.table(file="splist_2_0616.txt", header=TRUE)
names(splist_2)
#str(splist_2) 

#View(splist_2)

names(agg.catlut)
str(agg.catlut)
agg.catlut$catlut.num<-factor(agg.catlut$catlut.num)

names(splist_2)
str(splist_2)

## MERGE splist_2 & agg_catlut
splist_3<-merge(splist_2, agg.catlut, by.x="num", by.y="catlut.num", all=FALSE)

#View(splist_3)
names(splist_3)
str(splist_3)
splist_3<-unique(splist_3) # remove duplicates
splist_3<-droplevels(splist_3)

### reorder columns ##
splist_3<-splist_3[c("num","binomial","Level2","comb.GLC2000code", "f","s","mix","w")]

##rename column #
colnames(splist_3)[4]<-"GLCcodes"
splist_3$GLCcodes<-factor(splist_3$GLCcodes)

## 
#View(splist_3)

#### write table
#write.table(splist_3,"C:/Users/scienceintern/Documents/AndreaCB/Analysis/scratch/splist_3_0616.txt",col.names=T,row.names=F,sep="\t")

###################################################

##### 12. LOAD Distance data, edit and Categorize: Low, Mid, High ####
setwd("C:/Users/scienceintern/Documents/AndreaCB/Analysis/raw")
dist<-read.table(file="Distance.txt", header=TRUE)
names(dist)
#str(dist) 

#View(dist)

##### EDIT dataframe (dist) >> (splist_dist) ##
###Keep  Taxon.ID and Final.value.to.use columns ($Dist)##
## for analysis of glccode combination and frequency ##

splist_dist<-dist[c(2,3)]
names(splist_dist)
#View(splist_dist)
#str(splist_dist)

splist_dist$Taxon.ID <- as.factor(splist_dist$Taxon.ID)

### explore splist_dist
# hist(splist_dist$Dist, breaks=100)
# mean(splist_dist$Dist)
# median(splist_dist$Dist)
# x<-which(splist_dist$Dist<5)
# length(x)
# y<-which(splist_dist$Dist>5)
# length(y)
# x<-which(splist_dist$Dist>20)
# length(x)
# quantile (splist_dist$Dist)

### find natural breaks ###
install.packages("classInt")

classIntervals(splist_dist$Dist,n=3,style = "jenks")
#style: jenks
# [0.03,5.631892] (5.631892,18.59849] (18.59849,53.28185] 
# 936                 167                  44 

plot(splist_dist$Dist)

### create a new column for categories of dispersal distance ###
splist_dist$DistC<- ifelse(splist_dist$Dist<=5, "low", ifelse(splist_dist$Dist>20, "high", "mid"))

#### write in RAW so to load later
#write.table(splist_dist,"C:/Users/scienceintern/Documents/AndreaCB/Analysis/scratch/splist_dist.txt",col.names=T,row.names=F,sep="\t")

##### 13. MERGE splist_3 with splist_dist ---> (splist_4) ####
## all= TRUE to get all rows merged, even if not intersect.. will get NAs on missing data #

#splist_dist<-read.table(file="splist_dist.txt", header=TRUE)


names(splist_3)
names(splist_dist)

splist_4<-merge(splist_3, splist_dist, by.x="num", by.y="Taxon.ID", all=TRUE) ## MERGE

#View(splist_4)
names(splist_4)
#str(splist_4)
splist_4<-unique(splist_4) # remove duplicates

splist_4$num<-factor(splist_4$num)

#### write table
#write.table(splist_4,"C:/Users/scienceintern/Documents/AndreaCB/Analysis/scratch/splist_4_0616.txt",col.names=T,row.names=F,sep="\t")


###################################################

####### SKIP DIET # 14. LOAD Guild data, EDIT####

# setwd("C:/Users/scienceintern/Documents/AndreaCB/Analysis/raw/") # on wcmc pc
# 
# guild<-read.table(file="guild.txt", header=TRUE)
# names(guild)
# str(guild) 

# #View(guild)
# which(is.na(guild))
# 
# guild$Taxon_ID<-factor(guild$Taxon_ID)
# 

####### SKIP DIET # 15. EDIT dataframe (guild) >> (splist_guild) ####
# 
# ###Keep  Taxon.ID and Diet columns (guild)##
# ## for analysis of glccode combination and frequency ##
# 
# splist_guild<-guild[c(2,3)]
# names(splist_guild)
# #View(splist_guild)
# str(splist_guild)
# dim(splist_guild)
# 
# splist_guild<-unique(splist_guild) # remove duplicates
# 
# ### GUILD contains 9851 species --> need to keep only our 1147
# sps<-splist_3[c(1)]
# #View(sps)
# str(sps)
# ### cut to keep only our species##
# sp_guild<-merge(sps, splist_guild, by.x="num", by.y="Taxon_ID",all=FALSE)
# str(sp_guild)
# droplevels(sp_guild)
# #View(sp_guild)
# 
# # write in RAW so to load later
# #write.table(sp_guild,"C:/Users/scienceintern/Documents/AndreaCB/Analysis/scratch/sp_guild.txt",col.names=T,row.names=F,sep="\t")

####### SKIP DIET # 16. MERGE Guild (sp_guild) with (splist_3) ---> (splist_4) ####
## all= TRUE to get all rows merged, even if not intersect.. will get NAs on missing data #

# names(splist_3)
# names(sp_guild)
# 
# splist_4<-merge(splist_3, sp_guild, by.x="num", by.y="num", all=FALSE)
# 
# #View(splist_4)
# names(splist_4)
# str(splist_4)
# splist_4<-unique(splist_4) # remove duplicates
# which(is.na(splist_4))
# 
# # write table
# #write.table(splist_4,"C:/Users/scienceintern/Documents/AndreaCB/Analysis/scratch/sp_all_traits.txt",col.names=T,row.names=F,sep="\t")
# 
# # write in RAW so to load later
# #write.table(splist_4,"C:/Users/scienceintern/Documents/AndreaCB/Analysis/raw/sp_all_traits.txt",col.names=T,row.names=F,sep="\t")



#############################################################################

##### 17. SUBSET (splist_4) to have only Dry, Moist Montane, Moist Lowland from LEVEL2 --> (splist_sub) ####

setwd("C:/Users/scienceintern/Documents/AndreaCB/Analysis/scratch/") # on wcmc pc

##### LOAD in splist_3  ###
#splist_4<-read.table(file="splist_4_0616.txt", header=TRUE)
names(splist_4)
#str(splist_4) 

#View(splist_4)
splist_4$num<-as.factor(splist_4$num)

#[20] "Forest_-_Subtropical/Tropical_Dry"                                                     
#[22] "Forest_-_Subtropical/Tropical_Moist_Lowland"                                           
#[23] "Forest_-_Subtropical/Tropical_Moist_Montane"


### subsetting that worked
splist_sub<-subset(splist_4, splist_4$Level2=="Forest_-_Subtropical/Tropical_Dry" | splist_3$Level2=="Forest_-_Subtropical/Tropical_Moist_Lowland" | splist_3$Level2=="Forest_-_Subtropical/Tropical_Moist_Montane")
#View(splist_sub)
splist_sub<-droplevels(splist_sub)

names(splist_sub)
str(splist_sub)


##write table
#write.table(splist_sub,"C:/Users/scienceintern/Documents/AndreaCB/Analysis/scratch/splist_sub_0616.txt",col.names=T,row.names=F,sep="\t")

###################

##### 18. FIND missing species: 42 species are missing from splist_sub => (miss42) ####

missing<-merge(splist_sub, splist_4, by.x="num", by.y="num", all=TRUE) # merge subset(1105sps) and splist_3(1147 sps)

#View(missing) ## will have all species, those 'missing' dry/montane/lowland will have NA's 
names(missing)
str(missing)

### Keep rows of the 42 missing species only ###
miss42<-subset(missing, is.na(missing$binomial.x))
#View(miss42)
str(miss42)
miss42<-droplevels(miss42)

## remove empty columns from merge ##

miss42<-miss42[c(1,11,12,13,14,15,16,17,18,19)]
names(miss42)

## Rename columns ##
colnames(miss42)[2]<-"binomial"
colnames(miss42)[3]<-"Level2"
colnames(miss42)[4]<-"GLCcodes"
colnames(miss42)[5]<-"f"
colnames(miss42)[6]<-"s"
colnames(miss42)[7]<-"mix"
colnames(miss42)[8]<-"w"
colnames(miss42)[9]<-"DIst"
colnames(miss42)[10]<-"DistC"

names(miss42)

## Recode entries in "Level2" to "other###
miss42$Level2<-"Other"
#View(miss42)

miss42<-droplevels(miss42)
miss42<-unique(miss42)
#View(miss42)

#### write table
#write.table(miss42,"C:/Users/scienceintern/Documents/AndreaCB/Analysis/scratch/42sps_noGraeme.txt",col.names=T,row.names=F,sep="\t")
#####################


### merge with subset of 1105 species WITH 


###################################################


###########################################################################

##### 19. COUNT rows e/sps dry-low-montane in (splist_sub)-> (count) and make generalist cat for sps in more than 1 (splist_count)####


#setwd("C:/Users/scienceintern/Documents/AndreaCB/Analysis/scratch/") # on wcmc pc
getwd()

#setwd("/Users/andreacbaquero/Dropbox/WCMC -CCI/R/") # on mac
#getwd()
## LOAD splist_sub_0616 (splist_sub)
#splist_sub<-read.table(file="splist_sub_0616.txt", header=TRUE)
names(splist_sub)
#View(splist_sub)
str(splist_sub)
splist_sub$num<-factor(splist_sub$num)

##### create a vector with species list
# x<-unique(splist_sub$num)
# #View(x)
# str(x)


count <-aggregate(splist_sub$Level2 ~ splist_sub$num, splist_sub, function(x) length(unique(x)))

#View(count)
#str(count)
#head(count)

## splist$num splist$Level2
## 1   22678736             1
## 2   22678748             1
## 3   22678752             1
## 4   22678760             1
## 5   22678790             1
## 6   22678795             1

# write table
#write.table(count,"C:/Users/scienceintern/Documents/AndreaCB/Analysis/scratch/sphcount_0616.txt",col.names=T,row.names=F,sep="\t") #WCMC PC

### Merge (count) and (splist_sub)--> (splist_count) ###

#names(splist_sub)
#names(count)

splist_count<-merge(splist_sub, count, by.x="num", by.y="splist_sub$num", all=TRUE)

#View(splist_count)
names(splist_count)

##rename column count
colnames(splist_count)[11]<-"IUCNCount"
str(splist_count)
splist_count$IUCNCount<-as.numeric(splist_count$IUCNCount)

### Recode splist_count$Level2 so if $count == 2 or ==3 then --> "Generalist" ##

splist_count$Level2<-as.character(splist_count$Level2)

splist_count$Level2[splist_count$IUCNCount==2]<-"Generalist"
splist_count$Level2[splist_count$IUCNCount==3]<-"Generalist"

#View(splist_count)

splist_count$Level2<-as.factor(splist_count$Level2)
str(splist_count)

## keep unique only (one entry per species) ##

splist_count<-unique(splist_count) # remove duplicates
splist_count<-droplevels(splist_count)
str(splist_count)
#View(splist_count)

#names(splist_count)
splist_count<-splist_count[c(1:10)]

#### write table
##write.table(splist_count,"/Users/andreacbaquero/Dropbox/WCMC -CCI/R/sp_list_graeme_unique.txt",col.names=T,row.names=F,sep="\t") # mac

# write table
#write.table(splist_count,"C:/Users/scienceintern/Documents/AndreaCB/Analysis/scratch/sp_list_graeme_unique.txt",col.names=T,row.names=F,sep="\t") #WCMC PC



##### 20. BIND (splist_count) and (miss42) to have a talbe with all 1147 sps#### 



names(miss42)
names(splist_count)

## correct dist column name on miss42#

colnames(miss42)[9]<-"Dist"


splist_total<-rbind(splist_count, miss42)

#View(splist_total)
#names(splist_total)
#str(splist_total)
splist_total<-unique(splist_total) # remove duplicates

splist_total$num<-factor(splist_total$num)

# write table
#write.table(splist_total,"C:/Users/scienceintern/Documents/AndreaCB/Analysis/scratch/splist_total.txt",col.names=T,row.names=F,sep="\t")



##################################### look here ###########


##### 20. ANALIZE table (splist_count) -find factor COMBINATIONS (combi) ####
#setwd("C:/Users/scienceintern/Documents/AndreaCB/Analysis/scratch/") # on wcmc pc
#getwd()

#setwd("/Users/andreacbaquero/Dropbox/WCMC -CCI/R/") # on mac
#getwd()

#splist_total<-read.table(file="splist_total.txt", header=TRUE)
#names(splist_total)
#View(splist_total)
str(splist_total)
splist_total$num<-factor(splist_total$num)



### MAKE UBER column 
combi<-(count(splist_total, c('Level2', 'GLCcodes','DistC')))

combi<-combi[order(-combi$freq),]

combi$comb <- 1:nrow(combi) 
combi$uber<-with(combi, interaction(Level2, GLCcodes, DistC))

#names(combi)
#str(combi)
#View(combi)
combi<-droplevels(combi)

#### write table
##write.table(combi,"/Users/andreacbaquero/Dropbox/WCMC -CCI/R/combinations.txt",col.names=T,row.names=F,sep="\t") # mac

#### write table
#write.table(combi,"C:/Users/scienceintern/Documents/AndreaCB/Analysis/scratch/combinations.txt",col.names=T,row.names=F,sep="\t") #WCMC PC


##### 21. MAKE UBER COLUMN IN (splist_total) --> (df) ####
df<-splist_total
df$uber<-with(df, interaction(Level2, GLCcodes, DistC))
#View(df)

#names(df)
#names(combi)


df<-merge(df, combi, by.x="uber", by.y="uber", all=TRUE)

#View(df)
names(df)
str(df)
df<-unique(df) # remove duplicates


##### write table
##write.table(df,"/Users/andreacbaquero/Dropbox/WCMC -CCI/R/sp_list_comb_0617.txt",col.names=T,row.names=F,sep="\t") # MAC

#### write table
#write.table(df,"C:/Users/scienceintern/Documents/AndreaCB/Analysis/scratch/sp_list_comb_0617.txt",col.names=T,row.names=F,sep="\t") #WCMC PC


count(df, c('uber'))


##### 22. MAKE UBER table (splist_uber)####
## load table with uber column ###
#setwd("/Users/andreacbaquero/Dropbox/WCMC -CCI/R/") # on mac
#getwd()

#setwd("C:/Users/scienceintern/Documents/AndreaCB/Analysis/scratch/") # on wcmc pc
#getwd()

#df<-read.table(file="sp_list_comb_0617.txt", header=TRUE)
names(df)
#View(df)
str(df)
df$num<-factor(df$num)

splist_uber<-df[,c("num","binomial","Level2.x","GLCcodes.x","f" ,"s", "mix","w","Dist" ,"DistC.x" , "freq", "comb","uber")]
#View(splist_uber)
names(splist_uber)

# rename columns #

colnames(splist_uber)[3]<-"IUCNhab"
colnames(splist_uber)[4]<-"GLCcodes"
colnames(splist_uber)[10]<-"DistC"

#names(splist_uber)
#str(splist_uber)

splist_uber$comb<-factor(splist_uber$comb)
#View(splist_uber) 
str(splist_uber)

#### write table
##write.table(splist_uber,"/Users/andreacbaquero/Dropbox/WCMC -CCI/R/splist_uber.txt",col.names=T,row.names=F,sep="\t") #MAc

#### write table
#write.table(splist_uber,"C:/Users/scienceintern/Documents/AndreaCB/Analysis/scratch/splist_uber_0617.txt",col.names=T,row.names=F,sep="\t") #WCMC PC


plot(splist_uber$comb)

#### OTHER STUFF DONE 06/17 #####

## load uber table ###
#setwd("/Users/andreacbaquero/Dropbox/WCMC -CCI/R/") # on mac
#getwd()


#setwd("C:/Users/scienceintern/Documents/AndreaCB/Analysis/scratch/") # on wcmc pc
#getwd()

#splist_uber<-read.table(file="splist_uber.txt", header=TRUE)
names(splist_uber)
#View(splist_uber)
str(splist_uber)
splist_uber$num<-factor(splist_uber$num)
splist_uber$comb<-as.numeric(splist_uber$comb)

length(which(splist_uber$comb<20))
splist_uber<-droplevels(splist_uber)
### find natural breaks ######
library(classInt)
n<-classIntervals(splist_uber$comb,n=3,style = "jenks") 

# style: jenks
# one of 325 possible partitions of this variable into 3 classes
# [1,41]  (41,88] (88,177] 
# 448      522      177 

pcol=c("darkblue", 'lightblue', 'palegreen')
plot(n,pal=pcol)


#### Compare taxonomic orders ####

## load birdlife list of species with family data ##
setwd("C:/Users/scienceintern/Documents/AndreaCB/Analysis/raw/") # on wcmc pc
birdlist<-read.table(file="birdlifelist.txt", header=TRUE)
names(birdlist)
str(birdlist) 

##View(birdlist)

## load our talble # 
#setwd("C:/Users/scienceintern/Documents/AndreaCB/Analysis/scratch/") # on wcmc pc
#splist_uber<-read.table("splist_uber_0617.txt", header=TRUE)


## merge on species code ##
names(birdlist)

colnames(birdlist)[4]<-"num"
names(birdlist)

names(splist_uber)

splist_tax<-merge(splist_uber, birdlist,by.x="num", by.y="num", all.x=TRUE)

#### write table
#write.table(splist_tax,"C:/Users/scienceintern/Documents/AndreaCB/Analysis/scratch/splist_tax.txt",col.names=T,row.names=F,sep="\t")

##### explore with ORDER and FAMILY ####
names(splist_tax)
##View(splist_tax)
str(splist_tax)
splist_tax$Family[splist_tax$comb==1]

unique(splist_tax$Family[splist_tax$comb==3])

splist_tax<-splist_tax[c(1:16)]

#### see which families in each combination ##

combtax<-splist_tax[c(12,13,11,14,16)]


##View(combtax)
combtax<-unique(combtax)



##### SUBSET splist_tax or splist_uber to have obly TOP 19 C #####
library(stratification)
topcomb<-subset(splist_tax, splist_tax$com<20)
s<-strata(topcomb,stratanames = "comb",size="freq",method="srswor")
##View(topcomb)

strata(topcomb,12,.1)


#### write table
#write.table(topcomb,"C:/Users/scienceintern/Documents/AndreaCB/Analysis/scratch/topcomb.txt",col.names=T,row.names=F,sep="\t") #WCMC PC



######## RANDOM STRATIFIED SAMPLING ####
#setwd("C:/Users/scienceintern/Documents/AndreaCB/Analysis/scratch/") # on wcmc pc
#topcomb<-read.table(file="topcomb.txt", header=TRUE)
names(topcomb)
##View(topcomb)
#str(topcomb)


#### MAKE my own function for stratification ### 

stratified = function(df, group, size) {
  #  USE: * Specify your data frame and grouping variable (as column 
  #         number) as the first two arguments.
  #       * Decide on your sample size. For a sample proportional to the
  #         population, enter "size" as a decimal. For an equal number 
  #         of samples from each group, enter "size" as a whole number.
  #
  #  Example 1: Sample 10% of each group from a data frame named "z",
  #             where the grouping variable is the fourth variable, use:
  # 
  #                 > stratified(z, 4, .1)
  #
  #  Example 2: Sample 5 observations from each group from a data frame
  #             named "z"; grouping variable is the third variable:
  #
  #                 > stratified(z, 3, 5)
  #
  require(sampling)
  temp = df[order(df[group]),]
  if (size < 1) {
    size = ceiling(table(temp[group]) * size)
  } else if (size >= 1) {
    size = rep(size, times=length(table(temp[group])))
  }  
  strat = strata(temp, stratanames = names(temp[group]), 
                 size = size, method = "srswor")
  (dsample = getdata(temp, strat))
}



z<-stratified(topcomb, "comb", .05)

str(z)
##View(z)

#### write table
#write.table(z,"C:/Users/scienceintern/Documents/AndreaCB/Analysis/scratch/samplespecies.txt",col.names=T,row.names=F,sep="\t") #WCMC PC


#############################

