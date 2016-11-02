##aim: calcualte  area-weighted average probabilities of nodes within cells
##that are within max dispersal dsit of each other
#this aims to give probability of dispersal between cells
##and can be used to measure overall metrics for say PC, ECA etc.
##and the dPC of each cell

##created by Andy Arnell 18/02/2016

print "Importing packages"

import os, sys, string
import arcpy
from arcpy import env
from arcpy.sa import *
import glob
import string
from sets import Set

import time

print "Setting local parameters and inputs"

#Check out the ArcGIS Spatial Analyst extension license
arcpy.CheckOutExtension("Spatial")

env.overwriteOutput = True

beginTime = time.clock()

#Set environment settings


sourceFolder="C:/Data/cci_connectivity/scratch/conefor_runs/importances"
tempFolder="C:/Data/cci_connectivity/scratch"
outFolder="C:/Data/cci_connectivity/scratch/conefor_runs/eca_runs/interCell/raw_dist"

fcCells = "C:/Data/cci_connectivity/scratch/grids/grid_mainland_afr.shp"


arcpy.env.workspace=sourceFolder

nodeField="nodeAggID" 
areaField="SUM_AREA_G"


print "Making a list of feature classes"
listFCs=arcpy.ListFeatureClasses("*impJoin*")


print "number of feature classes: {0}".format(str(len(listFCs)))

#getting projection system (assuming not using geodesic due to processing times)
coord_templates="C:/Data/cci_connectivity/scratch/coord_templates"
CS_FC=coord_templates+"/"+"azim_equidist.shp"
CS=desc=arcpy.Describe(CS_FC)
coordSys=desc.spatialReference

#setting counters

i=0
k=0
memoryFeature = "in_memory" + "\\" + "myMemoryFeature"
memoryFeatureFC = "in_memory" + "\\" + "memoryFeatureFC"
memoryFeatureFCPRJ= tempFolder+"/"+"memoryFeatureFCPRJ.shp" #"in_memory" + "\\" + "memoryFeatureFCPRJ"
memoryFeatureCell = "in_memory" + "\\" + "myMemoryFeatureCell"
memoryFeatureNear = tempFolder+"/"+"memoryFeatureNear.shp"#"in_memory" + "\\" + "myMemoryFeatureNear"
memoryFeatureNearNodes = "in_memory" + "\\" + "memoryFeatureNearNodes"
memoryFeatureInNodes = "in_memory" + "\\" + "memoryFeatureInNodes"

#defining a function for selcting features
def buildWhereClauseFromList(table, field, valueList):
    """Takes a list of values and constructs a SQL WHERE
    clause to select those values within a given field and table."""

    # Add DBMS-specific field delimiters
    fieldDelimited = arcpy.AddFieldDelimiters(arcpy.Describe(table).path, field)

    # Determine field type
    fieldType = arcpy.ListFields(table, field)[0].type

    # Add single-quotes for string field values
    if str(fieldType) == 'String':
        valueList = ["'%s'" % value for value in valueList]

    # Format WHERE clause in the form of an IN statement
    whereClause = "%s IN(%s)" % (fieldDelimited, ', '.join(map(str, valueList)))
    return whereClause

def between(value, a, b):
    # Find and validate before-part.
    pos_a = value.find(a)
    if pos_a == -1: return ""
    # Find and validate after part.
    pos_b = value.rfind(b)
    if pos_b == -1: return ""
    # Return middle part.
    adjusted_pos_a = pos_a + len(a)
    if adjusted_pos_a >= pos_b: return ""
    return value[adjusted_pos_a:pos_b]

wCard1="dis_sp_"
wCard2="_pr"


