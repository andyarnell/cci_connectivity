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
-------------------------------------------
--add azimuthal equidistant projection to the dbase
--INSERT into spatial_ref_sys (srid, auth_name, auth_srid, proj4text, srtext) values ( 54032, 'esri', 54032, '+proj=aeqd +lat_0=0 +lon_0=0 +x_0=0 +y_0=0 +ellps=WGS84 +datum=WGS84 +units=m +no_defs ', 'PROJCS["World_Azimuthal_Equidistant",GEOGCS["GCS_WGS_1984",DATUM["WGS_1984",SPHEROID["WGS_1984",6378137,298.257223563]],PRIMEM["Greenwich",0],UNIT["Degree",0.017453292519943295]],PROJECTION["Azimuthal_Equidistant"],PARAMETER["False_Easting",0],PARAMETER["False_Northing",0],PARAMETER["Central_Meridian",0],PARAMETER["Latitude_Of_Origin",0],UNIT["Meter",1],AUTHORITY["EPSG","54032"]]');

--select * from grid_pas_trees_40postcent_30agg limit 10;


--calculating distance between nodes for each species indivudally 
--with option to filter by distance table
drop table if exists links_grid_pas_trees_40postcent_30agg_eco;
create table links_grid_pas_trees_40postcent_30agg_eco AS 
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
(select st_transform(the_geom,54032) as the_geom, id_no1, season as season1, node_id, grid_id, season from int_grid_pas_trees_40postcent_30agg_by_nodeids order by id_no,node_id) 
as a,
(select st_transform(the_geom,54032) as the_geom, id_no1, season as season2, node_id, grid_id, season from int_grid_pas_trees_40postcent_30agg_by_nodeids order by id_no, node_id) 
as  b,
(select  taxon_id as id_no, final_value_to_use as mean_dist, (final_value_to_use*10*1000) as cutoff_dist from dispersal_data) 
as c
where
st_dwithin(a.the_geom,b.the_geom, 400000/*c.dist_test*/)
and a.node_id > b.node_id
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



/*create table 
select distinct to_node_id as select_nodes from links_grid_pas_trees_40postcent_30agg as foo1
union
select distinct from_node_id select_nodes from links_grid_pas_trees_40postcent_30agg as foo2;
*/

select * from int_grid_pas_trees_40postcent_30agg_by_nodeids limit 10

--adding a link_id column to use to later connect conefor results
-- ALTER TABLE forest_sp DROP COLUMN link_id;
/*
ALTER TABLE links_grid_pas_trees_40postcent_30agg 
ADD COLUMN link_id varchar;
UPDATE links_grid_pas_trees_40postcent_30agg SET link_id = from_node_id::text || '_'|| to_node_id::text;

ALTER TABLE links_grid_pas_trees_40postcent_30agg 
ADD COLUMN link_id2 varchar;
UPDATE links_grid_pas_trees_40postcent_30agg SET link_id2 = to_node_id::text || '_'|| from_node_id::text;

ALTER TABLE links_grid_pas_trees_40postcent_30agg ALTER COLUMN the_geom TYPE geometry(LineString, 54032) USING ST_SetSRID(the_geom, 54032);


-- this should create and clean up spatial indexing, which speeds up overlap processing
CREATE INDEX links_grid_pas_trees_40postcent_30agg_geom_gist ON links_grid_pas_trees_40postcent_30agg USING GIST (the_geom);
CLUSTER links_grid_pas_trees_40postcent_30agg USING links_grid_pas_trees_40postcent_30agg_geom_gist;
ANALYZE links_grid_pas_trees_40postcent_30agg;
*/

create index links_grid_pas_trees_40postcent_30agg_index on links_grid_pas_trees_40postcent_30agg(from_node_id);
create index links_grid_pas_trees_40postcent_30agg_index2 on links_grid_pas_trees_40postcent_30agg(to_node_id);


-- this should create and clean up spatial indexing, which speeds up overlap processing
CREATE INDEX forest_aves_in_africa_geom_gist ON forest_aves_in_africa USING GIST (the_geom);
CLUSTER forest_aves_in_africa USING forest_aves_in_africa_geom_gist;
ANALYZE forest_aves_in_africa;




