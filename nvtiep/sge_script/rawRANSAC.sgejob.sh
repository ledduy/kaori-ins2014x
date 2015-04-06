# Written by Duy Le - ledduy@ieee.org
# Last update Jun 26, 2012
#!/bin/sh
# Force to use shell sh. Note that #$ is SGE command
#$ -S /bin/sh
# Force to limit hosts running jobs
#$ -q all.q@@bc3hosts
# Log starting time
date 
# change to your code directory here
cd /net/per900c/raid0/ledduy/github-projects/kaori-ins2014/nvtiep/
# Log info of current dir
pwd
# run your command with parameters ($1, $2,...) here, string variable is put in ' '
matlab -nodisplay -r "rerank_using_DPM_and_RANSAC( $1, $2 )"
# Log ending time
date
