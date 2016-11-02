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
import datetime

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
    

fcList = arcpy.ListFeatureClasses()

print "Number of feature classes in list: {0}".format( str(len(fcList)))
#####remove  isolated patches?
isolatedSmallNodeRemove = False


i=0
txtFile = tempFolder+"/processing_metadata/"+"Error_file_intersect_ESH_nodes_with_cells_and_node_aggregation.txt"
outFile = open(txtFile, "a")
outFile.write("\n"+"Processing start time:" +str(datetime.datetime.now())+"\n")
for fc in fcList[230:]:
        try:
                beginTime2 = time.clock()
                memCells = "in_memory" + "\\" + "memCells"
                memCells2 = "in_memory" + "\\" + "memCells2"
                arcpy.MakeFeatureLayer_management (inCells, memCells)

        ##        #dist = 250
        ##        #buffDist = str(dist)+" Kilometers"
                print "Creating feature class in memory and selecting grid cells that intersect features. FC: {0}".format(fc)
                memFC="in_memory"+"\\"+"memFC"
                arcpy.MakeFeatureLayer_management (fc, memFC)
                arcpy.SelectLayerByLocation_management (memCells, 'intersect', memFC)
                arcpy.MakeFeatureLayer_management (memCells, memCells2)
                print("Time elapsed (minutes): " + str((time.clock() - beginTime2)/60)+"\n")
                beginTime2a = time.clock()
                print "Intersecting cells with species"
                in_features = """{0} #; {1} #""".format(memCells2,memFC)
                out_feature_class = outFolder+"/"+"int_"+fc#"in_memory"+"\\"+"memIntCellsFC"
                arcpy.Intersect_analysis(in_features, out_feature_class,join_attributes="NO_FID",cluster_tolerance="#",output_type="INPUT")
                print("Time elapsed (minutes): " + str((time.clock() - beginTime2a)/60)+"\n")
                beginTime2b = time.clock()
                print "Fixing geometry"
                #arcpy.RepairGeometry_management(out_feature_class)
                #arcpy.RepairGeometry_management(out_feature_class)
                #arcpy.RepairGeometry_management(out_feature_class)
                print "Removing unnecesary fields and adding useful fields"
                arcpy.DeleteField_management(out_feature_class,"ORIG_FID")
                arcpy.AddField_management(out_feature_class,"nodetypes","Short")
                arcpy.CalculateField_management(out_feature_class,field="nodetypes",expression="1")
            ##    print "Adding geometry (area) attributes for each node"
            ##    arcpy.AddGeometryAttributes_management (out_feature_class,
            ##                                      Geometry_Properties="AREA_GEODESIC",
            ##                                      Length_Unit="#",
            ##                                      Area_Unit="SQUARE_KILOMETERS",
            ##                                      Coordinate_System="#")
                print "Deleting temp files"
                arcpy.Delete_management(memFC)
                del memFC
                arcpy.Delete_management(memCells)
                del memCells
                arcpy.Delete_management(memCells2)
                del memCells2
                print("Time elapsed (minutes): " + str((time.clock() - beginTime2b)/60)+"\n")
                beginTime2c = time.clock()

                ############
        ##        if isolatedSmallNodeRemove==True:
        ##            print "Highlighting isolated fragments using a raster buffer: \nN.B. currently this is lat long only and so varies with latitude, \n so further work could involve an equal area or equidistant version."
        ##            cellSize = "0.0125"
        ##            expansionFactor="2"
        ##            print "Cellsize is {0} and expansion is {1}".format(cellSize,expansionFactor)
        ##            rast = tempFolder + "/" + "tempRast.tif"
        ##            rastExp = tempFolder + "/" + "tempRastExp.tif"
        ##            memoryFeature=tempFolder + "/" + "tempFeatExp.shp"
        ##            print "Converting to raster"
        ##            arcpy.FeatureToRaster_conversion(in_features=out_feature_class,
        ##                                         field="nodetypes",
        ##                                         out_raster=rast,
        ##                                         cell_size=cellSize)
        ##            print("Time elapsed (minutes): " + str((time.clock() - beginTime2c)/60)+"\n")
        ##            beginTime2d = time.clock()
        ##            print "Expanding raster"
        ##            arcpy.gp.Expand_sa(rast,
        ##                           rastExp,
        ##                           expansionFactor,"1")
        ##            print "Converting expanded raster to vector"
        ##            arcpy.RasterToPolygon_conversion(in_raster=rastExp,
        ##                                         out_polygon_features=memoryFeature,
        ##                                         simplify="NO_SIMPLIFY",raster_field="Value")
        ##            memoryFeature2=tempFolder + "/" + "tempFeatExpDiss.shp"
        ##            print("Time elapsed (minutes): " + str((time.clock() - beginTime2d)/60)+"\n")
        ##            beginTime2e = time.clock()
        ##            print "Ensuring unique ids are added to each seperate polygon:"
        ##            print "a) dissolving to join any features in contact with each other"
        ##            arcpy.Dissolve_management(in_features=memoryFeature,out_feature_class=memoryFeature2)
        ##            memoryFeature=tempFolder + "/" + "tempFeatExpDissMS.shp"
        ##            print "b) single part to multipart tool to split into seperate features"
        ##            print("Time elapsed (minutes): " + str((time.clock() - beginTime2e)/60)+"\n")
        ##            beginTime2f = time.clock()
        ##            arcpy.MultipartToSinglepart_management(in_features=memoryFeature2,out_feature_class=memoryFeature)
        ##            print "c) adding IDagg field"
        ##            arcpy.AddField_management(memoryFeature,"IDagg","Long")
        ##            print "d) populating the IDagg field with unique values for individual features"
        ##            arcpy.CalculateField_management(memoryFeature,field="IDagg",
        ##                                            expression="!FID!+1",
        ##                                            expression_type="PYTHON_9.3")
        ##            print("Time elapsed (minutes): " + str((time.clock() - beginTime2f)/60)+"\n")
        ##            beginTime2g = time.clock()
        ##            print "Aggregating based on spatial join of the main featureclass to the newly expanded vector"
        ##            in_feature_class = fc
        ##            out_feature_class =outFolder+"/"+"isol_"+fc
        ##            arcpy.SpatialJoin_analysis(target_features=in_feature_class,
        ##                                       join_features=memoryFeature,
        ##                                       out_feature_class=out_feature_class,
        ##                                       join_operation="JOIN_ONE_TO_ONE",join_type="KEEP_ALL",
        ##                                       match_option="INTERSECT",search_radius="#",distance_field_name="#")
        ##            #arcpy.Delete_management(in_feature_class)
        ##            print("Time elapsed (minutes): " + str((time.clock() - beginTime2g)/60)+"\n")
        ##            beginTimeh = time.clock()
        ##            nodeAggField = "IDagg"
        ##            print "Adding geometry (area) attributes for each node"
        ##            arcpy.AddGeometryAttributes_management (out_feature_class,
        ##                                              Geometry_Properties="AREA_GEODESIC",
        ##                                              Length_Unit="#",
        ##                                              Area_Unit="SQUARE_KILOMETERS",
        ##                                              Coordinate_System="#")
        ##            print("Time elapsed (minutes): " + str((time.clock() - beginTime2h)/60)+"\n")
        ##            beginTimei = time.clock()
        ##            print "Dissolving by field containing aggregated node IDs: {0}".format(nodeAggField)
        ##            in_feature_class =out_feature_class
        ##            out_feature_class =outFolder+"/"+"islD_"+fc
        ##            arcpy.Dissolve_management(in_features=in_feature_class,
        ##                                      out_feature_class=out_feature_class,
        ##                                      dissolve_field=nodeAggField,
        ##                                      statistics_fields="AREA_GEO SUM;Join_Count SUM",
        ##                                      multi_part="MULTI_PART",unsplit_lines="DISSOLVE_LINES")
        ##            print("Time elapsed (minutes): " + str((time.clock() - beginTime2i)/60)+"\n")
        ##            beginTime2j = time.clock()
        ##            arcpy.Delete_management(rast)
        ##            del(rast)
        ##            arcpy.Delete_management(rastExp)
        ##            del(rastExp)
        ##            #arcpy.Delete_management(memoryFeature)
        ##            del(memoryFeature)
        ##            in_feature_class =out_feature_class
        ##            memoryFeature="in_memory\\tempFeatExp.shp"
        ##            memoryFeature2="in_memory\\tempFeatEx2.shp"
        ##            minIsolPatchArea=2
        ##            expression= """  "SUM_AREA_G" < {0} AND "SUM_Join_C" <2 """.format(minIsolPatchArea)
        ##            print "Creating feature layer with those features under a certain size ({0}) and isolated"
        ##            arcpy.MakeFeatureLayer_management(in_feature_class,memoryFeature,where_clause=expression)
        ##            out_feature_class=outFolder+"/"+"intemp_"+fc
        ##            arcpy.CopyFeatures_management(memoryFeature,out_feature_class)
        ##            del(in_feature_class)
        ##            in_feature_class =outFolder+"/"+"int_"+fc
        ##            arcpy.MakeFeatureLayer_management(in_feature_class,memoryFeature2)
        ##            print "Selecting by location any isolated, small features, removing them and creating a new layer"
        ##            arcpy.SelectLayerByLocation_management(memoryFeature2, "INTERSECT", memoryFeature,selection_type="NEW_SELECTION")
        ##            arcpy.DeleteFeatures_management(memoryFeature2)
        ##            out_feature_class=outFolder+"/"+"int2_"+fc
        ##            arcpy.CopyFeatures_management(memoryFeature2,out_feature_class)
                #del(memoryFeature)
                #del(memoryFeature2)
                ######################################
                ######################################
                print "Aggregating nodes using a raster buffer: \nN.B. currently this is lat long only and so varies with latitude, \n so further work could involve a equal area or equidistant version."
                beginTime2a = time.clock()
                cellSize = "0.0125"
                expansionFactor="1"
                print "Cellsize is {0} and expansion is {1}".format(cellSize,expansionFactor)
                rast = tempFolder + "/" + "tempRast.tif"
                rastExp = tempFolder + "/" + "tempRastExp.tif"
                memoryFeature=tempFolder + "/" + "tempFeatExp.shp"#"in_memory" + "\\" + "myMemoryfeature"
                print "Fixing geometry"
                #arcpy.RepairGeometry_management(out_feature_class)
                #arcpy.RepairGeometry_management(out_feature_class)
                #arcpy.RepairGeometry_management(out_feature_class) 
                print "Converting to raster"
                arcpy.PolygonToRaster_conversion(in_features=out_feature_class,value_field="nodetypes",out_rasterdataset=rast,
                                                 cell_assignment = "MAXIMUM_COMBINED_AREA",priority_field="nodetypes",cellsize=cellSize)
                print("Time elapsed (minutes): " + str((time.clock() - beginTime2a)/60)+"\n")
                beginTime2a = time.clock()
                print "Expanding raster"
                arcpy.gp.Expand_sa(rast,
                               rastExp,
                               expansionFactor,"1;-1")
                print("Time elapsed (minutes): " + str((time.clock() - beginTime2a)/60)+"\n")
                beginTime2a = time.clock()

                print "Converting expanded raster to vector"
                arcpy.RasterToPolygon_conversion(in_raster=rastExp,
                                             out_polygon_features=memoryFeature,
                                             simplify="NO_SIMPLIFY",raster_field="Value")
                print("Time elapsed (minutes): " + str((time.clock() - beginTime2a)/60)+"\n")
                beginTime2a = time.clock()

                memoryFeature2=tempFolder + "/" + "tempFeatExpDiss.shp"
                print "Ensuring unique ids are added to each seperate polygon:"
                print "a) dissolving to join any features in contact with each other"
                arcpy.Dissolve_management(in_features=memoryFeature,out_feature_class=memoryFeature2)
                print("Time elapsed (minutes): " + str((time.clock() - beginTime2a)/60)+"\n")
                beginTime2a = time.clock()

                memoryFeature=tempFolder + "/" + "tempFeatExpDissMS.shp"
                print "b) single part to multipart tool to split into seperate features"
                arcpy.MultipartToSinglepart_management(in_features=memoryFeature2,out_feature_class=memoryFeature)
                print "c) adding IDagg field"
                arcpy.AddField_management(memoryFeature,"IDagg","Long")
                print "d) populating the IDagg field with unique values for individual features"
                arcpy.CalculateField_management(memoryFeature,field="IDagg",
                                                expression="!FID!+1",
                                                expression_type="PYTHON_9.3")
                print("Time elapsed (minutes): " + str((time.clock() - beginTime2a)/60)+"\n")
                beginTime2a = time.clock()

                print "Aggregating based on spatial join of the main featureclass to the newly expanded vector"
                in_feature_class =out_feature_class
                out_feature_class =outFolder+"/"+"nde_"+fc
                arcpy.SpatialJoin_analysis(target_features=in_feature_class,
                                           join_features=memoryFeature,
                                           out_feature_class=out_feature_class,
                                           join_operation="JOIN_ONE_TO_ONE",join_type="KEEP_ALL",
                                           match_option="INTERSECT",search_radius="#",distance_field_name="#")
                print("Time elapsed (minutes): " + str((time.clock() - beginTime2a)/60)+"\n")
                beginTime2a = time.clock()
                
                #arcpy.Delete_management(in_feature_class)
                nodeAggField = "nodeAggID"
                print "Adding and calculating aggregated node ids to this field: {0}".format(nodeAggField)
                arcpy.AddField_management(out_feature_class,nodeAggField,"Long")
                arcpy.CalculateField_management(out_feature_class,field=nodeAggField,
                                                expression="""int((str(!cell_id!)) +str(int(!IDagg!)))""",
                                                expression_type="PYTHON_9.3")
                print("Time elapsed (minutes): " + str((time.clock() - beginTime2a)/60)+"\n")
                beginTime2a = time.clock()

                print "Dissolving by field containing aggregated node IDs: {0}".format(nodeAggField)
                in_feature_class =out_feature_class
                out_feature_class =outFolder+"/"+"dis_"+fc
                arcpy.Dissolve_management(in_features=in_feature_class,
                                          out_feature_class=out_feature_class,
                                          dissolve_field=nodeAggField,
                                          statistics_fields="cell_id FIRST;nodetypes FIRST;Join_Count SUM;",
                                          multi_part="MULTI_PART",unsplit_lines="DISSOLVE_LINES")
                print("Time elapsed (minutes): " + str((time.clock() - beginTime2a)/60)+"\n")
                beginTime2a = time.clock()

                print "Deleting temp files"
                #arcpy.Delete_management(rast)
                del(rast)
                arcpy.Delete_management(rastExp)
                del(rastExp)
                #arcpy.Delete_management(memoryFeature)
                del(memoryFeature)
                #arcpy.Delete_management(in_feature_class)

                print("Time elapsed (minutes): " + str((time.clock() - beginTime2a)/60)+"\n")
                beginTime2a = time.clock()
                i += 1
                print "Processed featureclass number: {0} Filename: {1} ".format (i,fc)
                print("Total time (minutes): " + str((time.clock() - beginTime2)/60)+"\n")
        except:
                message = "ERROR No: {0} : {1}".format(str(i),str(fc))
                print "Error processing feature class: see output errorfile: {0}".format(txtFile)
                print message
                outFile.write(message + "\n")
print "Finished processing"
print("Total elapsed time (minutes): " + str((time.clock() - beginTime)/60))

outFile.close()
