########Aim: project species to new coorodinate system
########Created by Andy Arnell 24/02/2016 
import arcpy
import time
import sys, calendar, datetime, traceback
from arcpy.sa import *


print "Setting local parameters and inputs"

# Check out the ArcGIS Spatial Analyst extension license
arcpy.CheckOutExtension("Spatial")

arcpy.env.overwriteOutput = True

beginTime = time.clock()

wkspce1 = "C:/Data/cci_connectivity/raw/species/alt_clipped_ranges_c1200spp_Feb2016"

wkspce2 =  "C:/Data/cci_connectivity/scratch/spp/geographic_coord"

trimRst = "C:/Data/cci_connectivity/scratch/forest/output/hansen_treecover2000_postpcent40_agg10.tif"

arcpy.env.workspace = wkspce1

print "Making list of rasters to trim from: " + wkspce1

rstList = arcpy.ListRasters()


#getting coordinate system of forest raster
desc=arcpy.Describe(trimRst)
coord=desc.spatialReference

print "Number of rasters to trim/refine: " + str(len(rstList))

print "Looping through rasters and projecting to coord system of forest:{0} /n Coord sys: {1}".format(trimRst,coord)

beginTime1 = time.clock()



i = 0
for rst in rstList:
    beginTime1a = time.clock()
    
    arcpy.ProjectRaster_management(rst,wkspce2+"/"+rst,coord)
    i += 1
    print "Processed raster number: {0} Filename: {1} in {2}/n".format (i,rst,str((time.clock() - beginTime1a)/60))
    
print("Elapsed time (minutes): " + str((time.clock() - beginTime1)/60))
