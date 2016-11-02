import arcpy
from arcpy import env
env.workspace = "C:/Data"
print 'Processing...'
fc = "Updated_subset.shp"
cursor = arcpy.da.SearchCursor(fc, ["FID"])
for row in cursor:
    SQL_stat= "FID = "+ str(row[0])
    fc2 = "airports_old.shp"
    cursor2 = arcpy.da.SearchCursor(fc, ["STATE"], SQL_stat)
    for row2 in cursor2:
        UpdatedValue = row2[0]
        cursor3 = arcpy.da.UpdateCursor(fc2, ["STATE"],SQL_stat)
        for row3 in cursor3:
            row3[0] = UpdatedValue
            cursor3.updateRow(row3)
del row
del cursor
del row2
del cursor2
del row3
del cursor3

print "Done"
