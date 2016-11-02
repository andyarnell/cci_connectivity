##aim: run Conefor executable for disntace and nodes fiels in the desired folder
##the conefor command line exe needs to be in the same folder.

##created by Andy Arnell 09/06/2015

print "Importing packages"

import os, sys, string
import arcpy
import subprocess
#from arcpy import env
#from arcpy.sa import *
#import string


folderName= "C:/Data/cci_connectivity/scratch/conefor_runs"

coneforName= "conefor_1.0.85_X64.exe" #"conefor1083.exe"

print "Chnaging directory to :{0}".format(folderName)
os.chdir(folderName)
os.getcwd()


dispDists=[100000]
batFile="conBatchFile.bat"
outFile=open(folderName+"/"+batFile,'w')
print "Creating batch file to call conefor for {0} species".format(str(len(dispDists)))

for dist in dispDists:
    params="-nodeFile nodes_ -conFile distances_ -* -confProb {0} 0.36788 -PC -nodetypes".format(dist)
    print params
    outFile.write(coneforName+" "+params + "\n")
outFile.close()

print "Batch file created successfully and stored here: \n {0}/{1}".format(folderName,batFile)
print "Running batch file - command line window should pop up showing progress"


subprocess.call("C:/Data/cci_connectivity/scratch/conefor_runs/conBatchFile.bat",shell=False)#(folderName+"/"+batFile)
#stdout, stderr = p.communicate()
#os.system(folderName+"/"+batFile)

#cmd = "{0}/{1}".format(folderName,coneforName)
#print cmd
#import subprocess
#subprocess.call([cmd,params], shell=False)#, stdout=subprocess.PIPE)

#subprocess.call(cmd + [str(url)], shell=False)
