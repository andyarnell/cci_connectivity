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


all_distances=False

if all_distances is True:
    print "Calculating for all_distances = True, so calculating all distances"
else:
    print "Calculating all_distances = False, so calculating based on groups (i.e. cells and buffers)" 
rawFolder = "C:/Data/cci_connectivity/scratch/intersected_spp"

tempFolder = "C:/Data/cci_connectivity/scratch/node_aggregation" 

outFolder="C:/Data/cci_connectivity/scratch/conefor_runs"
outFolder2="C:/Data/cci_connectivity/scratch/conefor_runs/eca_runs"

###################ADD IN THE NAME OF THE GRID (CELLS) FILE

field="FIRST_cell"

env.workspace = rawFolder+"/"

fcList=arcpy.ListFeatureClasses(wild_card="dis_sp_*")
print "Number of feature classes: {0}".format(str(len(fcList)))

searchRadius= 250000#"100 Kilometers"

nodeField="nodeAggID" 
areaField="SUM_AREA_G"
nodetypeField="FIRST_node"


#getting projection system (assuming not using geodesic due to processing times)
coord_templates="C:/Data/cci_connectivity/scratch/coord_templates"
CS_FC=coord_templates+"/"+"azim_equidist.shp"
CS=desc=arcpy.Describe(CS_FC)
coordSys=desc.spatialReference
def unique_values(table, field):
    with arcpy.da.SearchCursor(table, [field]) as cursor:
        return sorted({row[0] for row in cursor})
    
j=1

