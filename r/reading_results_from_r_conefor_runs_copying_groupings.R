####Result aggregation### 
library(rgdal) 
library(sp)
library(rgeos)
library(raster)

###aim: read in results from conefor and aggregate ###simple aggregation for PAs when ids match 
in_path1="C:/Data/cci_connectivity/scratch/conefor_runs/inputs/test"
in_path2="C:/Data/cci_connectivity/scratch/nodes"
out_path="C:/Data/cci_connectivity/scratch/conefor_runs/outputs"

#get species ids from node files
setwd(in_path1)

#make list of node and distance files for conefor in the in_path2 folder
file_list <- list.files()

#selecting files, based on string recognition to select outputs
stringPattern="_node_importances.txt*"

stringPattern="nodes*"
file_list<-file_list[lapply(file_list,function(x) length(grep(stringPattern,x,value=FALSE))) == 1]
file_list
x<-file_list

######################################################
###add step to copy files where others in same group
#get list of files to run from "all_final_to_run_list.csv"
to_run.df<-read.csv("all_final_to_run_list.csv",header=TRUE)
#to_run<-to_run.df$to_run
#to_run<-as.character(to_run.df$file_list[which(to_run.df$to_run==1)])
#str(to_run)

##################
#remove this bit
file_list.remove<-file_list[which(!file_list %in% to_run)]
file_list.remove

for (fn in file_list.remove){
  if (file.exists(fn)) file.remove(fn)
}

to_run<-to_run.df[which(to_run.df$to_run==1),]
to_run<-data.frame(cbind(to_run$id_no,to_run$season))
names(to_run)<-c("id_no","season")
#to_run<-unique(to_run)
to_run<-droplevels(to_run)
#list files run
grp<-3

count<-1
for (grp in 1:length(to_run){
  #for each file that was run select the others files in that that group that were not run
  grp.run<-to_run[grp,]
  #grp.run
  grp.unrun<-to_run.df$dist_group[which(to_run.df$file_list==to_run.df$file_list[grp])]  
  grp.unrun<-to_run.df[which(to_run.df$dist_group==grp.unrun & to_run.df$to_run==0),]
  grp.unrun<-data.frame(cbind(grp.unrun$id_no,grp.unrun$season))
  names(grp.unrun)<-c("id_no","season")
  agg.res<-read.csv("conefor_outputs.csv",header=TRUE)#get csv of outputs from conefor
  ##version where copying results rows as opposed to the text files
  run.res<-agg.res[which(agg.res$id_no==paste0(grp.run$id_no,"_",grp.run$season)),] #if id_no column in results is concatonation of id_no and season
  ##or 
  #run.res<-agg.res[which(agg.res$id_no==grp.run$id_no & agg.res$season == grp.run$season)),] #if seperate id_no and season fields in results
                                   
  for (sp in 1:length(grp.unrun){
    #then loop through the species that were not run 
    run.res$id_no<-paste0(grp.unrun$id_no,"_",unrun$season) #if id_no column in results is concatonation of id_no and season
    #run.res$id_no<-grp.unrun$id_no   #if seperate id_no and season fields in results
    #run.res$season<-grp.unrun$season)     #if seperate id_no and season fields in results
    #for each one make a new copy of the file output that was run 
    if (count=1){
      agg.res.comb<-agg.res
    }else {
      agg.res.comb<-rbind(run.res,agg.res.comb)}
    #and renaming it to one of the ones that wasn't ran 
    count=count+1 
  }
}

write.csv(agg.res.com,"conefor_results_expanded_groups.csv",row.names=FALSE)

###################
file_list
to_run.df


agg_res<-data.frame()

for (i in 1:length(x)){
  res<-read.table(x[i],header=TRUE)
  str(res)
  #res<-subset(res,res$varPC>0)
  #res<-droplevels(res)
  dt<- strsplit(x[i],"_")[[1]]#splits string
  dt<-dt[c(TRUE,TRUE,FALSE,FALSE)]#chooses certain part to keep
  print (dt)
  res$id_no<-paste0(dt[1],"_",dt[2])
  print (res)
  agg_res<-rbind(agg_res,res)
}

write.csv(agg_res,"conefor_outputs.csv")

agg_res_vals<-read.csv("conefor_outputs.csv")
agg_res_vals_sub<-subset(agg_res_vals,agg_res_vals$varPC>0)
agg_res_vals_sub<-subset(agg_res_vals,agg_res_vals$varPC>0)
agg_res_vals_sub$ratio_varPC<-(agg_res_vals_sub$dA/agg_res_vals_sub$varPC)
agg_res_vals_sub$ratio_dPC<-(agg_res_vals_sub$dA/agg_res_vals_sub$dPC)
agg_res_vals_sub$count<-1
head(agg_res_vals_sub)


nodeOutVals<-aggregate(. ~ Node, agg_res_vals_sub,FUN=mean)
head(nodeOutVals)

list.files(, pattern='\\.shp$')
setwd(in_path2)

shp<-"grid_pas_trees_40postcent_30agg_diss_ovr1ha_subset_guinea"
spdf<-readOGR(".",shp)

head(spdf@data)

spdfMerge<-merge(spdf,nodeOutVals,by.x="nodeiddiss",by.y="Node")
head(spdfMerge@data)
spdfMerge@data$ratio1<-spdfMerge@data$varPC/spdfMerge@data$AREA_GEO
spdfMerge<-subset(spdfMerge,spdfMerge@data$ratio1>0)
plot(spdfMerge@data$ratio1~spdfMerge@data$varPC)

plot(spdfMerge@data$ratio_varPC~spdfMerge@data$dPC)

shapes<-spdfMerge

setwd(out_path)

writeOGR(shapes, ".", "nodes_out_res1", "ESRI Shapefile")
#shapefile("nodes_out_varPC.shp", object=shapes, overwrite=TRUE, verbose=FALSE)

