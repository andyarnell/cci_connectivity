##aim: group clusters of polygons (nodes) together based on distance
##so that all polygons within that distance of each other have the same id.
#this aims to reduce number of nodes for later analyses 

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

#Set environment settings

rawFolder = "C:/Data/cci_connectivity/raw/hansen"

tempFolder = "C:/Data/cci_connectivity/scratch" 

outFolder=tempFolder+"/output/"

#distance to aggregate pixels
aggDist=2km 

#set to raw folder
env.workspace = rawFolder+"/"

inRast= "hansen_treecover2000_agg30"


rastBoolean = Int(SetNull(inRast<=30,1))

env.workspace = rawFolder+"/"

outRast=tempFolder+"/"+"bool_"+inRast
rastBoolean.save(tempFolder+"/"+"bool_"+inRast)

polyName = "hansen_treecover2000_agg30"


arcpy.RasterToPolygon_conversion(in_raster=boolRast,
                                 out_polygon_features=tempFolder+"/"+polyName,
                                 simplify="NO_SIMPLIFY",raster_field="Value")

arcpy.AddGeometryAttributes_management(Input_Features="test_shape",Geometry_Properties="AREA_GEODESIC;PERIMETER_LENGTH_GEODESIC",
                                       Length_Unit="KILOMETERS",Area_Unit="SQUARE_KILOMETERS",Coordinate_System="#")

arcpy.Buffer_analysis(in_features="test_shape",
                      out_feature_class="C:/Data/cci_connectivity/scratch/test_shape_buff.shp",
                      buffer_distance_or_field="2 Kilometers",
                      line_side="FULL",line_end_type="ROUND",
                      dissolve_option="ALL",dissolve_field="#")

arcpy.MultipartToSinglepart_management(in_features="test_shape_buff",
                                       out_feature_class="C:/Data/cci_connectivity/scratch/test_shape_buff_single.shp")

arcpy.CalculateField_management(in_table="test_shape_buff_single",field="ORIG_FID",
                                expression="[FID]+1",expression_type="VB",code_block="#")