for fc in fcList[1:2]:
    
    vals=unique_values(fc,field)
    print "\nProcessing interpatch distances (under {0}) for:\n{1}\n".format(searchRadius,fc)
    beginTime2 = time.clock()
    i=1
    rows = arcpy.SearchCursor(fc)  
            #count the number of rows in output     
    count = 0
    for row in rows:  
        count += 1

    
    print "The number of nodes/features in featureclass: {0})".format(count)
    for val in vals:
        beginTime3 = time.clock()
        memoryFeature = "in_memory" + "\\" + "myMemoryFeature"
        memoryFeature2 = "in_memory" + "\\" + "myMemoryFeature2"

        memoryFeaturePRJ=tempFolder + "/myMemoryFeaturePRJ.shp"

        ##################ADD IN A LAYER FOR THE INDIVIDUAL CELL USING MAKEFEATURE ON THE GRID LAYER
        ##################USE SELECT BY LOCATION AND A SEARCH DISTANCE OF MAX DISPERSAL
        ##################MAKE SELECTED FEATURES AN IN MEMORY FEATURE
        
        arcpy.MakeFeatureLayer_management(fc,memoryFeature,"{0} = {1}".format(field,val))
        print "Projecting nodes within group (i.e. cell and buffer)to planar equidistance projection - N.B. currently centred on lat 0 and long 0 but this is inaccurate"
        print "so should be made to centre on FC (ideally the cell being analysed) dynamically "
        
        arcpy.Project_management(memoryFeature,memoryFeaturePRJ,coordSys)
        
        arcpy.MakeFeatureLayer_management(memoryFeaturePRJ,memoryFeature)

        if all_distances is True:
            print "Projecting ALL NODES to a planar equidistance projection - N.B. currently centred on lat 0 and long 0 but this is inaccurate so should be made to centre on FC dynamically"
            prjFC=tempFolder+"/"+"p"+fc
            arcpy.Project_management(fc,prjFC,coordSys)
            fc=prjFC
            arcpy.MakeFeatureLayer_management(prjFC,memoryFeature2)
        else:
            memoryFeature2= memoryFeature
        
        rows = arcpy.SearchCursor(memoryFeature)  
            #count the number of rows in output     
        count = 0
        
        for row in rows:  
                count += 1
        print "The number of nodes/features in group: {0}  (for cell_id: {1})".format(count,val)
        print "Creating node text file"
        ##N.B that currently cutting off a few characters from output name in line below
        ## so when using bird id_codes instead of long latin names this should be -4 instead of -6
        tble=(fc[:-6])+"_"+str(i)
        txtSearch = arcpy.da.SearchCursor(memoryFeature, [nodeField,areaField,nodetypeField])
        outFile = open(outFolder+"/nodes_{0}_{1}.txt".format(tble,str(val)), "w")
        for txtRow in txtSearch:
            zval = (str(txtRow[0]) +"   "+str(round(((txtRow[1])*1000),3))+"    "+str(txtRow[2]))
            outFile.write(zval + "\n")
        outFile.close()
        memoryFeatureOut = "in_memory" + "\\" + "myMemoryFeatureOut"
        ##outTable=tempFolder+"/text_files/"+tble+".dbf
        print "Creating distance file: calcualting distances between nodes"
        arcpy.GenerateNearTable_analysis(in_features=memoryFeature,
                                         near_features=memoryFeature2,
                                         out_table=memoryFeatureOut,
                                         search_radius=searchRadius,location="LOCATION",
                                         angle="NO_ANGLE",closest="ALL",closest_count="0",method="PLANAR")#"GEODESIC")
        
        print 'Fixing FIDs to match featureclass IDs'
        fc1 = memoryFeature
        cursor = arcpy.da.SearchCursor(fc1, ["FID"])
        for row in cursor:
            SQL_stat= "FID = "+ str(row[0])
            fc2 = memoryFeatureOut
            cursor2 = arcpy.da.SearchCursor(fc1, [nodeField], SQL_stat)
            for row2 in cursor2:
                UpdatedValue = row2[0]
                cursor3 = arcpy.da.UpdateCursor(fc2, ["IN_FID"],"IN_"+SQL_stat)
                for row3 in cursor3:
                    row3[0] = UpdatedValue
                    cursor3.updateRow(row3)
                cursor4 = arcpy.da.UpdateCursor(fc2, ["NEAR_FID"],"NEAR_"+SQL_stat)
                for row4 in cursor4:
                    row4[0] = UpdatedValue
                    cursor4.updateRow(row4)
                          
        del row
        del cursor
        del row2
        del cursor2
        if cursor3 is True:
            del row3
            del cursor3
            del row4
            del cursor4
        expression= "IN_FID > NEAR_FID"
        txtSearch = arcpy.da.SearchCursor(memoryFeatureOut, ["IN_FID","NEAR_FID","NEAR_DIST"],where_clause=expression)
        outFile = open(outFolder+"/distances_{0}_{1}.txt".format(tble,str(val)), "w")
        for txtRow in txtSearch:
            zval = format(str(txtRow[0]) +"   "+str(txtRow[1])+"  "+str(round(((txtRow[2])),3)))
            outFile.write(zval + "\n")
        outFile.close()
        #send copies into ECA folder
        ###shutil.copy(outFile, outFolder2)
        
        ##to clear space in memory
        arcpy.Delete_management(memoryFeature)
        arcpy.Delete_management(memoryFeature2)
        
        if all_distances is True:
            arcpy.Delete_management(prjFC)        
        else:
            pass
        arcpy.Delete_management(memoryFeatureOut)
        del(memoryFeatureOut)
        del(memoryFeature)
        del(memoryFeature2)

##        arcpy.XYToLine_management(in_table=tempFolder+"/text_files/"+tble+".dbf",
##                                  out_featureclass=tempFolder+"/link_shapes/"+tble,
##                              startx_field="FROM_X",starty_field="FROM_Y",
##                              endx_field="NEAR_X",endy_field="NEAR_Y",
##                              line_type="GEODESIC",id_field="#",
##                              spatial_reference="GEOGCS['GCS_WGS_1984',DATUM['D_WGS_1984',SPHEROID['WGS_1984',6378137.0,298.257223563]],PRIMEM['Greenwich',0.0],UNIT['Degree',0.0174532925199433]];-400 -400 1000000000;-100000 10000;-100000 10000;8.98315284119522E-09;0.001;0.001;IsHighPrecision")
        time_end2=str (round(((time.clock() - beginTime3)/60),2))
        print "Group {0} of {1} processed for {2}. Time taken (minutes): {3}".format( (str(i)),str(len(vals)),fc,time_end2)
        i+=1
    print "Finished processing feature class {0}: {1}".format(str(j),fc)
    print "Total time processing featureclass: " +str(round(((time.clock() - beginTime2)/60),2)) 
    j+=1


print "Finished processing"
print "Total time elapsed: " +str(round(((time.clock() - beginTime)/60),2))

        
        
        
        
        
    
    

