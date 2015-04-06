function extract_perdoch_rootsift(DB, startShotInd, endShotInd)
% example run
% extract_perdoch_rootsift('INS2013', 1, 1)

% IMPORTANT NOTE
% Du lieu duoc luu truc tiep len server dir --> next version se chinh lai de luu tren local tmp cua tung node, sau khi finish se upload len server dir
% perdoch does not support -no_angle option

renew = false; % dung de chay lai tu dau (starting from scratch) --> ghi de len file da ton tai
addpath('/net/per610a/export/das11f/ledduy/plsang/nvtiep/funcs/perdoch_hesaff');

DB = 'INS2013';
switch DB
case 'INS2013'
    work_dir = fullfile('/net/per610a/export/das11f/ledduy/plsang/nvtiep/INS/',DB);
end

feature_config = '-perdoch -hesaff -rootsift';
feature_dir = strrep(feature_config, '-', '');
feature_dir = strrep(feature_dir, ' ', '_');

% ds cac shotID - tao ra bang cach dung lenh >> ls /net/per610a/export/das11g/caizhizhu/ins/ins2013/frames_png
lst_shots_file = fullfile(work_dir, '/meta/lst_shots.mat');

% keyframe dir - imported from CZ
db_frame_dir = '/net/per610a/export/das11g/caizhizhu/ins/ins2013/frames_png';

	% output feature dir - 1 shot = 1 file .mat - luu tat ca raw feature (da tinh rootSIFT) cua tung frame, 128-d
db_feat_dir = fullfile(work_dir,[feature_name '_mat']); 

if ~exist(db_feat_dir, 'dir')
	mkdir(db_feat_dir);
end

% open list shot file
load(lst_shots_file);
nshot = length(lst_shots);

%matlabpool('open', 8);	
% startShot & endShot dung de chay tren grid
for i=startShotInd:endShotInd
	fprintf('\r %d - %d - %d', i, startShotInd, endShotInd);
	shot_name = lst_shots{i};
	shot_frame_dir = fullfile(db_frame_dir, shot_name);
	
	% output feature file .mat
	shot_feature_file = fullfile(db_feat_dir, [shot_name,'.mat']);
	if exist(shot_feature_file, 'file') && ~renew
		continue;
	end
	
	% Load all frames of a shot
	% CZ tao file frames.txt cho moi dir shotID, luu danh sach cac keyframeID
	fid = fopen(fullfile(shot_frame_dir,'frames.txt'));
	frame_folders = textscan(fid, '%s');
	fclose(fid);
	frame_folders = frame_folders{1};
	
    % Number of frames
    num_frame = length(frame_folders);
	clip_kp = cell(1,num_frame);
	clip_desc = cell(1,num_frame);
	clip_frame = cell(num_frame,1);
	
	% Extract feature using perdoch hesaff rootsift
	for k=1:num_frame
		frame_name = frame_folders{k};
		frame_path = fullfile(shot_frame_dir, frame_folders{k});
		
		% dung de bo di file-ext, eg. '.png'
		clip_frame{k}=frame_name(1:end-4);
		
		% call function of perdoch
		[clip_kp{k},clip_desc{k}] = mxhesaff(frame_path,~isempty(strfind(feature_config,'root')),false);
	end
	% save to .mat file
	% -v7.3: dung de luu big data
	save(shot_feature_file, 'clip_kp', 'clip_desc', 'clip_frame', '-v7.3'); 
end
%matlabpool('close');
quit;
end
