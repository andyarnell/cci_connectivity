#########################################
##creating resistance layers ###
## rasters for each species #####
#########################################


### Files needed:
## shapefile birds SUBSETTED for OUR 54 selected species: samplesps.csv
## landcover data : Landcover_LUT.txt
## Raster Africa Land cover, projected: glcprojected.tif




library(Matrix)
library(sp)  # vector data
library(raster)  # raster data
library(rgdal)  # input/output, projections
library(rgeos)  # geometry ops
library(spdep)  # spatial dependence


setwd("C:/Users/scienceintern/Documents/AndreaCB/Analysis/scratch/")
ogrDrivers()

##### LOAD Reading in shapefile birds SUBSETTED for OUR 54 selected species// (spShape) with species' shape ####

spShape = readOGR(".", "samplesps")
crs<-"+proj=aeqd +lat_0=0 +lon_0=0 +x_0=0 +y_0=0 +ellps=WGS84 +datum=WGS84 +units=m +no_defs"
spShape <-spTransform(spShape, crs) ## project polygons

##### LOAD in landcover data and do data check with names and structure ####
setwd("C:/Users/scienceintern/Documents/AndreaCB/Analysis/raw/")
Landcover_LUT<-read.table(file="Landcover_LUT.txt", header=TRUE)


#### create vector of OUR 54 species #### 

samplesps<-read.csv(file="samplesps.csv", header=TRUE)
names(samplesps)
spID<-as.vector(samplesps$num)

##### LOAD in Raster Africa Land cover (r) ####
setwd("C:/Users/scienceintern/Documents/AndreaCB/Analysis/scratch/")

## r <- raster("glc2000afr.tif") # original raster no projection in RAW
r<-raster("glcprojected.tif")

#plot(r)

################
##### LOOP #####

## to loop though for each ID in our selections 


setwd("C:/Users/scienceintern/Documents/AndreaCB/Analysis/scratch/projected")


### START ###
start.time <- Sys.time()

for(i in spID[41:54])
{
  start.time2 <- Sys.time()
  print (i)
  spRange <-spShape[spShape$id_no==i,] 
  #print (spRange@data$id_no)
  writeOGR(spRange, ".", i, "ESRI Shapefile")
  

  #print (extent(spRange))
  ##r3 <- mask(r2, spRange)
  ##writeRaster(r2, paste("test",i,".tif",  sep = ""),"GTiff",overwrite=TRUE)
  ## change extent dimentions
  
  ### set new extend
  x<-data.frame(spRange@bbox) #extract extent
  x$min<-x$min-100000 # change dimentions
  x$max<-x$max+100000 # change dimentions
  x<-as.vector(t(x)) # create vector 
  #x # new extent
  bb <- extent(x)
  
  ### Crop
  r2 <- crop(r, extent(bb))
  # plot(r2)
  # plot(spRange, add=TRUE, lwd=2)
  # str(extent(spRange))
  
  
  ### recode raster 
  sphab<-as.vector(Landcover_LUT$GLC2000code[Landcover_LUT$num== i])
  sphab<-unique(sphab)
  
  df<-data.frame(sphab,100)
  x<-subs(r2,df)
  x2<-subs(r2, df, subsWithNA=TRUE)
  x2[is.na(x2)]<-200
  
  ### reclassify
  m <- c(100, 1, 200, 2)
  rclmat <- matrix(m, ncol=2, byrow=TRUE)
  #View(rclmat)
  x2 <- reclassify(x2, rclmat)
  
  # ### project raster
  # 
  # crs<-"+proj=aeqd +lat_0=0 +lon_0=0 +x_0=0 +y_0=0 +ellps=WGS84 +datum=WGS84 +units=m +no_defs"
  # 
  # proj<-projectRaster(x2, r, method="ngb", alignOnly=FALSE, over=FALSE) 
  
  writeRaster(x2, paste(i,".tif",  sep = ""),"GTiff",overwrite=TRUE)
  rm(x2)
  rm(r2)

  end.time2 <- Sys.time()
  time.taken2 <- end.time2 - start.time2
  time.taken2
}


end.time <- Sys.time()
time.taken <- end.time - start.time
time.taken

#### END ###
############  
