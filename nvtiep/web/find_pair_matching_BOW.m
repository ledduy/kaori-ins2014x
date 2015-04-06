function [score, new_output_img, nshares_fg, nshares_bg] = find_pair_matching(data_name, test_pat, query_pat, qr_image, query_id, topic_id, db_image, frame_id, output_image, runID, frame_quant_info, query_filenames, topic_bows, bins, clip_frame, clip_kp)

if nargin == 0 % default data used for testing
	qr_image = '/net/per610a/export/das11g/caizhizhu/ins/ins2013/query/frames_png/9071/9071.3.src.png';
	db_image = '/net/per610a/export/das11g/caizhizhu/ins/ins2013/frames_png/shot20_8/01:00:26.52_000001.png';
	output_image = '/net/per610a/export/das11f/ledduy/plsang/nvtiep/INS/INS2013/web/9069.3.src.png_shot168_1298_01:14:25.04_000001.png';
	runID = '2.2.run_query2013-new_test2013-new_TiepBoW_No1_10K_combine_DPM';
end
% base dir
root_dir = '/net/per610a/export/das11f/ledduy/trecvid-ins-2014';
work_dir_test = fullfile(root_dir, 'feature/keyframe-5', data_name, test_pat); % result/tv2014/test2014
work_dir_query = fullfile(root_dir, 'feature/keyframe-5', data_name, query_pat); % result/tv2014/test2014

if ~isempty(strfind(runID, 'surrey'))
	db_quant_dir = fullfile(work_dir_test, 'hesaff_rootsift_noangle_cluster/akmeans_1000000_100000000_50/kdtree_8_800/v1_f1_1_sub_quant');
	db_frame_info_dir = fullfile(work_dir_test, 'hesaff_rootsift_noangle_mat');
	qr_raw_bow = fullfile(work_dir_query, 'bow.db_1_qr_fg+bg_0.1_hesaff_rootsift_noangle_akmeans_1000000_100000000_50_kdtree_8_800_kdtree_3_0.0125/raw_bow.mat');
else
	db_quant_dir = fullfile(work_dir_test, 'perdoch_hesaff_rootsift_cluster/akmeans_1000000_100000000_50/kdtree_8_800/v1_f1_3_sub_quant');
	db_frame_info_dir = fullfile(work_dir_test, 'perdoch_hesaff_rootsift_mat');
	qr_raw_bow = fullfile(work_dir_query, 'bow.db_1_qr_fg+bg_0.1_perdoch_hesaff_rootsift_akmeans_1000000_100000000_50_kdtree_8_800_kdtree_3_0.0125/raw_bow.mat');
end

% parse shot_id + frame name
re = [query_pat '/(.*)/(.*.png)'];
[rematch, retok] = regexp(qr_image, re, 'match', 'tokens');

qr_shotID = retok{1}{1};
qr_fname = retok{1}{2};

re = [test_pat '/(.*)/(.*\.png)'];
[rematch, retok] = regexp(db_image, re, 'match', 'tokens');
db_shotID = retok{1}{1};
db_fname = retok{1}{2};

% get list of visual words of db_image
db_quant_file = fullfile(db_quant_dir, [db_shotID,'.mat']);
%load(db_quant_file);		% dung de lay thong tin bins
db_frame_info_file = fullfile(db_frame_info_dir, [db_shotID,'.mat']);
%load(db_frame_info_file);	% dung de lay thong tin clip_frame
nframe_per_shot = length(clip_frame);
% Tim frame_id cua db_image trong danh sach frame cua db_shotID
for db_frame_id = 1:nframe_per_shot+1
	if strcmp(clip_frame{db_frame_id}, db_fname(1:end-4))
		break;
	end
end
db_words_id = [];	% neu khong co trong danh sach thi set empty
db_keypoint = [];
if db_frame_id <= nframe_per_shot
	db_words_id = bins{db_frame_id};
	db_keypoint = round(clip_kp{db_frame_id}(1:2,:));
end

% get list of visual words of qr_image
%load(qr_raw_bow); 			% Dung de lay thong tin query_filenames va frame_quant_info
nquery = length(query_filenames);

qr_words_id_fg = [];
qr_words_id_bg = [];
qr_keypoint_fg = [];
qr_keypoint_bg = [];


