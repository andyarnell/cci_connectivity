
import arcpy


arcpy.env.overwriteOutput="True"

wkspace1=r"C:\Data\cci_connectivity\scratch\intern\clipped_sel"
wkspace2=r"C:\Data\cci_connectivity\scratch\intern\clipped_sel_append"
outFile=wkspace2+"/"+"append_clip_sel.shp"

arcpy.env.workspace=wkspace1
fcList =arcpy.ListFeatureClasses()
print fcList
for fc in fcList:

    if fc==fcList[0]:
        print fc
        print outFile
        arcpy.Copy_management(fc,outFile)
        arcpy.AddField_management (outFile,"shp_num", field_type="TEXT",field_length=25)
        expr="""'{0}'""".format(fc[:-4])
        print expr
        arcpy.CalculateField_management(in_table=outFile,field="shp_num",expression="""{}""".format(expr),expression_type="PYTHON_9.3",code_block="#")
        arcpy.AddField_management (outFile,"id_no", field_type="TEXT",field_length=25)
        expr="""'{0}'""".format(fc.split("_")[1])
        print expr
        arcpy.CalculateField_management(in_table=outFile,field="id_no",expression="""{}""".format(expr),expression_type="PYTHON_9.3",code_block="#")
        arcpy.Copy_management(fc,outFile)
        print "Created: " + outFile
           
    else:
        #outFile=wkspace2+"/"+"append_clipped_sel.shp"
        arcpy.AddField_management (fc,"shp_num", field_type="TEXT",field_length=25)
        expr="""'{0}'""".format(fc[:-4])
        print expr
        arcpy.CalculateField_management(in_table=fc,field="shp_num",expression="""{}""".format(expr),expression_type="PYTHON_9.3",code_block="#")
        arcpy.AddField_management (fc,"id_no", field_type="TEXT",field_length=25)
        expr="""'{0}'""".format(fc.split("_")[1])
        print expr
        arcpy.CalculateField_management(in_table=fc,field="id_no",expression="""{}""".format(expr),expression_type="PYTHON_9.3",code_block="#")
        arcpy.Append_management([fc],outFile)
        print "appended: " + str(fc)


