
CREATE SCHEMA IF NOT EXISTS cci_2015; 

SET search_path=cci_2015,public,topology;

select id_no from grid_pas_trees_40postcent_30agg_by_nodeids group by id_no limit 10;

drop table if exists int_grid_pas_trees_40postcent_30agg_by_nodeids;
create table int_grid_pas_trees_40postcent_30agg_by_nodeids as
select 
foo2.id_no,
foo2.id_no1,
foo2.season,
foo1.node_id,
foo1.grid_id,
min(foo1.area) as area,
min(case when (wdpa>-1) then 1 else -1 end) as wdpa
from 
grid_pas_trees_40postcent_30agg_diss_ovr1ha_clean
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
and foo2.category in ('CR','EN','VU') limit 10
)
as foo2
where
st_intersects(foo1.the_geom,foo2.the_geom)
group by 
foo1.node_id,
foo2.id_no,
foo2.id_no1,
foo2.season,
foo1.grid_id
;


select count (distinct grid_id) from int_int_grid_pas_trees_40postcent_30agg_by_nodeids group by id_no order by count (id_no) desc;

drop table if exists int_grid_pas_trees_40postcent_30agg_by_nodeids;
create table int_grid_pas_trees_40postcent_30agg_by_nodeids as
select 
foo2.id_no,
foo2.id_no1,
foo2.season,
foo1.node_id,
foo1.grid_id,
st_intersection(foo1.the_geom,foo2.the_geom) as the_geom
from 
grid_pas_trees_40postcent_30agg_diss_ovr1ha_clean
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
and foo2.category in ('CR') limit 2
)
as foo2
where
st_intersects(foo1.the_geom,foo2.the_geom)
;
