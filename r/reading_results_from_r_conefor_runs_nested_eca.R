####Result aggregation### 
library(rgdal) 
library(sp)
library(rgeos)
library(raster)


rm(list=ls())

###aim: read in results from conefor and aggregate ###simple aggregation for PAs when ids match 
in_path1="C:/Data/cci_connectivity/scratch/conefor_runs/inputs/nested/for_gridcell_eca/ecoregions/Western_Guinean_lowland_forests/t0"
#in_path2="C:/Data/cci_connectivity/scratch/nodes"
out_path="C:/Data/cci_connectivity/scratch/conefor_runs/inputs/nested/for_gridcell_runs/ecoregions/Western_Guinean_lowland_forests/t0"


setwd(in_path1)
getwd()

#make list of node and distance files for conefor in the in_path2 folder
file_list <- list.files()

#selecting files, based on string recognition to select outputs
stringPattern="results_all_EC(PC)*"
file<-file_list[lapply(file_list,function(x) length(grep(stringPattern,x,value=FALSE))) == 1]
file
eca.df<-read.table(file,header=T)#read.table(inCSV)
eca.df<-data.frame(cbind(eca.df[1],eca.df[4]))
#substitute for "" after second "_" to give species id and season combined
x<-eca.df$Prefix
eca.df$id_no1<-gsub("^([^_]*_[^_]*)_.*$", "\\1", x)
#substitute for "" after second "_" to give gridcell id as the new node id for final conefor runs
eca.df$gridcell_id<-gsub('.*\\_', '', x)
eca.df$gridcell_id<-as.integer(eca.df$gridcell_id)
eca.df$EC.PC.<-as.numeric(eca.df$EC.PC.)
head(eca.df)

spList<-unique(eca.df$id_no1)

spList

for (i in 1:length(spList)){
  eca.df.sub<-subset(eca.df,eca.df$id_no1==eca.df$id_no1[i])
  suffix<-eca.df.sub$id_no1[1]
  print (suffix)
  out.df<-data.frame(cbind(eca.df.sub$gridcell_id,eca.df.sub$EC.PC.))
  out.name<-paste0(out_path,"/nodes_",suffix,".txt")
  print(out.name)
  write.table(out.df,out.name,col.names = FALSE,row.names = FALSE)
  }

