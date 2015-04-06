% INPUT: RUN_ID with precomputed RANSAC data
% OUTPUT: RUN_ID containing result files

function rerank_using_RANSAC_fg_tf_max(data_name, base_feature, base_RANSAC, start_video_id, end_video_id)
% Example:
% rerank_using_RANSAC_tfidf_sum('tv2014', 'surrey.hard.soft', 
% 'R4_rawRANSAC_tv2013.surrey.hard.soft.latefusion.asym', 1, 2)

% base_RANSAC: R4_rawRANSAC_tv2013.surrey.hard.soft.latefusion.asym
% NOTE: base_RANSAC phai CONSISTENT voi base_feature, ie. neu base_feature la surrey.hard.soft thi base_RANSAC phai co surrey.hard.soft
% base_feature: chi moi support surrey.hard.soft

if nargin == 0
	data_name = 'tv2014';
	base_feature = 'surrey.hard.soft';
	base_RANSAC = 'R4_tv2013.rawRANSAC.surrey.hard.soft.latefusion.asym';
	start_video_id = 1;
	end_video_id = 1000;
end

if isempty(strfind(base_RANSAC, base_feature))
	disp ('Insconsistency between base_featue and base_RANSAC');
	quit;
end

ROOT_DIR = '/net/per610a/export/das11f/ledduy/trecvid-ins-2014/';

ROOT_FEATURE_DIR = fullfile(ROOT_DIR, 'feature/keyframe-5');

ROOT_RESULT_DIR = fullfile(ROOT_DIR, 'result');

ROOT_TMP_DIR = fullfile(ROOT_DIR, 'tmp');

% identify queryID
if strcmp(data_name, 'tv2013')
	start_query_id = 9069;
	end_query_id = 9098;
	query_pat = 'query2013';
	test_pat = 'test2013';
end

if strcmp(data_name, 'tv2014')
	start_query_id = 9099;
	end_query_id = 9128;
	query_pat = 'query2014';
	test_pat = 'test2014';
end

if strcmp(base_feature, 'surrey.hard.soft')
	QUERY_FEATURE_CONFIGZ = 'bow.db_1_qr_fg+bg_0.1_hesaff_rootsift_noangle_akmeans_1000000_100000000_50_kdtree_8_800_kdtree_3_0.0125';
	TESTDB_QUANTIZATION_CONFIGZ = 'hesaff_rootsift_noangle_cluster/akmeans_1000000_100000000_50/kdtree_8_800/v1_f1_1_sub_quant';
	TESTDB_RAW_FEATURE_CONFIGZ = 'hesaff_rootsift_noangle_mat';
end

debug_mode = false;

%% base level path configuration
ex_bounding_box = 0; % NOT USED


RESULT_RUN_ID = ['R0_', data_name, '.', base_feature, '+RANSAC_foreground_tf_max'];

BASE_RESULT_DIR = fullfile(ROOT_RESULT_DIR, data_name, test_pat, RESULT_RUN_ID); 

% raw RANSAC dir
BASE_TMP_RANSAC_DIR = fullfile(ROOT_RESULT_DIR, data_name, test_pat, base_RANSAC);  

LOG_FILE = fullfile(ROOT_TMP_DIR, 'R0_fusion_using_BOW+DPM+RANSAC.txt');

LOCAL_DIR = '/tmp/dpm/';


% Create result folder
if ~exist(BASE_RESULT_DIR, 'dir')
	mkdir(BASE_RESULT_DIR);
	fileattrib(BASE_RESULT_DIR, '+w', 'a');
end

