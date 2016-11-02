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
-------------------------------------------

--make a table to store csv habitat info before importing cleaned info into habitat_prefs_redd_pac_2015_congo2nd table
DROP TABLE IF EXISTS habitat_prefs_cci_2015_africa_cleaning;
CREATE TABLE habitat_prefs_cci_2015_africa_cleaning (
id bigserial NOT NULL,
taxonid BIGINT,
friendly_name VARCHAR,
suitability VARCHAR,
habitatsclass VARCHAR,
season VARCHAR,
majorimportance VARCHAR,
CONSTRAINT habitat_prefs_cci_2015_africa_cleaning_pkey PRIMARY KEY (id)
)
WITH (OIDS=FALSE);
ALTER TABLE habitat_prefs_cci_2015_africa_cleaning
  OWNER TO postgres;


--import data from the text file of habitat preferences into the habitat_prefs_cci_2015_africa_cleaning table
COPY habitat_prefs_cci_2015_africa_cleaning (taxonid,friendly_name,habitatsclass,suitability,season,majorimportance) 
FROM
'C:\Data\Habitats_IUCN_for_import\nature_serve_new_habitat_affiliations\WCMC_Habitat_Info2_Aug2014_AA.csv' delimiter ',' CSV HEADER ;


drop index if exists habitat_prefs_cci_2015_africa_cleaning_index;
CREATE INDEX habitat_prefs_cci_2015_africa_cleaning_index
ON habitat_prefs_cci_2015_africa_cleaning (taxonid);

-----------------------------------------------------------
--select any species with forest prefs
drop table if exists forest_sp_cci_2015_africa;
create table forest_sp_cci_2015_africa as 
select distinct taxonid 
from habitat_prefs_cci_2015_africa_cleaning 
where 
suitability = 'Suitable'
and
(split_part(habitatsclass,' ',1)) in ('1.1','1.2','1.3','1.4','1.5','1.6','1.7','1.8','1.9');

/*
--remove those with non-forest habitat from forest speces
DELETE FROM forest_sp_cci_2015_africa
  WHERE taxonid IN (
select distinct taxonid 
from habitat_prefs_cci_2015_africa_cleaning 
where 
suitability = 'Suitable'
and (split_part(habitatsclass,' ',1)) not in ('1.1','1.2','1.3','1.4','1.5','1.6','1.7','1.8','1.9')
);

CREATE INDEX forest_sp_cci_2015_africa_index
ON forest_sp_cci_2015_africa (taxonid);
*/

--prior to importing to dbase make sure a version of the crosswalk from xls file into a text file format compatible (i.e. text tab delimited) for upload with only necessary columns i.e. no spaces in titles
--make a table to help convert iucn habitat affiliations to glc2000 classes (from lndshift output) via crosswalk text file (columns made to fit those from text file)
--N.B. sense checks should be made on results of crosswalks
DROP TABLE IF EXISTS iucn_crosswalk_cci_2015_africa;
CREATE TABLE iucn_crosswalk_cci_2015_africa (
id bigserial NOT NULL,
iucn_middle_level_code VARCHAR,
iucndescription VARCHAR,
glc2000code VARCHAR,
glc2000description VARCHAR,
CONSTRAINT iucn_crosswalk_cci_2015_africa_pkey PRIMARY KEY (id)
)
WITH (OIDS=FALSE);
ALTER TABLE iucn_crosswalk_cci_2015_africa
  OWNER TO postgres;

--N.B. don't reimport this as you can end up with multiple crosswalks in one table - rememeber to delete and rebuild this table (sql above) if need to update this --(in future could implement a unique code to be present when importing to stop this)
COPY iucn_crosswalk_cci_2015_africa (iucn_middle_level_code,iucndescription,glc2000code,glc2000description) 
FROM
'C:\Data\GLC2000_crosswalk_for_import\GLCCrossWalk_Updated_20150310.csv' delimiter ',' CSV HEADER ;

--make habitat_prefs_cci_2015_africa table from selected columns out of -
--the habitat_prefs_cci_2015_africa_cleaning table and joined to the crosswalk table -
--by iucn code (iucn code extracted using split_part function)
DROP TABLE IF EXISTS habitat_prefs_cci_2015_africa;
CREATE TABLE habitat_prefs_cci_2015_africa AS
SELECT
hc.taxonid as taxonid, 
hc.suitability AS spchabimpdesc, 
split_part(hc.habitatsclass,' ',1) AS iucn_code, 
hc.habitatsclass as iucn_desc,
cw.glc2000code AS suitlc,
cw.glc2000description as glc2000description
FROM 
habitat_prefs_cci_2015_africa_cleaning AS hc, 
iucn_crosswalk_cci_2015_africa AS cw 
WHERE split_part(hc.habitatsclass,' ',1) = cw.iucn_middle_level_code;

