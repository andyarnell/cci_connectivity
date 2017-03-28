library(sp)
library(raster)
library(rgdal)
install.packages("spatialEco")
library(spatialEco)
library(maptools)
ogrDrivers()

#zonal statistics for buffers around euclidean distances


##rm(list=ls()) #clear workspace

wkspace1="C:/Data/cci_connectivity/scratch/intern/euclid/buffer/split"

wkspace2="C:/Data/cci_connectivity/scratch/intern/projected_res_rast/projected"

wkspace3="C:/Data/cci_connectivity/scratch/intern/zonal_euclid"

setwd(wkspace1)

fcList<-list.files(".",pattern=".shp",)

#fcList<-subset(grep(fcList,".xml", 'r'))
#fcList <- subset(a, x == glob2rx("blue*") )
fcList<-grep(glob2rx("*.xml*"), fcList, value=TRUE, invert=TRUE)
fcList


for (i in fcList[10:50]) {
  setwd(wkspace1)
  i=gsub(".shp", "", i)
  shp = readOGR(".", i)
  j<-as.character(i)
  setwd(wkspace2)
  j<-strsplit(j, "_")
  j<-unlist(j)
  j<-j[2]
  j = paste(j,".tif",sep = "")
  print(j)
  rst = raster(j)
  plot(rst)
  z.stats<-zonal.stats(x=shp, y=rst, stat=mean, trace = TRUE, plot = FALSE)
  z <- data.frame(ID=as.numeric(as.character(row.names(shp@data))),mean=z.stats) 
  print (z.stats)
  shp3<-cbind(shp,z)
  shp3$effectDist<-shp3$mean*shp3$dist
  setwd(wkspace3)
  write.csv(shp3,i,)
  write.csv(shp3,paste0(wkspace3,"/",i,".csv"),row.names=FALSE )
}


