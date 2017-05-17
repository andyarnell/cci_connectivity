

CREATE SCHEMA IF NOT EXISTS cci_2015; 

SET search_path=cci_2015,public,topology;


--find/display current path for sql processing 
SHOW search_path;



--find/display current path for sql processing 
SHOW search_path;


drop table if exists links_grid_pas_trees_40postcent_30agg_t1;

create table links_grid_pas_trees_40postcent_30agg_t1 AS 
with a0 as (
select 
foo2.id_no,
foo2.id_no1,
foo2.season,
foo1.node_id,
foo1.grid_id,
foo1.the_geom,
st_transform(foo1.the_geom,54032) as the_geom_azim_eq_dist,
min(foo1.area) as area,
min(case when (wdpa>-1) then 1 else -1 end) as wdpa,
min(case when (impacted<>0) then 1 else -1 end) as impacted,
min(foo1.fid_corrid) as fid_corrid
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
where foo2.id_no=left((REPLACE(foo1.id_no, 'sp_', '')), length((REPLACE(foo1.id_no, 'sp_', ''))) - 2)::bigint
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
foo1.grid_id)
--calculating distance between nodes for each species individually 
--with option to filter by distance table
select 
a.node_id AS from_node_id, 
b.node_id AS to_node_id,
a.grid_id as from_grid_id,
b.grid_id as to_grid_id,
a.id_no1,
a.season,
/*st_shortestline(a.the_geom,b.the_geom) as the_geom,st_buffer(st_shortestline(a.the_geom,b.the_geom)),(st_distance(a.the_geom,b.the_geom)/5)) AS the_geombff*/
(st_distance(a.the_geom,b.the_geom)) AS distance
from
(select the_geom_azim_eq_dist as the_geom, id_no1, season, node_id, grid_id from a0)
as a,
(select the_geom_azim_eq_dist as the_geom, id_no1, season, node_id, grid_id from a0)
as  b,
(select taxon_id as id_no, final_value_to_use as mean_dist, (final_value_to_use*8*1000)::bigint as cutoff_dist from dispersal_data order by cutoff_dist desc) 
as c,
(select id_no1, season, count (distinct (node_id)) from int_grid_pas_trees_40postcent_30agg_by_nodeids_t1 group by id_no1,season order by count desc) 
/*(select id_no1, season, count from (select id_no1, season, count (distinct (node_id)) from int_grid_pas_trees_40postcent_30agg_by_nodeids_t1 group by id_no1,season order by count desc) as foo where count >1 and count <100) */
as d
where
/*st_dwithin(a.the_geom,b.the_geom, 500000)
and */
a.node_id > b.node_id
and d.id_no1=a.id_no1
and d.season=a.season
and d.id_no1=b.id_no1
and d.season=b.season
and st_distance(a.the_geom,b.the_geom)<c.cutoff_dist
and c.id_no=a.id_no1
group by  
from_node_id, 
to_node_id, 
a.id_no1, 
a.season, 
from_grid_id, 
to_grid_id 
,a.the_geom, 
b.the_geom;

