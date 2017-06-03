####Result aggregation### 
library(rgdal) 
library(sp)
library(rgeos)
library(raster)

###aim: read in results from conefor and aggregate ###simple aggregation for PAs when ids match 
in_path1="C:/Data/cci_connectivity/scratch/conefor_runs/inputs/nested/for_gridcell_eca"
#in_path2="C:/Data/cci_connectivity/scratch/nodes"
out_path="C:/Data/cci_connectivity/scratch/conefor_runs/for_gridcell_runs"

#if nested
selection_code<-c(TRUE,TRUE,TRUE,FALSE,FALSE)

#if normal run 
#selection_code<-c(TRUE,TRUE,FALSE,FALSE)

#get species ids from node files
setwd(in_path1)

#make list of node and distance files for conefor in the in_path2 folder
file_list <- list.files()

#selecting files, based on string recognition to select outputs
stringPattern="results_all_EC(PC)*"
file<-file_list[lapply(file_list,function(x) length(grep(stringPattern,x,value=FALSE))) == 1]
file
eca.df<-read.table(file,header=T)#read.table(inCSV)
head(eca.df)
eca.df<-data.frame(cbind(eca.df[1],eca.df[4]))
eca.df$Prefix<-data.frame(lapply(eca.df[1], as.character), stringsAsFactors=FALSE)
str(eca.df)
dt<- strsplit(eca.codes[2,],"_")[[1]]#splits string
eca.df$Prefix<-
data.frame(lapply(eca.codes, strsplit(x,"_")), stringsAsFactors=FALSE)
sapply(strsplit(eca.df[1], "_"), "[[", 1)
sapply(strsplit(eca.df[1], ""), function(a) a[1])
x<-as.list(eca.df[1])

lapply(x, function(x)strsplit(x, split='_')[[1]])
dt<-dt[c(selection_code)]#chooses certain part to keep
print (dt[1:2])

res$id_no<-paste0(dt[1],"_",dt[2])
