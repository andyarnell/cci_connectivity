##aim: aggregate high resolution datasets (with optional reclassification section)
##created by Andy Arnell 09/06/2015

print "Importing packages"

import os
import arcpy
from arcpy import env
from arcpy.sa import *
import glob
import string

import time

print "Setting local parameters and inputs"

# Check out the ArcGIS Spatial Analyst extension license
arcpy.CheckOutExtension("Spatial")

env.overwriteOutput = True

beginTime = time.clock()

arcpy.env.overwriteOutput = True 
#Set environment settings

# Check out Spatial Analyst extension license
arcpy.CheckOutExtension("Spatial")

rawFolder = "C:/Data/cci_connectivity/raw/hansen"

tempFolder = "C:/Data/cci_connectivity/scratch" 

reclFolder=tempFolder+"/reclass/"

aggFolder=tempFolder+"/aggregate/"

outFolder=tempFolder+"/forest/output/"

#amount to aggregate pixels
aggVal=30 
threshold=15
AggMethod = "Mean"

#substring to identify the rasters
wildCard = "treecover2000"

outFName="hansen_{0}_agg{1}.tif".format(wildCard,aggVal)
outReclFName="hansen_{0}_postpcent{1}_agg{2}.tif".format(wildCard,threshold,aggVal)


#for names in listNames:
env.workspace = rawFolder+"/"
raster_list = arcpy.ListRasters("*{}*".format(wildCard),"TIF")
print "Number of rasters to mosaic: "+str(len(raster_list))
#raster_list = [os.path.basename(x) for x in glob.glob(rawFolder+"/" + "/*.tif)]
dataset = rawFolder+"/" + raster_list[0]
spatial_ref = arcpy.Describe(dataset).spatialReference
#cellSize=arcpy.GetRasterProperties_management(dataset,"CELLSIZEX")
#print "test with two tiles"
##raster_list = raster_list[0:2]
print "Raster list from folder, contains the following files:" + str(raster_list)


beginTime1 = time.clock

i=0
print "Aggregating  rasters by factor: " + str(aggVal)
for raster in raster_list:
    outAggreg = Aggregate(raster, aggVal, AggMethod, "EXPAND", "DATA")
    outAggreg.save(aggFolder+str(raster))
    print "Aggegated raster no {0}: {1}".format(i,str(raster))
    i += 1


#print("Elapsed time (minutes): " + str((time.clock() - beginTime2)/60))

beginTime3 = time.clock()

print "Mosaic files to new raster"
#set new workspace and make new raster list
env.workspace = aggFolder
raster_list = arcpy.ListRasters("*{}*".format(wildCard),"TIF")
print "Number of rasters to mosaic: " + str(len(raster_list))
arcpy.MosaicToNewRaster_management(raster_list,outFolder,outFName,"#", pixel_type="32_BIT_FLOAT",cellsize="#",
                                   number_of_bands="1",mosaic_method="MEAN",mosaic_colormap_mode="MATCH")

print("Elapsed time (minutes): " + str((time.clock() - beginTime3)/60))

print "Using the {0} threshold on {1} to create a binary layer".format(threshold,outFName)
env.workspace = outFolder 
inRaster=Raster(outFName)
OutRaster = Con(inRaster>threshold,1,0)
OutRaster.save(outReclFName)
print "created binary layer {0}".format(outReclFName)

print "Deleting intermediate rasters from {0} and {1}".format(aggFolder,reclFolder)
env.workspace = aggFolder
raster_list = arcpy.ListRasters("*{}*".format(wildCard),"TIF")
print raster_list

for raster in raster_list:
        arcpy.Delete_management(raster)
        
print "Deleted intermediate rasters"

print "Finished processing"

print("Total elapsed time (minutes): " + str((time.clock() - beginTime)/60))



