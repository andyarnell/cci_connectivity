# !/usr/bin/env python
# coding:utf-8
# Author: D.E.Smith
# Date:
# Description: Generate Hexagons.
# Credit: graber  and twhiteaker's comment from http://blogs.esri.com/esri/arcgis/2013/05/06/a-new-tool-for-creating-sampling-hexagons/
# Notes:
# ToDo: 1) Need to convert the AOI to a geometry object and compare the hexagon. if it intersects then insert into the output data setOn intersect, insert.
#       2) auto generate the output dataset
#       3) selectable area units.
# Dependencies: ArcGIS Desktop 10.1+, python 2.7
# Archetecture: 32bit, 64bit (wuth proper installs)

# Import system modules
import sys, string, os, time, string, math, arcpy
from arcpy import env
import datetime
import arcpy.da
starttime = datetime.datetime.now()

env.overwriteOutput = True


# Change parameters below to suit your needs
extentlayer = "C:/Data/cci_connectivity/scratch/half_degree_mainland_afr_prj.shp" #Input to get Extent from'
output_tot = "C:/Data/cci_connectivity/scratch/hexagons.gdb/hex_prj50000kmsq" #Ouput Location
hexareastr = 50000 #area of hexagons (in kmsq if projection is in meters)
hexarea = float(hexareastr) * float(1000000) #area conversion betoween km and sq meteres.

triarea = hexarea / 6
oneside = math.sqrt((triarea * 4) / math.sqrt(3))
halfside = oneside / 2
# Need to recondince
_oneHi = halfside * halfside
oneHi_ =oneside * oneside
_oneHi_ = oneHi_ - _oneHi
onehi = math.sqrt(_oneHi_)
#------
longway = oneside * 2
shortway = onehi * 2

desc = arcpy.Describe(extentlayer)
sr = desc.spatialreference

minx = desc.extent.XMin
miny = desc.extent.YMin
maxx = desc.extent.XMax
maxy = desc.extent.YMax
x_range = maxx - minx
y_range = maxy -miny


distancex = oneside + halfside
distancey = shortway

th = int((x_range + longway + oneside + 0.02) / distancex)* int((y_range + shortway + shortway) / distancey)
oum = str(th) + "Will Cover the Extent Area"
print oum
arcpy.AddMessage(oum)
arcpy.AddMessage("Generating Hexagons…")


# Open an InsertCursor
#
cursor = arcpy.da.InsertCursor(output_tot, ("SHAPE@"))


for xc in range(int((x_range + longway + oneside + 0.02) / distancex)):
    centerx = (minx + (xc * distancex)) - .01
    #if (xc%10) == 0:
    print "On Row" + str(xc) + "of" + str(int((x_range + shortway) / distancex))
    if (xc%2) == 0:
        ystart = miny
    else:
        ystart = miny - onehi
    for yc in range(int((y_range + shortway + shortway) / distancey)):
        print "3"
        centery = ystart + (yc * distancey)
        #Hex Generation
        gonarray = arcpy.Array()

        pt1 = arcpy.Point()
        pt1.X = centerx + halfside
        pt1.Y = centery + onehi
        gonarray.add(pt1)

        pt2 = arcpy.Point()
        pt2.X = centerx + oneside
        pt2.Y = centery
        gonarray.add(pt2)

        pt3 = arcpy.Point()
        pt3.X = centerx + halfside
        pt3.Y = centery - onehi
        gonarray.add(pt3)

        pt4 = arcpy.Point()
        pt4.X = centerx - halfside
        pt4.Y = centery - onehi
        gonarray.add(pt4)

        pt5 = arcpy.Point()
        pt5.X = centerx - oneside
        pt5.Y = centery
        gonarray.add(pt5)

        pt6 = arcpy.Point()
        pt6.X = centerx - halfside
        pt6.Y = centery + onehi
        gonarray.add(pt6)

        pt7 = arcpy.Point()
        pt7.X = centerx + halfside
        pt7.Y = centery + onehi
        gonarray.add(pt7)


        op = arcpy.Polygon (gonarray)
        # check to see if the polygon intersects the extent if so insert
        #if op.touches(extentlayer) == True:
        cursor.insertRow((op,))
        gonarray.removeAll()


del desc
del arcpy

endtime = datetime.datetime.now()

td = endtime - starttime



print "Total Processing Timez {0}".format(td)
