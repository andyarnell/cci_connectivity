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




---------corridors
--making a new clean corridor dataset
drop table if exists corridors_type_3_buff_agg;
create table corridors_type_3_buff_agg as
select *, st_buffer(st_transform(the_geom,54032),0) as the_geom_azim_eq_dist 
from corridors_type_3_buff_agg_moll;


select foo1.*, st_area(st_transform(st_intersection(foo1.the_geom_azim_eq_dist,foo2.the_geom_azim_eq_dist),54009))/1000000 as the_geom_edit
from
(select * from int_grid_pas_trees_40postcent_30agg_by_nodeids_eco limit 1000) as foo1,
corridors_type_3_buff_agg as foo2 
where st_intersects(foo1.the_geom_azim_eq_dist,foo2.the_geom_azim_eq_dist);


select foo1.*, st_difference(foo1.the_geom_azim_eq_dist,foo2.the_geom_azim_eq_dist) as the_geom_edit, st_difference(foo1.the_geom_azim_eq_dist,foo2.the_geom_azim_eq_dist)
from
(select * from int_grid_pas_trees_40postcent_30agg_by_nodeids_eco limit 10000) as foo1,
corridors_type_3_buff_agg as foo2 
where st_intersects(foo1.the_geom_azim_eq_dist,foo2.the_geom_azim_eq_dist);

