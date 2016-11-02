#The vector map to be loaded must have only the polygons of the protected areas with a unique ID, and must be in latlong projection

#Load packages
library(maptools)
library(rgeos)
library(rgdal)

#Load shapefile in latlong projection
au_ll<-readShapePoly("/Users/Oritteropus/Desktop/Progetti/Global_PA_Network/mappe/Africa/Africa", IDvar="wdpaid", proj4string=CRS("+proj=longlat +datum=WGS84"))

#To calculate distances with gDistance function, each polygon must be "single part", so in this step I make an MCP of all multipart polygons
au_ll2<-gConvexHull(au_ll, byid=TRUE)

#create a vector of polygons
id<-as.numeric(names(au_ll2))

#OUTPUT FILE
OUT<-data.frame(ID1=numeric(), ID2=numeric(), Distance_m=numeric())

#loops through all polygons ID, it calculates the distances from each polygon to all other polygons (it doesn't calculate the distance with the polygons for which distance has already been computed)
for (i in 1:length(id))
{
	print(paste(i," of ", length(id), sep=''))

if (i==length(au_ll2)) {break} #The loop stops when reaches the last polygon (distances for this have already been calculated in previous iterations)

cent<-coordinates(au_ll2[i,]) #takes the ceontroid of the polygon
au_eq<-spTransform(au_ll2, CRS(paste("+proj=aeqd +lon_0=",cent[1,1]," +lat_0=",cent[1,2], sep=""))) #re-project to azimutal equidistant projection, setting the azimut on the polygon
au_eq<-createSPComment(au_eq, which=NULL, overwrite=TRUE) #necessary to assign polygons' holes to each polygon

temp<-gDistance(au_eq[i,], au_eq[(i+1):length(au_eq),], byid = TRUE) #calculate distances from the polygon to all other polygons except previous ones
temp<-cbind(rep(id[i], nrow(temp)),rownames(temp),temp) #adds 2 new columns with the polygon ID from which distance is calculated, and the polygon ID of the other polygons
temp<-as.data.frame(temp) #convert to dataframe
rownames(temp)<-NULL #remove row names
names(temp)<-c('ID1', 'ID2', 'Distance_m') #names columns
if(nrow(temp)>0) {OUT<-rbind(OUT, temp)} #attach to the output file
else {print ("End")}
} #close loop

OUT<-apply(OUT, 2, as.numeric) #for some reasons the values are considered as characters, I convert them to numeric

#saves output file
write.csv(OUT, "Distances.csv", row.names=FALSE)