--add primary key and id column to habitat_prefs_cci_2015_africa table
ALTER TABLE habitat_prefs_cci_2015_africa
ADD COLUMN id bigserial NOT NULL,
ADD CONSTRAINT habitat_prefs_cci_2015_africa_pkey PRIMARY KEY (id);

--add a normal index on column (as used in subsequent joins with large tables)
create index habitat_prefs_cci_2015_africa_taxonid_index
ON habitat_prefs_cci_2015_africa (taxonid);

--add a normal index on column (as used in subsequent joins with large tables)
create index habitat_prefs_cci_2015_africa_suitlc_index
ON habitat_prefs_cci_2015_africa (suitlc);

CLUSTER habitat_prefs_cci_2015_africa USING habitat_prefs_cci_2015_africa_taxonid_index;
CLUSTER habitat_prefs_cci_2015_africa USING habitat_prefs_cci_2015_africa_suitlc_index;
ANALYZE habitat_prefs_cci_2015_africa;

select count(distinct taxonid) from  habitat_prefs_cci_2015_africa;
select count(*) from forest_sp_cci_2015_africa;


--forest species prefrences (not filtering out "suitable" category here - that comes later
drop table if exists habitat_prefs_cci_2015_africa_cleaning_forest;
create table  habitat_prefs_cci_2015_africa_cleaning_forest as
select distinct foo1.*, (split_part(habitatsclass,' ',1)) 
from
habitat_prefs_cci_2015_africa_cleaning as foo1
inner join
forest_sp_cci_2015_africa as foo2
on foo1.taxonid=foo2.taxonid;

DROP TABLE IF EXISTS habitat_prefs_cci_2015_africa_suitforest;
CREATE TABLE habitat_prefs_cci_2015_africa_suitforest AS
select distinct taxonid, suitlc::bigint 
from habitat_prefs_cci_2015_africa
where spchabimpdesc = 'Suitable';


DROP TABLE IF EXISTS lc_lut_cci_2015_africa;
CREATE TABLE lc_lut_cci_2015_africa (
id bigserial NOT NULL,
lc_raw integer,
lc_lookup varchar,
CONSTRAINT lc_lut_cci_2015_africa_pkey PRIMARY KEY (id)
)
WITH (OIDS=FALSE);
ALTER TABLE lc_lut_cci_2015_africa
 OWNER TO postgres;

   
--lookup table for converting. 
--N.B. don't reimport this as you can end up with multiple crosswalks in one table - remember to delete and rebuild this table (sql above) if need to update this --(in future could implement a unique code to be present when importing to stop this)
-- used the values between 100 and 120 (crop) as 100 in the lookup table for glc2000. 
-- used 201 (grazing) as 200, and 200 as 200
--don't 
-- set-aside left as 99 (i.e. not counted).
INSERT INTO lc_lut_cci_2015_africa (lc_raw,lc_lookup) VALUES 
(0,0),
(1,1),
(2,2),
(3,3),
(4,4),
(5,5),
(6,6),
(7,7),
(8,8),
(9,9),
(10,10),
(11,11),
(12,12),
(13,13),
(14,14),
(15,15),
(16,16),
(17,17),
(18,18),
(19,19),
(20,20),
(21,21),
(22,22),
(23,23),
(99,99),
(100,100),
(101,100),
(102,100),
(103,100),
(104,100),
(105,100),
(106,100),
(107,100),
(108,100),
(109,100),
(110,100),
(111,100),
(112,100),
(113,100),
(114,100),
(115,100),
(116,100),
(117,100),
(118,100),
(119,100),
(120,100),
(200,200),
(201,200);


---------------------------------------------------------------------------
------------------------------------------------------------------------------

drop table if exists forest_aves_list;
create table forest_aves_list as
select distinct foo3.id_no, category
from 
forest_sp_cci_2015_africa as foo1,
	(
select id_no, class, category, st_area(the_geom) as eoo_area, the_geom from 
raw.species_eoo_gridbscale where 
class = 'AVES' 
--and 
--category in ('CR','EN','VU')
	) 
as foo2,
	(
select distinct id_no from 
wwf_afdb.species_intersecting_wwf_afdb_africa50km_temp
	)
as foo3 
where foo1.taxonid=foo2.id_no
and foo2.id_no=foo3.id_no;



drop table if exists forest_aves_areas;
create table forest_aves_areas as
select 
id_no, 
sum(st_area(st_intersection(foo3.the_geom,foo4.the_geom))) area_in_africa
 from 
	(
select foo2.* from
forest_crenvu_aves_list as foo1
join
raw.species_eoo_gridbscale as foo2
on foo1.id_no=foo2.id_no
	)
as foo3
join
	(
select st_simplifypreservetopology(st_transform(the_geom,54009),1000) as the_geom 
from
africa_dcw_dissolved
	) 
as foo4
on 
st_intersects(foo3.the_geom,foo4.the_geom)
group by foo3.id_no;


drop table if exists forest_aves_prop;
create table forest_aves_prop as
select foo1.id_no,
foo1.area_in_africa/st_area(foo2.the_geom)
 as prop_eoo
from 
forest_aves_areas as foo1,
raw.species_eoo_gridbscale as foo2
where foo1.id_no=foo2.id_no
order by prop_eoo desc;

drop table if exists forest_aves_in_africa;
create table forest_aves_in_africa as
select foo1.* from 
raw.species_eoo_gridbscale as foo1,
forest_aves_prop as foo2
where foo1.id_no=foo2.id_no
and foo2.prop_eoo > 0;

CREATE INDEX forest_aves_in_africa_geom_gist ON forest_aves_in_africa USING GIST (the_geom);
CLUSTER forest_aves_in_africa USING forest_aves_in_africa_geom_gist;
ANALYZE forest_aves_in_africa;

CREATE INDEX forest_aves_in_africa_index_id_no ON forest_aves_in_africa (id_no);


drop table if exists intsct_forest_aves_lcover;
create table intsct_forest_aves_lcover as
SELECT id_no, 
        st_transform(((gv).geom),54009) as the_geom,
        (gv).val as lc
 FROM (SELECT id_no, 
              /*ST_Intersection(rast, the_geom) AS gv*/  st_dumpaspolygons((St_clip(rast,the_geom))) AS gv --the st_dumpaspolygons is best if quick (but less accurate) method is needed
       FROM public.glc2000_raster,  --raster to get values from
            (
SELECT id_no, 
st_buffer(st_transform(the_geom,4326),0) as the_geom  
FROM (select * from forest_aves_in_africa order by random() limit 25) as afr
) as bob
       WHERE ST_Intersects(rast, the_geom)
      ) foo;

alter table intsct_forest_aves_lcover
add column id bigserial,
ADD CONSTRAINT intsct_forest_aves_lcover_pkey PRIMARY KEY (id);

*/

--alternative for all that like forest
/*
	(
select distinct taxonid 
from habitat_prefs_cci_2015_africa_cleaning 
where 
suitability = 'Suitable'
and
(split_part(habitatsclass,' ',1)) 
in ('1.1','1.2','1.3','1.4','1.5','1.6','1.7','1.8','1.9')
	)	
as foo1,
*/

----------------------------------------------------------------------------------------

--calculate ESH for each species
DROP TABLE IF EXISTS esh_overlap_africa;
create table esh_overlap_africa as 
SELECT 
foo1.id_no,
(st_dump(st_union(foo1.the_geom))).geom as the_geom
FROM 
(select * from intsct_forest_aves_lcover offset 0)
AS foo1, 
habitat_prefs_cci_2015_africa_suit 
as foo3
where
foo3.suitlc = foo1.lc
and
foo1.id_no = foo3.taxonid
GROUP BY foo1.id_no;

--add a unique id column 
alter table esh_overlap_africa
add column node_id bigserial;
--make column into primary key 
alter table esh_overlap_africa
add constraint esh_overlap_africa_node_id_pkey primary key (node_id);

--add index on column uesd in subsequent joins
CREATE INDEX esh_overlap_africa_id_no_index ON esh_overlap_africa (id_no);

ALTER TABLE esh_overlap_africa
ADD Column node_area numeric;
update esh_overlap_africa set node_area = st_area(the_geom)/1000000;


----------------------------------

--add a unique id column 
alter table spp_22714700_wgs
add column node_id bigserial;
--make column into primary key 
alter table spp_22714700_wgs
add constraint spp_22714700_wgs_node_id_pkey primary key (node_id);

--add index on column uesd in subsequent joins
CREATE INDEX spp_22714700_wgs_id_no_index ON spp_22714700_wgs (id_no);

ALTER TABLE spp_22714700_wgs
ADD Column node_area numeric;
update spp_22714700_wgs set node_area = st_area(the_geom)/1000000;

--add a unique id column 
alter table spp_22714700_wgs
add column id_no bigint;

update spp_22714700_wgs set id_no = 22714700 ;

select * from spp_22714700_wgs limit 10;

SELECT UpdateGeometrySRID('spp_22714700_wgs','the_geom',4326);

--------------------------------------------------------------------------------
--add azimuthal equidistant projection to the dbase
INSERT into spatial_ref_sys (srid, auth_name, auth_srid, proj4text, srtext) values ( 54032, 'esri', 54032, '+proj=aeqd +lat_0=0 +lon_0=0 +x_0=0 +y_0=0 +ellps=WGS84 +datum=WGS84 +units=m +no_defs ', 'PROJCS["World_Azimuthal_Equidistant",GEOGCS["GCS_WGS_1984",DATUM["WGS_1984",SPHEROID["WGS_1984",6378137,298.257223563]],PRIMEM["Greenwich",0],UNIT["Degree",0.017453292519943295]],PROJECTION["Azimuthal_Equidistant"],PARAMETER["False_Easting",0],PARAMETER["False_Northing",0],PARAMETER["Central_Meridian",0],PARAMETER["Latitude_Of_Origin",0],UNIT["Meter",1],AUTHORITY["EPSG","54032"]]');


--calculating distance between nodes for each species indivudally 
--with option to filter by distance table
drop table if exists links_forest_sp;
create table links_forest_sp AS 
select
(a.node_id) AS from_node_id,
(b.node_id) AS to_node_id,
a.cell_id,
--st_transform(st_shortestline(a.the_geom,b.the_geom),54009) AS the_geom, 
st_distance(a.the_geom,b.the_geom) AS distance,
b.id_no
from
(select /*st_transform(the_geom,54032) as */  the_geom::geography, node_id, id_no, left((node_id)::varchar,3) as cell_id from spp_22714700_wgs order by node_id limit 50000)  as a,
(select /*st_transform(the_geom,54032) as */ the_geom::geography, node_id, id_no,  left((node_id)::varchar,3) as cell_id from spp_22714700_wgs order by node_id limit 50000)  as b
where
st_dwithin(a.the_geom,b.the_geom, 100000/*c.dist_test*/)
and a.id_no = b.id_no 
and a.node_id > b.node_id
and a.cell_id= b.cell_id;

--adding a link_id column to use to later connect conefor results
-- ALTER TABLE forest_sp DROP COLUMN link_id;
ALTER TABLE links_forest_sp 
ADD COLUMN link_id varchar;
UPDATE links_forest_sp SET link_id = from_node_id::text || '_'|| to_node_id::text;

---------------------------------------------------

--select only those nodes with some links (this is necessary for when there are no correspondiong link tables - due to distnaces between nodes being too large or only one node/patch)
drop table if exists nodes_forest_sp; 
create table nodes_forest_sp as
select foo1.* from 
spp_22714700_wgs as foo1, 
(select distinct(id_no) from links_forest_sp) as foo2 
where foo1.id_no=foo2.id_no;

------------------------------------------------------------------------------------------------
/*
--to remove duplicate links (i.e. link from node 2 to 3 and link from nodes 3 to 2) 
DROP TABLE IF EXISTS links_duplicates_removed_x1;
CREATE TABLE links_duplicates_removed_x1 AS 
SELECT *
FROM links_forest_sp AS a 
WHERE a.from_node_id > a.to_node_id and not(a.from_node_id is null or a.to_node_id is null);
*/

/*
--summing links to see where multiple species
DROP TABLE IF EXISTS links_sum_x1;
CREATE TABLE links_sum_x1 AS 
SELECT link_id, min(distance) AS distance, the_geom, count(link_id) as no_spp
FROM links_duplicates_removed_x1
GROUP BY link_id, the_geom;

drop table if exists iba_spp_eoo;
create table iba_spp_eoo as
select * from species_eoo as foo inner join (select distinct sciname from iba_trigger_species) as foo2
 on foo.species=foo2.sciname;	
*/

--select count (distinct node_id) as countnodes, id_no  from esh_overlap_africa group by id_no order by countnodes desc ;