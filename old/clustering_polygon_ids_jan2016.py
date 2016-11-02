##aim: group clusters of polygons (nodes) together based on distance
##so that all polygons within that distance of each other have the same id.
#this aims to reduce number of nodes for later analyses 

##created by Andy Arnell 09/06/2015

print "Importing packages"

import os, sys, string
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

rawFolder = "C:/Data/cci_connectivity/scratch/intersected_spp"

tempFolder = "C:/Data/cci_connectivity/scratch/node_aggregation" 

outFolder=tempFolder+"/output/"

#distance to aggregate pixels
aggDist="2km"

def unique_values(table, field):
    with arcpy.da.SearchCursor(table, [field]) as cursor:
        return sorted({row[0] for row in cursor})

field="cellBuffID"

env.workspace = rawFolder+"/"

fcList=arcpy.ListFeatureClasses()

searchRadius= "2 Kilometers"

j=1
for fc in fcList:
    vals=unique_values(fc,field)
    print "\nProcessing interpatch distances (under {0}) for:\n{1}\n".format(searchRadius,fc)
    beginTime2 = time.clock()
    i=1
      
    for val in vals:
        memoryFeature = "in_memory" + "\\" + "myMemoryFeature"
        arcpy.MakeFeatureLayer_management(fc,memoryFeature,"{0} = {1}".format(field,val))
        ##N.B that currently cutting off a few characters from output name in line below
        ## so when using bird id_codes instead of long latin names this should be -4 instead of -6
        tble=(fc[:-6])+"_"+str(i)
        txtSearch = arcpy.da.SearchCursor(memoryFeature, ["node_id","AREA_GEO"])
        outFile = open(tempFolder+"/text_files/nodes_{0}_{1}.txt".format(tble,str(val)), "w")
        #outFile.write(\n")
        for txtRow in txtSearch:
            zval = (str(txtRow[0]) +"   "+str(round(((txtRow[1])*1000),3)))
            outFile.write(zval + "\n")
        outFile.close()
        memoryFeatureOut = "in_memory" + "\\" + "myMemoryFeatureOut"
        #outTable=tempFolder+"/text_files/"+tble+".dbf
        arcpy.GenerateNearTable_analysis(in_features=memoryFeature,
                                         near_features=memoryFeature,
                                         out_table=memoryFeatureOut,
                                         search_radius=searchRadius,location="LOCATION",
                                         angle="NO_ANGLE",closest="ALL",closest_count="0",method="GEODESIC")
        expression= "IN_FID > NEAR_FID"
        txtSearch = arcpy.da.SearchCursor(memoryFeatureOut, ["IN_FID","NEAR_FID","NEAR_DIST"],where_clause=expression)
        outFile = open(tempFolder+"/text_files/distances_{0}_{1}.txt".format(tble,str(val)), "w")
        for txtRow in txtSearch:
            zval = (str(txtRow[0]) +"   "+str(txtRow[1])+"  "+str(round(((txtRow[2])*1000),3)))
            outFile.write(zval + "\n")
        outFile.close()
        
        ##to clear space in memory
        del(memoryFeature)
        del(memoryFeatureOut)
#
#        arcpy.XYToLine_management(in_table=tempFolder+"/text_files/"+tble+".dbf",
##                                  out_featureclass=tempFolder+"/link_shapes/"+tble,
##                              startx_field="FROM_X",starty_field="FROM_Y",
##                              endx_field="NEAR_X",endy_field="NEAR_Y",
##                              line_type="GEODESIC",id_field="#",
##                              spatial_reference="GEOGCS['GCS_WGS_1984',DATUM['D_WGS_1984',SPHEROID['WGS_1984',6378137.0,298.257223563]],PRIMEM['Greenwich',0.0],UNIT['Degree',0.0174532925199433]];-400 -400 1000000000;-100000 10000;-100000 10000;8.98315284119522E-09;0.001;0.001;IsHighPrecision")
        time_end2=str (round(((time.clock() - beginTime2)/60),2))
        print "Group {0} of {1} processed for {2}. Time taken (minutes): {3}".format( (str(i)),str(len(vals)),fc,time_end2)
        i+=1
    print "Finished processing feature class {0}: {1}".format(str(j),fc)
    print "Total time processing featureclass: " +str(round(((time.clock() - beginTime)/60),2)) 
    j+=1


print "Finished processing"
print "Total time elapsed: " +str(round(((time.clock() - beginTime)/60),2))

        
        
        
        
        
    
    

