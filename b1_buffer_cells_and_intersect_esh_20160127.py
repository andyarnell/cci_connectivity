##aim: take analysis cells
##buffer cells by species dispersal distances
##intersect these with species extent of suitable habitat (ESH)

##created by Andy Arnell 11/01/2016

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

rawFolder = "C:/Data/cci_connectivity/scratch/spp_refined/40pcent/vector"

outFolder = "C:/Data/cci_connectivity/scratch/intersected_spp" 

tempFolder = "C:/Data/cci_connectivity/scratch"

env.workspace = rawFolder+"/"

inCells = "C:/Data/cci_connectivity/scratch/grids/grid_mainland_afr.shp" 


fcList=arcpy.ListFeatureClasses()
i=0


for fc in fcList[0:20]:
    beginTime2 = time.clock()
    dist = 250
    buffDist = str(dist)+" Kilometers"
    print "Buffering cells for {0} by {1}".format(fc, buffDist)
    memoryFeature = "in_memory" + "\\" + "myMemoryFeature"
    arcpy.MakeFeatureLayer_management (inCells, memoryFeature)
    arcpy.SelectLayerByLocation_management (memoryFeature, 'intersect', fc)
    memoryFeatureBuff = "in_memory" + "\\" + "myMemoryFeatureBuff"
    arcpy.Buffer_analysis(in_features= memoryFeature,out_feature_class=memoryFeatureBuff,
                          buffer_distance_or_field=buffDist,line_side="OUTSIDE_ONLY",
                          line_end_type="ROUND",dissolve_option="NONE",dissolve_field="#")
    arcpy.DeleteField_management(memoryFeatureBuff,"ORIG_FID")
    print "Merging cells and buffers"
    inputs=memoryFeatureBuff+" ; "+memoryFeature
    mergedCellBf=outFolder+"/"+"cell_bf_"+fc
    arcpy.Merge_management(inputs,mergedCellBf)
    print "Merged features"
    print "Intersecting merged cells and buffers with species"
    in_features = """{0} #; {1} #""".format(mergedCellBf,fc)
    out_feature_class =outFolder+"/"+"int_"+fc
    arcpy.Intersect_analysis(in_features, out_feature_class,join_attributes="NO_FID",cluster_tolerance="#",output_type="INPUT")
    print "Removing unnecesary fields and adding useful fields"
    arcpy.DeleteField_management(out_feature_class,"ORIG_FID")
    arcpy.AddField_management(out_feature_class,"nodetypes","Short")
    arcpy.CalculateField_management(out_feature_class,field="nodetypes",
                                    expression="""myCalc(!BUFF_DIST!)""",
                                    expression_type="PYTHON_9.3",
                                    code_block="""def myCalc (x):
                                                  if (x> 0):
                                                      return -1
                                                  else:
                                                      return 1""")
    arcpy.AddField_management(out_feature_class,"nodetypes","Short")

    arcpy.AddField_management(out_feature_class,"cellBuffID","Long")
    arcpy.CalculateField_management(out_feature_class,field="cellBuffID",
                                    expression="""int((str(!nodetypes!)) +str(!cell_id!))""",
                                    expression_type="PYTHON_9.3")
    print """Adding and populating 'node_id' field"""
    arcpy.AddField_management(out_feature_class,"node_id","LONG")
    arcpy.CalculateField_management(out_feature_class,field="node_id",
                                    expression="!FID!+1",
                                    expression_type="PYTHON_9.3")
    arcpy.DeleteField_management(out_feature_class,"BUFF_DIST")
    
    print "Adding geometry (area) attributes for each node"
    arcpy.AddGeometryAttributes_management (out_feature_class,
                                      Geometry_Properties="AREA_GEODESIC",
                                      Length_Unit="#",
                                      Area_Unit="SQUARE_KILOMETERS",
                                      Coordinate_System="#")
    print "Deleting temp files"
    arcpy.Delete_management(memoryFeature)
    del(memoryFeature)
    arcpy.Delete_management(memoryFeatureBuff)
    del(memoryFeatureBuff)
    arcpy.Delete_management("bf_"+fc)
    ###arcpy.Delete_management(mergedCellBf)
    ############
    print "Highlighting isolated fragments using a raster buffer: \nN.B. currently this is lat long only and so varies with latitude, \n so further work could involve an equal area or equidistant version."
    cellSize = "0.005"
    expansionFactor="5"
    print "Cellsize is {0} and expansion is {1}".format(cellSize,expansionFactor)
    rast = tempFolder + "/" + "tempRast.tif"
    rastExp = tempFolder + "/" + "tempRastExp.tif"
    memoryFeature=tempFolder + "/" + "tempFeatExp.shp"#"in_memory" + "\\" + "myMemoryfeature"
    print "Converting to raster"
    arcpy.FeatureToRaster_conversion(in_features=out_feature_class,
                                 field="nodetypes",
                                 out_raster=rast,
                                 cell_size=cellSize)
    print "Expanding raster"
    arcpy.gp.Expand_sa(rast,
                   rastExp,
                   expansionFactor,"1;-1")
    print "Converting expanded raster to vector"
    arcpy.RasterToPolygon_conversion(in_raster=rastExp,
                                 out_polygon_features=memoryFeature,
                                 simplify="NO_SIMPLIFY",raster_field="Value")
    memoryFeature2=tempFolder + "/" + "tempFeatExpDiss.shp"
    print "Ensuring unique ids are added to each seperate polygon:"
    print "a) dissolving to join any features in contact with each other"
    arcpy.Dissolve_management(in_features=memoryFeature,out_feature_class=memoryFeature2)
    memoryFeature=tempFolder + "/" + "tempFeatExpDissMS.shp"
    print "b) single part to multipart tool to split into seperate features"
    arcpy.MultipartToSinglepart_management(in_features=memoryFeature2,out_feature_class=memoryFeature)
    print "c) adding IDagg field"
    arcpy.AddField_management(memoryFeature,"IDagg","Long")
    print "d) populating the IDagg field with unique values for individual features"
    arcpy.CalculateField_management(memoryFeature,field="IDagg",
                                    expression="!FID!+1",
                                    expression_type="PYTHON_9.3")
    print "Aggregating based on spatial join of the main featureclass to the newly expanded vector"
    in_feature_class = fc
    out_feature_class =outFolder+"/"+"isol_"+fc
    arcpy.SpatialJoin_analysis(target_features=in_feature_class,
                               join_features=memoryFeature,
                               out_feature_class=out_feature_class,
                               join_operation="JOIN_ONE_TO_ONE",join_type="KEEP_ALL",
                               match_option="INTERSECT",search_radius="#",distance_field_name="#")
    #arcpy.Delete_management(in_feature_class)
    
    nodeAggField = "IDagg"
    print "Adding geometry (area) attributes for each node"
    arcpy.AddGeometryAttributes_management (out_feature_class,
                                      Geometry_Properties="AREA_GEODESIC",
                                      Length_Unit="#",
                                      Area_Unit="SQUARE_KILOMETERS",
                                      Coordinate_System="#")
    print "Dissolving by field containing aggregated node IDs: {0}".format(nodeAggField)
    in_feature_class =out_feature_class
    out_feature_class =outFolder+"/"+"islD_"+fc
    arcpy.Dissolve_management(in_features=in_feature_class,
                              out_feature_class=out_feature_class,
                              dissolve_field=nodeAggField,
                              statistics_fields="AREA_GEO SUM;Join_Count SUM",
                              multi_part="MULTI_PART",unsplit_lines="DISSOLVE_LINES")
    arcpy.Delete_management(rast)
    del(rast)
    arcpy.Delete_management(rastExp)
    del(rastExp)
    #arcpy.Delete_management(memoryFeature)
    del(memoryFeature)
    in_feature_class =out_feature_class
    memoryFeature="in_memory\\tempFeatExp.shp"
    memoryFeature2="in_memory\\tempFeatEx2.shp"
    minIsolPatchArea=2
    expression= """  "SUM_AREA_G" < {0} AND "SUM_Join_C" <2 """.format(minIsolPatchArea)
    print "Creating feature layer with those features under a certain size ({0}) and isolated"
    arcpy.MakeFeatureLayer_management(in_feature_class,memoryFeature,where_clause=expression)
    out_feature_class=outFolder+"/"+"intemp_"+fc
    arcpy.CopyFeatures_management(memoryFeature,out_feature_class)
    del(in_feature_class)
    in_feature_class =outFolder+"/"+"int_"+fc
    arcpy.MakeFeatureLayer_management(in_feature_class,memoryFeature2)
    print "Selecting by location any isolated, small features, removing them and creating a new layer"
    arcpy.SelectLayerByLocation_management(memoryFeature2, "INTERSECT", memoryFeature,selection_type="NEW_SELECTION")
    arcpy.DeleteFeatures_management(memoryFeature2)
    out_feature_class=outFolder+"/"+"int2_"+fc
    arcpy.CopyFeatures_management(memoryFeature2,out_feature_class)
    
    #del(memoryFeature)
    #del(memoryFeature2)
    ##################



    
    print "Aggregating nodes using a raster buffer: \nN.B. currently this is lat long only and so varies with latitude, \n so further work could involve a equal area or equidistant version."
    cellSize = "0.005"
    expansionFactor="1"
    print "Cellsize is {0} and expansion is {1}".format(cellSize,expansionFactor)
    rast = tempFolder + "/" + "tempRast.tif"
    rastExp = tempFolder + "/" + "tempRastExp.tif"
    memoryFeature=tempFolder + "/" + "tempFeatExp.shp"#"in_memory" + "\\" + "myMemoryfeature"
    print "Converting to raster"
    arcpy.FeatureToRaster_conversion(in_features=out_feature_class,
                                 field="nodetypes",
                                 out_raster=rast,
                                 cell_size=cellSize)
    print "Expanding raster"
    arcpy.gp.Expand_sa(rast,
                   rastExp,
                   expansionFactor,"1;-1")
    print "Converting expanded raster to vector"
    arcpy.RasterToPolygon_conversion(in_raster=rastExp,
                                 out_polygon_features=memoryFeature,
                                 simplify="NO_SIMPLIFY",raster_field="Value")
    memoryFeature2=tempFolder + "/" + "tempFeatExpDiss.shp"
    print "Ensuring unique ids are added to each seperate polygon:"
    print "a) dissolving to join any features in contact with each other"
    arcpy.Dissolve_management(in_features=memoryFeature,out_feature_class=memoryFeature2)
    memoryFeature=tempFolder + "/" + "tempFeatExpDissMS.shp"
    print "b) single part to multipart tool to split into seperate features"
    arcpy.MultipartToSinglepart_management(in_features=memoryFeature2,out_feature_class=memoryFeature)
    print "c) adding IDagg field"
    arcpy.AddField_management(memoryFeature,"IDagg","Long")
    print "d) populating the IDagg field with unique values for individual features"
    arcpy.CalculateField_management(memoryFeature,field="IDagg",
                                    expression="!FID!+1",
                                    expression_type="PYTHON_9.3")
    print "Aggregating based on spatial join of the main featureclass to the newly expanded vector"
    in_feature_class =out_feature_class
    out_feature_class =outFolder+"/"+"nde_"+fc
    arcpy.SpatialJoin_analysis(target_features=in_feature_class,
                               join_features=memoryFeature,
                               out_feature_class=out_feature_class,
                               join_operation="JOIN_ONE_TO_ONE",join_type="KEEP_ALL",
                               match_option="INTERSECT",search_radius="#",distance_field_name="#")
    
    #arcpy.Delete_management(in_feature_class)
    
    nodeAggField = "nodeAggID"
    print "Adding and calculating aggregated node ids to this field: {0}".format(nodeAggField)
    arcpy.AddField_management(out_feature_class,nodeAggField,"Long")
    arcpy.CalculateField_management(out_feature_class,field=nodeAggField,
                                    expression="""int((str(!cellBuffId!)) +str(int(!IDagg!)))""",
                                    expression_type="PYTHON_9.3")
    print "Dissolving by field containing aggregated node IDs: {0}".format(nodeAggField)
    in_feature_class =out_feature_class
    out_feature_class =outFolder+"/"+"dis_"+fc
    arcpy.Dissolve_management(in_features=in_feature_class,
                              out_feature_class=out_feature_class,
                              dissolve_field=nodeAggField,
                              statistics_fields="AREA_GEO SUM;cell_id FIRST;nodetypes FIRST;Join_Count SUM;",
                              multi_part="MULTI_PART",unsplit_lines="DISSOLVE_LINES")

    print "Deleting temp files"
    arcpy.Delete_management(rast)
    del(rast)
    arcpy.Delete_management(rastExp)
    del(rastExp)
    #arcpy.Delete_management(memoryFeature)
    del(memoryFeature)
    #arcpy.Delete_management(in_feature_class)
    i += 1
    print "Processed featureclass number: {0} Filename: {1} ".format (i,fc)
    print("Total time (minutes): " + str((time.clock() - beginTime2)/60)+"\n")


print "Finished processing"
print("Total elapsed time (minutes): " + str((time.clock() - beginTime)/60))

