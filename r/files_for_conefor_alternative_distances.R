
#Aim: avoid running multiple species but prune after instead 
strSQL<-paste0(select taxon_id as id_no1, final_value_to_use as mean_dist, 
               (final_value_to_use*8*1000) as cutoff_dist from dispersal_data) 
spDists<-dbGetQuery(con,strSQL)

max_eco_dist<-merge(spDist,spList,by.x="taxon_id,by.y="spList")


#STEP 6: loop through species in the list (the spList object) and for each one
  gc()#garbage collection in casememory fills up
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
    (select area, /*wdpa,*/ fid_corrid, the_geom_azim_eq_dist as the_geom, id_no1, season::int, node_id, grid_id from int_grid_pas_trees_by_species_",a$eco_id[y],")
    as a,
    (select area, /*wdpa*/ fid_corrid, the_geom_azim_eq_dist as the_geom, id_no1, season::int, node_id, grid_id from int_grid_pas_trees_by_species_",a$eco_id[y],")  
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



