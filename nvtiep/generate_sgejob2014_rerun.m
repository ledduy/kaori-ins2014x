function generate_sgejob2014_rerun(nindex, ncoreperjob)
% Example run:
% nindex: tong so videoID
% ncoreperjob: so cores per job
% generate_sgejob2014(1000, 2) 

% Resource co the dung de chay 240job cung luc, trong do: 160jobs tren grid va 40jobs tren moi server (co 2 servers)
% Co tong cong 30 queries --> 22 queries chay tren grid, 4 queries chay tren moi server

sh_command_file = '/net/per900c/raid0/ledduy/github-projects/kaori-ins2014/nvtiep/sge_script/rerank_using_DPM2014.sgejob.sh';
sge_script_file = '/net/per900c/raid0/ledduy/github-projects/kaori-ins2014/nvtiep/sge_script/runme.qsub.rerank_using_DPM2014.ins2014-rerun';

% Grid config - query chay tu 9099 -> 9118
sge_script_file_grid = [sge_script_file '.sh'];
% ncore: tong so job sinh ra
ncore = 1000;
fid = fopen(sge_script_file_grid, 'w');
delta = ceil(nindex/ncore);
endID = 0;
query_start = 9099;
query_end = 9128;
for i=1:ncore
	startID = endID+1;
	if startID > nindex
		break;
	end
	endID = min(startID+delta-1, nindex);
	fprintf(fid, ['qsub -pe localslots %d -e /dev/null -o /dev/null %s %d %d %d %d\n', ], ncoreperjob, sh_command_file, startID, endID, query_start, query_end);
end
fclose(fid);

% server A
sge_script_file_per910b = [sge_script_file '_per910b.sh'];
ncore = 15; % chay 30 jobs dong thoi tren 1 server
fid = fopen(sge_script_file_per910b, 'w');
delta = ceil(nindex/ncore);
endID = 0;
query_start = 9121;
query_end = 9124;
for i=1:ncore
	startID = endID+1;
	if startID > nindex
		break;
	end
	endID = min(startID+delta-1, nindex);
	fprintf(fid, ['%s %d %d %d %d &\n', ], sh_command_file, startID, endID, query_start, query_end);
end
fclose(fid);

% server B
sge_script_file_per910c = [sge_script_file '_per910c.sh'];
ncore = 15; % chay 30 jobs dong thoi tren 1 serverncore = 30; % chay 30 jobs dong thoi tren 1 server
fid = fopen(sge_script_file_per910c, 'w');
delta = ceil(nindex/ncore);
endID = 0;
query_start = 9125;
query_end = 9128;
for i=1:ncore
	startID = endID+1;
	if startID > nindex
		break;
	end
	endID = min(startID+delta-1, nindex);
	fprintf(fid, ['%s %d %d %d %d &\n', ], sh_command_file, startID, endID, query_start, query_end);
end
fclose(fid);

end
