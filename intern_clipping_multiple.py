#clipping forest polygons by ranges

import time
import arcpy

arcpy.env.overwriteOutput=True

inWkspace=r"C:\Data\cci_connectivity\scratch\intern"
inWkspace2=r"C:\Data\cci_connectivity\scratch\forest\vector"
outWkspace=r"C:\Data\cci_connectivity\scratch\intern\clipped"

arcpy.env.workspace= inWkspace

inFC=inWkspace2+"/"+"agg_intern_1kmnodes.shp"

listFC=arcpy.ListFeatureClasses()

beginTime = time.clock()

for fc in listFC:
    beginTime2 = time.clock()
    outFC=outWkspace+"/"+fc
    arcpy.Clip_analysis(inFC,fc,outFC)
    print "processed fc to: "+outFC
    print "Time taken processing featureclass: " +str(round(((time.clock() - beginTime2)/60),2)) 

print "Finished processing"

print "Total time processing featureclasses: " +str(round(((time.clock() - beginTime2)/60),2)) 
