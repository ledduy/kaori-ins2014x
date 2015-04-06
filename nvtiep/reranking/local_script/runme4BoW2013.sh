# change to your code directory here
cd /net/per900c/raid0/ledduy/github-projects/kaori-ins2014/nvtiep
# Log info of current dir
pwd
# run your command with parameters ($1, $2,...) here, string variable is put in ' '
matlab -nodisplay -r "processOneRun('run_configs/tv2013.surrey.soft.soft.latefusion.asym.cfg', 'tv2013', 'query2013', 'test2013', 10000); quit;"
matlab -nodisplay -r "processOneRun('run_configs/tv2013.surrey.hard.soft.latefusion.asym.cfg', 'tv2013', 'query2013', 'test2013', 10000); quit;"
matlab -nodisplay -r "processOneRun('run_configs/tv2013.perdoch.soft.soft.latefusion.asym.cfg', 'tv2013', 'query2013', 'test2013', 10000); quit;"
# Log ending time
date
