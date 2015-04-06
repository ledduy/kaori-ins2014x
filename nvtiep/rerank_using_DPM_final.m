function rerank_using_DPM_final(feature_id, start_video_id, end_video_id, query_start, query_end)

% feature_id: 'surrey.soft.soft'

if nargin == 0
	%query_id = '9074';
	start_video_id = 0;
	end_video_id = 999;
	%lookup_fname = [query_id,'/TRECVID2013_', num2str(start_video_id),'.res'];
end

dpm_code_dir = '/net/per900c/raid0/ledduy/github-projects/kaori-ins2014/voc-release5';
addpath(fullfile(dpm_code_dir, 'features'));
addpath(fullfile(dpm_code_dir, 'gdetect'));
addpath(fullfile(dpm_code_dir, 'bin'));
addpath(fullfile(dpm_code_dir, 'model'));

n_keyframes = 0;

% number of detection per frame to save
N_DETECTIONS = 1;	% just save the first one (i.e the one with highest score)
DETECTION_THRESHOLD = -2.0;

% base level path configuration
data_name = 'tv2014';
test_pat = 'test2014';
query_pat = 'query2014'

arrInput = containers.Map;
arrInput('surrey.hard.soft') = 'R2_tv2013.surrey.hard.soft.latefusion.asym_fg+bg_0.1_hesaff_rootsift_noangle_akmeans_1000000_100000000_50_kdtree_8_800_v1_f1_1_avg_pooling_full_notrim_clip_idf_nonorm_kdtree_3_0.0125_-1_dist_avg_autoasym_ivf_0.5';
arrInput('surrey.soft.soft') = 'R2_tv2013.surrey.soft.soft.latefusion.asym_fg+bg_0.1_hesaff_rootsift_noangle_akmeans_1000000_100000000_50_kdtree_8_800_v1_f1_3_0.0125_avg_pooling_full_notrim_clip_idf_nonorm_kdtree_3_0.0125_-1_dist_avg_autoasym_ivf_0.5';
arrInput('CaizhiBest') = 'R2_tv2013.CaizhiBest'; 

arrOutput = containers.Map;
arrOutput('surrey.hard.soft') = 'R3_tv2013.DPM.surrey.hard.soft.latefusion.asym_fg+bg_0.1_hesaff_rootsift_noangle_akmeans_1000000_100000000_50_kdtree_8_800_v1_f1_1_avg_pooling_full_notrim_clip_idf_nonorm_kdtree_3_0.0125_-1_dist_avg_autoasym_ivf_0.5';
arrOutput('surrey.soft.soft') = 'R3_tv2013.DPM.surrey.soft.soft.latefusion.asym_fg+bg_0.1_hesaff_rootsift_noangle_akmeans_1000000_100000000_50_kdtree_8_800_v1_f1_3_0.0125_avg_pooling_full_notrim_clip_idf_nonorm_kdtree_3_0.0125_-1_dist_avg_autoasym_ivf_0.5';
arrOutput('CaizhiBest') = 'R3_tv2013.DPM.CaizhiBest';

if ~isKey(arrInput, feature_id)
	disp('Feature id not found (surrey.soft.soft, surrey.hard.soft, CaizhiBest)');
	quit;
end

% arPath = 'tv2014/test2014/';
ROOT_DIR = '/net/per610a/export/das11f/ledduy/trecvid-ins-2014/'
ROOT_RESULT_DIR = fullfile(ROOT_DIR, 'result', data_name, test_pat);

LOOK_UP_DIR = fullfile(ROOT_RESULT_DIR, arrInput(feature_id));
LOG_FILE = fullfile(ROOT_DIR, 'tmp/rerank_using_DMP.txt');

BASE_RESULT_DIR = fullfile(ROOT_RESULT_DIR, arrOutput(feature_id));
BASE_MODEL_DIR = fullfile(ROOT_DIR, '/model/ins-dpm/', data_name, query_pat);

% tam thoi KO THAY DOI vi duoc dung de lay cac tap tin .prg --> TO CHUC thanh cac video TRECVID2013_1, etc
BASE_DIR = '/net/per610a/export/das11f/ledduy/trecvid-ins-2013/';
BASE_IMG_DIR = '/net/per610a/export/das11f/ledduy/trecvid-ins-2013/keyframe-5/tv2013/test2013-new/';
BASE_CONFIG_DIR = fullfile(BASE_DIR, 'metadata/keyframe-5/tv2013/'); 
BASE_LOOKUP_PATH = fullfile(BASE_CONFIG_DIR, 'test2013-new/');

LOCAL_DIR = fullfile('/tmp/dpm/', arrInput(feature_id));

TEMP_IMG_DIR = [LOCAL_DIR 'untar_kf/'];

if ~exist(TEMP_IMG_DIR, 'dir')
	try
		mkdir(TEMP_IMG_DIR);
		% make folder writable by all users
		fileattrib(TEMP_IMG_DIR, '+w', 'a');
	catch
		error('error creating TEMP_IMG_DIR');
	end
end

if ~exist(BASE_RESULT_DIR, 'dir')
	try
		mkdir(BASE_RESULT_DIR);
		% make folder writable by all users
		fileattrib(BASE_RESULT_DIR, '+w', 'a');
	catch
		error('error creating BASE_RESULT_DIR');
	end
end

