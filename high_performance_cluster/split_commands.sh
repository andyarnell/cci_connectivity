#This script expects to find a file called slurm_submit.command_line in the directory where it is run
#which contains the line application="command_line"
#It will then replace the application with each line from its input file and output a file called
#submit_"prefix", where it assumes the last thing on each line of the input is "prefix" followed by a number
#Usage:
#sh split_commands <name of file containing conefor command lines>
while read line 
do
prefix=`echo $line | sed 's/.*prefix //'`
sed "s/command_line/$line/" slurm_submit.command_line >submit_$prefix
done < $1
exit
