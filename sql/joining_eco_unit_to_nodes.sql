
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

drop table if exists grid_pas_trees_40postcent_30agg_diss_ovr1ha_clean_eco1;
create table grid_pas_trees_40postcent_30agg_diss_ovr1ha_clean_eco1 as
select foo1.*, foo2.eco_id from 
grid_pas_trees_40postcent_30agg_diss_ovr1ha_clean as foo1
join 
(select distinct nodeiddiss as node_id, eco_id::int as eco_id from grid_pas_trees_40postcent_30agg_diss_ovr1ha_ecoregions) 
as foo2
on foo1.node_id=foo2.node_id;


drop table if exists int_grid_pas_trees_40postcent_30agg_by_nodeids_eco1;
create table int_grid_pas_trees_40postcent_30agg_by_nodeids_eco1 as
select foo1.*, foo2.eco_unit from 
int_grid_pas_trees_40postcent_30agg_by_nodeids as foo1
join 
(select distinct ((eco_num::int)::varchar||nodeiddiss::varchar)::int as node_id, biome::int as biome, eco_num::int as eco_num from grid_pas_trees_40postcent_30agg_diss_ovr1ha_ecoregions) 
as foo2
on foo1.node_id=foo2.node_id;

drop table if exists lut_eco_unit;
create table lut_eco_unit as
select distinct ((eco_num::int)::varchar||nodeiddiss::varchar)::bigint  as node_id, eco_id::bigint as eco_unit from grid_pas_trees_40postcent_30agg_diss_ovr1ha_ecoregions;
create index lut_eco_unit_index_eco_unit on lut_eco_unit (eco_unit);
create index lut_eco_unit_index_node_id on lut_eco_unit (node_id);


--update from eco unit (ecoregions) layer
alter table int_grid_pas_trees_40postcent_30agg_by_nodeids_eco
add column eco_id bigint;

/*
update int_grid_pas_trees_40postcent_30agg_by_nodeids_eco as foo1
set eco_id = foo2.eco_unit
from (select * from lut_eco_unit limit 300) as foo2
where 
foo1.node_id = foo2.node_id
;
*/

drop table if exists int_grid_pas_trees_40postcent_30agg_by_nodeids_eco1;
create table int_grid_pas_trees_40postcent_30agg_by_nodeids_eco1 as
select foo1.*, foo2.eco_unit as eco_unit from 
int_grid_pas_trees_40postcent_30agg_by_nodeids_eco as foo1,
(select * from lut_eco_unit)
 as foo2
where 
foo1.node_id = foo2.node_id;



select eco_id,id_no, count(*) from int_grid_pas_trees_40postcent_30agg_by_nodeids_eco group by id_no, eco_id order by count desc;

select * from int_grid_pas_trees_40postcent_30agg_by_nodeids_eco limit 1000


drop table if exists int_grid_pas_trees_40postcent_30agg_by_nodeids_eco1;
create table int_grid_pas_trees_40postcent_30agg_by_nodeids_eco1 as
select foo1.*, foo2.eco_unit as eco_unit from 
int_grid_pas_trees_40postcent_30agg_by_nodeids_eco as foo1,
(select * from lut_eco_unit)
 as foo2
where 
foo1.node_id = foo2.node_id;

drop table if exists corridors_type_3_buff_agg;
create table corridors_type_3_buff_agg as
select *, st_buffer(st_transform(the_geom,54032),0) as the_geom_azim_eq_dist 
from corridors_type_3_buff_agg_moll;


select foo1.*, st_intersection(foo1.the_geom_azim_eq_dist,foo2.the_geom_azim_eq_dist) as the_geom_edit
from
(select * from int_grid_pas_trees_40postcent_30agg_by_nodeids_eco limit 100000) as foo1,
corridors_type_3_buff_agg as foo2 
where st_intersects(foo1.the_geom_azim_eq_dist,foo2.the_geom_azim_eq_dist);




