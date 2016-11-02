import arcpy
import time
import sys, calendar, datetime, traceback
from arcpy.sa import *


print "Setting local parameters and inputs"

# Check out the ArcGIS Spatial Analyst extension license
arcpy.CheckOutExtension("Spatial")

arcpy.env.overwriteOutput = True

beginTime = time.clock()

percentThresh = 40 #treecover threshold chosen - must have folder to output to

wkspce1 = "C:/Data/cci_connectivity/raw/species/alt_clipped_ranges_c1200spp_Feb2016"

wkspce2 =  "C:/Data/cci_connectivity/scratch/spp_refined/{0}pcent/raster".format(percentThresh)

wkspce3 =  "C:/Data/cci_connectivity/scratch/spp_refined/{0}pcent/vector".format(percentThresh)

try:
    if inMemRst:
        del inMemRst
except:
    pass

try:
    if inMemRst2:
        del inMemRst2
except:
    pass

try:
    if trimRst:
        del trimRst
except:
    pass

trimRst = "C:/Data/cci_connectivity/scratch/forest/output/hansen_treecover2000_postpcent40_agg10.tif"

print "Raster used to trim/refine other rasters : /n {0}".format(trimRst)
threshold = 1

print "Threshold used on trim layer set as: {0} to denote areas of presence".format(threshold)

arcpy.env.workspace = wkspce1

print "Making list of rasters to trim from: " + wkspce1
rstList = arcpy.ListRasters()

#getting coordinate system of forest raster
spatialRef = arcpy.Describe(trimRst).spatialReference


print "Number of rasters to trim/refine: " + str(len(rstList))

print "Forest coord sys: {0}".format(spatialRef.abbreviation)

print "Looping through rasters projecting to coord system of forest and trimming using raster :{0} \n".format(trimRst)

beginTime1 = time.clock()

#set memory workspace outputs
inMemRst="in_memory"+"\\"+"inMemRst"
inMemRst2="in_memory"+"\\"+"inMemRst2"

#creat memory version of trimRst for speed
arcpy.MakeRasterLayer_management(trimRst, inMemRst2)

#set to snap to the trimRst
arcpy.env.snapRaster = trimRst
#open text file to write errors into
txtFile=wkspce3+"errors_script_a1_species_refining_ranges_and_covnert_to_polygons.txt"
outFile = open(txtFile, "w")


#set counter
i = 0
for rst in rstList:
    i += 1
    beginTime1a = time.clock()
    arcpy.env.workspace = wkspce1
    #inMemRst="in_memory"+"\\"+"inMemRst"
    inMemRst="C:/Data/cci_connectivity/scratch/inMemRst"
    arcpy.ProjectRaster_management(rst,inMemRst,spatialRef)#inMemRst=rst#
    #set cell size to minimum of inputs
    cellsize_option= "MINOF"
    arcpy.env.cellSize = cellsize_option
    arcpy.env.workspace = wkspce2
    newRst = SetNull(Con( ((Raster(inMemRst)==1) & (Raster(inMemRst2)>=threshold) ) , 1,0)==0,1)
    #newRst.save(rst)
    #print "Processed raster number: {0} Filename: {1} in {2}n".format (i,rst,str((time.clock() - beginTime1a)/60))
    
    del inMemRst
    arcpy.env.workspace = wkspce3
    fc=rst[:-4]+".shp"
    #print "Converting {0} to polygon".format(rst)
    try:
        arcpy.RasterToPolygon_conversion(in_raster=newRst,out_polygon_features=fc,simplify="NO_SIMPLIFY",raster_field="Value")
        #print "Adding patchID field and populating it based on FID field"
        arcpy.AddField_management(fc,"patchID","LONG")
        arcpy.CalculateField_management(in_table=fc,field="patchID",expression="[FID]+1",expression_type="VB",code_block="#")
        #print "Removing unneccesary fields: GRIDCODE,ID"
        arcpy.DeleteField_management(fc,"GRIDCODE")
        arcpy.DeleteField_management(fc,"ID")
        #print  "Processed shapefile number: {0} Filename: {1} in {2} /n".format (i,fc,str((time.clock() - beginTime3a)/60)))
        #arcpy.Delete_management(inMemRst)
    except:
        print "ERROR empty raster,no conversion to polygon possible for raster: "+str(rst)
        message = "ERROR No: {0} empty raster,no conversion to polygon possible for raster: {1}".format(str(i),str(rst))
        outFile.write(message + "\n")
        
    print "Created FC number: {0} Filename: {1} in {2} seconds \n".format (i,fc,str((time.clock() - beginTime1a)))
    
outFile.close()


print "Finished processing"
print("Total elapsed time (minutes): " + str((time.clock() - beginTime)/60))


