#########################################
##creating the Look up table ###
#########################################

###27-05-16#############

### Create a Look up table for species with habitat data ###


#set workspace to folder R 
setwd("C:/Users/scienceintern/Documents/AndreaCB/Analysis/raw")


##### Load Project Species - file: our-species, dataframe: ourbirds ####

ourbirds<-read.table(file="our-species_2705.txt", header=TRUE)
#names(ourbirds)

### structure: gives info about each column and line
#str(ourbirds) 
#View(ourbirds)

##### Load Species hab data- file: hab_data, dataframe: stu_birds ####

stubirds<-read.table(file="hab_data.txt", header=TRUE)
names(stubirds)

# str(stubirds) 
# View(stubirds)

##### 1. Merge tables (ourbirds & stubrids) using IUCN sp code to get hab preference data list for only OURBIRDS ####
### dataframe: spp_HabPref2 , output: joint_birds-hab2.txt###

spp_HabPref<-merge(ourbirds, stubirds, by.x="num", by.y="SIS_ID", all=FALSE)
spp_HabPref<-unique(spp_HabPref)

# View(spp_HabPref)
# str(spp_HabPref)
# head(spp_HabPref)

## drop unused levels  ###

spp_HabPref<-droplevels(spp_HabPref)
# str(spp_HabPref)
unique(spp_HabPref)

## Export a table ###

#write.table(spp_HabPref,"C:/Users/scienceintern/Documents/AndreaCB/Analysis/scratch/joint_birds-hab2_0608.txt",col.names=T,row.names=F,sep="\t")

##### 2. Choose only those with suitable habitat. ####
#Subset from spp_HabPref2 , output: HabPref_Suit // HabPref_Suit.txt #

#levels(spp_HabPref$Suitability)

HabPref_Suit<-subset(spp_HabPref, spp_HabPref$Suitability=="Suitable")
#str(HabPref_Suit)

HabPref_Suit<-droplevels(HabPref_Suit)
#str(HabPref_Suit)

#write.table(HabPref_Suit,"C:/Users/scienceintern/Documents/AndreaCB/Analysis/scratch/HabPref_Suit_0608.txt",col.names=T,row.names=F,sep="\t")

##### 3. Edit merged dataset: HabPref_Suit.txt ####
## remove NA's, HabPref_Suit-noNA ## 

## set workspace to folder R 
setwd("C:/Users/scienceintern/Documents/AndreaCB/Analysis/scratch")

## load in data if needed
#HabPref_Suit<-read.table(file="HabPref_Suit_0608.txt", header=TRUE)

#names(HabPref_Suit)
# str(HabPref_Suit) 
# View(HabPref_Suit)
# head(HabPref_Suit)

###Replace NA's on Level 2 ##
# for Level1=='Rocky areas' with "Rocky_areas_(eg._inland_cliffs,_mountain_peaks)" in accord with Crosswalk data###


## find NA's##
which(is.na(HabPref_Suit$Level2))
is.na(HabPref_Suit$Level2)


####### IF NA'S (missing values) ###

###Replace NA's (missing values) on Level 2 for Level1=='Rocky areas' with "Bare_Areas" in accord with Crosswalk data###

str(HabPref_Suit)

### First: make column Level 2 a character type to be able to change NA's##
HabPref_Suit$Level2<- as.character(HabPref_Suit$Level2)

#Check Structure#
str(HabPref_Suit)

## Replace NA's##
HabPref_Suit$Level2[is.na(HabPref_Suit$Level2)]<-"Rocky_areas_(eg._inland_cliffs,_mountain_peaks)"

View(HabPref_Suit)

## Export table###
#write.table(HabPref_Suit,"/C:/Users/scienceintern/Documents/AndreaCB/Analysis/scratch/outputs/HabPref_Suit-noNA_0608.txt",col.names=T,row.names=F,sep="\t")


########## IF NO NA (missing values) ==  integer(0) ## then>>> treating it as a character "na" ###

which(HabPref_Suit$Level2=="na")

### First: make column Level 2 a character type to be able to change NA's##
HabPref_Suit$Level2<- as.character(HabPref_Suit$Level2)

### replace "na" for Rocky_areas_(eg._inland_cliffs,_mountain_peaks)###

HabPref_Suit$Level2[HabPref_Suit$Level2=="na"]<-"Rocky_areas_(eg._inland_cliffs,_mountain_peaks)"

# str(HabPref_Suit) 

View(HabPref_Suit)

### Export table##
#write.table(HabPref_Suit,"C:/Users/scienceintern/Documents/AndreaCB/Analysis/scratch/HabPref_Suit-noNA_0806.txt",col.names=T,row.names=F,sep="\t")

##################################

################################################################
################################################################

##### 4. Merge Habitat Suitability dataset with GLC CrossWalk ####
## habmerge // HabMerge_all.txt # data with full outer join X-U-Y#

#set workspace to folder R 
setwd("C:/Users/scienceintern/Documents/AndreaCB/Analysis/raw")

getwd()

#to turn off graphs
dev.off()

###### Load GLC Crosswalk table ###


#crosswalk<-read.table(file="GLCCrossWalk_Updated_20150310.txt", header=TRUE) ## old crosswalk
#crosswalk<-read.table(file="New_Crosswalk_no999.txt", header=TRUE) # new one without 999, 100, 200

crosswalk<-read.table(file="New_Crosswalk_no17f.txt", header=TRUE) # new one 17 and forest link removed and without 999,100,200
names(crosswalk)


#str(crosswalk) 
#View(crosswalk)