re = '.*_KSC(.*)';
for q_id = start_query_id:end_query_id	% Duyet qua tat ca cac cau query
	qr_shotID = num2str(q_id);
	final_result_dir = fullfile(BASE_RESULT_DIR, qr_shotID);
	final_result_local_dir = fullfile(LOCAL_DIR, qr_shotID);
	% create folder if not existing
	if ~exist(final_result_dir, 'dir')
		mkdir(final_result_dir);
		fileattrib(final_result_dir, '+w', 'a');
	end
	if ~exist(final_result_local_dir, 'dir')
		mkdir(final_result_local_dir);
	end
	
	% Duyet qua tat ca cac video ID
	for id = start_video_id:end_video_id
		fprintf('\rQuery %d, Video: %d - (%d - %d)', q_id, id, start_video_id, end_video_id);
		lookup_fname = [qr_shotID,'/TRECVID2013_', num2str(id),'.res'];
		% Write Log file
		logfile=fopen(LOG_FILE,'a');
		fprintf(logfile, '\r Query: %d. VidId: %d - (%d - %d)\n', q_id, id, start_video_id, end_video_id);
		fclose(logfile);
		fileattrib(LOG_FILE, '+w', 'a');
		
		% Check .res file already existed in data server or not?
		ransac_reranking_res_file = fullfile(final_result_dir, ['/TRECVID2013_', num2str(id),'.res']);
		if exist(ransac_reranking_res_file, 'file')
			continue;
		end
		
		% Load inlier shared words using RANSAC from computing raw RANSAC step
		ransac_inlier_file = fullfile(BASE_TMP_RANSAC_DIR, qr_shotID, ['/TRECVID2013_', num2str(id),'.mat']);
		if ~exist(ransac_inlier_file, 'file')
			continue;
		end
		load(ransac_inlier_file); % To get inliers_struct
				
		% Find common shot id and Fuse score
		ransac_reranking_local_file = fullfile(final_result_local_dir, ['/TRECVID2013_', num2str(id),'.res']);
		if ~debug_mode
			fid = fopen(ransac_reranking_local_file, 'w');
		end

		nshot = length(inliers_struct.shot_list);
		for shot_idx = 1:nshot	% duyet qua tat ca cac shot trong danh sach cua RANSAC
			shot = inliers_struct.shot_list{shot_idx};
			if debug_mode && ~strcmp(shot, debug_shot)
				continue;
			end
			%frame_locs = find(ismember(shot_id, shot));	% tim nhung frameID trong DPM .res co shot ID giong voi shotID cua RANSAC
			
			N_fg = 0; % co the nam trong lan ko nam trong DPM region??!!??
			
			%[~, previous_score_id] = ismember(shot, dpm_fusion{1});
			%P_score = dpm_fusion{3}(previous_score_id);
			new_scores = [];
			nframe = length(inliers_struct.frame_name{shot_idx});
			for frame_idx=1:nframe % duyet qua tat ca cac frame ma co su dung DPM
				
				fg_kp = [];
				
				if ~isempty(inliers_struct.fg_inlier_loc{shot_idx}{frame_idx})
					% merge all shared words
					fg_kp = [inliers_struct.fg_inlier_loc{shot_idx}{frame_idx}{:}];
					fg_kp = unique(fg_kp', 'rows')';
				end

				N_fg = size(fg_kp,2);
				
				% Compute new score
				new_scores(end+1) = N_fg; 	% using both Nd and Nfg

				if debug_mode
					fullfile('/net/per610a/export/das11g/caizhizhu/ins/ins2013/frames_png/', shot, [frame_name{end}{1} '.png'])
					I = imread(fullfile('/net/per610a/export/das11g/caizhizhu/ins/ins2013/frames_png/', shot, [frame_name{end}{1} '.png']));
					figure; imshow(I); hold on;
					xx = [left(frame_locs(frame_idx))  right(frame_locs(frame_idx)) right(frame_locs(frame_idx)) left(frame_locs(frame_idx)) left(frame_locs(frame_idx))];
					yy = [top(frame_locs(frame_idx)) top(frame_locs(frame_idx)) bottom(frame_locs(frame_idx)) bottom(frame_locs(frame_idx)) top(frame_locs(frame_idx))];
					plot(xx, yy, 'r');
					if ~isempty(fg_kp)
						plot(fg_kp(1,:), fg_kp(2,:), 'g+');
					end

					pause;
				end
			end
			% Write to output file
			if ~debug_mode
				fprintf(fid, '%s #$# %s #$# %f\n', shot, shot, max(new_scores));
			end
		end
		if ~debug_mode
			fclose(fid);
			status = unix(['mv ' ransac_reranking_local_file ' ' ransac_reranking_res_file]);
			if status == 0
				try
					delete(ransac_reranking_local_file);
				catch
					error('Cannot delete temporary result file');
				end
			end
			fileattrib(ransac_reranking_res_file, '+w', 'a');
		end
		clear inliers_struct fg_locs fg_kp frame_names shot_id
	end
end

quit

end
