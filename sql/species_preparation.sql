
--Aim: make a cleaner species layer
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