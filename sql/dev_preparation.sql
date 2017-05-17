--but still have access to tables and most importantly functions in the public schema


CREATE SCHEMA IF NOT EXISTS cci_2017; 

SET search_path=cci_2017,cci_2015,public,topology;


--find/display current path for sql processing 
SHOW search_path;



--find/display current path for sql processing 
SHOW search_path;



--if postgis/postgresql running locally on desktop increase access to memory (RAM) 
SET work_mem TO 120000;
SET maintenance_work_mem TO 120000;




---------corridors
--making a new clean corridor dataset
drop table if exists dev_forest_loss_40;
create table dev_forest_loss_40 as
select *, st_buffer(st_transform(the_geom,54032),0) as the_geom_azim_eq_dist 
from loss_ovr40pcent;


drop index if exists dev_forest_loss_40_geom_gist;
CREATE INDEX dev_forest_loss_40_geom_gist ON dev_forest_loss_40 USING GIST (the_geom_azim_eq_dist);
CLUSTER dev_forest_loss_40 USING dev_forest_loss_40_geom_gist;
ANALYZE dev_forest_loss_40;

