function rerank_using_DPM_and_RANSAC(feature_id, start_video_id, end_video_id, query_start, query_end)

start_query_id = query_start;
end_query_id = query_end;

arr_config = containers.Map;
arr_config('surrey.hard.soft') = 'R2_tv2013.surrey.hard.soft.latefusion.asym_fg+bg_0.1_hesaff_rootsift_noangle_akmeans_1000000_100000000_50_kdtree_8_800_v1_f1_1_avg_pooling_full_notrim_clip_idf_nonorm_kdtree_3_0.0125_-1_dist_avg_autoasym_ivf_0.5';
arr_config('surrey.soft.soft') = 'R2_tv2013.surrey.soft.soft.latefusion.asym_fg+bg_0.1_hesaff_rootsift_noangle_akmeans_1000000_100000000_50_kdtree_8_800_v1_f1_3_0.0125_avg_pooling_full_notrim_clip_idf_nonorm_kdtree_3_0.0125_-1_dist_avg_autoasym_ivf_0.5';
arr_config('CaizhiBest') 	   = 'R2_tv2013.CaizhiBest';

arr_output = containers.Map;
arr_output('surrey.hard.soft') = 'R4_rawRANSAC_tv2013.surrey.hard.soft.latefusion.asym';
arr_output('surrey.soft.soft') = 'R4_rawRANSAC_tv2013.surrey.soft.soft.latefusion.asym';
arr_output('CaizhiBest') 	   = 'R4_rawRANSAC_tv2013.CaizhiBest';

if ~isKey(arr_config, feature_id)
	disp('Please check featre_id');
	quit;
end

%% base level path configuration
ex_bounding_box = 0;
RESULT_DIR = '/net/per610a/export/das11f/ledduy/trecvid-ins-2014/result/tv2014/test2014/';
LOOK_UP_DIR = fullfile(RESULT_DIR, arr_config(feature_id));
BASE_TMP_RANSAC_DIR = fullfile(RESULT_DIR, arr_output(feature_id));
LOG_FILE = '/net/per610a/export/das11f/ledduy/plsang/nvtiep/INS/INS2013/log/rerank_using_DPM_RANSAC.txt';
LOCAL_DIR = '/tmp/dpm/';

% Change when using different features BoW
%qr_raw_bow = '/net/per610a/export/das11f/ledduy/plsang/nvtiep/INS/INS2013/query/bow/fg+bg_0.1_hesaff_rootsift_noangle_akmeans_1000000_100000000_50_kdtree_8_800_kdtree_3_0.0125/raw_bow.mat';
qr_raw_bow = '/net/per610a/export/das11f/ledduy/trecvid-ins-2014/feature/keyframe-5/tv2014/query2014/bow.db_1_qr_fg+bg_0.1_hesaff_rootsift_noangle_akmeans_1000000_100000000_50_kdtree_8_800_kdtree_3_0.0125/raw_bow.mat';
db_quant_dir = '/net/per610a/export/das11f/ledduy/trecvid-ins-2014/feature/keyframe-5/tv2014/test2014/hesaff_rootsift_noangle_cluster/akmeans_1000000_100000000_50/kdtree_8_800/v1_f1_1_sub_quant';
db_frame_info_dir = '/net/per610a/export/das11f/ledduy/trecvid-ins-2014/feature/keyframe-5/tv2014/test2014/hesaff_rootsift_noangle_mat';
addpath('/net/per610a/export/das11f/ledduy/plsang/nvtiep/INS/code');
addpath('/net/per610a/export/das11f/ledduy/plsang/nvtiep/INS/code/web');
run('/net/per610a/export/das11f/ledduy/plsang/nvtiep/libs/vlfeat-0.9.18/toolbox/vl_setup.m');

% Run RANSAC for fg only, bg only, both bg and fg

% Create directory for saving raw RANSAC data
if ~exist(BASE_TMP_RANSAC_DIR, 'dir')
	try
		mkdir(BASE_TMP_RANSAC_DIR);
		% make folder writable by all users
		fileattrib(BASE_TMP_RANSAC_DIR, '+w', 'a');
	catch
		error('Error creating BASE_TMP_RANSAC_DIR');
	end
end
% Load all query
load(qr_raw_bow); 			% Dung de lay thong tin query_filenames va frame_quant_info
nquery = length(query_filenames);

