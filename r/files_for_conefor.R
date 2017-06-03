
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

##load driver
drv <- dbDriver("PostgreSQL")
con <- dbConnect(drv, host='localhost', port='5432', dbname='biodiv_processing', user='postgres', password='Seltaeb1') ##assign connection info
dbListTables(con) #look at tables in database


#STEP 2: species info####
#getting anciliary data on species (optional) 
sp_status<-read.csv("C:/Data/cci_connectivity/raw/species/spp_name_id_category_joined.csv") #getting IUCN Red List category based on metadata for species
str(sp_status)#check it worked




#STEP 3: 
#eco<- read.dbf("C:/Data/cci_connectivity/scratch/ecoregions/freq_20km_kba_forestloss.dbf")
#new_name<- sapply(eco$ECO_NAME, function(x) chartr( " ,-","___", x))
#eco$NEW_ECO_NAME<- new_name 
#eco<- eco[, -1]

strSQL<-paste0("SET search_path=cci_2017,cci_2015,public,topology;
select eco_id::bigint, count (eco_name), eco_name as raw_eco_name from grid_pas_trees_40postcent_30agg_diss_ovr1ha_t1 group by eco_name,eco_id")

eco<-dbGetQuery(con,strSQL)
eco$eco_id<-as.integer(eco$eco_id)
str(eco)

eco$eco_name<- (sapply(eco$raw_eco_name, function(x) chartr( " ,-","___", x)))
write.csv(eco,"C:/Data/cci_connectivity/scratch/eco_nodecount.csv",row.names=F, quote = FALSE)

#select those in west africa using a list
Wafrica<- c("Eastern_Guinean_forests", "West_Sudanian_savanna", "Guinean_forest-savanna_mosaic", 
            "Western_Guinean_lowland_forests", "Jos_Plateau_forest-grassland_mosaic", "Guinean_mangroves",
            "Central_African_mangroves", "Guinean_montane_forests", "Lake_Chad_flooded_savanna", 
            "Cross-Sanaga-Bioko_coastal_forests", "Cross-Niger_transition_forests", "Niger_Delta_swamp_forests") 
1:length(Wafrica)
Wafrica<-data.frame(Wafrica)
a<-merge(eco,Wafrica,by.x="eco_name",by.y="Wafrica")
#a<- data.frame(eco_name= c("Ethiopian_montane_moorlands", "Eastern_Arc_forests"), eco_id= c(31008,30109))
#a<-eco
a

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

  
  

for (y in 5:length(a$eco_id)){
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
    (
    select foo1.*, 
    left((REPLACE(foo1.id_no, 'sp_', '')), length((REPLACE(foo1.id_no, 'sp_', ''))) - 2)::bigint as id_no1,
    right(foo1.id_no,1)::int as season
    from 
    (select spp_id as id_no, the_geom as the_geom from sp_merged_all) as foo1
    )
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
    foo1.the_geom_azim_eq_dist,
    ;")
  
  
dbGetQuery(con, strSQL)
    
    --this bit took a day for all species and with whole africa
    
    drop index if exists int_grid_pas_trees_by_species_",a$eco_id[y],"_index;
    create index int_grid_pas_trees_by_species_",a$eco_id[y],"_index_id_no1 on int_grid_pas_trees_by_species_",a$eco_id[y]," (id_no1);
    create index int_grid_pas_trees_by_species_",a$eco_id[y],"_index_season on int_grid_pas_trees_by_species_",a$eco_id[y]," (season);
    create index int_grid_pas_trees_by_species_",a$eco_id[y],"_index_node_id on int_grid_pas_trees_by_species_",a$eco_id[y]," (node_id);
    create index int_grid_pas_trees_by_species_",a$eco_id[y],"_index_fid_corrid on int_grid_pas_trees_by_species_",a$eco_id[y]," (fid_corrid);
    
    
    drop index if exists  int_grid_pas_trees_by_species_",a$eco_id[y],"_the_geom_azim_eq_dist_gist;
    CREATE INDEX int_grid_pas_trees_by_species_",a$eco_id[y],"_the_geom_azim_eq_dist_gist ON int_grid_pas_trees_by_species_",a$eco_id[y]," USING GIST (the_geom_azim_eq_dist);
    CLUSTER int_grid_pas_trees_by_species_",a$eco_id[y]," USING int_grid_pas_trees_by_species_",a$eco_id[y],"_the_geom_azim_eq_dist_gist;
    ANALYZE int_grid_pas_trees_by_species_",a$eco_id[y],";
    
    drop index if exists int_grid_pas_trees_by_species_",a$eco_id[y],"_geom_gist;
    CREATE INDEX int_grid_pas_trees_by_species_",a$eco_id[y],"_geom_gist ON int_grid_pas_trees_by_species_",a$eco_id[y]," USING GIST (the_geom);
    CLUSTER int_grid_pas_trees_by_species_",a$eco_id[y]," USING int_grid_pas_trees_by_species_",a$eco_id[y],"_geom_gist;
    ANALYZE int_grid_pas_trees_by_species_",a$eco_id[y],";
    
    ")
  
  
  dbGetQuery(con, strSQL)
}
  
  
  #STEP 4: create folder and change directory
  
  dir.create(file.path(mainDir,print(as.character(a$ECO_NAME[which(a$eco_id==a$eco_id[y])]))))
  setwd(file.path(mainDir,print(as.character(a$ECO_NAME[which(a$eco_id==a$eco_id[y])]))))
  dir.create(file.path(getwd(),"raw"))
  setwd(file.path(getwd(), "raw"))
  
  #STEP 5: getting list of species to run - includes optional filtering to see if nodes are impacted by development  #######
  
  #this optional filtering selects all species with nodes touching the area affected (using the "where impacted = 1" clause)
  #Note that links could be impacted too if overlap development so may want to run all by using /* and */ either side of the "where impacted = 1" clause 
  #Note: can choose specific runs for different corridors by choosing the id number from the development (e.g. fid_corrid number) - for these see development file
  strSQL="(
  select distinct foo1.id_no1, foo1.season, foo1.count from 
  (select id_no, id_no1, season::int, count (distinct (node_id)) 
  from  cci_2017.int_grid_pas_trees_by_species_",a$eco_id[y]," group by id_no, id_no1,season order by count desc) 
  as foo1,
  (select distinct id_no1, season from cci_2017.int_grid_pas_trees_by_species_",a$eco_id[y]," 
  /*where impacted =-1 and not impacted = 1*/ /* and fid_corrid=6*/) 
  as foo2
  where 
  foo1.count>1
  and foo1.id_no1=foo2.id_no1 
  and foo1.season = foo2.season::int
  order by count desc
  )" 
  spList
  spList<- dbGetQuery(con, strSQL)   ## Submits a sql statement
  
  #spList<-fetch(spList,n=-1) ##place data in dataframe
  
  head(spList)#view results
  str(spList)
  
  
  #STEP 6: loop through species in the list (the spList object) and for each one
  
  spList$id_no1
  for (i in 1:nrow(spList)){
    
    gc()#garbage collection in casememory fills up
    id_no1<-spList$id_no1[i]
    season<-spList$season[i]
    print (id_no1)
    print (season)
    print(spList$count[i])
    print (i)
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
      (select area, wdpa, fid_corrid, the_geom_azim_eq_dist as the_geom, id_no1, season::int, node_id, grid_id from int_grid_pas_trees_by_species_",a$eco_id[y]," where id_no1 =",id_no1," and season::int = ",season,")
      as a,
      (select area, wdpa, fid_corrid, the_geom_azim_eq_dist as the_geom, id_no1, season::int, node_id, grid_id from int_grid_pas_trees_by_species_",a$eco_id[y]," where id_no1 =",id_no1," and season::int = ",season,")  
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
                    (select node_id, area, wdpa, fid_corrid from int_grid_pas_trees_by_species_",a$eco_id[y]," where id_no1 =",id_no1," and season::int = ",season,")" )
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
  
    
  
  forestloss<- read.dbf("C:/Thesis_analysis/Development_corridors/conefor/ecoregions/gis_data/hansenNew_eco_20km_passNew_kba_corr_forestloss_clean_WGS.dbf")
  forestloss<- forestloss[,c("FID_loss_o", "nodiddiss4")]
  colnames(forestloss)<- c("loss", "node") 
  
  
  ## Nodes
  #activecorr<- c(0,2,3,8,14,20,22,25,26,31)
  
  file_list<- list.files()
  file_list
  string_pattern<- "nodes_*"
  file_list<- file_list[lapply(file_list, function(x) length(grep(string_pattern, x, value=FALSE))) ==1 ]
  file_list
  
  file_list2<- lapply(file_list, read.table)
  file_list<- strsplit(file_list, ".txt")
  file_list<- lapply(file_list, function(x) gsub("nodes", "nodes_adj",x))
  names(file_list2)<- file_list
  file_list2<- lapply(file_list2, setNames, nm=c("node", "area"))
  file_list2<- lapply(file_list2, function(x) merge(x, forestloss, by= "node"))
  file_listt0<- lapply(file_list2, function(x) x[!(x$loss > -1),])
  file_listt0<- lapply(file_listt0, function(x) x[c(1,2)]) 
  
  dir.create(file.path(mainDir,print(as.character(a$ECO_NAME[which(a$eco_id==y)])), "t0"))
  
  sapply(names(file_listt0), function(x) write.table(file_listt0[[x]], 
                                                     file=paste0(mainDir, "/",print(as.character(a$ECO_NAME[which(a$eco_id==y)])),"/t0/",x,".txt"), 
                                                     col.names=F, row.names=F ))
  
  file_listt1<- lapply(file_list2, function(x) x[!(x$loss > -1),])
  file_listt1<- lapply(file_list2, function(x) x[(x$fid_corrid== -1),])
  file_listt1<- lapply(file_listt1, function(x) x[c(1,2)]) 
  
  dir.create(file.path(mainDir,print(as.character(a$ECO_NAME[which(a$eco_id==y)])), "t1"))
  
  sapply(names(file_listt1), function(x) write.table(file_listt1[[x]], 
                                                     file=paste0(mainDir, "/",print(as.character(a$ECO_NAME[which(a$eco_id==y)])),"/t1/",x,".txt"), 
                                                     col.names=F, row.names=F ))
  
  ## Distances
  file_list<- list.files()
  file_list
  string_pattern<- "distances_*"
  file_list<- file_list[lapply(file_list, function(x) length(grep(string_pattern, x, value=FALSE))) ==1 ]
  
  file_list2<- lapply(file_list, read.table)
  file_list<- strsplit(file_list, ".txt")
  file_list<- lapply(file_list, function(x) gsub("distances", "distances_adj",x))
  names(file_list2)<- file_list
  file_list2<- lapply(file_list2, setNames, nm=c("from_node", "to_node", "distance"))
  file_list2<- lapply(file_list2, function(x) merge(x, forestloss, by.x= "from_node", by.y= "node", all.x=TRUE))
  file_list2<- lapply(file_list2, function(x) merge(x, forestloss, by.x= "to_node", by.y= "node", all.x=TRUE))
  file_listt0<- lapply(file_list2, function(x) x[!(x$loss.x > -1 | x$loss.y > -1),])
  file_listt0<- lapply(file_listt0, function(x) x[c(1,2,3)]) 
  
  
  sapply(names(file_listt0), function(x) write.table(file_listt0[[x]], 
                                                     file=paste0(mainDir, "/",print(as.character(a$ECO_NAME[which(a$eco_id==y)])),"/t0/",x,".txt"), 
                                                     col.names=F, row.names=F ))
  
  file_listt1<- lapply(file_list2, function(x) x[!(x$loss.x > -1 | x$loss.y > -1),])
  file_listt1<- lapply(file_listt1, function(x) x[(x$from_fid_corrid== -1 & x$to_fid_corrid== -1),])
  file_listt1<- lapply(file_listt1, function(x) x[c(1,2,3)]) 
  
  
  sapply(names(file_listt1), function(x) write.table(file_listt1[[x]], 
                                                     file=paste0(mainDir, "/",print(as.character(a$ECO_NAME[which(a$eco_id==y)])),"/t1/",x,".txt"), 
                                                     col.names=F, row.names=F ))
  
  
}
















