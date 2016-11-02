#selecting cells with specific numbers of patches between min and max


import arcpy
import random
from random import randint
import os
arcpy.env.overwriteOutput=True

inWkspace=r"C:\Data\cci_connectivity\scratch\intern\clipped"
outWkspace=r"C:\Data\cci_connectivity\scratch\intern\clipped_sel"
arcpy.env.workspace= inWkspace


listFC=arcpy.ListFeatureClasses()


minPatch=25

maxPatch=75

for fc in listFC:
        cur= arcpy.da.SearchCursor(fc,"cell_id")
        cellListAll=list()
        for row in cur:
                cellListAll.append(row[0])
        #remove duplicates
        cellListAll=list(set(cellListAll))
        countPatchFC=int(arcpy.GetCount_management(fc).getOutput(0))
        print "Count of patches for FC: "+ str(countPatchFC)
        if countPatchFC >= minPatch and countPatchFC <= maxPatch:
                arcpy.Copy_management(fc,outWkspace+"/"+fc)
        else: 
                print cellListAll
                inMemFC="in_memory\\inmemFC"
                cellList=list()
                      
                for cell in cellListAll:
                        print cell
                        arcpy.MakeFeatureLayer_management(fc, inMemFC,'"cell_id"={0}'.format(cell))
                        countPatch=int(arcpy.GetCount_management(inMemFC).getOutput(0))
                        print "Count of patches: " +str(countPatch)
                        arcpy.Delete_management(inMemFC)
                        if countPatch >= minPatch and countPatch <= maxPatch:
                                cellList.append(cell)
                                print "name of cell: "+str(cell)
                        else:
                                print "Not in range so skipping cell"
                                
                numb=len(cellList)
                                
                if numb>0:
                        print "List of cells in min and max range: " + str(cellList)
                        numbSel=random.randint(0,(numb-1))
                        print "Random number: " + str(numbSel)
                        cellSel=cellList[numbSel]
                        print "ID of randomly chosen cell within min and max range:"+str(cellSel)+"\n"
                        outFC = "{0}/{1}_cell{2}".format(outWkspace,str(fc[:-4]),str(cellSel))
                        print outFC
                        arcpy.Select_analysis(fc,outFC,'"cell_id"={0}'.format(cellSel))
                        print "Processed FC: "+str(outFC)
                else:
                        print "Skipping FC: " + fc
                
	
