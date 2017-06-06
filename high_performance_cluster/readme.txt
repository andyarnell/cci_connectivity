Put these three files into each directory where you want to do things (e.g. eco1).
Then cd to that directory and type

sh split_commands.sh <name of command line file to be split up>

This should create a set of slurm scripts called submit_<prefix>

Where I have  assumed that all your command lines end

-prefix <some unique number>

Then the second script can be run by

sh slurm_jobs.sh

which will go through the list of all files beginning with the text "submit_" in the current directory and submit them to the queue

Do you think the output will be large? If so then one should perhaps do all this from directories in /scratch rather then in someone's home directory.

Does this sound OK? I suggest testing the first script to see whether it works as you expect and produces submit scripts that look right before trying the second one, and doing this on just a couple of runs at first to check everything functions OK.

You might also need to adjust the times in the submit scripts - at the moment this is set to one minute (you can edit slurm_submit.command_line if you want to change this for a whole set)