for q_id = start_query_id:end_query_id
	qr_shotID = num2str(q_id);
	
	% create folder containing result file for this video id
	final_result_dir = fullfile(BASE_TMP_RANSAC_DIR, qr_shotID);
	local_result_dir = fullfile(LOCAL_DIR, qr_shotID);
	if ~exist(final_result_dir, 'dir')
		try
			mkdir(final_result_dir);
			% make folder writable by all users
			fileattrib(final_result_dir, '+w', 'a');
		catch
			error('error creating final_result_dir');
		end
	end
	if ~exist(local_result_dir, 'dir')
		try
			mkdir(local_result_dir);
			% make folder writable by all users
			fileattrib(local_result_dir, '+w', 'a');
		catch
			error('error creating local_result_dir');
		end
	end

	% get list of query images
	re = ['/' qr_shotID '/(.*.png)'];		
	query_set = cell(0);
	count = 0;
	query_id = -1;
	for i = 1:nquery	% find all frames of given query
		for topic_id = 1:length(query_filenames{i})
			[rematch, retok] = regexp(query_filenames{i}{topic_id}, re, 'match', 'tokens');
			if ~isempty(retok)
				count = count+1;
				query_set{count} = query_filenames{i}{topic_id};
				query_id = i;
			end
		end
		if query_id ~= -1
			break;
		end
	end

	for id = start_video_id:end_video_id
		lookup_fname = [qr_shotID,'/TRECVID2013_', num2str(id),'.res']
		% Log
		logfile=fopen(LOG_FILE,'a');
		fprintf(logfile, 'Query: %d. VidId: %d - (%d - %d)\n', q_id, id, start_video_id, end_video_id);
		fclose(logfile);
		fileattrib(LOG_FILE, '+w', 'a');
		% get list of keyframes to perform detection
		lookup_path = fullfile(LOOK_UP_DIR, lookup_fname);
		lookup_file = fopen(lookup_path, 'r');
		db_shot_list = [];
		if lookup_file ~= -1
			db_shot_list = textscan(lookup_file, '%s #$# %s #$# %s');
			db_shot_list = db_shot_list{1};
		else
			continue;
		end
		fclose(lookup_file);
		
		% create result file at temporary directory
		video_id = ['TRECVID2013_' int2str(id)];
		result_file = fullfile(final_result_dir, [video_id '.mat']);
		local_result_file = fullfile(local_result_dir, [video_id '.mat']);
		
		% RANSAC
		if exist(result_file, 'file')
			continue;
		else
			clear inliers_struct
			% inliers_struct{ shot_list frame_name fg_inlier_loc bg_inlier_loc fg_bg_inlier{fg_loc bg_loc} } Luu trong file "TRECVID2013_XXX.mat"
			inliers_struct.shot_list = db_shot_list;
			nshot = length(inliers_struct.shot_list);
			inliers_struct.frame_name = cell(1, nshot);
			clear db_shot_list;
			
			for shot_idx=1:nshot	% For all shots in the res file
				db_shotID = inliers_struct.shot_list{shot_idx};
				
				% get list of visual words of db_image
				db_quant_file = fullfile(db_quant_dir, [db_shotID,'.mat']);
				load(db_quant_file);		% dung de lay thong tin bins
				db_frame_info_file = fullfile(db_frame_info_dir, [db_shotID,'.mat']);
				load(db_frame_info_file);	% dung de lay thong tin clip_frame
				nframe_per_shot = length(clip_frame);
				
				% Tim frame_id cua db_image trong danh sach frame cua db_shotID
				db_set=clip_frame;
				inliers_struct.frame_name{shot_idx} = db_set;
				inliers_struct.fg_inlier_loc{shot_idx} = cell(1,nframe_per_shot);
				inliers_struct.fg_inlier_id{shot_idx} = cell(1,nframe_per_shot);
				inliers_struct.bg_inlier_loc{shot_idx} = cell(1,nframe_per_shot);
				inliers_struct.bg_inlier_id{shot_idx} = cell(1,nframe_per_shot);
				inliers_struct.fg_bg_inlier{shot_idx} = cell(1,nframe_per_shot);
				
				% Use RANSAC to find no. of inliers
				for db_frame_id=1:nframe_per_shot	% For all frames of a shot
					% db image info
					db_words_id = bins{db_frame_id};
					db_keypoint = round(clip_kp{db_frame_id}(:,:));
					inliers_struct.fg_inlier_loc{shot_idx}{db_frame_id} = cell(1, length(query_set));
					inliers_struct.fg_inlier_id{shot_idx}{db_frame_id} = cell(1, length(query_set));
					inliers_struct.bg_inlier_loc{shot_idx}{db_frame_id} = cell(1, length(query_set));
					inliers_struct.bg_inlier_id{shot_idx}{db_frame_id} = cell(1, length(query_set));
					
					for topic_id = 1:length(query_set)	% For all frames of a query
						% parse shot_id + frame name
						%[rematch, retok] = regexp(query_set{topic_id}, re, 'match', 'tokens');
						%qr_fname = retok{1}{1};
						
						% query image info
						fg_idx = frame_quant_info{query_id}.fg_index{topic_id};
						bg_idx = frame_quant_info{query_id}.bg_index{topic_id};
						qr_words_id_fg = frame_quant_info{query_id}.valid_bins{topic_id}(:,fg_idx);
						qr_words_id_bg = frame_quant_info{query_id}.valid_bins{topic_id}(:,bg_idx);
						qr_keypoint_fg = round(frame_quant_info{query_id}.query_kp{topic_id}(:, fg_idx));
						qr_keypoint_bg = round(frame_quant_info{query_id}.query_kp{topic_id}(:, bg_idx));
						
						[shared_words_fg, iqr_fg, idb_fg] = intersect(qr_words_id_fg(:), db_words_id);
						[shared_words_bg, iqr_bg, idb_bg] = intersect(qr_words_id_bg(:), db_words_id);

						knn=size(qr_words_id_fg,1);
						iqr_fg = floor((iqr_fg+knn-1)/knn);
						iqr_bg = floor((iqr_bg+knn-1)/knn);

						% RANSAC on foreground only
						frame1 = qr_keypoint_fg(:, iqr_fg);
						frame2 = db_keypoint(:,idb_fg);
						matches = [1:size(frame1,2); 1:size(frame1,2)];
						if size(frame1, 2) > 0
							[inliers, H] = geometricVerification(frame1, frame2, matches, 'numRefinementIterations', 10);
							%num_bg_inliers = num_bg_inliers+length(inliers);
							inliers_struct.fg_inlier_loc{shot_idx}{db_frame_id}{topic_id} = frame2(1:2,inliers); % Chi lay nhung points tren db image
							inliers_struct.fg_inlier_id{shot_idx}{db_frame_id}{topic_id} = shared_words_fg(inliers); % Chi lay nhung points tren db image
						end
						
						% RANSAC on background only
						frame1 = qr_keypoint_bg(:, iqr_bg);
						frame2 = db_keypoint(:,idb_bg);
						matches = [1:size(frame1,2); 1:size(frame1,2)];
						if size(frame1, 2) > 0
							[inliers, H] = geometricVerification(frame1, frame2, matches, 'numRefinementIterations', 10);
							%num_bg_inliers = num_bg_inliers+length(inliers);
							inliers_struct.bg_inlier_loc{shot_idx}{db_frame_id}{topic_id} = frame2(1:2,inliers); % Chi lay nhung points tren db image
							inliers_struct.bg_inlier_id{shot_idx}{db_frame_id}{topic_id} = shared_words_bg(inliers); % Chi lay nhung points tren db image
						end
						% RANSAC on foreground and background
						%frame1 = [qr_keypoint_fg(:, iqr_fg) qr_keypoint_bg(:, iqr_bg)];
						%frame2 = [db_keypoint(:,idb_fg) db_keypoint(:,idb_bg)];
						%matches = [1:size(frame1,2); 1:size(frame1,2)];
						
						%if size(frame1, 2) > 0
						%	[inliers, H] = geometricVerification(frame1, frame2, matches, 'numRefinementIterations', 10);
						%	inliers_struct.fg_bg_inlier{shot_idx}{db_frame_id}{topic_id}.fg_loc = frame2(1:2,inliers<=length(iqr_fg)); % Chi lay nhung points tren db image
						%	inliers_struct.fg_bg_inlier{shot_idx}{db_frame_id}{topic_id}.bg_loc = frame2(1:2,inliers<=length(iqr_bg)); % Chi lay nhung points tren db image
						%end
					end
				end
				% free memory
			end
			save(local_result_file, 'inliers_struct', '-v6');
			unix(['mv ' local_result_file ' ' result_file]);
			fileattrib(result_file, '+w', 'a');
		end
	end
end

quit

end