print "Looping through featureclasses and getting list of unique cell_ids for that species"
for FC in listFCs[1:2]:
    dispConst=100000
    inP=0.36788
    j=0
    beginTime2=time.clock()
    FCSpString=(between(FC,wCard1,wCard2))
    outFileFC = open(outFolder+"/dist_{0}.txt".format(str(FCSpString)), "w")
    outFileAWP = open(outFolder+"/AWP_{0}.txt".format(str(FCSpString)), "w")
    import math
    #dispConst = 100000
    #inP = 0.36788
    i+=1
    print "Feature class {0} of {1}: {2}".format(str(i),str(len(listFCs)),FC)
    arcpy.env.workspace=sourceFolder
    maxDispDist = "200 Kilometers"
    fields=["First_cell"]
    cursor=arcpy.da.SearchCursor(FC,fields)
    FC_cellIDs=list()
    for row in cursor:
        FC_cellIDs.append(row[0])
    FC_cellIDs=list(set(FC_cellIDs))
    print "Number of cells for feature class {0}: {1}".format(i,str(len(FC_cellIDs)))
    
    
    for cell in FC_cellIDs:
        
        outFileCell = open(outFolder+"/{0}_{1}.txt".format(str(cell),str(FC)), "w")
        j+=1
        beginTime3=time.clock()
        print "For each cell getting a list of cells within max dispersal distance"
        expression = "cell_id = {0}".format(cell)
        print "Cell number: {0} of {1} ({2}) in FC: {3}".format(j,str(len(FC_cellIDs)),expression,FC)
        arcpy.MakeFeatureLayer_management(fcCells,memoryFeature)
        
        arcpy.MakeFeatureLayer_management(memoryFeature,memoryFeatureCell,expression)
        #desc=arcpy.Describe(memoryFeatureCell)
        #print desc.extent
        #count = arcpy.GetCount_management(memoryFeatureCell)
        #print count
        
        ##################N.B. CURRENTLY NOT USING GEODESIC DISTANCES  AS ONLY AVAILABLE IN V.10.3 AND ABOVE.
        #################UPDATE TO THIS (overlap_type="WITHIN_A_DISTANCE_GEODESIC")WHEN USING 10.3
        #del memoryFeature

        arcpy.SelectLayerByLocation_management (in_layer=memoryFeature, overlap_type="WITHIN_A_DISTANCE",
                                                select_features=memoryFeatureCell,
                                                search_distance=maxDispDist, selection_type="NEW_SELECTION")
        arcpy.CopyFeatures_management(memoryFeature,memoryFeatureNear)
        fields = ["cell_id"]#,"FIRST_cell"]
        desc=arcpy.Describe(memoryFeatureNear)
        print desc.extent
        cursor1=arcpy.da.SearchCursor(memoryFeatureNear,fields)
        nearCells= list()
        for row in cursor1:
            nearCells.append(row[0])
        #print "Before number: "+ str(len(nearCells))
        a = Set(nearCells)
        b = Set(FC_cellIDs)
        nearCells = list(a.intersection(b))
        #print "After number: " + str(len(nearCells))
        del a
        del b
        if  nearCells==0:
            print "No nearby cells"
            pass
        else:
            print "Number of near cells to calculate distances between: {0}".format(str(len(nearCells)))
            del cursor1
            del fields
            arcpy.env.workspace=sourceFolder
            print "Selecting subset of near cells"
            expression = buildWhereClauseFromList(FC, "FIRST_cell", nearCells)
            print expression
            tempFC=tempFolder+"/"+"tmp"+FC
            arcpy.Select_analysis(in_features=FC, out_feature_class=tempFC, where_clause=expression)
            print "Projecting to equidistant projection"
            arcpy.Project_management(tempFC,memoryFeatureFCPRJ,coordSys)
            arcpy.MakeFeatureLayer_management(memoryFeatureFCPRJ,memoryFeatureFC)
            arcpy.env.workspace=outFolder
            print "For each cell calculating distances between nodes to those in nearby cells"
            #select the from/in nodes 
            expression="FIRST_cell = {0}".format(cell)
            arcpy.SelectLayerByAttribute_management(in_layer_or_view=memoryFeatureFC,selection_type="NEW_SELECTION",where_clause=expression)
            arcpy.CopyFeatures_management(memoryFeatureFC,memoryFeatureInNodes)
            #arcpy.SelectLayerByAttribute_management(in_layer_or_view=memoryFeatureFC,selection_type="CLEAR_SELECTION",where_clause=expression)
            memoryFeatureOut = "in_memory" + "\\" + "myMemoryFeatureOut"#"{0}_{1}_{2}".format(str(cell),str(nearCell),str(FC))
          
            for nearCell in nearCells:
                if cell > nearCell:
                    pass
                else:    
                    print "Calculating near cells with cell_id: {0}".format(nearCell)
                    #select the to/destination nodes 
                    expression="FIRST_cell = {0}".format(nearCell)
                    arcpy.SelectLayerByAttribute_management(in_layer_or_view=memoryFeatureFC,selection_type="NEW_SELECTION",where_clause=expression)
                    arcpy.CopyFeatures_management(memoryFeatureFC,memoryFeatureNearNodes)
                    #arcpy.MakeFeatureLayer_management(memoryFeatureFC,memoryFeatureNearNodes,expression)
                    try:
                        arcpy.GenerateNearTable_analysis(in_features=memoryFeatureInNodes,
                                             near_features=memoryFeatureNearNodes,
                                             out_table=memoryFeatureOut,
                                             search_radius="#",location="LOCATION",
                                             angle="NO_ANGLE",closest="ALL",closest_count="0",method="PLANAR")#"GEODESIC")
                    except:
                        k+=1
                        print "\nWARNING - distance calculation failed - repairing geoetry and using erase to fix areas of overlap\n"
                        memoryFeatureErase  = tempFolder+"/"+"memErase.shp"#"in_memory" + "\\" + "myMemoryFeatureErase"
                        arcpy.Erase_analysis(memoryFeatureNearNodes,memoryFeatureInNodes,memoryFeatureErase)
                        inError= tempFolder+"/"+"anInE_{0}_{1}_{2}".format(str(cell),str(nearCell),str(FC))
                        outError= tempFolder+"/"+"anOutE_{0}_{1}_{2}".format(str(cell),str(nearCell),str(FC))
                        arcpy.CopyFeatures_management(memoryFeatureInNodes,inError)
                        arcpy.CopyFeatures_management(memoryFeatureNearNodes,outError)
                        arcpy.RepairGeometry_management(memoryFeatureInNodes)
                        arcpy.RepairGeometry_management(memoryFeatureInNodes)
                        arcpy.GenerateNearTable_analysis(in_features=memoryFeatureInNodes,
                                             near_features=memoryFeatureErase,
                                             out_table=memoryFeatureOut,
                                             search_radius="#",location="LOCATION",
                                             angle="NO_ANGLE",closest="ALL",closest_count="0",method="PLANAR")#"GEODESIC")
                        print "\n Processing distances was successful for fixed feature classes!\n"
                    print 'Fixing FIDs to match featureclass IDs'
                    arcpy.AddField_management(memoryFeatureOut,"inArea","DOUBLE")
                    arcpy.AddField_management(memoryFeatureOut,"nearArea","DOUBLE")
                    fc1 = memoryFeatureNearNodes
                    cursor = arcpy.da.SearchCursor(fc1, ["FID"])
                    for row in cursor:
                        SQL_stat= "FID = "+ str(row[0])
                        fc2 = memoryFeatureOut
                        cursor2 = arcpy.da.SearchCursor(fc1, [nodeField,areaField], SQL_stat)
                        for row2 in cursor2:
                            UpdatedValue = row2[0]
                            UpdatedValue2 = row2[1]
                            cursor3 = arcpy.da.UpdateCursor(fc2, ["NEAR_FID","nearArea"],"NEAR_"+SQL_stat)
                            for row3 in cursor3:
                                row3[0] = UpdatedValue
                                row3[1] = UpdatedValue2
                                cursor3.updateRow(row3)
                    fc1 = memoryFeatureInNodes
                    cursor = arcpy.da.SearchCursor(fc1, ["FID"])
                    for row in cursor:
                        SQL_stat= "FID = "+ str(row[0])
                        fc2 = memoryFeatureOut
                        cursor2 = arcpy.da.SearchCursor(fc1, [nodeField,areaField], SQL_stat)
                        for row2 in cursor2:
                            UpdatedValue = row2[0]
                            UpdatedValue2 = row2[1]
                            cursor3 = arcpy.da.UpdateCursor(fc2, ["IN_FID","inArea"],"IN_"+SQL_stat)
                            for row3 in cursor3:
                                row3[0] = UpdatedValue
                                row3[1] = UpdatedValue2
                                cursor3.updateRow(row3)
                    del row
                    del cursor
                    del row2
                    del cursor2
                    if cursor3 is True:
                        del row3
                        del cursor3
                        del row4
                        #del cursor4
                    ###sql expression > usually stops duplciation of distances (as Confefor software likes it)
                    ###e.g. instead of both node 1 to node 2 and node 2 to node 1, it is just distance for node 1 to node 2
                    ##however, earlier on used expression on whole cells so this will be already be encorporated
                    ## so only necessary on intracell distance calculations 
                    if cell == nearCell:
                        expression= "IN_FID > NEAR_FID"
                    else:
                        expression= "#"
                    txtSearch = arcpy.da.SearchCursor(memoryFeatureOut, ["IN_FID","NEAR_FID","NEAR_DIST","inArea","nearArea"],where_clause=expression)
                    
                    ########"
                    for txtRow in txtSearch:
                        dist=txtRow[2]
                        val = format(str(txtRow[0]) +"   "+str(txtRow[1])+"  "+str(round(((txtRow[2])),3)))
                        valP = format(str(txtRow[0]) +"   "+str(txtRow[1])+"  "+str(round(((txtRow[2])),3))+
                                      "  "+str(txtRow[3])+"  "+str(txtRow[4])+"   "+str(cell))+"   "+str(nearCell)+"  "+str(math.exp(-(-1*(math.log(inP)/dispConst)) * dist))+"  "+str(math.exp(-(-1*(math.log(inP)/dispConst)) * dist)*txtRow[4])
                        outFileCell.write(valP + "\n")
                        outFileFC.write(val + "\n")
                        outFileAWP.write(valP + "\n")          
            outFileCell.close()
            print "Deleting temp files"
            del nearCells
            del memoryFeatureOut
    ####get it so it updates FIDs with node ids (not essential)
    ####but MOST IMPORTNANT SO IT WORKS OUT AVERAGE AREA WEIGHTED PROB"
            print "Finished processing for {0}. That took {1} minutes".format(cell,(str(round(((time.clock() - beginTime3)/60),2))))
    outFileFC.close()
    outFileAWP.close()
    arcpy.Delete_management(memoryFeatureFCPRJ)
    arcpy.Delete_management(memoryFeatureNear)
    arcpy.Delete_management(memoryFeature)
    arcpy.Delete_management(memoryFeatureCell)
    arcpy.Delete_management(memoryFeatureFC)
    arcpy.Delete_management(tempFC)
##    del memoryFeature 
##    del memoryFeatureFC 
##    del memoryFeatureFCPRJ 
##    del memoryFeatureNear
##    del memoryFeatureCell
    #del memoryFeatureErase
    ##########################NEED SOMETHING TO GET DISTANCES FROM BIG FILE INTO SMALL"
    print "Finished processing for {0}. That took {1} minutes".format(FC,(str(round(((time.clock() - beginTime2)/60),2))))

print "Finished processing"
print "Number of errors fixed (using erase tool to limit overlap) during processing: {0}".format(str(k))
print "Total time elapsed: " +str(round(((time.clock() - beginTime)/60),2))

    
