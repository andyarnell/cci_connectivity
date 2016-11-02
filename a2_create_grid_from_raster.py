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

rawFolder = "C:/Data/cci_connectivity/raw/mainland_grid"

tempFolder = "C:/Data/cci_connectivity/scratch"

outFolder=  "C:/Data/cci_connectivity/scratch/grids"

cellSize="4"

arcpy.env.workspace = rawFolder+"/"

aoi="half_degree_mainland_afr.shp"

rastName="/testRastGrid.tif"
rastName2="/testRastGrid2.tif"
fcName="grid_mainland_afr.shp"

    
print "Getting extent from: {0}".format(aoi)
desc = arcpy.Describe(aoi)
extent = desc.extent
extent= str(extent.XMin)+" "+str(extent.YMin) +" "+str(extent.XMax)+" "+str(extent.YMax)

coordSys=desc.spatialReference


print "Creating random raster"
arcpy.CreateRandomRaster_management(out_path=tempFolder+"/",out_name=rastName,distribution="NORMAL 0.0 10000000.0",raster_extent=extent, cellsize=cellSize)

arcpy.env.workspace = tempFolder+"/"

print "Making integer"
arcpy.gp.RasterCalculator_sa("""Int(rastName)""",rastName2)

print "Converting raster to polygon"
arcpy.RasterToPolygon_conversion(in_raster=rastName2,out_polygon_features=outFolder+"/"+fcName,simplify="NO_SIMPLIFY",raster_field="Value")

arcpy.Delete_management(rastName)
arcpy.Delete_management(rastName2)

arcpy.env.workspace = outFolder+"/"
gridCellID="cell_id"
arcpy.AddField_management(fcName,gridCellID,"LONG")
arcpy.CalculateField_management(fcName,field=gridCellID,
                                    expression="""!FID!+1""",
                                    expression_type="PYTHON_9.3")
arcpy.DeleteField_management(fcName,"ID")
arcpy.DeleteField_management(fcName,"GRIDCODE")
                     
arcpy.DefineProjection_management(fcName,coordSys)

print "Finished processing"

print("Total elapsed time (minutes): " + str((time.clock() - beginTime)/60))


