function rerank_using_DQE_fgbg_tfidf_max(data_name, base_feature, base_RANSAC, start_video_id, end_video_id)

Ntop = 10;
Nbottom = 200;
if nargin == 0
	data_name = 'tv2014';
	base_feature = 'surrey.hard.soft';
	base_RANSAC = 'R0_tv2014.surrey.hard.soft+RANSAC_fg+bg_tfidf_max';
	start_video_id = 1;
	end_video_id = 1000;
end

if isempty(strfind(base_RANSAC, base_feature))
	disp ('Insconsistency between base_featue and base_RANSAC');
	quit;
end

addpath('/net/per900c/raid0/ledduy/github-projects/kaori-ins2014/nvtiep/funcs/liblinear-1.94/matlab');

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
	TESTDB_BOW_CONFIGZ = 'hesaff_rootsift_noangle_cluster/akmeans_1000000_100000000_50/kdtree_8_800/v1_f1_1/sub_bow';
	TESTDB_RAW_FEATURE_CONFIGZ = 'hesaff_rootsift_noangle_mat';
	TESTDB_IDF_WEIGHT_DIR = '/net/per610a/export/das11f/ledduy/trecvid-ins-2014/feature/keyframe-5/tv2014/test2014/hesaff_rootsift_noangle_cluster/akmeans_1000000_100000000_50/kdtree_8_800/v1_f1_1/bow_clip_full_notrim_clip_idf_nonorm_avg_pooling.mat';
	% Load idf weight
	load(TESTDB_IDF_WEIGHT_DIR, 'weight');
	hist_len = length(weight);
end

%% base level path configuration

RESULT_RUN_ID = ['R0_', data_name, '.', base_feature, '+DQE_fg+bg_tfidf_max'];

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
	
	% Load ranked list using RANSAC tfidf
	sorted_list = fullfile(BASE_TMP_RANSAC_DIR, [qr_shotID '.rank']);
	fid = fopen(sorted_list, 'r');
	nshot = 0;
	re = '(.*)#\$#';
	while ~feof(fid)
		line = fscanf(fid, '%s#$#%s');
		[rematch, retok] = regexp(line, re, 'match', 'tokens');
		if ~isempty(retok)
			nshot = nshot + 1;
			ranked_list{nshot} = retok{1}{1};
		end
	end
	fclose(fid);
	% Lay danh sach tat ca cac positives va negatives
	positives = ranked_list(1:Ntop);
	negatives = ranked_list(end-Nbottom+1:end);
	
	% Thong ke danh sach cac relevant visual words trong positives
	active_words = sparse(1000000,1);
	for i=1:Ntop
		load(fullfile(ROOT_FEATURE_DIR, data_name, test_pat, TESTDB_BOW_CONFIGZ, positives{i}));
		active_words = active_words+sum(frame_bow, 2);
	end
	
	% Create BoW feature vector for negative samples
	train_bow = sparse(length(find(active_words~=0)), Ntop+Nbottom);
	for i=1:Ntop
		load(fullfile(ROOT_FEATURE_DIR, data_name, test_pat, TESTDB_BOW_CONFIGZ, positives{i}));
		pos_bow = sum(frame_bow, 2);
		train_bow(:,i) = pos_bow(active_words~=0);
	end
	for i=1:Nbottom
		load(fullfile(ROOT_FEATURE_DIR, data_name, test_pat, TESTDB_BOW_CONFIGZ, negatives{i}));
		neg_bow = sum(frame_bow, 2);
		train_bow(:, Ntop+i) = neg_bow(active_words~=0);
	end 
	train_label = [ones(Ntop,1);-ones(Nbottom,1)];
	
	% Train using LIBLINEAR
	model = train(train_label, train_bow, '-c 1', 'col');
	
	% Rerank duyet qua tat ca cac video ID
	for id = start_video_id:end_video_id
		fprintf('\rQuery %d, Video: %d - (%d - %d)', q_id, id, start_video_id, end_video_id);
		lookup_fname = [qr_shotID,'/TRECVID2013_', num2str(id),'.res'];
		% Write Log file
		logfile=fopen(LOG_FILE,'a');
		fprintf(logfile, '\r Query: %d. VidId: %d - (%d - %d)\n', q_id, id, start_video_id, end_video_id);
		fclose(logfile);
		fileattrib(LOG_FILE, '+w', 'a');
		
		% Check .res file already existed in data server or not?
		dqe_reranking_res_file = fullfile(final_result_dir, ['/TRECVID2013_', num2str(id),'.res']);
		if exist(dqe_reranking_res_file, 'file')
			continue;
		end
		
		% Find common shot id and Fuse score
		ransac_res_file = fullfile(BASE_TMP_RANSAC_DIR, lookup_fname);
		if ~exist(ransac_res_file, 'file')
			continue;
		end
		ran_fid = fopen(ransac_res_file, 'r');
		lines = textscan(ran_fid, '%s #$# %s #$# %s');
		fclose(ran_fid);
		
		dqe_reranking_local_file = fullfile(final_result_local_dir, ['/TRECVID2013_', num2str(id),'.res']);
		fid = fopen(dqe_reranking_local_file, 'w');	
		for i=1:length(lines{1})
			shot = lines{1}{i};
			% Load bag of words
			load(fullfile(ROOT_FEATURE_DIR, data_name, test_pat, TESTDB_BOW_CONFIGZ, shot));
			test_bow = sum(frame_bow, 2);
			test_bow = test_bow(active_words~=0);
			fprintf(fid, '%s #$# %s #$# %f\n', shot, shot, model.w*test_bow);
		end
		fclose(fid);
		
		% Move result file from local to destination
		status = unix(['mv ' dqe_reranking_local_file ' ' dqe_reranking_res_file]);
		if status == 0
			try
				delete(dqe_reranking_local_file);
			catch
				error('Cannot delete temporary result file');
			end
		end
		fileattrib(dqe_reranking_res_file, '+w', 'a');
	end
end

quit

end
