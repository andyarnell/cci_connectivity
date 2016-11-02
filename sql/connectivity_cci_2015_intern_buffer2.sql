--AIM: Make species EOO,ESH and range-rarity (national) maps based on a grid covering the area of interest (aoi) This has been used for landshift results for africa paper with kassel University

---set path for sql processing to act on tables in a specific schema within the database (normally defaults to public otherwise)
--more than one can be listed using commas
--in this case it will add new tables to the first schema (e.g. a newly created schema)  in the list 
--but still have access to tables and most importantly functions in the public schema


CREATE SCHEMA IF NOT EXISTS cci_2015; 

SET search_path=cci_2015,public,topology;


--find/display current path for sql processing 
SHOW search_path;



--if postgis/postgresql running locally on desktop increase access to memory (RAM) 
SET work_mem TO 120000;
SET maintenance_work_mem TO 120000;
SET client_min_messages TO DEBUG;

--add azimuthal equidistant projection to the dbase
INSERT into spatial_ref_sys (srid, auth_name, auth_srid, proj4text, srtext) values ( 54032, 'esri', 54032, '+proj=aeqd +lat_0=0 +lon_0=0 +x_0=0 +y_0=0 +ellps=WGS84 +datum=WGS84 +units=m +no_defs ', 'PROJCS["World_Azimuthal_Equidistant",GEOGCS["GCS_WGS_1984",DATUM["WGS_1984",SPHEROID["WGS_1984",6378137,298.257223563]],PRIMEM["Greenwich",0],UNIT["Degree",0.017453292519943295]],PROJECTION["Azimuthal_Equidistant"],PARAMETER["False_Easting",0],PARAMETER["False_Northing",0],PARAMETER["Central_Meridian",0],PARAMETER["Latitude_Of_Origin",0],UNIT["Meter",1],AUTHORITY["EPSG","54032"]]');

select * from hansen1km_agg limit 10;

--calculating distance between nodes for each species indivudally 
--with option to filter by distance table
drop table if exists links_hansen1km_agg;
create table links_hansen1km_agg AS 
select
a.node_id AS from_node_id, 
b.node_id AS to_node_id, 
st_buffer(st_transform(st_shortestline(a.the_geom,b.the_geom),54032),(st_distance(a.the_geom,b.the_geom)/5)) AS the_geom,
st_distance(a.the_geom,b.the_geom) AS distance,
b.id_no
from
(select st_transform(the_geom,54032) as the_geom, node_id, id_no from hansen1km_agg order by node_id limit 10) as a,
(select st_transform(the_geom,54032) as the_geom, node_id, id_no from hansen1km_agg order by node_id limit 10) as  b
where
st_dwithin(a.the_geom,b.the_geom, 1000000/*c.dist_test*/)
and a.id_no = b.id_no 
and a.node_id > b.node_id;

