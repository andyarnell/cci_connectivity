import arcpy

arcpy.env.workspace =  r"C:\Data\cci_connectivity\raw\species\alt_clipped_ranges_c1200spp_Feb2016"
listRast=arcpy.ListRasters()
##print listRast

for rast in listRast:
    print rast
