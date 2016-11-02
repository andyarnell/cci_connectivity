This script will join a shapefile to another shapefile -OR- join a .dbf file to a shapefile. The results are saved as a new shapefile with the original field names (NOT the "joined" field names  e.g. streets.id, streets.name etc.) There's an optional argument to drop unwanted fields in the output shapefile.

The point of writing this script was that there is no easy way to join 2 files and save the results without using many ArcToolBox tools. This script combines the following tools: MakeFeatureLayer, MakeTableView, AddJoin, ListFields, MakeFeatureLayer, CopyFeatures & DeleteField.

The script was written to be used "stand-alone" at a command prompt. It could be easily modified for use as a tool in ArcToolBox or run from pythonwin.

Feel free to send comments or questions to:
R.D. Harles
rdh@adci.com