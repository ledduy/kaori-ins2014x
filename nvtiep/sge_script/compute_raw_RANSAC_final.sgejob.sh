# Written by Duy Le - ledduy@ieee.org
# Last update Aug 11, 2014
#!/bin/sh
# Force to use shell sh. Note that #$ is SGE command
#$ -S /bin/sh
# Force to limit hosts running jobs
#$ -q all.q@@bc4hosts,all.q@@bc3hosts,all.q@bc201.hpc.vpl.nii.ac.jp,all.q@bc202.hpc.vpl.nii.ac.jp,all.q@bc203.hpc.vpl.nii.ac.jp,all.q@bc204.hpc.vpl.nii.ac.jp,all.q@bc205.hpc.vpl.nii.ac.jp,all.q@bc206.hpc.vpl.nii.ac.jp,all.q@bc207.hpc.vpl.nii.ac.jp,all.q@bc208.hpc.vpl.nii.ac.jp
# Log starting time
date 
# change to your code directory here
cd /net/per900c/raid0/ledduy/github-projects/kaori-ins2014/nvtiep/
# Log info of current dir
pwd
# run your command with parameters ($1, $2,...) here, string variable is put in ' '
# compute_raw_RANSAC_final(feature_id, start_video_id, end_video_id, query_start, query_end)
matlab -nodisplay -r "compute_raw_RANSAC_final( '$1', $2, $3, $4, $5 )"
# Log ending time
date
