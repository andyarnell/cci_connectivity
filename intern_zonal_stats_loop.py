
#aim get zonal stats from rasters for corresponding feature classes 

import arcpy
from arcpy import env
from arcpy.sa import *
# Check out the ArcGIS Spatial Analyst
#  extension license
arcpy.CheckOutExtension("Spatial")

arcpy.env.overwriteOutput="True"

wkspace1=r"C:\Data\cci_connectivity\scratch\intern\euclid\buffer\split"

wkspace2=r"C:\Data\cci_connectivity\scratch\intern\projected_res_rast\projected"

wkspace3=r"C:\Data\cci_connectivity\scratch\intern\zonal_euclid"

arcpy.env.workspace=wkspace1

fcList=arcpy.ListFeatureClasses()
print fcList
arcpy.env.workspace=wkspace2

rstList=arcpy.ListRasters()

print rstList
#arcpy.env.workspace=wkspace3


for fc in fcList:
        #print str(fc.split("_")[1])
        fc_id=fc.split("_")[1]
        for rst in rstList:
                rst_id=rst[:-4]
                #print rst_id
                if str(rst_id) == str(fc_id):
                        print "zonal starting"
                        outTab= wkspace3+"/"+fc[:-4]+".dbf"
                        print wkspace1+"/"+fc
                        print wkspace2+"/"+rst
                        print outTab
                        arcpy.sa.ZonalStatisticsAsTable(wkspace1+"/"+fc, zone_field="link_id", in_value_raster=wkspace2+"/"+rst, out_table=outTab, ignore_nodata="DATA",statistics_type="ALL")
                        print "zonal stats calculated: " + outTab
                        AddJoin_management (in_layer_or_view, in_field, join_table, join_field, {join_type})
                        arcpy.CalculateField_management(
                        arcpy.CalculateField_management(in_table=outFile,field="shp_num",expression="""{}""".format(expr),expression_type="PYTHON_9.3",code_block="#")
                        arcpy.AddField_management (outFile,"id_no", field_type="TEXT",field_length=25)
                        expr="""'{0}'""".format(fc.split("_")[1])
                        print expr
                        arcpy.CalculateField_management(in_table=outFile,field="id_no",expression="""{}""".format(expr),expression_type="PYTHON_9.3",code_block="#")
                        arcpy.Copy_management(fc,outFile)
                else:
                        #print "skipping"
                        pass