for q_id = query_start:query_end
	query_id = num2str(q_id);
	% load model
	model_path = fullfile(BASE_MODEL_DIR, query_id, ['query_' query_id '_final.mat']);
	temp = load(model_path);
	model = temp.model;

	% create folder containing result file for this video id
	final_result_dir = fullfile(BASE_RESULT_DIR, query_id);
	if ~exist(final_result_dir, 'dir')
		try
			mkdir(final_result_dir);
			% make folder writable by all users
			fileattrib(final_result_dir, '+w', 'a');
		catch
			error('error creating final_result_dir');
		end
	end

	% get scale factor 
	query_config_path = fullfile(BASE_MODEL_DIR, query_id, [query_id '.cfg']);
	query_config_file = fopen(query_config_path, 'r');
	tline = fgetl(query_config_file);
	r = regexp(tline, ':', 'split');
	scale = str2num(r{2});
	fclose(query_config_file);

	for id = end_video_id:-1:start_video_id
		lookup_fname = [query_id,'/TRECVID2013_', num2str(id),'.res'];
		% Log
		logfile=fopen(LOG_FILE,'a');
		fprintf(logfile, 'Query: %d. VidId: %d - (%d - %d)\n', q_id, id, start_video_id, end_video_id);
		fclose(logfile);
		fileattrib(LOG_FILE, '+w', 'a');
		% get list of keyframes to perform detection
		lookup_dpm_path = fullfile(LOOK_UP_DIR, lookup_fname);
		dpm_lookup_file = fopen(lookup_dpm_path, 'r');
		dpm_list = [];
		if dpm_lookup_file ~= -1
			dpm_list = textscan(dpm_lookup_file, '%s #$# %s #$# %s');
			dpm_list = dpm_list{1};
		else
			continue;
		end
		fclose(dpm_lookup_file);
		
		video_id = ['TRECVID2013_' int2str(id)];
		% check if result file exist 
		%if exist([final_result_dir query_id '_' video_id '.res'], 'file')
		%	continue;
		%end
		if exist(fullfile(final_result_dir, [video_id '.res']), 'file')
			continue;
		end
		
		% detail level path configuration
		shots_dir = [BASE_IMG_DIR video_id '/'];
		temp_result_dir = LOCAL_DIR;		
		lookup_video_path = [BASE_LOOKUP_PATH video_id '.prg'];

		% create result file at temporary directory
		result_file = [temp_result_dir query_id '_' video_id '.res']
		fout = fopen(result_file,'w');
		% make file writable by all users
		fileattrib(result_file, '+w', 'a');
		
		% get list of images to perform detection on
		lookup_file = fopen(lookup_video_path, 'r');
		
		line = fgets(lookup_file); % moi line tuong ung voi 1 keyframev
		while ischar(line)
			line = strtrim(line);
			kf_id = line;
			r = regexp(line,'_KSC', 'split');
			shot_id = r{1}; % trong keyframe name, co luu thong cua shotID
			
			if ~isempty(dpm_list) % check xem shotID co nam trong ds phai excute DPM ko (thuong la top K shots tra ve tu baseline BOW)
				if ~ ismember(shot_id, dpm_list)
					line = fgets(lookup_file); % skip
					continue;
				end
			end
			
			% get shot_id.tar file --> gom cac keyframe trong folder thanh file .tar de tien cho viec chay tren grid
			% mot folder co the co nhieu file .tar boi vi do cach organize tu trecvid --> new_trecvid - re-organize de dam bao moi folder co so luong keyframe can bang, tien cho chay tren grid
			img_dir = [TEMP_IMG_DIR query_id '_' video_id '/' shot_id '/'];
			if ~exist(img_dir, 'dir') % check xem cac keyframe cua shot da duoc extract ra thu muc tam thoi chua, neu da thi skip
				try
					mkdir(img_dir);
					% make folder writable by all users
					fileattrib(img_dir, '+w', 'a');
					current_dir = pwd;
					% extract tar file
					cd(img_dir);
					shot_tar_dir = [shots_dir shot_id '.tar'];
					unix(sprintf('tar -xvf %s', shot_tar_dir));
					cd(current_dir);
				catch
					error('error creating img_dir');
				end
			end
			
			% toi buoc nay chung ta co duoc keyframe cua shot can phai chay DPM
			
			img_path = [img_dir kf_id '.jpg'];
			n_keyframes = n_keyframes + 1; % bien thua (???)
			
			% perform detection in each image and write results to file
			% corresponding to this video
			im = imread(img_path);
			% increase image size (for dealing with small objects in trecvid ins 2013 & 2012)
			im = imresize(im, scale, 'lanczos3');
			
			% perform detection
			pyra = featpyramid(im, model);
			[ds, bs] = gdetect(pyra, model, DETECTION_THRESHOLD);
			
			% write results
			for j=1:N_DETECTIONS
				% format: KeyFrameID #$# ShotID #$# DPMScore #$# Left #$# Top #$# Right #$# Bottom #$# ComponentID
				fprintf(fout, '%s #$# %s #$# %f #$# %f #$# %f #$# %f #$# %f #$# %f \n', kf_id, shot_id, ds(j,6), ds(j,1), ds(j,2), ds(j,3), ds(j,4), ds(j,5));
			end
			
			% free memory 
			clear pyra;
			clear ds;
			clear bs;
			
			% write to log
			disp(['Finish Detection on ' line ' by model query_' query_id ' with scale factor = ' num2str(scale)]);
			
			line = fgets(lookup_file);
			
		end		% end reading video_id.prg
		fclose(lookup_file);
		
		fclose(fout);
		% move result file to final directory
		status = unix(sprintf('mv %s %s', result_file, fullfile(final_result_dir, [video_id '.res'])));
		if status == 0
			try
				delete(result_file);
			catch
				error('Cannot delete temporary result file');
			end
		end
		% delete extracted img files
		if exist([TEMP_IMG_DIR query_id '_' video_id '/'], 'dir')
			unix(sprintf('rm -r %s', [TEMP_IMG_DIR query_id '_' video_id '/']));
		end
		% unix(sprintf('rm -r %s', img_dir));
	end		% end detection on this video_id

end
quit

end
