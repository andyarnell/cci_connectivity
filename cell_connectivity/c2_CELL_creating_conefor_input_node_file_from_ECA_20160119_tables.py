##aim: group clusters of polygons (nodes) together based on distance
##copies conefor files to a seperate directory for running ECA caluclations on
##these calcualtions are ignoring node areas in the buffers around cells
##created by Andy Arnell 16/02/2016

print "Importing packages"

import os, sys, string
import arcpy
from arcpy import env
from arcpy.sa import *
import glob
import string
import shutil

import time

print "Setting local parameters and inputs"

# Check out the ArcGIS Spatial Analyst extension license
arcpy.CheckOutExtension("Spatial")

env.overwriteOutput = True

beginTime = time.clock()

#Set environment settings

rawFolder = "C:/Data/cci_connectivity/scratch/conefor_runs/eca_runs"

tempFolder = "C:/Data/cci_connectivity/scratch" 

outFolder="C:/Data/cci_connectivity/scratch/conefor_runs/eca_runs/by_species"


print "editing ECA output textfiles to act as input by species to new conefor run"

print "Creating node text file"

##
##arcpy.env.workspace = rawFolder
##sep = ' '
##
##textFiles = arcpy.ListTables("*nodes*")
##numText =  len(str(textFiles))
##print numText
##count = 0
##for fName in textFiles[0:100]:
##    count+=1
##    outFile = open(outFolder+"/"+fName, "w")
##    txtSearch = arcpy.da.SearchCursor(fName,["*"])
##    for txtRow in txtSearch:
##        
##        if txtRow[0]>0:
##            zval = ("{1}{0}{2}{0}{3}".format(sep,(txtRow[0]),(txtRow[3]),(txtRow[7])))
##        else:
##            zval = ("{1}{0}{2}{0}{3}".format(sep,(txtRow[0]),"0",(txtRow[7])))            
##        #print zval
##        outFile.write(zval + "\n")
##    outFile.close()
##    print "written text file {0} of : {1}".format(str(count),outFolder+"/"+fName)
##


print "Finished processing"
print "Total time elapsed: " +str(round(((time.clock() - beginTime)/60),2))+ " minutes"

        
