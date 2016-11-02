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

inCells = "C:/Data/cci_connectivity/raw/mainland_grid/three_degree_mainland_afr.shp"


fcList=arcpy.ListFeatureClasses()
i=0


for fc in fcList[0:1]:
    beginTime2 = time.clock()
    dist = 100
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
    #arcpy.Delete_management(mergedCellBf)


print "Finished processing"
print("Total elapsed time (minutes): " + str((time.clock() - beginTime)/60))



