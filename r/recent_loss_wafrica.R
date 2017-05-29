
library(foreign)
library(sp)

setwd("C:/Thesis_analysis/Development_corridors/GIS/scratch/10km")
km10<- read.dbf("All_10km.dbf")

setwd("C:/Data/cci_connectivity/scratch/grid_cell_choice/20km/20km")
km20<- read.dbf("All_20km.dbf")

setwd("C:/Thesis_analysis/Development_corridors/GIS/scratch/30km")
km30<- read.dbf("All_30km.dbf")
setwd("C:/Thesis_analysis/Development_corridors/GIS/scratch/40km")
km40<- read.dbf("All_40km.dbf")


#list<- list(km10, km20, km30, km40)
#names(list)<- c("km10", "km20", "km30", "km40")
list<- list(km20)
names(list)<- c("km20")

str(list)
list.df<-data.frame(list)

#subset loss in 2014 
list.df<-cbind(list.df[1],round(list.df[16]*100)/400000000),2)
#add names
names(list.df)<-c("grid_id","loss2014")
#str(list.df)

#aggregate by grid cell
list.df.aggloss2014<-aggregate(list.df,by = list(list.df$grid_id),sum)
list.df.aggloss2014<-cbind(list.df.aggloss2014[2:3])

#explore what max loss was for 2014
#list.df.agg.maxloss2014<-subset(list.df.aggloss2014,list.df.aggloss2014$loss2014==max(list.df.aggloss2014$loss2014))

list.df.aggloss2014
write.csv(list.df.aggloss2014,"list_df_aggloss2014.csv",row.names=FALSE)

#subset for only those with loss in 2014
list.df.aggloss2014<-subset(list.df.aggloss2014,list.df.aggloss2014$loss2014!=0)

#select top 5%
n<-5
list.df.agg2014.top5pc<-subset(list.df.aggloss2014, loss2014 > quantile(loss2014, prob = 1 - n/100))
nrow(list.df.aggloss2014.top5pc)
#write to csv
help("write.csv")
write.csv(list.df.aggloss2014.top5pc,"list_df_aggloss2014_top5pc.csv",row.names=FALSE)
#listS<- lapply(list, function(x) aggregate(x, by= list(x$OBJECTID), sum))


#loss<- data.frame(sapply(listS, function(x) apply(x, 2, max)))
#names(listS)


#loss$km10 <- (loss$km10*100)/100000000
#loss$km20 <- (loss$km20*100)/400000000
#loss$km30 <- (loss$km30*100)/900000000
#loss$km40 <- (loss$km40*100)/1600000000

#apply(loss, 1, max)

#loss<- round(loss, 2)

