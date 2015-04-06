function generate_sgejob(sge_script_file, sh_command_file, param_format, ncore, nindex, ncoreperjob)
% Example run:
% generate_sgejob('runme.qsub.rerank_dpm.ins2013.sh', '/net/per900c/raid0/ledduy/github-projects/kaori-ins2014/nvtiep/sge_script/rerank_dpm.sgejob.sh', '%d %d\n', 500, 1000, 2)
% sge_script_file='runme.qsub.extractfeat.covdet.rootsift.ins2013.sh'
% sh_command_file='/net/per610a/export/das11f/ledduy/plsang/nvtiep/INS2013/code/sge_script/extract_feat.sgejob.sh'
% param_format='/net/per610a/export/das11f/ledduy/plsang/nvtiep/INS2013/metadata/keyframe-5/nvtiep.tv2013.test2013_new.allkeyframe.txt %d %d\n'
% generate_sgejob(sge_script_file, sh_command_file, param_format, 100, 471526)

fid = fopen(sge_script_file, 'w');
delta = ceil(nindex/ncore);
endID = 0;
for i=1:ncore
	startID = endID+1;
	endID = min(startID+delta-1, nindex);
	fprintf(fid, ['qsub -pe localslots %d -e /dev/null -o /dev/null %s ', param_format], ncoreperjob, sh_command_file, startID, endID);
end
fclose(fid);
end
