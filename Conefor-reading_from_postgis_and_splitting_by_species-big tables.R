
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

# 
# # Create SQL statement. Change to get the columns and state you want.
# ##getting non-spatial data is easy. 
# ##From what I can tell spatial data, however, requires the geometry column 
# ##to be converted into well known text format (ST_AsText)
# ##then read by R into a spatialpolygonsdataframe (I have only managed this with wgs84 format datasets so far)
# strSQL = "SELECT from_node_id, to_node_id, id_no, distance 
# FROM cci.links_grid_pas_trees_40postcent_30agg_sbset1;"
# 
# 
# ##get data from  postgresql database
# distances<-read.csv("C:/Data/cci_connectivity/scratch/links.csv",header=TRUE)
# 
# distances<- dbSendQuery(con, strSQL)   ## Submits a sql statement
# ##place data in dataframe
# distances<-fetch(distances,n=-1)
# str(distances)
# head(distances)
# 
# names(distances)
# #from pgis
# names(distances)<-c("from_node_id","to_node_id","sciname","distance")
# 
# #from csv
# names(distances)<-c("sciname","to_node_id","from_node_id","distance")
# 
# 
# length(unique(distances$sciname))

#write dataframe to multiple text files using lapply and column to split dataframe

#lapply(split(distances, distances$sciname), 
 #             function(x)write.table(x[, c("from_node_id", "to_node_id", "distance")], file = paste("distances",x$sciname[1],".txt")
  #                                   , sep = "\t", col.names = FALSE, row.names = FALSE, quote=F))
#######################################################################################################
##then read by R into a spatialpolygonsdataframe (I have only managed this with wgs84 format datasets so far)
strSQL = "SELECT foo.node_id, foo.area, foo.id_no, foo.wdpa
FROM cci_2015.int_grid_pas_trees_40postcent_30agg_by_nodeids as foo;"

##get data from  postgresql database

nodes<- dbSendQuery(con, strSQL)   ## Submits a sql statement
##place data in dataframe
nodes<-fetch(nodes,n=-1)

str(nodes)
head(nodes)
#from pgis
names(nodes)<-c("gid","sitarea","sciname","remove")
#from csv
#names(nodes)<-c("sciname","gid","sitarea","remove")

##fixing error from postgis for notetypes option
#x=nodes$remove
#nodes$remove=replace(x, x==0, -1)

spList<-unique(nodes$sciname)

#################################################################

strSQL="(select id_no1, season, count from (select id_no, id_no1, season::int, count (distinct (node_id)) 
from cci_2015.int_grid_pas_trees_40postcent_30agg_by_nodeids group by id_no, id_no1,season order by count desc) as foo where count<100 and count >10)"
spList<- dbSendQuery(con, strSQL)   ## Submits a sql statement
##place data in dataframe
spList<-fetch(spList,n=-1)

head(spList)
str(spList)
#spList<-list(spList$id_no1)
spList

for (i in 1:length(spList$id_no1)){
  id_no1<-spList$id_no1[i]
  season<-spList$season[i]
  print (id_no1)}
  print (spList$count[i])


for (i in 1:length(spList$id_no)){
  id_no1<-spList$id_no1[i]
  season<-spList$season[i]
  print (id_no1)
  print (season)
  print(count[i])
  
  strSQL=
  paste0("SET search_path=cci_2015,public,topology;
  select 
  a.node_id AS from_node_id, 
  b.node_id AS to_node_id,
  a.grid_id as from_grid_id,
  b.grid_id as to_grid_id,
  a.id_no1,
  a.season,
  /*st_shortestline(a.the_geom,b.the_geom) as the_geom,
  st_buffer(st_transform(st_shortestline(a.the_geom,b.the_geom),54032),(st_distance(a.the_geom,b.the_geom)/5)) AS the_geombff*/
  st_distance(a.the_geom,b.the_geom) AS distance
  from
  (select the_geom_azim_eq_dist as the_geom, id_no1, id_no, season::int, node_id, grid_id from int_grid_pas_trees_40postcent_30agg_by_nodeids where id_no1 =",id_no1," and season::int = ",season,")
  as a,
  (select the_geom_azim_eq_dist as the_geom, id_no1, id_no, season::int, node_id, grid_id from int_grid_pas_trees_40postcent_30agg_by_nodeids where id_no1 =",id_no1," and season::int = ",season,")  
   as  b,
  (select taxon_id as id_no, final_value_to_use as mean_dist, (final_value_to_use*10*1000) as cutoff_dist from dispersal_data) 
  as c
  where
  a.node_id > b.node_id
  and st_distance(a.the_geom,b.the_geom)<c.cutoff_dist
  group by  
  from_node_id, 
  to_node_id, 
  a.id_no1, 
  a.season, 
  from_grid_id, 
  to_grid_id 
  ,a.the_geom, 
  b.the_geom;")
  strSQL=gsub("\n", "", strSQL)
  print(strSQL)
  distances<- dbSendQuery(con, strSQL)   ## Submits a sql statement
  ##place data in dataframe
  distances<-fetch(distances,n=-1)
  names(distances)
  head(distances)
  #from pgis
  x<-distances
  write.table(x[, c("from_node_id", "to_node_id", "distance")], file = paste0("distances_",x$id_no[1],"_",x$season[1],".txt"), sep = "\t", col.names = FALSE, row.names = FALSE, quote=F) 

}



#write dataframe to multiple text files using d_ply and column to split dataframe

# 
# #d_ply seems similar to lappy but info says it doesn't save results - just carries out function - though I can't see difference
# d_ply(distances, "sciname", function(x)
#   write.table(x[, c("from_node_id", "to_node_id", "distance")], file = paste0("distances_",x$sciname[1],".txt")
#               , sep = "\t", col.names = FALSE, row.names = FALSE, quote=F))

nodes<-read.csv("C:/Data/cci_connectivity/scratch/nodes.csv",header=FALSE)


strSQL="(select id_no1, season, count from (select id_no, id_no1, season::int, count (distinct (node_id)) 
from cci_2015.int_grid_pas_trees_40postcent_30agg_by_nodeids group by id_no, id_no1,season order by count desc) as foo where count<100 and count >10)"

##then read by R into a spatialpolygonsdataframe (I have only managed this with wgs84 format datasets so far)
strSQL = "SELECT foo.node_id, foo.area, foo.id_no, foo.wdpa
FROM cci_2015.int_grid_pas_trees_40postcent_30agg_by_nodeids  as foo inner join
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

