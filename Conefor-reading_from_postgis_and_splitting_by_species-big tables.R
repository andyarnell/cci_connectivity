
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
setwd("C:/Data/cci_connectivity/scratch/conefor_runs/inputs/t0")

getwd()



#################################################################
#status based on metadata for species
sp_status<-read.csv("C:/Data/cci_connectivity/raw/species/spp_name_id_category_joined.csv")

str(sp_status)


###################
#find table of which species (or at least id_no1 and season combinations) aren't impacted by development and write to a csv 
##(this list is useful for metadata or basis for selecting output files from t0 that don't need to be rerun)

#spList<-list(spList$id_no1)
strSQL="(
  select distinct foo1.id_no1, foo1.season, foo1.count from 
  (
    select id_no, id_no1, season::int, count (distinct (node_id)
    ) 
    from  
    cci_2015.int_grid_pas_trees_40postcent_30agg_by_nodeids_t1 
    group by id_no, id_no1,season order by count desc
  ) 
  as foo1,
  (
    (select distinct foo1.id_no1, foo1.season from 
     (select distinct id_no1, season from cci_2015.int_grid_pas_trees_40postcent_30agg_by_nodeids_t1) as foo1
     left join 
     (select distinct id_no1, season from cci_2015.int_grid_pas_trees_40postcent_30agg_by_nodeids_t1 
      where impacted = 1
      ) as foo2
     on foo1.id_no1 = foo2.id_no1
     and foo1.season = foo2.season 
     where foo2.id_no1 is null)
  ) 
  as foo2
  where 
  foo1.count>1
  and foo1.id_no1=foo2.id_no1 
  and foo1.season = foo2.season::int
  order by count desc
)"


spList<- dbSendQuery(con, strSQL)   ## Submits a sql statement
##place data in dataframe
spList<-fetch(spList,n=-1)

View(spList)
str(spList)

#join to status from IUCN Red List
spList<-merge(spList,sp_status,by.x="id_no1",by.y="id_no",all.x=TRUE)
head(spList)
str(spList)

spList <- spList[order(-spList$count),] 
str(spList)

write.csv(spList, "t0_not_impacted.csv",row.names=F)


########################


#selecting species with some nodes in the area (using the where impacted clause)
# using =1 is for species that have nodes impacted by development (either touching or overlapping)
# use /* and */ either side of this where clause to choose all species - there is no need to rerun these as they will be the same as t0, so if needed copy the outputs from t0 run.
#can choose specific runs for different corridors by choosing the id number from the development (e.g. fid_corrid number) - for these see development file
#or make use >0 to get those that don't intersect the corridor
strSQL="(
select distinct foo1.id_no1, foo1.season, foo1.count from 
(
select id_no, id_no1, season::int, count (distinct (node_id)
) 
from  
cci_2015.int_grid_pas_trees_40postcent_30agg_by_nodeids_t1 
group by id_no, id_no1,season order by count desc
) 
as foo1,
(
select distinct id_no1, season from cci_2015.int_grid_pas_trees_40postcent_30agg_by_nodeids_t1 
/*where impacted =-1 and not impacted = 1*/
/* and fid_corrid=6*/
) 
as foo2
where 
foo1.count>1
and foo1.id_no1=foo2.id_no1 
and foo1.season = foo2.season::int
order by count desc
)" 

spList<- dbSendQuery(con, strSQL)   ## Submits a sql statement
##place data in dataframe
spList<-fetch(spList,n=-1)

View(spList)
str(spList)



####################


#########################################
 




##################################################################
###subsetting if needed

