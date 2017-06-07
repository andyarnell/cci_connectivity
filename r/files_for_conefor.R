
#################################################################################
##### POSTGRES SCRIPTS FOR CLEANING TABLES AND CREATING CONEFOR INPUT FILES #####
#################################################################################

#packages
library(sp)
library(rgeos)
library(rgdal)
library(plyr)
library(RPostgreSQL)
library(anchors)
library(foreign)

###cleaning memory
rm(list=ls()) #will remove ALL objects
ls()

###main directory
mainDir<- "C:/Data/cci_connectivity/scratch/conefor_runs/inputs/by_species/ecoregions"
setwd(mainDir)

#STEP 1: linking to postgresql/postgis database####

#names for input columns
node_id_field<-"nodiddiss4"
gridcell_id_field<-"fid_fnet_2"

#name of imported species table
sp_merged_all<-"sp_merged_c1200_alt_clip"
#making name of new clean species table 
sp_merged_all_clean<-paste0(sp_merged_all,"_clean")

##load driver
drv <- dbDriver("PostgreSQL")
con <- dbConnect(drv, host='localhost', port='5432', dbname='biodiv_processing', user='postgres', password='Seltaeb1') ##assign connection info
dbListTables(con) #look at tables in database


#STEP 2: species info####
#getting anciliary data on species (optional) 
sp_status<-read.csv("C:/Data/cci_connectivity/raw/species/spp_name_id_category_joined.csv") #getting IUCN Red List category based on metadata for species
str(sp_status)#check it worked


#get dispersal distances from csv
Dist<- read.csv("C:/Data/cci_connectivity/scratch/dispersal/dispersal_estimates.csv", h=T)
Dist<- Dist[,c(5,20)]
colnames(Dist) [1]<- "id_no"
colnames(Dist) [2]<- "Disp_mean"
Dist


#STEP 3: 

