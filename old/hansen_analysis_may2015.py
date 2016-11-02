##aim: analyse hansen data
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

tempFolder = "C:/Data/wwf_cea_2015/scratch"

rawFolder = "C:/Data/wwf_cea_2015/raw/"

listNames = ['cover','loss','gain', 'lossYr']

thresholdList = [10,30,50]


for names in listNames:
    env.workspace = rawFolder+names+"/"
    inFolder = rawFolder+names+"/"
    raster_list = [os.path.basename(x) for x in glob.glob(inFolder + "/*.tif")]
    dataset = inFolder + raster_list[0]
    spatial_ref = arcpy.Describe(dataset).spatialReference
    cellSize=arcpy.GetRasterProperties_management(dataset,"CELLSIZEX")
    #print ""+names+"with two tiles"
    #raster_list = raster_list[0:2]
    raster_list = str(raster_list).replace(",", ";")
    raster_list = str(raster_list).replace("'", "").strip('[]')
    print "Raster list from "+ names +" folder, contains the following files:" + raster_list
    print "Mosaic " + names + " files to new raster"
    arcpy.MosaicToNewRaster_management(raster_list,tempFolder,"mosaic_"+names+"_.tif","#", pixel_type="8_BIT_UNSIGNED",cellsize="#",number_of_bands="1",mosaic_method="LAST",mosaic_colormap_mode="MATCH")

print("Elapsed time (minutes): " + str((time.clock() - beginTime)/60))
beginTime2 = time.clock()

for names in listNames:
    inFolder = rawFolder+names+"/"
    raster_list = [os.path.basename(x) for x in glob.glob(inFolder + "/*.tif")]
    dataset = inFolder + raster_list[0]
    origCS = arcpy.Describe(dataset).spatialReference
    print('Defining projection (based on first tile used to create mosaic raster)')
    inRaster=tempFolder+"/"+"mosaic_"+names+"_.tif"
    arcpy.DefineProjection_management(inRaster,origCS)
    print('Projecting raster to equal-area')
    outCS = "C:/Users/andya/AppData/Roaming/ESRI/Desktop10.2/ArcMap/Coordinate Systems/Mollweide(world).prj"
    outRasterPrj=str(inRaster).replace(".tif","Prj.tif")
    outCS= """PROJCS["World_Mollweide",GEOGCS["GCS_WGS_1984",DATUM["D_WGS_1984",SPHEROID["WGS_1984",6378137.0,298.257223563]],PRIMEM["Greenwich",0.0],UNIT["Degree",0.0174532925199433]],PROJECTION["Mollweide"],PARAMETER["False_Easting",0.0],PARAMETER["False_Northing",0.0],PARAMETER["Central_Meridian",0.0],UNIT["Meter",1.0],AUTHORITY["ESRI",54009]]"""
    arcpy.ProjectRaster_management(inRaster,outRasterPrj,outCS,"BILINEAR")

for names in listNames:
    print "Calculating statistics and building pyramids"
    inFile = tempFolder+"/"+"mosaic_"+names+"_Prj.tif"
    arcpy.CalculateStatistics_management (inFile)
    arcpy.BuildPyramids_management (inFile)

print("Elapsed time (minutes): " + str((time.clock() - beginTime2)/60))
beginTime3 = time.clock()

for threshold in thresholdList:
    print "Reclassifying " + listNames[0] +" into binary layer using " + str(threshold) +"% threshold"
    inFile= tempFolder+"/"+"mosaic_"+listNames[0]+"_Prj.tif"
    out = Con(Raster(inFile)>threshold, 1,0)
    outFile = tempFolder+"/"+str(threshold)+"mosaic_"+listNames[0]+"_Prj.tif"
    out.save(outFile)

print("Elapsed time (minutes): " + str((time.clock() - beginTime3)/60))
beginTime4 = time.clock()

for threshold in thresholdList:
    print "Reclassifying " + listNames[1] +" into binary layer based on " + listNames[1] + " within "  + str(threshold) +"% threshold for "+ listNames[0]
    inFile1 = tempFolder+"/"+"mosaic_"+listNames[1]+"_Prj.tif"
    inFile2 = tempFolder+"/"+str(threshold)+"mosaic_"+listNames[0]+"_Prj.tif"
    out = Con(((Raster(inFile1)==1) & (Raster(inFile2) ==1)), 1, 0)
    outFile = tempFolder+"/"+str(threshold)+"mosaic_"+listNames[1]+"_Prj.tif"
    out.save(outFile)


print("Elapsed time (minutes): " + str((time.clock() - beginTime4)/60))
beginTime5 = time.clock()

for threshold in thresholdList:
    print "Calculating statistics and building pyramids"
    inFile = tempFolder+"/"+str(threshold)+"mosaic_"+listNames[1]+"_Prj.tif"
    arcpy.CalculateStatistics_management (inFile)
    arcpy.BuildPyramids_management (inFile)

print("Elapsed time (minutes): " + str((time.clock() - beginTime5)/60))

beginTime6 = time.clock()

for threshold in thresholdList:
    print "Reclassifying " + listNames[3] +" into binary layer based on " + listNames[3] + " within "  + str(threshold) +"% threshold for "+ listNames[0]
    inFile1 = tempFolder+"/"+"mosaic_"+listNames[3]+"_Prj.tif"
    inFile2 = tempFolder+"/"+str(threshold)+"mosaic_"+listNames[0]+"_Prj.tif"
    out = Con(((Raster(inFile1)==1) & (Raster(inFile2) >0)), (Raster(inFile2)), 0)
    outFile = tempFolder+"/"+str(threshold)+"mosaic_"+listNames[3]+"_Prj.tif"
    out.save(outFile)

for threshold in thresholdList:
    print "Calculating statistics and building pyramids"
    inFile = tempFolder+"/"+str(threshold)+"mosaic_"+listNames[3]+"_Prj.tif"
    arcpy.CalculateStatistics_management (inFile)
    arcpy.BuildPyramids_management (inFile)
    
#pas =
#paField = 

#for names in listNames:
    #outtable = 
    #outZonalStatistics = ZonalStatisticsAsTable(PAs, paField, outTable,"DATA","ALL")

print("Elapsed time (minutes): " + str((time.clock() - beginTime6)/60))

print "Finished processing"

print("Total elapsed time (minutes): " + str((time.clock() - beginTime)/60))



