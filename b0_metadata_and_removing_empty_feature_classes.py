##aim: count rows in preaggregation feature calsses and write to a file,
##and deleting those without rows

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

outFolder = "C:/Data/cci_connectivity/scratch/processing_metadata"

tempfolder = "C:/Data/cci_connectivity/scratch"
env.workspace = rawFolder+"/"


fcList=arcpy.ListFeatureClasses()

i=0

txtFile0 = outFolder+"/"+"Empty_polygons_from_raster_conv.txt"
outFile0 = open(txtFile0, "a")
txtFile1 = outFolder+"/"+"Count_rows_in_feature_class_pre_aggregation.txt"
outFile1 = open(txtFile1, "a")
##today = datetime.date.today()
##print today
##print 'ctime:', today.ctime()
startTime = datetime.datetime.now()
print startTime
outFile0.write("\n"+"Processing start time:" + str(startTime)+"\n"+"\n")
outFile1.write("\n"+"Processing start time:" + str(startTime)+"\n"+"\n")
print "Counting rows in featureclasses and deleting empty files - printing info to metadata text files"
for fc in fcList:
        i+=1
        fcCount=arcpy.management.GetCount(fc)[0]
        if fcCount == "0":
                message = "ERROR No: {0} empty feature class: {1}".format(str(i),str(fc))
                outFile0.write(message + "\n")
                print "Deleting empty featureclass: {0}".format(fc)
                arcpy.Delete_management(fc)
                del fc
                print "Featurclass deleted - saving info to file: {0}".format(txtFile0)
        else:
                fcCount
                
                message = "Number of rows in feature class {0}: {1} = {2}".format(str(i),str(fc),str(fcCount))
                outFile1.write(message + "\n")
                
print "Saved empty count info to file: {0}".format(txtFile0)

print "Saved count info to file: {0}".format(txtFile1)
outFile0.close()
outFile1.close()
