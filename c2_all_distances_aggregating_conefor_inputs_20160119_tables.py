##aim: group text files into a single list. Filtering according to a specific value
##created by Andy Arnell 21/01/2015

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

#Set environment settings

rawFolder1 = "C:/Data/cci_connectivity/scratch/conefor_runs"
rawFolder2 = "C:/Data/cci_connectivity/scratch/intersected_spp"

outFolder = "C:/Data/cci_connectivity/scratch/conefor_runs/importances" 

arcpy.env.workspace = rawFolder1

tableList=arcpy.ListTables("*distances*")
tableList2=arcpy.ListTables("*nodes*")
##print tableList


##get a list of species names/ID

##for each one open a text file

##then loop through all those that match that name/ID

##then close

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

nameList = list()

j = 0

for table in tableList:
    wCard1="dis_sp_"
    wCard2="_pr"
    nameList.append(between(table,wCard1,wCard2))

nameList=list(set(nameList))
print str(nameList)

for name in nameList:
    beginTime2 = time.clock()
    txtFile=outFolder+"/distances_{0}.txt".format(name)
    outFile = open(txtFile, "w")
    sep="   "
    #zval = "{1}{0}{2}{0}{3}".format(sep,[0],[1],[2])
    #outFile.write(zval + "\n")
    for table in tableList:
        if between(table,"dis_sp_","_pr") == name:
            #expression= "Node>0"
            txtSearch = arcpy.da.SearchCursor(table,"*")#,where_clause=expression)
            for txtRow in txtSearch:
                zval = "{1}{0}{2}{0}{3}".format(sep,txtRow[0],txtRow[3],txtRow[5])
                #print txtRow
                outFile.write(zval + "\n")
        else:
            pass
    print  "Finished aggregating distances for {0}".format(name)
        
    txtFile=outFolder+"/nodes_{0}.txt".format(name)
    outFile = open(txtFile, "w")
    sep="   "
    for table in tableList2:
        if between(table,"dis_sp_","_pr") == name:
            #expression= "Node>0"
            txtSearch = arcpy.da.SearchCursor(table,"*")#,where_clause=expression)
            for txtRow in txtSearch:
                zval = "{1}{0}{2}{0}{3}".format(sep,txtRow[0],txtRow[3],txtRow[5])
                #print txtRow
                outFile.write(zval + "\n")
        else:
            pass
    print  "Finished aggregating nodes for {0}".format(name)
    
    outFile.close()

    j+=1
    
    print "Total time processing species " +str(j)+" ("+str(name)+"): " +str(round(((time.clock() - beginTime2)/60),2))+ " minutes \n" 


print "Finished processing"
print "Total time elapsed: " +str(round(((time.clock() - beginTime)/60),2))+ " minutes"

        
   
