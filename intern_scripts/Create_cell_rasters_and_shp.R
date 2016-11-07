#### clip rasters to cell size - shape file####

library(Matrix)
library(sp)  # vector data
library(raster)  # raster data
library(rgdal)  # input/output, projections
library(rgeos)  # geometry ops
library(spdep)  # spatial dependence


### LOAD raster####
      setwd("C:/Users/scienceintern/Documents/AndreaCB/Analysis/scratch/")
      
      r<-raster("glcprojected.tif")
      
      
##### LOAD in landcover data and do data check with names and structure ####
      setwd("C:/Users/scienceintern/Documents/AndreaCB/Analysis/scratch/")
      Landcover_LUT<-read.table(file="Landcover_LUT.txt", header=TRUE)
      
      #View(Landcover_LUT)
    
##### LOAD SHAPEFILES for cells in one FILE together ####
      setwd("C:/Users/scienceintern/Documents/AndreaCB/CircuitScape/raw/Append_clipped/")
      
      ogrDrivers()
      
      spShape = readOGR(".", "append_clip_sel")
      crs<-"+proj=aeqd +lat_0=0 +lon_0=0 +x_0=0 +y_0=0 +ellps=WGS84 +datum=WGS84 +units=m +no_defs"
      spShape <-spTransform(spShape, crs) ## project polygons
      
####  Species LIST from shapefile $shp_num ####
      
      appsample<-spShape@data[,c("shp_num")]
      #View(appsample)
      appsample<-as.vector(appsample)
      appsample<-unique(appsample)

      
##########################################

########### LOOP #####
      
setwd("C:/Users/scienceintern/Documents/AndreaCB/CircuitScape/raw/rasters_and_shp_cells")
      
      
      start.time <- Sys.time()
      
      for(i in appsample)
      {
        
        start.time2 <- Sys.time()
        print (i)
        spRange <-spShape[spShape@data$shp_num==i,]
        
        crs<-"+proj=aeqd +lat_0=0 +lon_0=0 +x_0=0 +y_0=0 +ellps=WGS84 +datum=WGS84 +units=m +no_defs"
        spRange <-spTransform(spRange, crs) ## project polygons
        writeOGR(spRange, ".", i, "ESRI Shapefile")
        
        # 
        
        #print (extent(spRange))
        ##r3 <- mask(r2, spRange)
        ##writeRaster(r2, paste("test",i,".tif",  sep = ""),"GTiff",overwrite=TRUE)
        ## change extent dimentions
        
        ### set new extend
        x<-data.frame(spRange@bbox) #extract extent
        x$min<-x$min-75000 # change dimentions
        x$max<-x$max+75000 # change dimentions
        x<-as.vector(t(x)) # create vector 
        #x # new extent
        bb <- extent(x)
        
        ### Crop
        r2 <- crop(r, extent(bb))
        
        
        #### split i
        
        j<-as.character(i)
        j<-strsplit(j, "_")
        j<-unlist(j)
        j<-j[2]
        print(j)
        
        
        ####
        ### recode raster 
        sphab<-as.vector(Landcover_LUT$GLC2000code[Landcover_LUT$num== j])
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
      
########## END ######
#######################
 