####Load Habitat Suitability data: HabPref_Suit-noNA.txt ###

HabPref_Suit<-read.table(file="HabPref_Suit-noNA_0806.txt", header=TRUE)
names(HabPref_Suit)


#str(HabPref_Suit) 
#View(HabPref_Suit)

##Merge tables using IUCNDescription // Level2 habitat ###
## all= TRUE to get all rows merged, even if not intersect.. will get NAs on missing data #

habmerge<-merge(HabPref_Suit, crosswalk, by.x="Level2", by.y="IUCNDescription", all=TRUE)

names(habmerge)
#View(habmerge)
#str(habmerge)

unique(habmerge) # remove duplicates


## Export table: with the whole merge, HabMerge_all.txt###
#write.table(habmerge,"C:/Users/scienceintern/Documents/AndreaCB/Analysis/scratch/HabMerge_all_0608.txt",col.names=T,row.names=F,sep="\t")

##### 5. Edit merged crosswalk-bird data####

## find entries with NA on GLC Crosswalk ###
## find rows with NA's == Hab types from Level2 missing in IUCNDescription ###

which(is.na(habmerge$IUCN_middle_level_code))


##### Hab merge (GLC and Hab Suitability) without NA's on GLC's side ###
## output: habmerge_intersec_drop // merge_complete.txt

habmerge_withGLC<-subset(habmerge, !is.na(habmerge$IUCN_middle_level_code))
# View(habmerge_withGLC)
# str(habmerge_withGLC)

### now exclude entries without sps info###
habmerge_intersec<-subset(habmerge_withGLC, !is.na(habmerge_withGLC$binomial))
View(habmerge_intersec)
str(habmerge_intersec)

## drop levels

habmerge_intersec_drop<-droplevels(habmerge_intersec)
View(habmerge_intersec_drop)
str(habmerge_intersec_drop)

levels(habmerge_intersec_drop$Level2)

## Export table: GLC & Hab merge which are COMPLETE on GLC & sp data, merge_complete.txt  ###
#write.table(habmerge_intersec_drop,"C:/Users/scienceintern/Documents/AndreaCB/Analysis/scratch/merge_complete_0906.txt",col.names=T,row.names=F,sep="\t")

##### 6. Create land cover Lookup table with only relevant columns ####
habmerge_intersec_drop<-read.table(file="merge_complete_0906.txt", header=TRUE)
names(habmerge_intersec_drop)
#View(habmerge_intersec_drop)

## first LUT ###
Landcover_LUT<-habmerge_intersec_drop[,c("num","binomial","GLC2000code","GLC2000description")]
View(Landcover_LUT)
#str(Landcover_LUT)

Landcover_LUT<-unique(Landcover_LUT)
#str(Landcover_LUT)

## Export Landcover Lookup table: Landcover_LUT.txt###
#write.table(Landcover_LUT,"C:/Users/scienceintern/Documents/AndreaCB/Analysis/scratch/Landcover_LUT_0609.txt",col.names=T,row.names=F,sep="\t")


##### 7. Create NEW LUT with Level2 column, to merge with dist and guild #####

habmerge_intersec_drop<-read.table(file="merge_complete_0906.txt", header=TRUE)
names(habmerge_intersec_drop)
#View(habmerge_intersec_drop)

## first LUT ###
LUT_new<-habmerge_intersec_drop[,c("num","binomial","Level2","GLC2000code","GLC2000description")]
#View(LUT_new)
#str(LUT_new)

LUT_new<-unique(LUT_new)
#str(LUT_new)

## Export Landcover Lookup table: LUT_new.txt###
#write.table(LUT_new,"C:/Users/scienceintern/Documents/AndreaCB/Analysis/scratch/LUT_new_0609.txt",col.names=T,row.names=F,sep="\t")


###################
###################

##### EXTRAS####
################

# #### View data excluded above: entries with missing data from GLC ####
# 
# ### 365 rows where IUCN description is missing
# ### habmissing : rows with species*habitat data, which do NOT match with GLC habitat crosswalk ##
# ## output: MissingGLC_habitat.txt#
# 
# habmissing<-subset(habmerge, is.na(habmerge$IUCN_middle_level_code))
# View(habmissing)
# str(habmissing)
# 
# 
# habmissing_dropped<-droplevels(habmissing)
# View(habmissing_dropped)
# str(habmissing_dropped)
# 
# ## Export table: GLC & Hab merge which DO NOT have glc data, MissingGLC_habitat.txt ###
# write.table(habmissing_dropped,"C:/Users/scienceintern/Documents/AndreaCB/Analysis/scratch/MissingGLC_habitat_0608.txt",col.names=T,row.names=F,sep="\t")
# 
# levels(habmissing_dropped$Level2) # habitats Level2 missing GLC data
# 
# #[1] "Artificial/Aquatic_-_Canals_and_Drainage_Channels,_Ditches" "Artificial/Aquatic_-_Excavations_(open)"                   
# #[3] "Artificial/Aquatic_-_Ponds_(below_8ha)"                     "Artificial/Aquatic_-_Salt_Exploitation_Sites"              
# #[5] "Artificial/Terrestrial_-_Rural_Gardens"                     "Marine_Coastal/Supratidal_-_Coastal_Freshwater_Lakes"      
# #[7] "Marine_Intertidal_-_Tidepools"                             
# 
# ## unique: remove duplicates
# 
# habmissing_unique<-unique(habmissing$Level2)
# View(habmissing_unique)
# 
# which(habmissing$Level2=="Rocky_areas_(eg._inland_cliffs,_mountain_peaks)")

##########


