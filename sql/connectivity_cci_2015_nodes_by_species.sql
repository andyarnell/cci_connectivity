--AIM: Make species EOO,ESH and range-rarity (national) maps based on a grid covering the area of interest (aoi) This has been used for landshift results for africa paper with kassel University

---set path for sql processing to act on tables in a specific schema within the database (normally defaults to public otherwise)
--more than one can be listed using commas
--in this case it will add new tables to the first schema (e.g. a newly created schema)  in the list 
--but still have access to tables and most importantly functions in the public schema


CREATE SCHEMA IF NOT EXISTS cci_2015; 

SET search_path=cci_2017,cci_2015,public,topology;


--find/display current path for sql processing 
SHOW search_path;



--find/display current path for sql processing 
SHOW search_path;


--if postgis/postgresql running locally on desktop increase access to memory (RAM) 
SET work_mem TO 120000;
SET maintenance_work_mem TO 120000;
SET client_min_messages TO DEBUG;




--importing dispersal data
DROP TABLE IF EXISTS dispersal_data;
CREATE TABLE dispersal_data
(species varchar, 
taxon_id bigint,
fit_05 varchar,
upr_05 varchar,
lwr_05 varchar,
final_value_to_use numeric,
CONSTRAINT dispersal_data_pkey 
primary key (taxon_id)
)
WITH (OIDS=FALSE);
ALTER TABLE dispersal_data
  OWNER TO postgres;



copy dispersal_data
(species, 
taxon_id,
fit_05,
upr_05,
lwr_05,
final_value_to_use)
from 'C:\Data\cci_connectivity\scratch\dispersal\bird_dispersal_edit.csv'  delimiter ',' header CSV;


drop table if exists grid_pas_trees_40postcent_30agg_diss_ovr1ha_t1_clean;
create table grid_pas_trees_40postcent_30agg_diss_ovr1ha_t1_clean as
(select st_makevalid(st_buffer(the_geom,0)) as the_geom, nodiddiss2::int as node_id, fid_grid50 as grid_id, area_geo as area, fid_pas_in as wdpa, nodiddiss2 - nodeiddiss as impacted, fid_dev::int as fid_dev
from grid_pas_trees_40postcent_30agg_diss_ovr1ha_t1 offset 0);


--select ((eco_num::int)::varchar||nodeiddiss::varchar)::int as node_id from grid_pas_trees_40postcent_30agg_diss_ovr1ha_ecoregions limit 1000;

drop index if exists grid_pas_trees_40postcent_30agg_diss_ovr1ha_t1_clean_geom_gist;
CREATE INDEX grid_pas_trees_40postcent_30agg_diss_ovr1ha_t1_clean_geom_gist ON grid_pas_trees_40postcent_30agg_diss_ovr1ha_t1_clean USING GIST (the_geom);
CLUSTER grid_pas_trees_40postcent_30agg_diss_ovr1ha_t1_clean USING grid_pas_trees_40postcent_30agg_diss_ovr1ha_t1_clean_geom_gist;
ANALYZE grid_pas_trees_40postcent_30agg_diss_ovr1ha_t1_clean;

select * from grid_pas_trees_40postcent_30agg_diss_ovr1ha_t1_clean limit 1000

