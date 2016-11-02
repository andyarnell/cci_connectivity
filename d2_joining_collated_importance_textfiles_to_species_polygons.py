##aim: joining text files (already colalted) into a single list.

##created by Andy Arnell 12/02/2015

print "Importing packages"
import os.path
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
arcpy.env.qualifiedFieldNames = "FALSE"
#Set environment settings

#rawFolder1 = "C:/Data/cci_connectivity/scratch/conefor_runs"
rawFolder2 = "C:/Data/cci_connectivity/scratch/intersected_spp"

outFolder = "C:/Data/cci_connectivity/scratch/conefor_runs/importances" 



##get a list of species names/ID 
##for each one join the importnaces file to the featureclass

def between(value, a, b):
    # Find and validate before-part.
    pos_a = value.find(a)
    if pos_a == -1: return ""
    # Find and validate after part.
    pos_b = value.rfind(b)
    if pos_b == -1: return ""
    # Return middle part.
    adjusted_pos_a = pos_a + len(a)
    if adjusted_pos_a >= pos_b: return ""
    return value[adjusted_pos_a:pos_b]

#function to replace those with "none" and repalce with 0 - this may bot be needed as should be results for all
#def xstr(s):
##    if s is None:
##        return '0'
##    return str(s)
    
arcpy.env.workspace = outFolder


tableList=arcpy.ListTables("*node_importances_*.txt")
#tableList2=arcpy.ListTables("*_execution_events*")

nameList = list()

wCard1="node_importances_"
wCard2=".txt"
wCard3="dis_sp_"
wCard4="_pr"

for table in tableList:
    print table
    nameList.append(between(table,wCard1,wCard2))

nameList=list(set(nameList))
#print str(nameList)
numberSpecies=str(len((nameList)))
print "Number of species: {0}".format(numberSpecies)

i=1



for name in nameList:
    beginTime2 = time.clock()
    
    print "Joining importance textfile to featureclass"   
    #print  rawFolder2
    arcpy.env.workspace = rawFolder2
    print "*"+wCard3+name+wCard4+"*"
    joinFC = arcpy.ListFeatureClasses("*"+wCard3+name+wCard4+"*")
    
    print name
    print joinFC
    
    fcNodeField="nodeAggID"
    tableNodeField="Node"
    txtFile=outFolder+"/node_importances_{0}.txt".format(name)
    for fc in joinFC:
        print fc
        
        fcPath = os.path.join(arcpy.env.workspace, fc)
        
        print fcPath
        
        memFC = r'in_memory\memoryFeature'
        expression=""" {0} > 0 """.format(fcNodeField)
        print expression
        arcpy.MakeFeatureLayer_management (fcPath, memFC,where_clause=expression)
        arcpy.env.workspace = outFolder
        #arcpy.env.workspace = rawFolder1
        fieldList = ["Node","dA","dPC","varPC"]
        txtFileDBF=txtFile[:-4]+".dbf"
        print txtFileDBF
        if os.path.exists(txtFileDBF):
            arcpy.Delete_management(txtFileDBF)
        arcpy.TableToDBASE_conversion(Input_Table=txtFile,Output_Folder=outFolder)
        
        arcpy.AddJoin_management(in_layer_or_view=memFC, in_field=fcNodeField, join_table= txtFileDBF, join_field=tableNodeField, join_type="KEEP_ALL")

        def getFieldNames(shp):
            fieldnames = [f.name for f in arcpy.ListFields(shp)]
            return fieldnames


        print "Copying shapefile with joined importances to: " + "impJoin_"+fc
        arcpy.env.workspace = outFolder
        arcpy.CopyFeatures_management(memFC,"impJoin_"+fc)
        arcpy.Delete_management(memFC)
        del(memFC)
        
        fieldNames = getFieldNames("impJoin_"+fc)
        
        for field in fieldNames:
            if field.startswith("Field".format(name)):
                arcpy.DeleteField_management("impJoin_"+fc,field)
            else:
                pass
    i+=1
    print "Finished processing featureclass: {0} in {1} minutes \n".format(name,str(round(((time.clock() - beginTime2)/60),2)))
        
        
print "Finished processing"
print "Total time elapsed: {0} minutes".format(str(round(((time.clock() - beginTime)/60),2)))