fg_idx = frame_quant_info{query_id}.fg_index{topic_id};
bg_idx = frame_quant_info{query_id}.bg_index{topic_id};
qr_words_id_fg = frame_quant_info{query_id}.valid_bins{topic_id}(:,fg_idx);
qr_words_id_bg = frame_quant_info{query_id}.valid_bins{topic_id}(:,bg_idx);
qr_keypoint_fg = round(frame_quant_info{query_id}.query_kp{topic_id}(1:2, fg_idx));
qr_keypoint_bg = round(frame_quant_info{query_id}.query_kp{topic_id}(1:2, bg_idx));


% find shared word between foreground/background of query image and db image
[shared_words_fg, iqr_fg, idb_fg] = intersect(qr_words_id_fg(:), db_words_id(1,:));
[shared_words_bg, iqr_bg, idb_bg] = intersect(qr_words_id_bg(:), db_words_id(1,:));
nshares_fg = length(shared_words_fg);
nshares_bg = length(shared_words_bg);

knn=size(qr_words_id_fg,1);
iqr_fg = floor((iqr_fg+knn-1)/knn);
iqr_bg = floor((iqr_bg+knn-1)/knn);

%% Compute score of this pair
%% Compute score of this pair
if ~isempty(strfind(runID, 'surrey'))
	% Load bag of word of all queries
	qr_raw_bowzz = fullfile(work_dir_query, 'bow.db_1_qr_fg+bg_0.1_hesaff_rootsift_noangle_akmeans_1000000_100000000_50_kdtree_8_800_kdtree_3_0.0125/bow_full_notrim_clip_idf_nonorm_-1.mat');
	load(qr_raw_bowzz);

	% Load bag of word of current shot
	db_quant_dirzz = fullfile(work_dir_test, 'hesaff_rootsift_noangle_cluster/akmeans_1000000_100000000_50/kdtree_8_800/v1_f1_1/sub_bow', db_shotID);
	load(db_quant_dirzz);
else
	% Load bag of word of all queries
	qr_raw_bowzz = fullfile(work_dir_query, 'bow.db_1_qr_fg+bg_0.1_perdoch_hesaff_rootsift_akmeans_1000000_100000000_50_kdtree_8_800_kdtree_3_0.0125/bow_full_notrim_clip_idf_nonorm_-1.mat');
	load(qr_raw_bowzz);
	% Load bag of word of current shot
	db_quant_dirzz = fullfile(work_dir_test, 'perdoch_hesaff_rootsift_cluster/akmeans_1000000_100000000_50/kdtree_8_800/v1_f1_3_0.0125/sub_bow/', db_shotID);
	load(db_quant_dirzz);
end
qr_bow = topic_bows{query_id}{1}(:,topic_id);
db_bow = frame_bow(:,frame_id);
score = 2 - sum(abs(qr_bow/sum(qr_bow)-db_bow/sum(db_bow)));
new_output_img = [];

% draw shared words to output_image
I_qr = imread(qr_image);
I_db = imread(db_image);
I = I_qr;
w = size(I_qr, 2);
I(:,w+1:2*w,:) = I_db;

% draw shared words of foreground and db image
for i=1:length(iqr_fg)
	x_qr = qr_keypoint_fg(2,iqr_fg(i));
	y_qr = qr_keypoint_fg(1,iqr_fg(i));
	x_db = db_keypoint(2,idb_fg(i));
	y_db = w+db_keypoint(1,idb_fg(i));
	[x, y] = bresenham(x_qr, y_qr, x_db, y_db);
	for j=1:length(x)
		I(x(j), y(j), :) = [255, 0, 0];
	end
end

% draw on background
for i=1:length(iqr_bg)
	x_qr = qr_keypoint_bg(2,iqr_bg(i));
	y_qr = qr_keypoint_bg(1,iqr_bg(i));
	x_db = db_keypoint(2,idb_bg(i));
	y_db = w+db_keypoint(1,idb_bg(i));
	[x, y] = bresenham(x_qr, y_qr, x_db, y_db);
	for j=1:length(x)
		I(x(j), y(j), :) = [0, 255, 0];
	end
end
%imwrite(I, output_image);
new_output_img = [output_image '_' num2str(nshares_fg) '_' num2str(nshares_bg) '_' num2str(score) '.jpg' ];
imwrite(I, new_output_img);
fileattrib(new_output_img, '+w', 'a');
end