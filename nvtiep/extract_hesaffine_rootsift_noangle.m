function extract_hesaffine_rootsift_noangle(DB, startShotInd, endShotInd)
% example run
% extract_hesaff_rootsift_noangle('INS2013', 1, 1)

% IMPORTANT NOTE
% Du lieu duoc luu truc tiep len server dir --> next version se chinh lai de luu tren local tmp cua tung node, sau khi finish se upload len server dir
% dung binary hesaffine --> du lieu luu ra file trung gian --> convert ve format dung chung nhu perdoch

DB = 'INS2013';
switch DB
case 'INS2013'
    work_dir = fullfile('/net/per610a/export/das11f/ledduy/plsang/nvtiep/INS/',DB);
end

feature_config = '-hesaff -rootsift -noangle';
feature_dir = strrep(feature_config, '-', '');
feature_dir = strrep(feature_dir, ' ', '_');

%	lst_shots_file = '/net/per610a/export/das11f/ledduy/plsang/nvtiep/INS/INS2013/meta/lst_shots.mat';
%	db_frame_dir = '/net/per610a/export/das11g/caizhizhu/ins/ins2013/frames_png';
%	db_feat_dir = '/net/per610a/export/das11f/ledduy/plsang/nvtiep/INS/INS2013/hesaff_rootsift_noangle_mat';

% ds cac shotID - tao ra bang cach dung lenh >> ls /net/per610a/export/das11g/caizhizhu/ins/ins2013/frames_png
lst_shots_file = fullfile(work_dir, '/meta/lst_shots.mat');

% keyframe dir - imported from CZ
db_frame_dir = '/net/per610a/export/das11g/caizhizhu/ins/ins2013/frames_png';

% output feature dir
db_feat_dir = fullfile(work_dir,[feature_name '_mat']); 

if ~exist(db_feat_dir, 'dir')
	mkdir(db_feat_dir);
end

% code nay thuong cho ket qua tot hon so voi perdoch
exe = '/net/per610a/export/das11f/ledduy/plsang/nvtiep/tool/compute_descriptors_64bit.ln'; 
run('/net/per610a/export/das11f/ledduy/plsang/nvtiep/libs/vlfeat-0.9.18/toolbox/vl_setup.m');

% tmp dir la can thiet
tmp_dir = '/tmp';
sift_dir = fullfile(tmp_dir, feature_dir);
if ~exist(sift_dir, 'dir')
	mkdir(sift_dir);
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
	
	% bug co kha nang xay ra neu shot_feature_file ko phai unique khi chay tren grid, 
	% doi voi INS13 - shotID la duy nhat
	shot_feature_file = fullfile(db_feat_dir, [shot_name,'.mat']);
	if exist(shot_feature_file, 'file') && ~renew
		continue;
	end
	% Load all frames of a shot
	fid = fopen(fullfile(shot_frame_dir,'frames.txt'));
	frame_folders = textscan(fid, '%s');
	fclose(fid);
	frame_folders = frame_folders{1};
	
    % Number of frames
    num_frame = length(frame_folders);
	clip_kp = cell(1,num_frame);
	clip_desc = cell(1,num_frame);
	clip_frame = cell(num_frame,1);
	
	% Extract feature using compute_descriptors_64bit.ln hesaff rootsift noangle
	for k=1:num_frame
		frame_name = frame_folders{k};
		frame_path = fullfile(shot_frame_dir, frame_name);
		sift_filename = fullfile(sift_dir, [shot_name,'_',frame_name]);
		sift_filename = strrep(sift_filename, 'png', 'txt');
		clip_frame{k}=frame_name(1:end-4);
		
		cmd = sprintf('%s %s -i %s -o1 %s', exe, strrep(feature_config,'root',''), frame_path, sift_filename);
		unix(cmd);
		[clip_kp{k},clip_desc{k}] = vl_ubcread(sift_filename, 'format', 'oxford');
		feat_len = size(clip_desc{k},1);
		% Compute rootsift
		if ~isempty(strfind(feature_config,'rootsift'))
			sift = double(clip_desc{k});
			clip_desc{k} = single(sqrt(sift./repmat(sum(sift), feat_len, 1)));
		end
	end
	% save to .mat file
	save(shot_feature_file, 'clip_kp', 'clip_desc', 'clip_frame', '-v7.3'); 
	% remove temporary file
	unix(['rm ', sift_filename]);
end
%matlabpool('close');
unix(['rm -r ', sift_dir]);
quit;
end
