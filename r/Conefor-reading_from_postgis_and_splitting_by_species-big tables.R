
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

###cleaning memory
rm(list=ls()) #will remove ALL objects
ls()


#STEP 1: linking to postgresql/postgis database####

##load driver
drv <- dbDriver("PostgreSQL")
con <- dbConnect(drv, host='localhost', port='5432', dbname='biodiv_processing', user='postgres', password='Seltaeb1') ##assign connection info
dbListTables(con) #look at tables in database

#STEP 2: Setting workspace####
#choose appropriate if time period t0 or time period t1
setwd("C:/Data/cci_connectivity/scratch/conefor_runs/inputs/t0") ##set working directory for outputs to be sent to
setwd("C:/Data/cci_connectivity/scratch/conefor_runs/inputs/t1") ##set working directory for outputs to be sent to

getwd()#view directory

#STEP 3: species info####
#getting anciliary data on species (optional) 
sp_status<-read.csv("C:/Data/cci_connectivity/raw/species/spp_name_id_category_joined.csv") #getting IUCN Red List category based on metadata for species
str(sp_status)#check it worked

#STEP 4a: getting list of species to run - includes optional filtering to see if nodes are impacted by development  #######

#this optional filtering selects all species with nodes touching the area affected (using the "where impacted = 1" clause)
#Note that links could be impacted too if overlap development so may want to run all by using /* and */ either side of the "where impacted = 1" clause 
#Note: can choose specific runs for different corridors by choosing the id number from the development (e.g. fid_corrid number) - for these see development file
strSQL="(
select distinct foo1.id_no1, foo1.season, foo1.count from 
  (select id_no, id_no1, season::int, count (distinct (node_id)) 
  from  cci_2015.int_grid_pas_trees_40postcent_30agg_by_nodeids_t1 group by id_no, id_no1,season order by count desc) 
  as foo1,
  (select distinct id_no1, season from cci_2015.int_grid_pas_trees_40postcent_30agg_by_nodeids_t1 
  /*where impacted =-1 and not impacted = 1*/ /* and fid_corrid=6*/) 
  as foo2
where 
foo1.count>1
and foo1.id_no1=foo2.id_no1 
and foo1.season = foo2.season::int
order by count desc
)" 

spList<- dbSendQuery(con, strSQL)   ## Submits a sql statement

spList<-fetch(spList,n=-1) ##place data in dataframe

head(spList)#view results
str(spList)


# (optional) STEP 4b : subsetting further if needed ####

#add in status
spList<-merge(spList,sp_status,by.x="id_no1",by.y="id_no",all.x=TRUE)
head(spList)
str(spList)

spList <- spList[order(-spList$count),] 
str(spList)

#select those that are threatened (i.e. not Least Concern)
spList.sub<-subset(spList,spList$category!="LC")

#save least concern species list (for metadata purposes)
spList.sub.excl.status<-subset(spList,spList$category=="LC")
head(spList.sub.excl.status)
#copy list of threatened speceis excluded by status to csv
write.csv(spList.sub.excl.status,"excluded_species_least_concern.csv",row.names=F)


#select from those under 10000 nodes
#node threshold 
node_threshold<-50
spList.sub.incl<-subset(spList.sub,spList.sub$count<=node_threshold)
spList.sub.excl.nodes<-subset(spList.sub,spList.sub$count>node_threshold)

#copy list of threatened species excluded by node threshold to csv (for metadata purposes)
write.csv(spList.sub.excl.nodes,"excluded_species_threshold.csv",row.names=F)


#copy list of included species
write.csv(spList.sub.incl,paste0("included_species_crenvunt_",node_threshold,".csv"),row.names=F)

spList.sub.incl<-droplevels(spList.sub.incl)
str(spList.sub.incl)

unique(spList.sub.incl$id_no1)

#run following line only if want to use subset for main analysis
spList<-spList.sub.incl

