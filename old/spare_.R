
##################################################
#ignore this step as above does it
#selecting species ranges intersecting corridors
strSQL="(select id_no1, season from (
select id_no, id_no1, season::int
from 
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
as foo1,
(select st_transform(the_geom_azim_eq_dist,4326) as the_geom, NAME, status from corridors_type_3_buff_agg) as foo2
where
st_intersects(foo1.the_geom,foo2.the_geom)
group by id_no, id_no1,season))" 
spList_t1<- dbSendQuery(con, strSQL)   ## Submits a sql statement
##place data in dataframe
spList_t1<-fetch(spList_t1,n=-1)
