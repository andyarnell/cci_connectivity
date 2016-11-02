
##created by Andy Arnell 11/01/2016
print "AIM: clean up fields"
print "Importing packages"

import os
import arcpy
from arcpy import env
import time
import sys, calendar, datetime, traceback
from arcpy.sa import *

print "Setting local parameters and inputs"

# Check out the ArcGIS Spatial Analyst extension license
arcpy.CheckOutExtension("Spatial")

arcpy.env.overwriteOutput = True

beginTime = time.clock()

wkspce3 =  "C:/Data/cci_connectivity/scratch/spp_refined/40pcent/vector"

env.workspace = wkspce3+"/"

fcList= arcpy.ListFeatureClasses()

print "Number of featureclasses :" + str(len(fcList))
i=1
for fc in fcList:
    print "Adding patchID field and populating it based on FID field"
    #arcpy.AddField_management(wkspce3+"/"+fc,"patchID","LONG")
    arcpy.CalculateField_management(in_table=wkspce3+"/"+fc,field="patchID",expression="[FID]+1",expression_type="VB",code_block="#")
    print "Removing unneccesary fields: GRIDCODE,ID"
    #arcpy.DeleteField_management(wkspce3+"/"+fc,"GRIDCODE")
    #arcpy.DeleteField_management(wkspce3+"/"+fc,"ID")
    i=+1
    print  "Processed shapefile number: {0} Filename: {1}  \n".format (i,fc)
print "Finished processing"
print("Total elapsed time (minutes): " + str((time.clock() - beginTime)/60))

