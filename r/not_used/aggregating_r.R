library(sp)
library(rgeos)
library(rgdal)
library(plyr)
library(RPostgreSQL)
library(anchors)
rm(list=ls()) #will remove ALL objects
ls()
#############################
##load driver
drv <- dbDriver("PostgreSQL")
##assign connection info
con <- dbConnect(drv, host='localhost', port='5432', dbname='biodiv_processing',
                 user='postgres', password='Seltaeb1')

##look at tables in database
dbListTables(con)



##set working directory for outputs to be sent to
setwd("C:/Data/cci_connectivity/scratch/conefor_runs/inputs/old")

getwd()
##############################

strSQL="(select taxon_id, final_value_to_use from cci_2015.dispersal_data)"
disp<- dbSendQuery(con, strSQL)   ## Submits a sql statement
##place data in dataframe
disp<-fetch(disp,n=-1)

head(disp)
str(disp)


spList.disp<-merge(spList,disp, by.x="id_no1",by.y="taxon_id",all.x=TRUE)
head(spList.disp)


spList.disp$thresh_90pc<-spList.disp$final_value_to_use*0.1053607
spList.disp$thresh_95pc<-spList.disp$final_value_to_use*0.05129337

##########################################################

#trialling aggreagtion - unfinished

dst<-read.table("distances_22698676_1.txt",header = FALSE)
head(dst)
str(dst)
names(dst)<-c("from_node_id","to_node_id","distance")

nde<-read.table("nodes_22698676_1.txt")
head(nde)
names(nde)<-c("node_id","area","wdpa")

dst.areas<-merge(dst,nde,by.x="from_node_id",by.y="node_id",all.x=TRUE)
str(dst.areas)
dst.areas$wdpa<-NULL
names(dst.areas)[4]<-"from_node_area"
dst.areas<-merge(dst.areas,nde,by.x="to_node_id",by.y="node_id",all.x=TRUE)
str(dst.areas)
dst.areas$wdpa<-NULL
names(dst.areas)[5]<-"to_node_area"
str(dst.areas)

dst.areas.s1<-subset(dst.areas,dst.areas$from_node_area<=1 & dst.areas$from_node_area<=1 & dst.areas$distance<1000)

str(dst.areas.s1)

dst.areas.s1$new_from_node<-dst.areas.s1$to_node_id

dst.areas.s2<-subset(dst.areas,dst.areas$from_node_area<=10 & dst.areas$from_node_area<=1 & dst.areas$distance<1000)

dst.areas.s3<-subset(dst.areas,dst.areas$from_node_area<=1 & dst.areas$from_node_area<=10 & dst.areas$distance<1000)
head(dst.areas.s3)

dst.areas.s3[,2][which(dst.areas.s3$from_node_area<=1,dst.areas.s3$from_node_area<=10,dst.areas.s3$distance<1000)] <- dst.areas.s3$to_node_id

head(dst.areas.s3)
