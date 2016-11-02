
##
##    for fc in joinFC:
##        fcPath = os.path.join(arcpy.env.workspace, fc)
##        memFC = r'in_memory\memoryFeature'
##        expression=""" {0} > 0 """.format(fcNodeField)
##        print expression
##        arcpy.MakeFeatureLayer_management (fcPath, memFC,where_clause=expression)
##        arcpy.env.workspace = outFolder
##        arcpy.CopyFeatures_management(memFC,"impJoin_"+fc)
##        arcpy.env.workspace = rawFolder1
##        fieldList = ["Node","dA","dPC"]
##        #arcpy.AddField_management(txtFile,"OID","LONG")
##        #arpcy.CalculateField_management(txtFile,"OID","Node")
##        arcpy.JoinField_management(in_data=outFolder+"/"+"impJoin_"+fc, in_field=fcNodeField, join_table= txtFile, join_field=tableNodeField, fields = ["Node","dA","dPC"])
##        #arcpy.AddJoin_management(in_layer_or_view=memFC, in_field=fcNodeField, join_table= txtFile, join_field=tableNodeField, join_type="KEEP_ALL")
##        #print "copying to:" + "impJoin_"+fc
##        arcpy.env.workspace = outFolder
##        #arcpy.CopyFeatures_management(memFC,"impJoin_"+fc)
##        arcpy.Delete_management(memFC)
##        del(memFC)

                
