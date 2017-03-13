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

--select * from append_clip_sel limit 10;

--calculating distance between nodes for each species indivudally 
--with option to filter by distance table
drop table if exists links_append_clip_sel;
create table links_append_clip_sel AS 
select
a.node_id AS from_node_id, 
b.node_id AS to_node_id, 
a.id_no,
a.shp_num,
st_transform(st_shortestline(a.the_geom,b.the_geom),54032) as the_geom/*,
st_buffer(st_transform(st_shortestline(a.the_geom,b.the_geom),54032),(st_distance(a.the_geom,b.the_geom)/5)) AS the_geombff*/,
st_distance(a.the_geom,b.the_geom) AS distance
from
(select st_transform(the_geom,54032) as the_geom, id_no, shp_num, node_id1 as node_id from append_clip_sel order by node_id) as a,
(select st_transform(the_geom,54032) as the_geom, id_no, shp_num, node_id as node_id from append_clip_sel order by node_id) as  b
where
st_dwithin(a.the_geom,b.the_geom, 200000/*c.dist_test*/)
and
a.id_no = b.id_no 
and a.shp_num = b.shp_num
and a.node_id > b.node_id;

--adding a link_id column to use to later connect conefor results
-- ALTER TABLE forest_sp DROP COLUMN link_id;
ALTER TABLE links_append_clip_sel 
ADD COLUMN link_id varchar;
UPDATE links_append_clip_sel SET link_id = from_node_id::text || '_'|| to_node_id::text;

ALTER TABLE links_append_clip_sel 
ADD COLUMN link_id2 varchar;
UPDATE links_append_clip_sel SET link_id2 = to_node_id::text || '_'|| from_node_id::text;

ALTER TABLE links_append_clip_sel ALTER COLUMN the_geom TYPE geometry(LineString, 54032) USING ST_SetSRID(the_geom, 54032);


----------------
--buffer tool


--select only those nodes with some links (this is necessary for when there are no correspondiong link tables - due to distnaces between nodes being too large or only one node/patch)
/*drop table if exists nodes_agg_intern_1kmnodes; 
create table nodes_agg_intern_1kmnodes as
select foo1.* from 
agg_intern_1kmnodes as foo1, 
(select distinct(id_no) from links_agg_intern_1kmnodes) as foo2 
where foo1.id_no=foo2.id_no;*/


drop table if exists buff_links_append_clip_sel;
create table buff_links_append_clip_sel as
select 
to_node_id,
from_node_id,
link_id,
link_id2,
distance,
id_no,
shp_num,
st_buffer(the_geom,(distance/5)) AS the_geom
from (select * from links_append_clip_sel) as foo;



----------------------code for exporting shapefiles 
/*

--For exporting using ogr2ogr (osgeo4w command line) into separate shapefiles for change maps

ogr2ogr --config FGDB_BULK_LOAD YES  -progress -f "ESRI Shapefile" -sql "SELECT * FROM cci_2015.buff_links_append_clip_sel" C:\Data\cci_connectivity\scratch\intern\euclid\buffer PG:"host=localhost user=postgres password=Seltaeb1 dbname=biodiv_processing" -nln buff_links_append_clip_sel -nlt POLYGON -lco "SHPT=POLYGON"  -a_srs "EPSG:54032"
ogr2ogr --config FGDB_BULK_LOAD YES  -progress -f "ESRI Shapefile" -sql "SELECT * FROM cci_2015.links_append_clip_sel" C:\Data\cci_connectivity\scratch\intern\euclid\buffer PG:"host=localhost user=postgres password=Seltaeb1 dbname=biodiv_processing" -nln links_append_clip_sel  -a_srs "EPSG:54032"
*/