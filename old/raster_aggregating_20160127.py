##created by Andy Arnell 27/01/2016

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

rawFolder = "C:/Data/cci_connectivity/scratch/intersected_spp" 

outFolder = "C:/Data/cci_connectivity/scratch/intersected_spp" 

tempFolder = "C:/Data/cci_connectivity/scratch"

env.workspace = rawFolder+"/"


fcList=arcpy.ListFeatureClasses("*int_*")
i=0

print fcList

in_feature_class =outFolder+"/"+"_"+fc

for fc in fcList[0:1]:
    beginTime2 = time.clock()
    print "Aggregating nodes using a raster buffer: \nN.B. currently this is lat long only and so varies with latitude, \n so further work could involve a equal area or equidistant version."
    cellSize = "0.005"
    expansionFactor="1"
    print "Cellsize is {0} and expansion is {1}".format(cellSize,expansionFactor)
    rast = tempFolder + "/" + "tempRast.tif"
    rastExp = tempFolder + "/" + "tempRastExp.tif"
    memoryFeature="in_memory" + "\\" + "myMemoryfeature"
    print "Converting to raster"
    arcpy.FeatureToRaster_conversion(in_features=out_feature_class,
                                 field="nodetypes",
                                 out_raster=rast,
                                 cell_size=cellSize)
    print "Expsnding raster"
    arcpy.gp.Expand_sa(rast,
                   rastExp,
                   expansionFactor,"1;-1")
    print "Converting expanded raster to vector"
    arcpy.RasterToPolygon_conversion(in_raster=rastExp,
                                 out_polygon_features=memoryFeature,
                                 simplify="NO_SIMPLIFY",raster_field="Value")
    print "Aggregating based on spatial join of the main featureclass to the newly expanded vecotr"
    in_feature_class = rawFolder+"/"+fc
    out_feature_class =outFolder+"/"+"nde_"+fc
    arcpy.SpatialJoin_analysis(target_features=in_feature_class,
                               join_features=memoryFeature,
                               out_feature_class=out_feature_class,
                               join_operation="JOIN_ONE_TO_MANY",join_type="KEEP_ALL",
                               #field_mapping="""cell_id "cell_id" true true false 9 Long 0 9 ,First,#,int_sp_agelastesniger_projectras,cell_id,-1,-1;patchID "patchID" true true false 9 Long 0 9 ,First,#,int_sp_agelastesniger_projectras,patchID,-1,-1;nodetypes "nodetypes" true true false 4 Short 0 4 ,First,#,int_sp_agelastesniger_projectras,nodetypes,-1,-1;node_id "node_id" true true false 9 Long 0 9 ,First,#,int_sp_agelastesniger_projectras,node_id,-1,-1;AREA_GEO "AREA_GEO" true true false 19 Double 0 0 ,First,#,int_sp_agelastesniger_projectras,AREA_GEO,-1,-1;cellBuffID "cellBuffID" true true false 9 Long 0 9 ,First,#,int_sp_agelastesniger_projectras,cellBuffID,-1,-1;ID "ID" true true false 10 Double 0 10 ,First,#,test_expand_ap,ID,-1,-1""",
                               match_option="INTERSECT",search_radius="#",distance_field_name="#")
    arcpy.Delete_management(in_feature_class)
    
    nodeAggField = "nodeAggID"
    print "Adding and calculating aggregated node ids to this field: {0}".format(nodeAggField)
    arcpy.AddField_management(out_feature_class,nodeAggField,"Long")
    arcpy.CalculateField_management(out_feature_class,field=nodeAggField,
                                    expression="""int((str(!cellBuffId!)) +str(int(!id!)))""",
                                    expression_type="PYTHON_9.3")
    print "Dissolving by field conatining aggregated node IDs: {0}".format(nodeAggField)
    in_feature_class = out_feature_class
    out_feature_class =outFolder+"/"+"dis_"+fc
    arcpy.Dissolve_management(in_features=in_feature_class,
                              out_feature_class=out_feature_class,
                              dissolve_field=nodeAggField,
                              statistics_fields="AREA_GEO SUM;cell_id FIRST;nodetypes FIRST",
                              multi_part="MULTI_PART",unsplit_lines="DISSOLVE_LINES")
    print "Deleting temp files"
    arcpy.Delete_management(rast)
    del(rast)
    arcpy.Delete_management(rastExp)
    del(rastExp)
    arcpy.Delete_management(memoryFeature)
    del(memoryFeature)
    #arcpy.Delete_management(in_feature_class)
    i += 1
    print "Processed featureclass number: {0} Filename: {1} \n".format (i,fc)
    print("Total time (minutes): " + str((time.clock() - beginTime2)/60))

print "Finished processing"
print("Total elapsed time (minutes): " + str((time.clock() - beginTime)/60))

