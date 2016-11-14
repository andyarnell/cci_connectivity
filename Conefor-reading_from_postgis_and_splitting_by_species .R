
#remove ~ from below if not installed 
#install.packages("RPostgreSQL")
#install.packages("rgeos")
#install.packages("plyr")
#install.packages("anchors")
#loading packages
library(sp)
library(rgeos)
library(rgdal)
library(plyr)
library(RPostgreSQL)
library(anchors)
rm(list=ls()) #will remove ALL objects
ls()

##load driver
drv <- dbDriver("PostgreSQL")
##assign connection info
con <- dbConnect(drv, host='localhost', port='5432', dbname='biodiv_processing',
                 user='postgres', password='Seltaeb1')

##look at tables in database
dbListTables(con)



##set working directory for outputs to be sent to
setwd("C:/Data/cci_connectivity/scratch/conefor_runs/inputs")
getwd()




# Create SQL statement. Change to get the columns and state you want.
##getting non-spatial data is easy. 
##From what I can tell spatial data, however, requires the geometry column 
##to be converted into well known text format (ST_AsText)
##then read by R into a spatialpolygonsdataframe (I have only managed this with wgs84 format datasets so far)
strSQL = "SELECT from_node_id, to_node_id, id_no, distance 
FROM cci_2015.links_grid_pas_trees_40postcent_30agg_by_id_nos_filt2;"


##get data from  postgresql database
distances<-read.csv("C:/Data/cci_connectivity/scratch/links.csv",header=TRUE)

distances<- dbSendQuery(con, strSQL)   ## Submits a sql statement
##place data in dataframe
distances<-fetch(distances,n=-1)
str(distances)
head(distances)

names(distances)
#from pgis
names(distances)<-c("from_node_id","to_node_id","sciname","distance")
#from csv
names(distances)<-c("sciname","to_node_id","from_node_id","distance")


length(unique(distances$sciname))

#write dataframe to multiple text files using lapply and column to split dataframe

#lapply(split(distances, distances$sciname), 
 #             function(x)write.table(x[, c("from_node_id", "to_node_id", "distance")], file = paste("distances",x$sciname[1],".txt")
  #                                   , sep = "\t", col.names = FALSE, row.names = FALSE, quote=F))

#write dataframe to multiple text files using d_ply and column to split dataframe
#d_ply seems similar to lappy but info says it doesn't save results - just carries out function - though I can't see difference
d_ply(distances, "sciname", function(x)
  write.table(x[, c("from_node_id", "to_node_id", "distance")], file = paste0("distances_",x$sciname[1],".txt")
              , sep = "\t", col.names = FALSE, row.names = FALSE, quote=F))

nodes<-read.csv("C:/Data/cci_connectivity/scratch/nodes.csv",header=FALSE)

##then read by R into a spatialpolygonsdataframe (I have only managed this with wgs84 format datasets so far)
strSQL = "SELECT foo.node_id, foo.area, foo.id_no, foo.wdpa
FROM cci_2015.int_grid_pas_trees_40postcent_30agg_by_nodeids as foo inner join
(select distinct id_no from cci_2015.links_grid_pas_trees_40postcent_30agg_by_id_nos_filt2) as foo2
on foo.id_no=foo2.id_no;"

##get data from  postgresql database

nodes<- dbSendQuery(con, strSQL)   ## Submits a sql statement
##place data in dataframe
nodes<-fetch(nodes,n=-1)

str(nodes)
head(nodes)
#from pgis
names(nodes)<-c("gid","sitarea","sciname","remove")
#from csv
names(nodes)<-c("sciname","gid","sitarea","remove")

##fixing error from postgis for notetypes option
x=nodes$remove
nodes$remove=replace(x, x==0, -1)

#write dataframe to multiple text files using d_ply and column to split dataframe
#d_ply seems similar to lapply but info says it doesn't save results - just carries out function - though I can't see difference
d_ply(nodes, "sciname", function(x)
  write.table(x[, c("gid", "sitarea","remove")], file = paste0("nodes_",x$sciname[1],".txt")
              , sep = "\t", col.names = FALSE, row.names = FALSE, quote=F))

