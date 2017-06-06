for file in submit_*
do
echo submitting $file
sbatch $file
done