##removed the inporting csv code here and used the raw input file from postgres instead - although the dbf of the shapefile would work too.
strSQL<-paste0("SET search_path=cci_2017,cci_2015,public,topology;
select eco_id::bigint, count (eco_name), eco_name as raw_eco_name from grid_pas_trees_40postcent_30agg_diss_ovr1ha_t1 group by eco_name,eco_id")

eco<-dbGetQuery(con,strSQL)
eco$eco_id<-as.integer(eco$eco_id)
str(eco)

eco$eco_name<- (sapply(eco$raw_eco_name, function(x) chartr( " ,-","___", x)))
write.csv(eco,"C:/Data/cci_connectivity/scratch/eco_nodecount.csv",row.names=F, quote = FALSE)


#select those in west africa using a list
Wafrica<- c("Eastern_Guinean_forests", "West_Sudanian_savanna", "Guinean_forest_savanna_mosaic", 
            "Western_Guinean_lowland_forests", "Jos_Plateau_forest_grassland_mosaic", "Guinean_mangroves",
            "Central_African_mangroves", "Guinean_montane_forests", "Lake_Chad_flooded_savanna", 
            "Cross_Sanaga_Bioko_coastal_forests", "Cross_Niger_transition_forests", "Niger_Delta_swamp_forests") 
1:length(Wafrica)
#Wafrica$Wafrica<-(sapply(Wafrica$Wafrica, function(x) chartr( " ,-","___", x)))
Wafrica<-data.frame(Wafrica)
a<-merge(eco,Wafrica,by.x="eco_name",by.y="Wafrica")
#missing lake cahd but no forest i think so no join

a

#a<- data.frame(eco_name= c("Ethiopian_montane_moorlands", "Eastern_Arc_forests"), eco_id= c(31008,30109))
#a<-eco


strSQL<- paste0(
  "--AIM: Make species EOO,ESH and range-rarity (national) maps based on a grid covering the area of interest (aoi) This has been used for landshift results for africa paper with kassel University
  
  ---set path for sql processing to act on tables in a specific schema within the database (normally defaults to public otherwise)
  --more than one can be listed using commas
  --in this case it will add new tables to the first schema (e.g. a newly created schema)  in the list 
  --but still have access to tables and most importantly functions in the public schema
  
  
  
  SET search_path=cci_2017,cci_2015,public,topology;
  
  --find/display current path for sql processing 
  SHOW search_path;
  
  
  --if postgis/postgresql running locally on desktop increase access to memory (RAM) 
  SET work_mem TO 120000;
  SET maintenance_work_mem TO 120000;
  SET client_min_messages TO DEBUG;
  
  --find/display current path for sql processing 
  SHOW search_path;
  
  
  drop table if exists grid_pas_trees_40postcent_30agg_diss_ovr1ha_t1_clean;
  create table grid_pas_trees_40postcent_30agg_diss_ovr1ha_t1_clean as
  (select st_makevalid(st_buffer(the_geom,0)) as the_geom, ", node_id_field,"::int as node_id, ",gridcell_id_field," as grid_id, eco_id::int as ecoregion, area_geo as area, fid_pas_in as wdpa, fid_corrid::int as fid_corrid
  from grid_pas_trees_40postcent_30agg_diss_ovr1ha_t1 offset 0);
  
  
  --select ((eco_num::int)::varchar||nodeiddiss::varchar)::int as node_id from grid_pas_trees_40postcent_30agg_diss_ovr1ha_ecoregions limit 1000;
  
  drop index if exists grid_pas_trees_40postcent_30agg_diss_ovr1ha_t1_clean_geom_gist;
  CREATE INDEX grid_pas_trees_40postcent_30agg_diss_ovr1ha_t1_clean_geom_gist ON grid_pas_trees_40postcent_30agg_diss_ovr1ha_t1_clean USING GIST (the_geom);
  CLUSTER grid_pas_trees_40postcent_30agg_diss_ovr1ha_t1_clean USING grid_pas_trees_40postcent_30agg_diss_ovr1ha_t1_clean_geom_gist;
  ANALYZE grid_pas_trees_40postcent_30agg_diss_ovr1ha_t1_clean;
  
  create index grid_pas_trees_40postcent_30agg_diss_ovr1ha_t1_clean_index_ecoregion on grid_pas_trees_40postcent_30agg_diss_ovr1ha_t1_clean (ecoregion);
  --add in equidistant column (quicker for next steps)
  alter table grid_pas_trees_40postcent_30agg_diss_ovr1ha_t1_clean
  add column 
  the_geom_azim_eq_dist geometry(Geometry,54032);
  
  --#populate it from transforming previous one
    UPDATE grid_pas_trees_40postcent_30agg_diss_ovr1ha_t1_clean SET the_geom_azim_eq_dist = ST_Transform(the_geom, 54032)
  FROM spatial_ref_sys WHERE ST_SRID(the_geom) = srid;")

dbGetQuery(con, strSQL)

  
strSQL<-paste0("--Aim: make a cleaner species layer
drop table if exists ",sp_merged_all_clean,";
create table ",sp_merged_all_clean," as
select foo1.*, 
left((REPLACE(foo1.id_no, 'sp_', '')), length((REPLACE(foo1.id_no, 'sp_', ''))) - 2)::bigint as id_no1,
right(foo1.id_no,1)::int as season
from 
(select spp_id as id_no, the_geom as the_geom from ",sp_merged_all,")
as foo1;

SELECT UpdateGeometrySRID('",sp_merged_all_clean,"','the_geom',4326);

drop index if exists ",sp_merged_all_clean,"_geom_gist;
CREATE INDEX ",sp_merged_all_clean,"_geom_gist ON ",sp_merged_all_clean," USING GIST (the_geom);
CLUSTER ",sp_merged_all_clean," USING ",sp_merged_all_clean,"_geom_gist;
ANALYZE ",sp_merged_all_clean,";

create index ",sp_merged_all_clean,"_index_id_no1 on ",sp_merged_all_clean," (id_no1);
create index ",sp_merged_all_clean,"_index_season on ",sp_merged_all_clean," (season);")

dbGetQuery(con,strSQL)



for (y in 4:4){#length(a$eco_id)){
  print (a$eco_id[y])

  
  strSQL<- paste0(
    "--AIM: Make species EOO,ESH and range-rarity (national) maps based on a grid covering the area of interest (aoi) This has been used for landshift results for africa paper with kassel University
    
    ---set path for sql processing to act on tables in a specific schema within the database (normally defaults to public otherwise)
    --more than one can be listed using commas
    --in this case it will add new tables to the first schema (e.g. a newly created schema)  in the list 
    --but still have access to tables and most importantly functions in the public schema
    
    
    
    SET search_path=cci_2017,cci_2015,public,topology;
 
    --getting nodeids touching species
    drop table if exists int_grid_pas_trees_by_species_",a$eco_id[y],";
    create table int_grid_pas_trees_by_species_",a$eco_id[y]," as
    select 
    foo2.id_no,
    foo2.id_no1,
    foo2.season,
    foo1.node_id,
    foo1.grid_id,
    foo1.the_geom,
    foo1.the_geom_azim_eq_dist,
    min(foo1.area) as area,
    /*min(case when (wdpa>-1) then 1 else -1 end) as wdpa,*/
    min(foo1.fid_corrid) as fid_corrid
    from 
    (select * from grid_pas_trees_40postcent_30agg_diss_ovr1ha_t1_clean where ecoregion=", a$eco_id[y],")
    as foo1,
    /*(select id_no, st_makevalid(st_transform(st_buffer(the_geom,0),54032)) as the_geom from forest_aves_in_africa order by id_no)*/
    /*(select spp_id as id_no, the_geom  from sp_merged_all order by spp_id limit 200) */ 
    ",sp_merged_all_clean,"
    as foo2
    where
    st_intersects(foo1.the_geom,foo2.the_geom)
    group by 
    foo1.the_geom,
    foo1.node_id,
    foo2.id_no,
    foo2.id_no1,
    foo2.season,
    foo1.grid_id,
    foo1.the_geom_azim_eq_dist
    ;")
  
  
dbGetQuery(con, strSQL)
}    

for (y in 4:4){#length(a$eco_id)){
  print (a$eco_id[y])
  
  
  strSQL<- paste0(
    "--this bit took a day for all species and with whole africa
    
    drop index if exists int_grid_pas_trees_by_species_",a$eco_id[y],"_index;
    create index int_grid_pas_trees_by_species_",a$eco_id[y],"_index_id_no1 on int_grid_pas_trees_by_species_",a$eco_id[y]," (id_no1);
    create index int_grid_pas_trees_by_species_",a$eco_id[y],"_index_season on int_grid_pas_trees_by_species_",a$eco_id[y]," (season);
    create index int_grid_pas_trees_by_species_",a$eco_id[y],"_index_node_id on int_grid_pas_trees_by_species_",a$eco_id[y]," (node_id);
    create index int_grid_pas_trees_by_species_",a$eco_id[y],"_index_fid_corrid on int_grid_pas_trees_by_species_",a$eco_id[y]," (fid_corrid);
    
    
    drop index if exists  int_grid_pas_trees_by_species_",a$eco_id[y],"_the_geom_azim_eq_dist_gist;
    CREATE INDEX int_grid_pas_trees_by_species_",a$eco_id[y],"_the_geom_azim_eq_dist_gist ON int_grid_pas_trees_by_species_",a$eco_id[y]," USING GIST (the_geom_azim_eq_dist);
    CLUSTER int_grid_pas_trees_by_species_",a$eco_id[y]," USING int_grid_pas_trees_by_species_",a$eco_id[y],"_the_geom_azim_eq_dist_gist;
    ANALYZE int_grid_pas_trees_by_species_",a$eco_id[y],";
    
    /*drop index if exists int_grid_pas_trees_by_species_",a$eco_id[y],"_geom_gist;
    CREATE INDEX int_grid_pas_trees_by_species_",a$eco_id[y],"_geom_gist ON int_grid_pas_trees_by_species_",a$eco_id[y]," USING GIST (the_geom);
    CLUSTER int_grid_pas_trees_by_species_",a$eco_id[y]," USING int_grid_pas_trees_by_species_",a$eco_id[y],"_geom_gist;
    ANALYZE int_grid_pas_trees_by_species_",a$eco_id[y],";*/
    
    ")
  
  
  dbGetQuery(con, strSQL)
}
  

for (y in 4:4){#1:length(a$eco_id)){
  print (a$eco_id[y])
  
  #STEP 4: create folder and change directory  
  dir.create(file.path(mainDir,print(as.character(a$eco_name[which(a$eco_id==a$eco_id[y])]))))
  setwd(file.path(mainDir,print(as.character(a$eco_name[which(a$eco_id==a$eco_id[y])]))))
  dir.create(file.path(getwd(),"raw"))
  setwd(file.path(getwd(), "raw"))

  #STEP 5: getting list of species in study area for next steps 
  strSQL=paste0("
  select distinct foo1.id_no1, foo1.season, foo1.count from 
  (select id_no, id_no1, season::int, count (distinct (node_id)) 
  from  cci_2017.int_grid_pas_trees_by_species_",a$eco_id[y]," group by id_no, id_no1,season order by count desc) 
  as foo1,
  (select distinct id_no1, season from cci_2017.int_grid_pas_trees_by_species_",a$eco_id[y],") 
  as foo2
  where 
  foo1.count>1
  and foo1.id_no1=foo2.id_no1 
  and foo1.season = foo2.season::int
  order by count desc
  ") 

  spList<- dbGetQuery(con, strSQL)   ## Submits an sql statement
  # new species list: spList for use in next sql query
  #nrow(spList)
  print(paste0("Number of species-season combinations in ecoregion (",a$eco_name[which(a$eco_id==a$eco_id[y])], "): ",nrow(spList)  ))
  
  #copy metadata to ecoregion csv - note some species may not have output files - as not enough nodes (>1) within max dispersal 
  spList_meta<-merge(spList,Dist,by.x="id_no1",by.y="id_no")
  head(spList_meta)
  mdata_path<-file.path(mainDir,print(as.character(a$eco_name[which(a$eco_id==a$eco_id[y])])))
  fname<-paste0(mdata_path,"/mdata.csv")
  fname
  write.csv(spList_meta,fname,row.names=FALSE)
  
  
  #STEP 6: loop through species in the list (the spList object) and for each one create distance files in raw folder
  for (i in 1:nrow(spList)){
    
    gc()#garbage collection in casememory fills up
    id_no1<-spList$id_no1[i]
    season<-spList$season[i]
    print (paste0("id_no:",id_no1))
    print (paste0("season: ",season))
    print (paste0("nodes: ",(spList$count[i]) ))
    print (i)
    print (paste0("from total of: ",nrow(spList)))
    strSQL=paste0(
      "SET search_path=cci_2017, cci_2015,public,topology;
      select 
      a.area as from_area,
      b.area as to_area,
      a.fid_corrid as from_fid_corrid,
      b.fid_corrid as to_fid_corrid,
      a.node_id AS from_node_id, 
      b.node_id AS to_node_id,
      a.grid_id as from_grid_id,
      b.grid_id as to_grid_id,
      a.id_no1,
      a.season
      ,st_distance(a.the_geom,b.the_geom) AS distance
      /*,case when (st_intersects((ST_ShortestLine(a.the_geom,b.the_geom)), e.the_geom))
      then st_distance(a.the_geom,b.the_geom)- ST_Length(ST_Intersection((ST_ShortestLine(a.the_geom,b.the_geom)), e.the_geom))
      else 0
      end   as dist_over_barrier*/
      from
      (select area, /*wdpa,*/ fid_corrid, the_geom_azim_eq_dist as the_geom, id_no1, season::int, node_id, grid_id from int_grid_pas_trees_by_species_",a$eco_id[y]," where id_no1 =",id_no1," and season::int = ",season,")
      as a,
      (select area, /*wdpa*/ fid_corrid, the_geom_azim_eq_dist as the_geom, id_no1, season::int, node_id, grid_id from int_grid_pas_trees_by_species_",a$eco_id[y]," where id_no1 =",id_no1," and season::int = ",season,")  
      as  b,
      (select taxon_id as id_no1, final_value_to_use as mean_dist, (final_value_to_use*8*1000) as cutoff_dist from dispersal_data where taxon_id =", id_no1,") 
      as c
      /*, 
      (select the_geom_azim_eq_dist as the_geom, NAME, status from corridors_type_3_buff_agg) 
      as e*/
      where
      a.node_id > b.node_id
      and st_distance(a.the_geom,b.the_geom)<c.cutoff_dist
      and c.id_no1=a.id_no1;")
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
      write.table(x[, c("from_node_id", "to_node_id", "distance","from_fid_corrid", "to_fid_corrid","from_grid_id","to_grid_id")], file = paste0("distances_",x$id_no1[1],"_",x$season[1],".txt"), sep = "\t", col.names = FALSE, row.names = FALSE, quote=F) 
      
    }
    #clause so if only one nodes then no distances calculations are attampeted.
    if (length(x[1,])==0){
      print("error - no nodes to write outside of max distance threshold")
    }  else { # create node file from distances file
      
      print (dbListResults(con)[[1]])
      strSQL=paste0("SET search_path=cci_2017, cci_2015,public,topology; 
                    (select node_id, area, fid_corrid from int_grid_pas_trees_by_species_",a$eco_id[y]," where id_no1 =",id_no1," and season::int = ",season,")" )
      strSQL=gsub("\n", "", strSQL)
      #print(strSQL)
      nodes<- dbSendQuery(con, strSQL)   ## Submits a sql statement
      nodes<-fetch(nodes,n=-1)
      write.table(nodes[, c("node_id", "area", "fid_corrid")], file = paste0("nodes_",x$id_no1[1],"_",x$season[1],".txt"), sep = "\t", col.names = FALSE, row.names = FALSE, quote=F) 
      rm(nodes)
      rm(distances)
      rm(x)
      rm(id_no1)
      rm(season)
      rm(strSQL)  
    } 
    gc()
  }
  
}   


#Step 7: separating files into time periods using t0 and t1 based on specific columns - i.e. loss of forest, corridor
mainDir<- "C:/Data/cci_connectivity/scratch/conefor_runs/inputs/by_species/ecoregions"
setwd(mainDir)

#get look up table of forest loss, corridors and grid id (the latter should already be there but may not be needed)
forestloss<- read.dbf("C:/Data/cci_connectivity/scratch/nodes/corridors/hansenNew_eco_20km_passNew_kba_corr_floss1_wgs84.dbf")
forestloss<- forestloss[,c("FID_loss_o", "nodiddiss4","FID_corrid","FID_fnet_2")]
colnames(forestloss)<- c("loss", "node","fid_corrid","gridcell_id") 
str(forestloss)

file_list1<- list.files()
str(file_list1)
file_list1<-data.frame(file_list1)
file_list1$file_list1<-as.character(file_list1$file_list1)

a$eco_name<-as.character(a$eco_name)

str(file_list1)


################################################################
########
#not sure about this bit as it means you need to have the files beforehand - uncomment if needed and get errors running last bit
#a<-merge(a,file_list1,by.x="eco_name",by.y="file_list1",all.y)
#############
str(a)


for (y in 4:4){ #1:length(a$eco_id)){
  print (a$eco_id[y])
  setwd(paste0(mainDir,"/",as.character(a$eco_name[which(a$eco_id==a$eco_id[y])]),"/raw"))
  getwd()
  file_list<- list.files()
  file_list
  
  ## Nodes
  string_pattern<- "nodes_*"
  file_list<- file_list[lapply(file_list, function(x) length(grep(string_pattern, x, value=FALSE))) ==1 ]
  file_list
  
  
  file_list2<- lapply(file_list, read.table)
  file_list<- strsplit(file_list, ".txt")
  #file_list<- lapply(file_list, function(x) gsub("nodes", "nodes",x))
  names(file_list2)<- file_list
  file_list2<- lapply(file_list2, setNames, nm=c("node", "area"))
  file_list2<- lapply(file_list2, function(x) merge(x, forestloss, by= "node"))
  str(file_list2)
  
  ####t0 nodes
  file_listt0<-file_list2## if want to remove loss in t0 uncomment next line
  #file_listt0<- lapply(file_list2, function(x) x[!(x$loss > -1),])
  
  file_listt0<- lapply(file_listt0, function(x) x[c(1,2)]) 
  
  dir.create(file.path(mainDir,print(as.character(a$eco_name[which(a$eco_id==a$eco_id[y])])), "t0"))
  
  sapply(names(file_listt0), function(x) write.table(file_listt0[[x]], 
                                                     file=paste0(mainDir, "/",print(as.character(a$eco_name[which(a$eco_id==a$eco_id[y])])),"/t0/",x,".txt"), 
                                                     col.names=F, row.names=F ))
  
  ####t1 nodes
  file_listt1<- lapply(file_list2, function(x) x[!(x$loss > -1),])
  ## if want to corridors removed in t1 uncomment next line
  #file_listt1<- lapply(file_list2, function(x) x[(x$fid_corrid== -1),])
  file_listt1<- lapply(file_listt1, function(x) x[c(1,2)]) 
  
  dir.create(file.path(mainDir,print(as.character(a$eco_name[which(a$eco_id==a$eco_id[y])])), "t1"))
  
  sapply(names(file_listt1), function(x) write.table(file_listt1[[x]], 
                                                     file=paste0(mainDir, "/",print(as.character(a$eco_name[which(a$eco_id==a$eco_id[y])])),"/t1/",x,".txt"), 
                                                     col.names=F, row.names=F ))

  ####t2 nodes
  file_listt2<- lapply(file_list2, function(x) x[!(x$loss > -1),])
  ## if want to corridors removed in t2 uncomment next line
  file_listt2<- lapply(file_list2, function(x) x[(x$fid_corrid== -1),])
  file_listt2<- lapply(file_listt2, function(x) x[c(1,2)]) 
  
  dir.create(file.path(mainDir,print(as.character(a$eco_name[which(a$eco_id==a$eco_id[y])])), "t2"))
  
  sapply(names(file_listt2), function(x) write.table(file_listt2[[x]], 
                                                     file=paste0(mainDir, "/",print(as.character(a$eco_name[which(a$eco_id==a$eco_id[y])])),"/t2/",x,".txt"), 
                                                     col.names=F, row.names=F ))
  
  
  ## Distances
  file_list<- list.files()
  file_list
  string_pattern<- "distances_*"
  file_list<- file_list[lapply(file_list, function(x) length(grep(string_pattern, x, value=FALSE))) ==1 ]
  file_list
  i=0
  step<-10
  j<-i+1
  
  file_list_all<-file_list
  loopcount<-0#keep starting at 1
  
  while (j <= length(file_list_all)){
    gc()
    print (i)
    print ("to")
    print (j)
    print (paste0("out of files: ",length(file_list_all)))
    file_list<-file_list_all[i:j]
    file_list2<- lapply(file_list, read.table)
    file_list<- strsplit(file_list, ".txt")
    #file_list<- lapply(file_list, function(x) gsub("distances", "distances",x))
    names(file_list2)<- file_list
    file_list2<- lapply(file_list2, setNames, nm=c("from_node", "to_node", "distance","from_fid_corrid","to_fid_corrid","from_gridcell","to_gridcell"))
    file_list2<- lapply(file_list2, function(x) merge(x, forestloss, by.x= "from_node", by.y= "node", all.x=TRUE))
    file_list2<- lapply(file_list2, function(x) merge(x, forestloss, by.x= "to_node", by.y= "node", all.x=TRUE))
    #str(file_list2)
  
    ###t0 distances
    
    file_listt0<-file_list2## if want to remove loss in t0 uncomment next line
    #file_listt0<- lapply(file_list2, function(x) x[!(x$loss.x > -1 | x$loss.y > -1),])
    
    file_listt0<- lapply(file_listt0, function(x) x[c(1,2,3)]) 
    str(forestloss)
    sapply(names(file_listt0), function(x) write.table(file_listt0[[x]], 
                                                       file=paste0(mainDir, "/",print(as.character(a$eco_name[which(a$eco_id==a$eco_id[y])])),"/t0/",x,".txt"), 
                                                       col.names=F, row.names=F ))
    ###t1 distances
    file_listt1<- lapply(file_list2, function(x) x[!(x$loss.x > -1 | x$loss.y > -1),])
    ## if want to corridors removed in t1 uncomment next line
    #file_listt1<- lapply(file_listt1, function(x) x[(x$from_fid_corrid== -1 & x$to_fid_corrid== -1),])
    file_listt1<- lapply(file_listt1, function(x) x[c(1,2,3)]) 
    
    
    sapply(names(file_listt1), function(x) write.table(file_listt1[[x]], 
                                                       file=paste0(mainDir, "/",print(as.character(a$eco_name[which(a$eco_id==a$eco_id[y])])),"/t1/",x,".txt"), 
                                                       col.names=F, row.names=F ))
    ###t2 distances
    file_listt2<- lapply(file_list2, function(x) x[!(x$loss.x > -1 | x$loss.y > -1),])
    ## if want to corridors removed in t2 uncomment next line
    file_listt2<- lapply(file_listt2, function(x) x[(x$from_fid_corrid== -1 & x$to_fid_corrid== -1),])
    file_listt2<- lapply(file_listt2, function(x) x[c(1,2,3)]) 
    
    
    sapply(names(file_listt2), function(x) write.table(file_listt2[[x]], 
                                                       file=paste0(mainDir, "/",print(as.character(a$eco_name[which(a$eco_id==a$eco_id[y])])),"/t2/",x,".txt"), 
                                                       col.names=F, row.names=F ))
    
    if (loopcount==0){
      j<-j+step
    } else {
      j=j
    }
    if (length(file_list_all) >= j+(step)){
      i<-i+step+1
      j<-i+step
    } else{ 
      i<-j+1
      j<-j+2
    }
    loopcount<-loopcount+1
  }
}
          
      