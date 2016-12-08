--AIM: Make species EOO,ESH and range-rarity (national) maps based on a grid covering the area of interest (aoi) This has been used for landshift results for africa paper with kassel University

---set path for sql processing to act on tables in a specific schema within the database (normally defaults to public otherwise)
--more than one can be listed using commas
--in this case it will add new tables to the first schema (e.g. a newly created schema)  in the list 
--but still have access to tables and most importantly functions in the public schema


CREATE SCHEMA IF NOT EXISTS cci_2015; 

SET search_path=cci_2015,public,topology;


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

drop table if exists grid_pas_trees_40postcent_30agg_diss_ovr1ha_sbset1_clean;
create table grid_pas_trees_40postcent_30agg_diss_ovr1ha_sbset1_clean as
(select st_makevalid(st_buffer(the_geom,0)) as the_geom, nodeiddiss as node_id, fid_grid50 as grid_id, area_geo as area, fid_pas_in as wdpa from grid_pas_trees_40postcent_30agg_diss_ovr1ha_sbset1 offset 0);

CREATE INDEX grid_pas_trees_40postcent_30agg_diss_ovr1ha_sbset1_clean_geom_gist ON grid_pas_trees_40postcent_30agg_diss_ovr1ha_sbset1_clean USING GIST (the_geom);
CLUSTER grid_pas_trees_40postcent_30agg_diss_ovr1ha_sbset1_clean USING grid_pas_trees_40postcent_30agg_diss_ovr1ha_sbset1_clean_geom_gist;
ANALYZE grid_pas_trees_40postcent_30agg_diss_ovr1ha_sbset1_clean;



--getting nodeids touching species
drop table if exists int_grid_pas_trees_40postcent_30agg_by_nodeids;
create table int_grid_pas_trees_40postcent_30agg_by_nodeids as
select 
foo2.id_no,
foo2.id_no1,
foo2.season,
foo1.node_id,
foo1.grid_id,
foo1.the_geom,
min(foo1.area) as area,
min(case when (wdpa>-1) then 1 else -1 end) as wdpa
from 
grid_pas_trees_40postcent_30agg_diss_ovr1ha_sbset1_clean
as foo1,
/*(select id_no, st_makevalid(st_transform(st_buffer(the_geom,0),54032)) as the_geom from forest_aves_in_africa order by id_no)*/
/*(select spp_id as id_no, the_geom  from sp_merged_all order by spp_id limit 200) */ 
(
select foo1.*, 
left((REPLACE(foo1.id_no, 'sp_', '')), length((REPLACE(foo1.id_no, 'sp_', ''))) - 2)::bigint as id_no1,
right(foo1.id_no,1) as season
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
alter table int_grid_pas_trees_40postcent_30agg_by_nodeids
add column 
the_geom_azim_eq_dist geometry(Geometry,54032)

--#populate it from transforming previous one
UPDATE int_grid_pas_trees_40postcent_30agg_by_nodeids SET the_geom_azim_eq_dist = ST_Transform(the_geom, 54032)
FROM spatial_ref_sys WHERE ST_SRID(the_geom) = srid;


--drop index int_grid_pas_trees_40postcent_30agg_by_nodeids_index
create index int_grid_pas_trees_40postcent_30agg_by_nodeids_index_id_no1 on int_grid_pas_trees_40postcent_30agg_by_nodeids (id_no1);
create index int_grid_pas_trees_40postcent_30agg_by_nodeids_index_season on int_grid_pas_trees_40postcent_30agg_by_nodeids (season);
create index int_grid_pas_trees_40postcent_30agg_by_nodeids_index_node_id on int_grid_pas_trees_40postcent_30agg_by_nodeids (node_id);

CREATE INDEX int_grid_pas_trees_40postcent_30agg_by_nodeids_the_geom_azim_eq_dist_gist ON int_grid_pas_trees_40postcent_30agg_by_nodeids USING GIST (the_geom_azim_eq_dist);
CLUSTER int_grid_pas_trees_40postcent_30agg_by_nodeids USING int_grid_pas_trees_40postcent_30agg_by_nodeids_the_geom_azim_eq_dist_gist;
ANALYZE int_grid_pas_trees_40postcent_30agg_by_nodeids;

CREATE INDEX int_grid_pas_trees_40postcent_30agg_by_nodeids_geom_gist ON int_grid_pas_trees_40postcent_30agg_by_nodeids USING GIST (the_geom);
CLUSTER int_grid_pas_trees_40postcent_30agg_by_nodeids USING int_grid_pas_trees_40postcent_30agg_by_nodeids_geom_gist;
ANALYZE int_grid_pas_trees_40postcent_30agg_by_nodeids;



select count (distinct (node_id)) from int_grid_pas_trees_40postcent_30agg_by_nodeids group by id_no order by count desc;


--calculating distance between nodes for each species indivudally 
--with option to filter by distance table
drop table if exists links_grid_pas_trees_40postcent_30agg_sbset1;
create table links_grid_pas_trees_40postcent_30agg_sbset1 AS 
select 
a.node_id AS from_node_id, 
b.node_id AS to_node_id,
a.grid_id as from_grid_id,
b.grid_id as to_grid_id,
a.id_no1,
a.season1,
/*st_transform(st_shortestline(a.the_geom,b.the_geom),54032) as the_geom,
st_buffer(st_transform(st_shortestline(a.the_geom,b.the_geom),54032),(st_distance(a.the_geom,b.the_geom)/5)) AS the_geombff*/
st_distance(a.the_geom,b.the_geom) AS distance
from
(select /*st_transform(the_geom,54032)*/ the_geom_azim_eq_dist as the_geom, id_no1, season as season1, node_id, grid_id, season from int_grid_pas_trees_40postcent_30agg_by_nodeids) 
as a,
(select /*st_transform(the_geom,54032)*/ the_geom_azim_eq_dist as the_geom, id_no1, season as season2, node_id, grid_id, season from int_grid_pas_trees_40postcent_30agg_by_nodeids) 
as  b,
(select taxon_id as id_no, final_value_to_use as mean_dist, (final_value_to_use*10*1000) as cutoff_dist from dispersal_data) 
as c
where
/*st_dwithin(a.the_geom,b.the_geom, 500000)
and */a.node_id > b.node_id
and c.id_no=a.id_no1
and st_distance(a.the_geom,b.the_geom)<c.cutoff_dist
group by  
from_node_id, 
to_node_id, 
a.id_no1, 
a.season1, 
from_grid_id, 
to_grid_id 
,a.the_geom, 
b.the_geom
;

