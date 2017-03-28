#It loads a raster where the land = 1; sea = 0; and the cells of a protected areas had an ID (all cells within a protected area have the same ID). 
#The code first identifies the ID and find their coordinates, and then calculates the distance from each patch to all other patch within a certain radius.
#It provides a csv file with a many duplicated rows, and rows with distances with land or with the sea. These records will have to be removed later. 

library(raster)

mappa<-raster("africa")

#TO GET THE COORDINATES FROM ALL PATCHES
# convert raster to points
p <- data.frame(rasterToPoints(mappa))
names(p)<-c("x","y","patch")
# filter out packground
p <- p[p$patch > 1,]
# for each patch calc mean coordinates
patches_coordinates<-sapply(split(p[, c("x", "y")], p$patch), colMeans)

tabella<-NULL

patches<-unique(mappa) #takes patch values
patches<-patches[-c(1,2)] #remove 0 e 1 that correspond to sea and dry lands

n<-0

rasterOptions(tmpdir='/tmp/R_raster_tmp_luca')

	for (patch in patches) #the loop runs through each patch
{
	coordinates<-patches_coordinates[,colnames(patches_coordinates)==patch] #takes coordinates of all cells of a given patch
	ext<-extent(coordinates[1]-9, coordinates[1]+9, coordinates[2]-9, coordinates[2]+9) #calculates an extent of the region expanding by the search radius
	window<-crop(mappa,ext) #set the region with the extent calculated above
	dist<-gridDistance(window, origin=patch, omit=0) #calculates the map of distances from the patch
	data<-zonal(dist, window, min) #takes the minimum value
	data2<-cbind(patch,data) #add the patch ID from which distances have been calculated to the table with distances
	tabella<-rbind(tabella, data2) #add the results to the table
	n<-n+1
	print(n)
	removeTmpFiles()
}

 write.csv(tabella, "/data/userdata/luca/mappe/distanze/africa.csv")