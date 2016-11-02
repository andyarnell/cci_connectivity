#Aim: calculate the area weighted probability of dispersal between cells based on the individual distances between all the nodes in the cells.
#Andy Arnell 25/02/2016
#install.packages("gdata")
library(gdata) 
rm(list=ls())

dispConst=100000
inP=0.36788

         
setwd("C:/Data/cci_connectivity/scratch/conefor_runs/eca_runs/interCell/raw_dist")
getwd()
inCSV<-"AWP_agelastesniger.txt"#"AWP_method_check.csv"
#inCSV<-"AWP_method_check.txt"
spp<-read.table(inCSV,header=F)#read.table(inCSV)
str(spp)
head(spp)
#spp2<-subset(spp,select=-V2)  

colnames(spp) <- c("inNodeID","nearNodeID","dist","inArea","nearArea","inCellID","nearCellID","prob","ProdProbArea")
numbDecPlaces<-4 #number of decimal places for intercell prob in output (not much need after say 6 or 7 decimal places I would think)

#spp$prob<-exp(-(-1*(log(inP)/dispConst))*spp$dist)
#spp$ProdProbArea<-spp$prob*spp$nearArea
aggdata <-aggregate(spp, by=list(spp$inCellID,spp$nearCellID,spp$inNodeID,spp$inArea),
                    FUN=sum, na.rm=TRUE)
head(aggdata)
aggdata$inNodeToCellProb<-aggdata$ProdProbArea/aggdata$nearArea
spp.agg<-aggdata
spp.agg[,15]<-spp.agg[,14]*spp.agg[,4]
head(spp.agg)
spp.agg1<-data.frame(cbind(spp.agg[,1],spp.agg[,2],spp.agg[,4],spp.agg[,15]))
spp.agg2 <-aggregate(spp.agg1, by=list(spp.agg1[,1],spp.agg1[,2]),FUN=sum, na.rm=TRUE)
colnames(spp.agg2) <- c("inCellID","nearCellID","old1","old2","inAreaSum","inNodeToCellProbPRodAreaSum")
spp.agg2<-subset(spp.agg2,inCellID!=nearCellID)#no need to calculate prob to own cell
spp.agg2$areaWeightedAvg<-spp.agg2$inNodeToCellProbPRodAreaSum/spp.agg2$inAreaSum
spp.agg2$areaWeightedAvg<-round(spp.agg2$areaWeightedAvg,numbDecPlaces)
spp.agg3<-subset(spp.agg2,select=c(inCellID,nearCellID,areaWeightedAvg))
head(spp.agg3)
inCSV<- sub("\\..*", ".txt", inCSV)
outTable<-paste("prob_",inCSV)
write.table(spp.agg3,outTable,sep="\t",row.names=F,col.names=F)

