
    --AIM: Make species EOO,ESH and range-rarity (national) maps based on a grid covering the area of interest (aoi) This has been used for landshift results for africa paper with kassel University
    
    ---set path for sql processing to act on tables in a specific schema within the database (normally defaults to public otherwise)
    --more than one can be listed using commas
    --in this case it will add new tables to the first schema (e.g. a newly created schema)  in the list 
    --but still have access to tables and most importantly functions in the public schema
    drop table if exists sp_merged_alt_clip_clean;
    create table sp_merged_c1200_alt_clip_clean as
select foo1.*, 
    left((REPLACE(foo1.id_no, 'sp_', '')), length((REPLACE(foo1.id_no, 'sp_', ''))) - 2)::bigint as id_no1,
    right(foo1.id_no,1)::int as season
    from 
    (select spp_id as id_no, the_geom as the_geom from sp_merged_c1200_alt_clip)
	as foo1;
    
SELECT UpdateGeometrySRID('sp_merged_c1200_alt_clip_clean','the_geom',4326);

drop index if exists sp_merged_c1200_alt_clip_clean_geom_gist;
CREATE INDEX sp_merged_c1200_alt_clip_clean_geom_gist ON sp_merged_c1200_alt_clip_clean USING GIST (the_geom);
CLUSTER sp_merged_c1200_alt_clip_clean USING sp_merged_c1200_alt_clip_clean_geom_gist;
ANALYZE sp_merged_c1200_alt_clip_clean;

create index sp_merged_c1200_alt_clip_clean_index_id_no1 on sp_merged_c1200_alt_clip_clean (id_no1);
create index sp_merged_c1200_alt_clip_clean_index_season on sp_merged_c1200_alt_clip_clean (season);

select * from sp_merged_c1200_alt_clip_clean limit 10;

    SET search_path=cci_2017,cci_2015,public,topology;
 
    --getting nodeids touching species
    drop table if exists int_grid_pas_trees_by_species_30106;
    create table int_grid_pas_trees_by_species_30106 as
    with 
	foo1 as 
(select * from grid_pas_trees_40postcent_30agg_diss_ovr1ha_t1_clean where ecoregion=30106 order by node_id limit 10),
foo3 as (select st_union(foo1.the_geom) as the_geom from foo1)
select 
    foo2.id_no1,
    foo2.season,
    foo1.node_id,
    foo1.grid_id,
    foo1.the_geom,
    foo1.the_geom_azim_eq_dist,
area,
    /*min(case when (wdpa>-1) then 1 else -1 end) as wdpa,*/
fid_corrid
    from
foo3, 
    foo1, 
	 sp_merged_c1200_alt_clip_clean as foo2
    where
	st_intersects(foo1.the_geom,foo2.the_geom)
and
st_intersects(foo3.the_geom,foo2.the_geom);


   --getting nodeids touching species
    drop table if exists int_grid_pas_trees_by_species_30106;
    create table int_grid_pas_trees_by_species_30106 as

    select 
    foo2.id_no,
    foo2.id_no1,
    foo2.season,
    foo1.node_id,
    foo1.grid_id,
    foo1.the_geom,
    foo1.the_geom_azim_eq_dist,
    min(foo1.area) as area,
    /*min(case when (wdpa>-1) then 1 else -1 end) as wdpa,*/
    min(foo1.fid_corrid) as fid_corrid
    from
	(select * from grid_pas_trees_40postcent_30agg_diss_ovr1ha_t1_clean where ecoregion=30106 order by node_id) 
    as foo1,
    /*(select id_no, st_makevalid(st_transform(st_buffer(the_geom,0),54032)) as the_geom from forest_aves_in_africa order by id_no)*/
    /*(select spp_id as id_no, the_geom  from sp_merged_all order by spp_id limit 200) */ 
    (
    select foo1.*, 
    left((REPLACE(foo1.id_no, 'sp_', '')), length((REPLACE(foo1.id_no, 'sp_', ''))) - 2)::bigint as id_no1,
    right(foo1.id_no,1)::int as season
    from 
    (select spp_id as id_no, the_geom as the_geom from sp_merged_c1200_alt_clip) as foo1
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
    foo1.grid_id,
    foo1.the_geom_azim_eq_dist
    ;