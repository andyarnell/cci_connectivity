import os, sys, string
import arcpy
from arcpy import env
from arcpy.sa import *
import glob
import string
from sets import Set
import math 
import time

print "Setting local parameters and inputs"

#Check out the ArcGIS Spatial Analyst extension license
arcpy.CheckOutExtension("Spatial")

env.overwriteOutput = True

beginTime = time.clock()

#Set environment settings

sourceFolder1="C:/Data/cci_connectivity/scratch/conefor_runs/importances"
sourceFolder2="C:/Data/cci_connectivity/scratch/conefor_runs/eca_runs/interCell/raw_dist"
tempFolder="C:/Data/cci_connectivity/scratch"
outFolder="C:/Data/cci_connectivity/scratch/conefor_runs/eca_runs/interCell"



arcpy.env.workspace=sourceFolder2
print "Making a list of tables"
tableList=arcpy.ListTables("*awp_*")
print str(tableList)

cellField="First_cell"


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

wCard1="AWP_"
wCard2=".txt"

print "Looping through list of feature classes"
i=0

inMemFC="in_memory"+"\\"+"inMemFC"

for table in tableList[0:2]:
    i+=1
    print "Feature class {0} of {1}: {2}".format(i,str(len(tableList)),table)
    dispConst=100000
    inP=0.36788
    arcpy.env.workspace=sourceFolder1
    spName = between(table,wCard1,wCard2)
    print spName
    FCList=arcpy.ListFeatureClasses("*impJoin_dis_sp_{0}*".format(spName))
    
    for FC in FCList:
        fields=cellField
        cellList=list()
        cursor1=arcpy.da.SearchCursor(FC,[fields])
        for row in cursor1:
            cellList.append(row[0])
    cellList = list(set(cellList))
    print str(len(cellList))
    fields="*"
    arcpy.env.workspace=sourceFolder2
    print table
    
    for cell in cellList:
        print "Cell ID: {0}".format(cell)
        sumP_area=0
        sumArea=0
        awp=0
        expression = "Field16={0}".format(cell)
        #print expression
        cursor2=arcpy.da.SearchCursor(table,[fields])#,expression)
        for row in cursor2:
            if row[12]==cell and row[15]<>cell:
                inArea = row[7]
                nearArea= row[9]
                #print inArea
                #print nearArea
                dist= row[5]
                p = math.exp(-(-1*(math.log(inP)/dispConst)) * dist)
                #print p
                p_Area =  p * nearArea
                #print p_Area
                area=nearArea
                #print area
                sumP_area=sumP_area + p_Area
                #print sumP_area
                sumArea=sumArea+area
                #print sumArea
                awp=sumP_area/sumArea
        print "Cell id = {0} and AWP = {1}".format(str(cell),str(awp))
                
##
##    
    
    
