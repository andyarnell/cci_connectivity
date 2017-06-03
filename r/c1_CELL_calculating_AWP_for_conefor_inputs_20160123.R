#Aim: calculate the area weighted probability of dispersal between cells based on the individual distances between all the nodes in the cells.
#Andy Arnell 25/02/2016
#install.packages("gdata")
library(gdata) 
rm(list=ls())

#calculate probabilities
in_path1<-"C:/Data/cci_connectivity/scratch/dispersal"
in_path2<-"C:/Data/cci_connectivity/scratch/conefor_runs/inputs/by_species"
#make sure it's not the same as in path else will overwrite
out_path<-"C:/Data/cci_connectivity/scratch/conefor_runs/inputs/nested/for_gridcell_awp"

#get dispersal constants by species
setwd(in_path1)
Dist<- read.csv("dispersal_estimates.csv", h=T)
Dist<- Dist[,c(5,20)]
colnames(Dist) [1]<- "id_no"
colnames(Dist) [2]<- "Disp_mean"

#geting dispersal distances from csv
#make a list of files
setwd(in_path2)
file_list<- list.files()
file_list


#get distances
string_pattern<- "distances_*"
#choose only the distance files
file_list<- file_list[lapply(file_list, function(x) length(grep(string_pattern, x, value=FALSE))) ==1 ]
file_list

for (i in 1:length(file_list)){
  inCSV<-file_list[i]
  spp<-read.table(inCSV,header=F)#read.table(inCSV)
  #look up table for areas of nodes (using nodes file)
  inCSV2<-sub("distances","nodes",file_list[i])
  spp.lut<-read.table(inCSV2,header=F)#read.table(inCSV)
  #if nodetypes column present (last column isn't area) then remove it
  spp.lut$V3<-NULL
  #join (merge) lut to distances file (twice as using from_nodeid and to_nodeid columns) to give from_areas and to_areas
  #first merge
  spp.merge<-merge(spp,spp.lut,by.x="V1",by.y="V1",all.x=TRUE)
  str(spp.merge)
  #names(spp.merge)<-c("V1","V2","V3","V4","V5","V6")
  #second merge
  spp.merge<-merge(spp.merge,spp.lut,by.x="V2.x",by.y="V1",all.x=TRUE)
  str(spp.merge)
  spp.merge<-data.frame(cbind(spp.merge$V1,spp.merge$V2.x,spp.merge$V3,spp.merge$V2.y,spp.merge$V2,spp.merge$V4,spp.merge$V5))
  spp<-spp.merge
  colnames(spp) <- c("fromNodeID","toNodeID","dist","fromArea","toArea","fromCellID","toCellID")
  head(spp)
  #duplicating incase not all distances are present (this will be undone)
  spp1<-spp
  spp2<-data.frame(cbind(spp$toNodeID,spp$fromNodeID,spp$dist,spp$toArea,spp$fromArea,spp$toCellID,spp$fromCellID))
  names(spp2)<-names(spp1)
  #appending to make duplication of links but this is fixed in next section where only from one cell to another cells occurs 
  spp<-rbind(spp1,spp2)
  head(spp1)
  head(spp2)
  
  #remove ducplicates
  spp<-(unique(spp))
  spp
  #remove distances within cells
  spp<-subset(spp,spp$fromCellID!=spp$toCellID)
  spp<-subset(spp,spp$fromCellID>spp$toCellID)
  #spp<-subset(spp,spp$fromNodeID<spp$toNodeID)###NOT SURE ABOUT THISSSSSSSSSSSSSSSS???
  
  #get species id from file name
  file<-file_list[i]
  id_no1<- strsplit(file,"_")[[1]]#splits string
  id_no1<-id_no1[c(FALSE,TRUE,FALSE)]#chooses certain part to keep
  id_no1<-as.integer(id_no1)
  id_no1
  
  #get est median dispersal distances for each species
  inP=0.36788
  Dist.sub<-subset(Dist,Dist$id_no==id_no1)
  dispConst<-Dist.sub$Disp_mean*1000
  dispConst
  
  spp$prob<-exp(-(-1*(log(inP)/dispConst)) * spp$dist)
  head(spp)
  #product of probability and toArea
  spp$ProdProbArea<-spp$prob*spp$toArea
  
  
  numbDecPlaces<- 7 #number of decimal places for intercell prob in output (not much need after say 6 or 7 decimal places I would think)
  
  aggdata <-aggregate(spp, by=list(spp$fromCellID,spp$toCellID,spp$fromNodeID,spp$fromArea),
                      FUN=sum, na.rm=TRUE)
  head(aggdata)
  aggdata$fromNodeToCellProb<-aggdata$ProdProbArea/aggdata$toArea
  spp.agg<-aggdata
  spp.agg[,15]<-spp.agg[,14]*spp.agg[,4]
  head(spp.agg)
  spp.agg1<-data.frame(cbind(spp.agg[,1],spp.agg[,2],spp.agg[,4],spp.agg[,15]))
  spp.agg2 <-aggregate(spp.agg1, by=list(spp.agg1[,1],spp.agg1[,2]),FUN=sum, na.rm=TRUE)
  colnames(spp.agg2) <- c("fromCellID","toCellID","old1","old2","fromAreaSum","fromNodeToCellProbPRodAreaSum")
  spp.agg2<-subset(spp.agg2,fromCellID!=toCellID)#no need to calculate prob to own cell
  spp.agg2$areaWeightedAvg<-spp.agg2$fromNodeToCellProbPRodAreaSum/spp.agg2$fromAreaSum
  spp.agg2$areaWeightedAvg<-round(spp.agg2$areaWeightedAvg,numbDecPlaces)
  spp.agg3<-subset(spp.agg2,select=c(fromCellID,toCellID,areaWeightedAvg))
  head(spp.agg3)
  inCSV<- sub("\\..*", ".txt", inCSV)
  outTable<-paste0(out_path,"/",inCSV)
  write.table(spp.agg3,outTable,sep="\t",row.names=F,col.names=F)
  }