--getting nodeids touching species
drop table if exists int_grid_pas_trees_40postcent_30agg_by_nodeids_t1;
create table int_grid_pas_trees_40postcent_30agg_by_nodeids_t1 as
select 
foo2.id_no,
foo2.id_no1,
foo2.season,
foo1.node_id,
foo1.grid_id,
foo1.the_geom,
min(foo1.area) as area,
min(case when (wdpa>-1) then 1 else -1 end) as wdpa,
min(case when (impacted<>0) then 1 else -1 end) as impacted,
min(foo1.fid_dev) as fid_dev
from 
grid_pas_trees_40postcent_30agg_diss_ovr1ha_t1_clean
as foo1,
/*(select id_no, st_makevalid(st_transform(st_buffer(the_geom,0),54032)) as the_geom from forest_aves_in_africa order by id_no)*/
/*(select spp_id as id_no, the_geom  from sp_merged_all order by spp_id limit 200) */ 
(
select foo1.*, 
left((REPLACE(foo1.id_no, 'sp_', '')), length((REPLACE(foo1.id_no, 'sp_', ''))) - 2)::bigint as id_no1,
right(foo1.id_no,1)::int as season
from 
sp_merged_all_union as foo1,
sp_category  as foo2
where 
foo2.id_no=left((REPLACE(foo1.id_no, 'sp_', '')), length((REPLACE(foo1.id_no, 'sp_', ''))) - 2)::bigint
/*and foo2.category in ('CR','EN','VU') */
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
foo1.grid_id
;

--add in equidistant column (quicker for next steps)
alter table int_grid_pas_trees_40postcent_30agg_by_nodeids_t1
add column 
the_geom_azim_eq_dist geometry(Geometry,54032);

--#populate it from transforming previous one
UPDATE int_grid_pas_trees_40postcent_30agg_by_nodeids_t1 SET the_geom_azim_eq_dist = ST_Transform(the_geom, 54032)
FROM spatial_ref_sys WHERE ST_SRID(the_geom) = srid;

--this bit took a day for all species and with whole africa

drop index if exists int_grid_pas_trees_40postcent_30agg_by_nodeids_t1_index;
create index int_grid_pas_trees_40postcent_30agg_by_nodeids_t1_index_id_no1 on int_grid_pas_trees_40postcent_30agg_by_nodeids_t1 (id_no1);
create index int_grid_pas_trees_40postcent_30agg_by_nodeids_t1_index_season on int_grid_pas_trees_40postcent_30agg_by_nodeids_t1 (season);
create index int_grid_pas_trees_40postcent_30agg_by_nodeids_t1_index_node_id on int_grid_pas_trees_40postcent_30agg_by_nodeids_t1 (node_id);
create index int_grid_pas_trees_40postcent_30agg_by_nodeids_t1_index_fid_dev on int_grid_pas_trees_40postcent_30agg_by_nodeids_t1 (fid_dev);


drop index if exists  int_grid_pas_trees_40postcent_30agg_by_nodeids_t1_the_geom_azim_eq_dist_gist;
CREATE INDEX int_grid_pas_trees_40postcent_30agg_by_nodeids_t1_the_geom_azim_eq_dist_gist ON int_grid_pas_trees_40postcent_30agg_by_nodeids_t1 USING GIST (the_geom_azim_eq_dist);
CLUSTER int_grid_pas_trees_40postcent_30agg_by_nodeids_t1 USING int_grid_pas_trees_40postcent_30agg_by_nodeids_t1_the_geom_azim_eq_dist_gist;
ANALYZE int_grid_pas_trees_40postcent_30agg_by_nodeids_t1;

drop index if exists int_grid_pas_trees_40postcent_30agg_by_nodeids_t1_geom_gist;
CREATE INDEX int_grid_pas_trees_40postcent_30agg_by_nodeids_t1_geom_gist ON int_grid_pas_trees_40postcent_30agg_by_nodeids_t1 USING GIST (the_geom);
CLUSTER int_grid_pas_trees_40postcent_30agg_by_nodeids_t1 USING int_grid_pas_trees_40postcent_30agg_by_nodeids_t1_geom_gist;
ANALYZE int_grid_pas_trees_40postcent_30agg_by_nodeids_t1;

select * from 
int_grid_pas_trees_40postcent_30agg_by_nodeids_t1 
limit 10

--(select /*st_transform(the_geom,54032)*/ the_geom_azim_eq_dist as the_geom, id_no1, id_no, season as season1, node_id, grid_id from int_grid_pas_trees_40postcent_30agg_by_nodeids_t1 where id_no = 'sp_22681765_1') 

--#############################################################################
---use r script instead and ignore the following
