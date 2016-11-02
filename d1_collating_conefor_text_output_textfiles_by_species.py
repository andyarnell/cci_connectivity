##aim: group text files into a single list. Filtering accorddng to a specific value. 
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
arcpy.env.qualifiedFieldNames = "FALSE"
#Set environment settings

rawFolder1 = "C:/Data/cci_connectivity/scratch/conefor_runs"
rawFolder2 = "C:/Data/cci_connectivity/scratch/intersected_spp"

outFolder = "C:/Data/cci_connectivity/scratch/conefor_runs/importances" 

arcpy.env.workspace = rawFolder1

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

tableList=arcpy.ListTables("*_node_importances*")
tableList2=arcpy.ListTables("*_execution_events*")
nameList = list()

def xstr(s):
    if s is None:
        return '0'
    return str(s)

for table in tableList:
    wCard1="dis_sp_"
    wCard2="_pr"
    nameList.append(between(table,wCard1,wCard2))

nameList=list(set(nameList))
print str(nameList)
numberSpecies=str(len((nameList)))
print "Number of species: ".format(numberSpecies)


i=1


for name in nameList:
    beginTime2 = time.clock()

    print "Aggregating node importance textfiles based on species name/ID number: {0} ({1} of {2} species)".format(name,str(i),numberSpecies)
    arcpy.env.workspace = rawFolder1
    txtFile=outFolder+"/node_importances_{0}.txt".format(name)
    outFile = open(txtFile, "w")
    sep="   "
    zval = "{1}{0}{2}{0}{3}{0}{4}".format(sep,"Node","dA","dPC","varPC")
    outFile.write(zval + "\n")
    #print tableList
    tableList=arcpy.ListTables("*{0}*_node_importances*".format(name))
    print str(len(tableList))
    for table in tableList:
        print table
        expression= "Node>0"
        txtSearch = arcpy.da.SearchCursor(table,["Node","dA","dPC","varPC"],where_clause=expression)
        for txtRow in txtSearch:
            zval = ("{1}{0}{2}{0}{3}{0}{4}".format(sep,(txtRow[0]),(txtRow[1]),(txtRow[2]),(txtRow[3])))
            outFile.write(zval + "\n")

    outFile.close()


##    txtFile2=outFolder+"/execution_events{0}.txt".format(name)
##    outFile = open(txtFile2, "w")
##    sep="   "
##    outFile.write(zval + "\n")
##    
##    print "Aggregating execution event textfiles based on species name/ID number: {0} ({1} of {2} species)".format(name,str(i),numberSpecies)
##    for table in tableList2:
##        if between(table,"dis_sp_","_pro") == name:
##            expression= "Executing==Total"
##            txtSearch = arcpy.da.SearchCursor(table,["*"])#,where_clause=expression)
##            for txtRow in txtSearch:
##                #zval = ("{1}{0}{2}{0}{3}{0}{4}".format(sep,(txtRow[0]),(txtRow[1]),(txtRow[2]),(txtRow[3])))
##                outFile.write(str(txtRow) + "\n")
##        else:
##            pass
##    outFile.close()
##   

 ######################################################
    print "Finished processing featureclass: {0} in {1} minutes \n".format(name,str(round(((time.clock() - beginTime2)/60),2)))

    
print "Finished processing"
print "Total time elapsed: {0} minutes".format(str(round(((time.clock() - beginTime)/60),2)))
   
        

   


