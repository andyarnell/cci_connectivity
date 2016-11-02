import arcpy
import time
import sys, calendar, datetime, traceback
from arcpy.sa import *

print "Setting local parameters and inputs"

# Check out the ArcGIS Spatial Analyst extension license
arcpy.CheckOutExtension("Spatial")

arcpy.env.overwriteOutput = True

beginTime = time.clock()

wkspce1 = "C:/Data/cci_connectivity/raw/example_esh_alt_adj/wgs"

wkspce2 =  "C:/Data/cci_connectivity/scratch/spp_refined/40pcent/raster"

trimRst = "C:/Data/cci_connectivity/scratch/output/hansen_treecover2000_pcent40_agg10.tif"


print "Raster used to trim/refine other rasters : /n {0}".format(trimRst)
threshold = 10

print "Threshold used on trim layer set as: {0}".format(threshold)

arcpy.env.workspace = wkspce1

print "Making list of rasters to trim from: " + wkspce1
rstList = arcpy.ListRasters()

print "Number of rasters to trim/refine: " + str(len(rstList))

print "Looping through rasters and trimming using raster :{0} /n".format(trimRst)


i = 0
for rst in rstList:
    newRst = SetNull(Con( ((Raster(rst)==1) & (Raster(trimRst)>=threshold) ) , 1,0)==0,1)
    newRst.save(wkspce2+"/"+rst)
    print "Processed raster number: {0} Filename: {1}  /n".format (i,rst)
    i += 1
        
print "Processed {0} rasters stored here : {1}".format(i,wkspce2)

    

print "Finished processing"
print("Total elapsed time (minutes): " + str((time.clock() - beginTime)/60))


