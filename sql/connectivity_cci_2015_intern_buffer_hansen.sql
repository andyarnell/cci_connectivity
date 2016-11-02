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
INSERT into spatial_ref_sys (srid, auth_name, auth_srid, proj4text, srtext) values ( 54032, 'esri', 54032, '+proj=aeqd +lat_0=0 +lon_0=0 +x_0=0 +y_0=0 +ellps=WGS84 +datum=WGS84 +units=m +no_defs ', 'PROJCS["World_Azimuthal_Equidistant",GEOGCS["GCS_WGS_1984",DATUM["WGS_1984",SPHEROID["WGS_1984",6378137,298.257223563]],PRIMEM["Greenwich",0],UNIT["Degree",0.017453292519943295]],PROJECTION["Azimuthal_Equidistant"],PARAMETER["False_Easting",0],PARAMETER["False_Northing",0],PARAMETER["Central_Meridian",0],PARAMETER["Latitude_Of_Origin",0],UNIT["Meter",1],AUTHORITY["EPSG","54032"]]');

select * from agg_intern_1kmnodes limit 10;


--calculating distance between nodes for each species indivudally 
--with option to filter by distance table
drop table if exists links_agg_intern_1kmnodes;
create table links_agg_intern_1kmnodes AS 
select
a.node_id AS from_node_id, 
b.node_id AS to_node_id, 
st_transform(st_shortestline(a.the_geom,b.the_geom),54032) as the_geom/*,
st_buffer(st_transform(st_shortestline(a.the_geom,b.the_geom),54032),(st_distance(a.the_geom,b.the_geom)/5)) AS the_geombff*/,
st_distance(a.the_geom,b.the_geom) AS distance
from
(select st_transform(the_geom,54032) as the_geom, node_id1 as node_id from agg_intern_1kmnodes order by node_id) as a,
(select st_transform(the_geom,54032) as the_geom, node_id as node_id from agg_intern_1kmnodes order by node_id) as  b
where
st_dwithin(a.the_geom,b.the_geom, 100000/*c.dist_test*/)
and a.node_id > b.node_id;

--adding a link_id column to use to later connect conefor results
-- ALTER TABLE forest_sp DROP COLUMN link_id;
ALTER TABLE links_agg_intern_1kmnodes 
ADD COLUMN link_id varchar;
UPDATE links_agg_intern_1kmnodes SET link_id = from_node_id::text || '_'|| to_node_id::text;

ALTER TABLE links_agg_intern_1kmnodes 
ADD COLUMN link_id2 varchar;
UPDATE links_agg_intern_1kmnodes SET link_id2 = to_node_id::text || '_'|| from_node_id::text;

#ALTER TABLE links_agg_intern_1kmnodes ALTER COLUMN the_geom TYPE geometry(Multipolygon, 54032) USING ST_SetSRID(the_geom, 54032)

drop table if exists links_agg_intern_1kmnodes_spp;
create table links_agg_intern_1kmnodes_spp AS 
select
link_id, 
link_id2
distance,
id_no
from links_agg_intern_1kmnodes  as foo1
where foo1.node_id1 = foo2.from_node_id 
and foo1.node_id1 = foo2.to_node_id
group by id_no;


CREATE INDEX links_agg_intern_1kmnodes_geom_gist ON links_agg_intern_1kmnodes USING GIST (the_geom);
CLUSTER links_agg_intern_1kmnodes USING links_agg_intern_1kmnodes_geom_gist;
ANALYZE links_agg_intern_1kmnodes;

---------------------------------------------------

--select only those nodes with some links (this is necessary for when there are no correspondiong link tables - due to distnaces between nodes being too large or only one node/patch)
drop table if exists nodes_agg_intern_1kmnodes; 
create table nodes_agg_intern_1kmnodes as
select foo1.* from 
agg_intern_1kmnodes as foo1, 
(select distinct(id_no) from links_agg_intern_1kmnodes) as foo2 
where foo1.id_no=foo2.id_no;




drop table if exists buff_links_agg_intern_1kmnodes;
create table buff_links_agg_intern_1kmnodes as
select to_node_id,
from_node_id,
link_id,
distance,
st_buffer(the_geom,(distance/5)) AS the_geom
from (select * from links_agg_intern_1kmnodes limit 1000) as foo;


