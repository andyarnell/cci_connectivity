##
## joinfiles.py
##
## Joins a shapefile to another shapefile -OR- joins a dbf to a shapefile.
## Resets field names back to their original names in the output shapefile.
## Deleting fields from the output shapefile (5th argument) is optional.
## The "joined" shapefile is saved to a directory called output with the same shapefile name as sys.argv[1] (the first shapefile).
##
## R.D. Harles
## 09-25-07 Original Code
## 12-19-07 Replaced split(".") with rsplit(".", 1)  - The point of the split() is to separate the file name
##          from the field name.  If there happens to be a "." in the file name, the split() will incorrectly
##          split the file name instead.  By doing a rsplit(".", 1) with a maxsplit = 1, it should always correctly
##          divide the file name from the field name.
##

import sys, os, string

# Usage
args = len(sys.argv)
if args == 1:
	print '\njoinfiles.py <shpfile1> <joinfield1> <shpfile2 -OR- dbf> <joinfield2> <field list>\n'
	print ' <shpfile1> = The base shapefile'
	print ' <joinfield1> = shpfile1\'s join field'
	print ' <shpfile2 or dbf> = The shapefile or dbf to be joined'
	print ' <joinfield2> = shpeile2 or dbf\'s join field'
	print ' <fieldlist> = (OPTIONAL) The field or fields to be deleted, separated by ";" and surrounded by ""\n'	
	print '   e.g. joinfiles.py streets.shp st_name truck.shp name'
	print '   e.g. joinfiles.py streets.shp st_name truck.dbf name "id;fid_1;lane_cat"\n'
	sys.exit(1)

# Make sure spelling is correct and file exists for 1st argument
if not os.path.exists(sys.argv[1]):
    print "\n "+sys.argv[1]+" does not exist on the system, try again.\n"
    sys.exit(1)
# Make sure spelling is correct and file exists for 3rd argument
if not os.path.exists(sys.argv[3]):
    print "\n "+sys.argv[3]+" does not exist on the system, try again.\n"
    sys.exit(1)
    
# Import modules and create the geoprocessor object
try:
    # 9.2 and beyond    
    import arcgisscripting
    gp = arcgisscripting.create()
    print "\nImporting geoprocessor for 9.2 and beyond..."    
except:    
    # 9.1 and before    
    import win32com.client
    gp = win32com.client.Dispatch("esriGeoprocessing.GpDispatch.1")
    print "\nImporting geoprocessor for 9.1 and before..."  

# Set the current workspace
gp.workspace = os.getcwd()

## Convert sys.argv[1] to a layer (shp)
print "\nCreating lyr file from : " + sys.argv[1]      
gp.MakeFeatureLayer(sys.argv[1], "lyr"+sys.argv[1][:-4])           
print gp.GetMessages()

## Convert sys.argv[3] to a layer (shp)
# Does sys.argv[3] contain a .shp?
result = string.find(sys.argv[3], ".shp")
# -1 means that string.find did not match
# if sys.argv[3] contains .shp...
if result != -1:    
    print "\nCreating lyr file from : " + sys.argv[3]
    gp.MakeFeatureLayer(sys.argv[3], "lyr"+sys.argv[3][:-4])           
    print gp.GetMessages()

## Convert sys.argv[3] to a layer (dbf)
# Does sys.argv[3] contain a .dbf?
result = string.find(sys.argv[3], ".dbf")
# -1 means that string.find did not match
# if sys.argv[3] contains .dbf...
if result != -1:    
    print "\nCreating lyr file from : " + sys.argv[3]
    gp.MakeTableView(sys.argv[3], "lyr"+sys.argv[3][:-4])           
    print gp.GetMessages() 

## AddJoin        
print "\nJoining " + "lyr"+sys.argv[1][:-4] + " with " + "lyr"+sys.argv[3][:-4]+"..."
try:
    gp.AddJoin_management("lyr"+sys.argv[1][:-4], sys.argv[2], "lyr"+sys.argv[3][:-4], sys.argv[4])                
    print gp.GetMessages()                    
except:
    print gp.GetMessages()
    print "\n*** Failure joining " + "lyr"+sys.argv[1][:-4] + " with " + "lyr"+sys.argv[3][:-4] + " ***\n"    

# Start an empty list
fieldList = []

# Create the field_info for the MakeFeatureLayer tool.
print "\nGetting a list of the fields from "+"lyr"+sys.argv[1][:-4]+"..."
fields = gp.ListFields("lyr"+sys.argv[1][:-4],"*")
fields.reset()
field = fields.next()
while field:	
	
	# Append the full joined file.field name (e.g. Streets.NAME)
	fieldList.append(field.Name)
	print field.Name
	
	# Get only the field name, not the file name.
	# Use rsplit() with a maxsplit=1 instead of split().
	# rsplit() splits from the right in case there are "."'s in the file name.
	base = field.Name.rsplit(".", 1)

	# Append just the field name (e.g. NAME)
	fieldList.append(base[1])

	# Append the keyword 'VISIBLE;'. This means "keep the field in the output file".    
	fieldList.append("VISIBLE;")
	
	field = fields.next()    

# Join all the components together (file.field field VISIBLE;), separated by a space, for the field_info option on the MakeFeatureLayer tool.
fieldinfo = " ".join(fieldList)

# Create a new Feature Layer with "proper" field names, not those 'file.field' field names
try:
    print "\nResetting field names for output file " + "output/"+sys.argv[1]+"..."
    gp.MakeFeatureLayer_management("lyr"+sys.argv[1][:-4], "fixlyr"+sys.argv[1][:-4], "", "",  ""+ fieldinfo +"")    
    print gp.GetMessages()
except:
    print "\nMakeFeatureLayer Failed.\n"
    print gp.GetMessages()    
   
# Create an output directory so that we can give the output shapefile the same name as the input shapefile name.
if not os.path.exists("output"):
    print "\nCreating output directory..."
    os.mkdir("output")

## CopyFeatures
# Create a new shapefile from the "fixed" layer and put it in an output directory
print "\nCopyFeatures " + "fixlyr"+sys.argv[1][:-4] + " to " + "output/"+sys.argv[1]+"..."
gp.CopyFeatures("fixlyr"+sys.argv[1][:-4], "output/"+sys.argv[1])            
print gp.GetMessages()

# If no fields are to be dropped (no sys.argv[5]), DeleteField fails & the script finishes cleanly.
try:    
    # The field, or fields, to be dropped from the user given sys.argv[5] list.    
    gp.DeleteField("output/"+sys.argv[1], sys.argv[5])
    print "\nDropping field(s) "+sys.argv[5]+" from output/"+sys.argv[1]
    print gp.GetMessages()
except:    
    print ""   

print "\nDone.\n"