# #select those that are threatened (i.e. not Least Concern)
# spList.sub<-subset(spList,spList$category!="LC")
# spList.sub.excl.status<-subset(spList,spList$category=="LC")
# #copy list of threatened speceis excluded by status to csv
# write.csv(spList.sub.excl.status,"excluded_species_least_concern.csv",row.names=F)
# 
# head(spList.sub)
# 
# #select from those under 10000 nodes
# #node threshold 
# node_threshold<-8000
# spList.sub.incl<-subset(spList.sub,spList.sub$count<=node_threshold)
# spList.sub.excl.nodes<-subset(spList.sub,spList.sub$count>node_threshold)
# #copy list of threatened speceis excluded by node threshold to csv
# write.csv(spList.sub.excl.nodes,"excluded_species_threshold.csv",row.names=F)
# 
# #copy list of included species
# write.csv(spList.sub.incl,paste0("included_species_crenvunt_",node_threshold,".csv"),row.names=F)
# 
# spList.sub<-droplevels(spList.sub)
# str(spList.sub)
# 
# unique(spList.sub$id_no1)
# 
# spList<-spList.sub


###########################################

for (i in 101:length(spList$id_no)){
  gc()
  id_no1<-spList$id_no1[i]
  season<-spList$season[i]
  print (id_no1)
  print (season)
  print(spList$count[i])
  print (i)
  strSQL=paste0(
  "SET search_path=cci_2015,public,topology;
  select 
  a.area as from_area,
  b.area as to_area,
  a.wdpa as from_wdpa,
  b.wdpa as to_wdpa,
  a.node_id AS from_node_id, 
  b.node_id AS to_node_id,
  a.grid_id as from_grid_id,
  b.grid_id as to_grid_id,
  a.id_no1,
  a.season
  ,st_distance(a.the_geom,b.the_geom) AS distance,
  case when (st_intersects((ST_ShortestLine(a.the_geom,b.the_geom)), e.the_geom))
  then st_distance(a.the_geom,b.the_geom)- ST_Length(ST_Intersection((ST_ShortestLine(a.the_geom,b.the_geom)), e.the_geom))
  else 0
  end   as dist_over_barrier
  from
  (select area, wdpa, the_geom_azim_eq_dist as the_geom, id_no1, season::int, node_id, grid_id from int_grid_pas_trees_40postcent_30agg_by_nodeids_t1 where id_no1 =",id_no1," and season::int = ",season," and fid_corrid=-1)
  as a,
  (select area, wdpa, the_geom_azim_eq_dist as the_geom, id_no1, season::int, node_id, grid_id from int_grid_pas_trees_40postcent_30agg_by_nodeids_t1 where id_no1 =",id_no1," and season::int = ",season,"  and fid_corrid=-1)  
   as  b,
  (select taxon_id as id_no, final_value_to_use as mean_dist, (final_value_to_use*8*1000) as cutoff_dist from dispersal_data where taxon_id =", id_no1,") 
  as c
  , 
  (select the_geom_azim_eq_dist as the_geom, NAME, status from corridors_type_3_buff_agg) as e
  where
  a.node_id > b.node_id
  and st_distance(a.the_geom,b.the_geom)<c.cutoff_dist
  and c.id_no=a.id_no1;")
  strSQL=gsub("\n", "", strSQL)
  print(strSQL)
  distances<- dbSendQuery(con, strSQL)   ## Submits a sql statement
  ##place data in dataframe
  distances<-fetch(distances,n=-1)
  names(distances)
  head(distances)
  
  #from pgis
  x<-unique(distances)
  if (length(x[1,])==0){
    print("error - no links to write as outside of max distance threshold")
  }  else {
    write.table(x[, c("from_node_id", "to_node_id", "distance")], file = paste0("distances_",x$id_no1[1],"_",x$season[1],".txt"), sep = "\t", col.names = FALSE, row.names = FALSE, quote=F) 
    write.table(x[, c("from_node_id", "to_node_id", "distance","dist_over_barrier")], file = paste0("distances_adj_",x$id_no1[1],"_",x$season[1],".txt"), sep = "\t", col.names = FALSE, row.names = FALSE, quote=F) 
  }
  
 if (length(x[1,])==0){
   print("error - no nodes to write outside of max distance threshold")
  }  else {
    
    print (dbListResults(con)[[1]])
    strSQL=paste0("SET search_path=cci_2015,public,topology; 
    (select node_id, area, wdpa from int_grid_pas_trees_40postcent_30agg_by_nodeids_t1 where id_no1 =",id_no1," and season::int = ",season,")" )
    strSQL=gsub("\n", "", strSQL)
    #print(strSQL)
    nodes<- dbSendQuery(con, strSQL)   ## Submits a sql statement
    nodes<-fetch(nodes,n=-1)
    write.table(nodes[, c("node_id", "area", "wdpa")], file = paste0("nodes_",x$id_no1[1],"_",x$season[1],".txt"), sep = "\t", col.names = FALSE, row.names = FALSE, quote=F) 
    rm(nodes)
    rm(distances)
    rm(x)
    rm(id_no1)
    rm(season)
    rm(strSQL)  
  } 
  gc()
}


# 
# postgresqlTransactionStatement <- function(con, statement) {
#   ## are there resultSets pending on con?
#   if(length(dbListResults(con)) > 0){
#     res <- dbListResults(con)[[1]]
#     if(!dbHasCompleted(res)){
#       stop("connection with pending rows, close resultSet before continuing")
#     }
#     dbClearResult(res)
#   }
#   
#   rc <- try(dbGetQuery(con, statement))
#   !inherits(rc, ErrorClass)
# }
# 
# postgresqlTransactionStatement(con,strSQL)


#write dataframe to multiple text files using d_ply and column to split dataframe

# 
# #d_ply seems similar to lappy but info says it doesn't save results - just carries out function - though I can't see difference
# d_ply(distances, "sciname", function(x)
#   write.table(x[, c("from_node_id", "to_node_id", "distance")], file = paste0("distances_",x$sciname[1],".txt")
#               , sep = "\t", col.names = FALSE, row.names = FALSE, quote=F))
# 
# nodes<-read.csv("C:/Data/cci_connectivity/scratch/nodes.csv",header=FALSE)
# 
# 
# strSQL="(select id_no1, season, count from (select id_no, id_no1, season::int, count (distinct (node_id)) 
# from cci_2015.int_grid_pas_trees_40postcent_30agg_by_nodeids_eco group by id_no, id_no1,season order by count desc) as foo where count<100 and count >10)"
# 
# ##then read by R into a spatialpolygonsdataframe (I have only managed this with wgs84 format datasets so far)
# strSQL = "SELECT foo.node_id, foo.area, foo.id_no, foo.wdpa
# FROM cci_2015.int_grid_pas_trees_40postcent_30agg_by_nodeids_eco  as foo inner join
# (select distinct id_no from cci_2015.links_grid_pas_trees_40postcent_30agg_by_id_nos_filt2) as foo2
# on foo.id_no=foo2.id_no;"
# 
# ##get data from  postgresql database
# 
# nodes<- dbSendQuery(con, strSQL)   ## Submits a sql statement
# ##place data in dataframe
# nodes<-fetch(nodes,n=-1)
# 
# str(nodes)
# head(nodes)
# #from pgis
# names(nodes)<-c("gid","sitarea","sciname","remove")
# #from csv
# names(nodes)<-c("sciname","gid","sitarea","remove")
# 
# ##fixing error from postgis for notetypes option
# x=nodes$remove
# nodes$remove=replace(x, x==0, -1)
# 
# #write dataframe to multiple text files using d_ply and column to split dataframe
# #d_ply seems similar to lapply but info says it doesn't save results - just carries out function - though I can't see difference
# d_ply(nodes, "sciname", function(x)
#   write.table(x[, c("gid", "sitarea","remove")], file = paste0("nodes_",x$sciname[1],".txt")
#               , sep = "\t", col.names = FALSE, row.names = FALSE, quote=F))
# 