--getting ids and distances for each species -TOO SLOW WITHOUT SPATIAL INDEX (spatial index makes v large files - plus it won't cover all node connections necessarily)
/*select 
efoo2.id_no,
foo1.to_node_id,
foo2.id_no,
min(foo1.distance)
from 
links_grid_pas_trees_40postcent_30agg 
as foo1,
(select id_no, st_transform(the_geom,54032) as the_geom 
from forest_aves_in_africa limit 10)
as foo2
where
st_within(foo1.the_geom,foo2.the_geom)
group by 
foo1.from_node_id,
foo1.to_node_id,
foo2.id_no
;
*/

--instead chose to get node ids [er species and then the dsitances between them from the links table (possible errors of the link distances occuring outside the range of the species for big/convoluted patches)

drop table if exists sp_merged_all_union;
create table sp_merged_all_union as
(select spp_id as id_no, st_union((st_buffer(the_geom,0))) as the_geom  from (select * from sp_merged_all order by spp_id) as foo group by id_no);

select * from sp_merged_all_union;



CREATE INDEX sp_merged_all_union_geom_gist ON sp_merged_all_union USING GIST (the_geom);
CLUSTER sp_merged_all_union USING sp_merged_all_union_geom_gist;
ANALYZE sp_merged_all_union;

drop table if exists grid_pas_trees_40postcent_30agg_diss_ovr1ha_eco_clean;
create table grid_pas_trees_40postcent_30agg_diss_ovr1ha_eco_clean as
(select st_makevalid(st_buffer(the_geom,0)) as the_geom, nodeiddiss as node_id, fid_grid50 as grid_id, area_geo as area, fid_pas_in as wdpa from grid_pas_trees_40postcent_30agg_diss_ovr1ha_eco offset 0);

CREATE INDEX grid_pas_trees_40postcent_30agg_diss_ovr1ha_eco_clean_geom_gist ON grid_pas_trees_40postcent_30agg_diss_ovr1ha_eco_clean USING GIST (the_geom);
CLUSTER grid_pas_trees_40postcent_30agg_diss_ovr1ha_eco_clean USING grid_pas_trees_40postcent_30agg_diss_ovr1ha_eco_clean_geom_gist;
ANALYZE grid_pas_trees_40postcent_30agg_diss_ovr1ha_eco_clean;



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


--importing sp_category
DROP TABLE IF EXISTS sp_category;
CREATE TABLE sp_category
(
id_no bigint,
binomial varchar,
category  varchar,
CONSTRAINT sp_category_pkey 
primary key (id_no)
)
WITH (OIDS=FALSE);
ALTER TABLE sp_category
  OWNER TO postgres;

copy sp_category
(
id_no,
binomial,
category)
from 'C:\Data\cci_connectivity\raw\species\spp_name_id_category_joined.csv'  delimiter ',' header CSV;






select  left((REPLACE(id_no, 'sp_', '')), length((REPLACE(id_no, 'sp_', ''))) - 1)  from sp_merged_all_union limit 10

regexp_replace(string, '-$', '') as one_trimmed

SELECT id_no LENGTH(name) FROM cities ORDER BY LENGTH(name);

select * from sp_merged_all_union limit 10

select * 
from 
(select  taxon_id as id_no, final_value_to_use as mean_dist, (final_value_to_use*10) as cutoff_dist from dispersal_data) as foo1, 
(select left((REPLACE(id_no, 'sp_', '')), length((REPLACE(id_no, 'sp_', ''))) - 2)::bigint as id_no from sp_merged_all_union)
as foo2
where foo1.id_no=foo2.id_no;




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
grid_pas_trees_40postcent_30agg_diss_ovr1ha_eco_clean
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
drop table if exists links_grid_pas_trees_40postcent_30agg_eco;
create table links_grid_pas_trees_40postcent_30agg_eco AS 
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


select distinct (id_no) from int_grid_pas_trees_40postcent_30agg_by_nodeids





--select count(*) from int_grid_pas_trees_40postcent_30agg_by_nodeids limit 10;


--make sure there are indexes on both tables
--drop index int_grid_pas_trees_40postcent_30agg_by_nodeids_index
create index int_grid_pas_trees_40postcent_30agg_by_nodeids_node_id_index on int_grid_pas_trees_40postcent_30agg_by_nodeids (node_id);
create index int_grid_pas_trees_40postcent_30agg_by_nodeids_idno_index on int_grid_pas_trees_40postcent_30agg_by_nodeids (id_no);


--choosing all links, for each species, based on node_ids
drop table if exists links_grid_pas_trees_40postcent_30agg_by_id_nos;
create table links_grid_pas_trees_40postcent_30agg_by_id_nos as
select 
foo2.id_no,
foo1.to_node_id,
foo1.from_node_id,
min(foo1.distance) as distance
from 
links_grid_pas_trees_40postcent_30agg 
as foo1,
(select * from int_grid_pas_trees_40postcent_30agg_by_nodeids order by id_no, node_id)
as foo2
where
foo1.to_node_id=foo2.node_id
or 
foo1.from_node_id=foo2.node_id
group by 
foo1.from_node_id,
foo1.to_node_id,
foo2.id_no
;


--choosing all links, for each species, based on node_ids
drop table if exists links_grid_pas_trees_40postcent_30agg_by_id_nos1;
create table links_grid_pas_trees_40postcent_30agg_by_id_nos1 as
select 
foo2.id_no1,
foo2.season,
foo1.to_node_id,
foo1.from_node_id,
min(foo1.distance) as distance
from 
links_grid_pas_trees_40postcent_30agg_eco 
as foo1,
(select * from int_grid_pas_trees_40postcent_30agg_by_nodeids order by id_no, node_id)
as foo2,
(select taxon_id as id_no, final_value_to_use as mean_dist, (final_value_to_use*8) as cutoff_dist from dispersal_data)
as foo3
/*,
sp_category as foo4*/
where
foo3.id_no=foo2.id_no1
and
foo1.to_node_id=foo2.node_id
/* 
and
foo4.id_no=foo3.id_no
*/
or 
foo1.from_node_id=foo2.node_id
and
foo1.distance<foo3.cutoff_dist
group by 
foo1.from_node_id,
foo1.to_node_id,
foo2.id_no1,
foo2.season
;








create index links_grid_pas_trees_40postcent_30agg_by_id_nos_index on links_grid_pas_trees_40postcent_30agg_by_id_nos(from_node_id);
create index links_grid_pas_trees_40postcent_30agg_by_id_nos_index2 on links_grid_pas_trees_40postcent_30agg_by_id_nos(to_node_id);
create index links_grid_pas_trees_40postcent_30agg_by_id_nos_index3 on links_grid_pas_trees_40postcent_30agg_by_id_nos(id_no);


drop table if exists links_grid_pas_trees_40postcent_30agg_by_id_nos_filt1;
create table links_grid_pas_trees_40postcent_30agg_by_id_nos_filt1 as
select 
foo2.id_no,
foo1.to_node_id,
foo1.from_node_id,
min(foo1.distance) as distance
from 
links_grid_pas_trees_40postcent_30agg_by_id_nos 
as foo1,
(select * from int_grid_pas_trees_40postcent_30agg_by_nodeids order by id_no, node_id)
as foo2
where
foo1.id_no=foo2.id_no
and
foo1.from_node_id=foo2.node_id
group by 
foo1.from_node_id,
foo1.to_node_id,
foo2.id_no
;

create index links_grid_pas_trees_40postcent_30agg_by_id_nos_filt1_index on links_grid_pas_trees_40postcent_30agg_by_id_nos_filt1(from_node_id);
create index links_grid_pas_trees_40postcent_30agg_by_id_nos_filt1_index2 on links_grid_pas_trees_40postcent_30agg_by_id_nos_filt1(to_node_id);


drop table if exists links_grid_pas_trees_40postcent_30agg_by_id_nos_filt2;
create table links_grid_pas_trees_40postcent_30agg_by_id_nos_filt2 as
select 
foo2.id_no,
foo1.to_node_id,
foo1.from_node_id,
min(foo1.distance) as distance
from 
links_grid_pas_trees_40postcent_30agg_by_id_nos_filt1 
as foo1,
(select * from int_grid_pas_trees_40postcent_30agg_by_nodeids order by id_no, node_id)
as foo2
where
foo1.id_no=foo2.id_no
and
foo1.to_node_id=foo2.node_id
group by 
foo1.from_node_id,
foo1.to_node_id,
foo2.id_no
;

select count(*) from links_grid_pas_trees_40postcent_30agg_by_id_nos_filt2;

copy links_grid_pas_trees_40postcent_30agg_by_id_nos_filt2 to 
'C:/Data/cci_connectivity/scratch/links.csv' delimiter ',';

copy int_grid_pas_trees_40postcent_30agg_by_nodeids to 
'C:/Data/cci_connectivity/scratch/nodes.csv' delimiter ',';

select id_no, count(node_id) from int_grid_pas_trees_40postcent_30agg_by_nodeids group by id_no


----------------
--buffer tool


--select only those nodes with some links (this is necessary for when there are no correspondiong link tables - due to distnaces between nodes being too large or only one node/patch)
/*drop table if exists nodes_agg_intern_1kmnodes; 
create table nodes_agg_intern_1kmnodes as
select foo1.* from 
agg_intern_1kmnodes as foo1, 
(select distinct(id_no) from links_agg_intern_1kmnodes) as foo2 
where foo1.id_no=foo2.id_no;*/

/*
drop table if exists buff_links_grid_pas_trees_40postcent_30agg;
create table buff_links_grid_pas_trees_40postcent_30agg as
select 
to_node_id,
from_node_id,
link_id,
link_id2,
distance,
st_buffer(the_geom,(distance/5)) AS the_geom
from (select * from links_grid_pas_trees_40postcent_30agg) as foo;
*/


----------------------code for exporting shapefiles 
/*

--For exporting using ogr2ogr (osgeo4w command line) into separate shapefiles for change maps

ogr2ogr --config FGDB_BULK_LOAD YES  -progress -f "ESRI Shapefile" -sql "SELECT * FROM cci_2015.buff_links_grid_pas_trees_40postcent_30agg" C:\Data\cci_connectivity\scratch\intern\euclid\buffer PG:"host=localhost user=postgres password=Seltaeb1 dbname=biodiv_processing" -nln buff_links_grid_pas_trees_40postcent_30agg -nlt POLYGON -lco "SHPT=POLYGON"  -a_srs "EPSG:54032"
*/