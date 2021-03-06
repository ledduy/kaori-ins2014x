function generate_raw_ransac_sgejob_final(tv_year, feature_id, nindex, ncoreperjob)
% Copied from generate_sgejob2014
% Example run:
% tv_year: tv2013 or tv2014
% feature_id: surrey.soft.soft, surrey.hard.soft, CaizhiBest
% nindex: tong so videoID
% ncoreperjob: so cores per job
 
% Resource co the dung de chay 240job cung luc, trong do: 160jobs tren grid va 40jobs tren moi server (co 2 servers)
% Co tong cong 30 queries --> 22 queries chay tren grid, 4 queries chay tren moi server


% FIX PARAMS
tv_year = 'tv2014'; % only support 2014
nindex = 1000;
ncoreperjob = 2;

arrInput = containers.Map;
arrInput('surrey.hard.soft') = 1;
arrInput('surrey.soft.soft') = 1;
arrInput('CaizhiBest') = 1; 

if ~isKey(arrInput, feature_id)
	disp('Feature id not found (surrey.soft.soft, surrey.hard.soft, CaizhiBest)');
	quit;
end

sh_command_file = ['/net/per900c/raid0/ledduy/github-projects/kaori-ins2014/nvtiep/sge_script/compute_raw_RANSAC_final.sgejob.sh']; % CHANGED
sge_script_file = ['/net/per900c/raid0/ledduy/github-projects/kaori-ins2014/nvtiep/sge_script/runme.qsub.compute_raw_RANSAC_final.', feature_id, '.', tv_year]; % tv2014 CHANGED

% Grid config - query chay tu 9099 -> 9118
sge_script_file_grid = [sge_script_file '_grid.sh'];
% ncore: tong so job sinh ra
ncore = 400;
fid = fopen(sge_script_file_grid, 'w');
fprintf(fid, '# This file is generated by [generate_raw_ransac_sgejob_final.m] %s %s %d %d\n', tv_year, feature_id, nindex, ncoreperjob);
delta = ceil(nindex/ncore);
endID = nindex; % Set endID = nindex de khong chay tren grid nua
query_start = 9099;
query_end = 9120;
for i=1:ncore
	startID = endID+1;
	if startID > nindex
		break;
	end
	endID = min(startID+delta-1, nindex);
	fprintf(fid, ['qsub -pe localslots %d -e /dev/null -o /dev/null %s %s %d %d %d %d\n', ], ncoreperjob, sh_command_file, feature_id, startID, endID, query_start, query_end);
end
fclose(fid);

% server A
sge_script_file_per910b = [sge_script_file '_per910b.sh'];
ncore = 10; % chay 30 jobs dong thoi tren 1 server
fid = fopen(sge_script_file_per910b, 'w');
fprintf(fid, '# This file is generated by [generate_raw_ransac_sgejob_final.m] %s %s %d %d\n', tv_year, feature_id, nindex, ncoreperjob);
delta = ceil(nindex/ncore);
endID = 0;
query_start = 9099;
query_end = 9099+15-1;
for i=1:ncore
	startID = endID+1;
	if startID > nindex
		break;
	end
	endID = min(startID+delta-1, nindex);
	fprintf(fid, ['%s %s %d %d %d %d &\n', ], sh_command_file, feature_id, startID, endID, query_start, query_end);
end
fclose(fid);

% server B
sge_script_file_per910c = [sge_script_file '_per910c.sh'];
ncore = 10; % chay 30 jobs dong thoi tren 1 serverncore = 30; % chay 30 jobs dong thoi tren 1 server
fid = fopen(sge_script_file_per910c, 'w');
fprintf(fid, '# This file is generated by [generate_raw_ransac_sgejob_final.m] %s %s %d %d\n', tv_year, feature_id, nindex, ncoreperjob);
delta = ceil(nindex/ncore);
endID = 0;
query_start = 9099+15;
query_end = 9128;
for i=1:ncore
	startID = endID+1;
	if startID > nindex
		break;
	end
	endID = min(startID+delta-1, nindex);
	fprintf(fid, ['%s %s %d %d %d %d &\n', ], sh_command_file, feature_id, startID, endID, query_start, query_end);
end
fclose(fid);

end