# (optional) STEP 4c : listing species not impacted in t1 and make a list of them (for metadata) ####
#create a table of which species aren't impacted by development and write to a csv (N.B. for this analysis each id_no1 and season combination is treated as if were a different species, thus allowing distinction betweeen connectivity in breeding and non-breeding areas)
#the csv output could be used as a basis for selecting output files from t0 that don't need to be rerun in conefor as they would be the same. Also useful for reporting metadata)

#create a string to send to query postgresql database
#this one 
strSQL.no_touch="(
select distinct foo1.id_no1, foo1.season, foo1.count 
from 
(
select id_no, id_no1, season::int, count (distinct (node_id)) 
from  
cci_2015.int_grid_pas_trees_40postcent_30agg_by_nodeids_t1 
group by id_no, id_no1,season order by count desc
) 
as foo1,
(
(select distinct foo1.id_no1, foo1.season 
from 
(select distinct id_no1, season from cci_2015.int_grid_pas_trees_40postcent_30agg_by_nodeids_t1) 
as foo1
left join 
(select distinct id_no1, season from cci_2015.int_grid_pas_trees_40postcent_30agg_by_nodeids_t1 where impacted = 1) 
as foo2
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

spList.no_touch<- dbSendQuery(con, strSQL.no_touch)   ## Submits a sql statement

spList.no_touch<-fetch(spList.no_touch,n=-1)##place data in dataframe

View(spList.no_touch)
str(spList.no_touch)

#join to status from IUCN Red List
spList.no_touch<-merge(spList.no_touch,sp_status,by.x="id_no1",by.y="id_no",all.x=TRUE)
head(spList.no_touch)
str(spList.no_touch)

spList.no_touch <- spList.no_touch[order(-spList.no_touch$count),] 
str(spList.no_touch)

write.csv(spList, "t0_not_impacted.csv",row.names=F)

###########################################
#STEP 5: loop through species in the list (the spList object) and for each one

#set development id 
#code for which nodes to include using dev_id. 
#KEY:
#t0: dev_id=-1 would mean all nodes (or parts of nodes) are removed from development - a scenario where all corridors are built at some time.
#t1: dev_id<>0 means no nodes (or parts of nodes) are removed from development (don't use the alternative distance files)

#(optional)#t1 s1 -if one specific corridor is to be removed add corridor id to fid+corrid and set "dev_id<>fid_corrid"
#fid_corrid="" #this would be a scenario (s1) where only a single developement (i.e., with fid_corrid=5) will be removed and adj distances calculated just for this section 
#to add to corridor /*where fid_corrid=",fid_corrid,"*/

#set dev_id based on above key
dev_id=-1

start_num=101 # normally start at 1 but can start later. Later in list has less nodes to run.

for (i in start_num:length(spList$id_no)){
  gc()#garbage collection in casememory fills up
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
  (select area, wdpa, the_geom_azim_eq_dist as the_geom, id_no1, season::int, node_id, grid_id from int_grid_pas_trees_40postcent_30agg_by_nodeids_t1 where id_no1 =",id_no1," and season::int = ",season," and fid_corrid=",dev_id,")
  as a,
  (select area, wdpa, the_geom_azim_eq_dist as the_geom, id_no1, season::int, node_id, grid_id from int_grid_pas_trees_40postcent_30agg_by_nodeids_t1 where id_no1 =",id_no1," and season::int = ",season," and fid_corrid=",dev_id,")  
   as  b,
  (select taxon_id as id_no, final_value_to_use as mean_dist, (final_value_to_use*8*1000) as cutoff_dist from dispersal_data where taxon_id =", id_no1,") 
  as c
  , 
  (select the_geom_azim_eq_dist as the_geom, NAME, status from corridors_type_3_buff_agg) 
  as e
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
  #clause so if only one nodes then no distances calculations are attampeted.
 if (length(x[1,])==0){
   print(paste0("error - no nodes to write outside of max distance threshold for species id_no:","id_no1","and season",season)
  }  else { # create node file from distances file
    
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

