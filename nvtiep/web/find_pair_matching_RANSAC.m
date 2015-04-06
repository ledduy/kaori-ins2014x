function [score, new_output_img, nshares_fg, nshares_bg] = find_pair_matching_RANSAC(data_name, test_pat, query_pat, qr_image, query_index, topic_id, db_image, frame_id, output_image, runID, frame_quant_info, query_filenames, topic_bows, bins, clip_frame, clip_kp)
% Example run:
% find_pair_matching_set2set_RANSAC('tv2014' , 'test2014', 'query2014' , '/net/per610a/export/das11f/ledduy/trecvid-ins-2014/tmp/RANSAC-9102-shot174_350/zz9102-shot174_350-1.logz', 'R0_tv2013.surrey.hard.soft+DPM+RANSAC', '9102' , 'shot174_350', '/net/per610a/export/das11f/ledduy/trecvid-ins-2014/tmp/RANSAC-9102-shot174_350')

% base dir
root_dir = '/net/per610a/export/das11f/ledduy/trecvid-ins-2014';
work_dir_test = fullfile(root_dir, 'feature/keyframe-5', data_name, test_pat); % result/tv2014/test2014
work_dir_query = fullfile(root_dir, 'feature/keyframe-5', data_name, query_pat); % result/tv2014/test2014

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
	db_keypoint = clip_kp{db_frame_id}(:,:);
	db_keypoint(1:2,:) = round(db_keypoint(1:2,:));
end

% get list of visual words of qr_image
%load(qr_raw_bow); 			% Dung de lay thong tin query_filenames va frame_quant_info
nquery = length(query_filenames);

qr_words_id_fg = [];
qr_words_id_bg = [];
qr_keypoint_fg = [];
qr_keypoint_bg = [];

fg_idx = frame_quant_info{query_index}.fg_index{topic_id};
bg_idx = frame_quant_info{query_index}.bg_index{topic_id};
qr_words_id_fg = frame_quant_info{query_index}.valid_bins{topic_id}(:,fg_idx);
qr_words_id_bg = frame_quant_info{query_index}.valid_bins{topic_id}(:,bg_idx);
qr_keypoint_fg = frame_quant_info{query_index}.query_kp{topic_id}(:, fg_idx);
qr_keypoint_bg = frame_quant_info{query_index}.query_kp{topic_id}(:, bg_idx);
qr_keypoint_fg(1:2,:) = round(qr_keypoint_fg(1:2,:));
qr_keypoint_bg(1:2,:) = round(qr_keypoint_bg(1:2,:));


% find shared word between foreground/background of query image and db image
[shared_words_fg, iqr_fg, idb_fg] = intersect(qr_words_id_fg(:), db_words_id(1,:));
[shared_words_bg, iqr_bg, idb_bg] = intersect(qr_words_id_bg(:), db_words_id(1,:));
%nshares_fg = length(shared_words_fg);
%nshares_bg = length(shared_words_bg);

knn=size(qr_words_id_fg,1);
iqr_fg = floor((iqr_fg+knn-1)/knn);
iqr_bg = floor((iqr_bg+knn-1)/knn);

% RANSAC
I_qr = imread(qr_image);
I_db = imread(db_image);
I = I_qr;
w = size(I_qr, 2);
h = size(I_qr, 1);
I(:,w+1:2*w,:) = I_db;

run('/net/per610a/export/das11f/ledduy/plsang/nvtiep/libs/vlfeat-0.9.18/toolbox/vl_setup.m');
%frame1 = [qr_keypoint_fg(:, iqr_fg) qr_keypoint_bg(:, iqr_bg)];
%frame2 = [db_keypoint(:,idb_fg) db_keypoint(:,idb_bg)];
%matches = [1:size(frame1,2); 1:size(frame1,2)];
%[inliers, H] = geometricVerification(frame1, frame2, matches, 'numRefinementIterations', 10)

frame1_fg = [qr_keypoint_fg(:, iqr_fg)];
frame2_fg = [db_keypoint(:,idb_fg)];
matches_fg = [1:size(frame1_fg,2); 1:size(frame1_fg,2)];
frame1_bg = [qr_keypoint_bg(:, iqr_bg)];
frame2_bg = [db_keypoint(:,idb_bg)];
matches_bg = [1:size(frame1_bg,2); 1:size(frame1_bg,2)];

% DPM base dir
DPM_model_dir = fullfile(root_dir, 'model/ins-dpm', data_name, query_pat);
result_dir = fullfile(root_dir, 'result', data_name, test_pat);
base_config_dir = fullfile(DPM_model_dir, qr_shotID);

if ~isempty(strfind(runID, '.DPM.'))
	%% Plot DPM bounding box
	% Load DPM scale factor
	scale_factor_file = fullfile(base_config_dir, [qr_shotID '.cfg']);
	scale_reg = 'Scale : (.*)';
	fid = fopen(scale_factor_file);
	[rematch, retok] = regexp(strtrim(fgetl(fid)), scale_reg, 'match', 'tokens');
	scale_factor = 1.0/str2double(retok{end}{1});
	fclose(fid);

	% Find VideoID that contains db_shot_id
	for vid = 1:999
		fid = fopen(fullfile(result_dir, runID, qr_shotID, ['TRECVID2013_',num2str(vid),'.res']), 'r');
		if fid == -1
			continue;
		end
		C = textscan(fid, '%s #$# %s #$# %f #$# %f #$# %f #$# %f #$# %f #$# %f');
		fclose(fid);
		
		shot_id = C{1};
		[is_member, loc] = ismember([db_shotID '_KSC' db_fname(1:end-4)], shot_id);
		if ~is_member
			continue;
		end
		%score = C{3}(loc);
		left = round(C{4}(loc)*scale_factor + w);
		top = max(1,round(C{5}(loc)*scale_factor));
		right = min(2*w,round(C{6}(loc)*scale_factor + w));
		bottom = min(h,round(C{7}(loc)*scale_factor));
		
        % Plot DPM bounding box
        for jj = left:right
            I(top, jj, :) = [0, 0, 255];
            I(bottom, jj, :) = [0, 0, 255];
        end
        for ii = top:bottom
            I(ii, left, :) = [0, 0, 255];
            I(ii, right, :) = [0, 0, 255];
        end
		break;
    end
end

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
qr_bow = topic_bows{query_index}{1}(:,topic_id);
db_bow = frame_bow(:,frame_id);
score = 2 - sum(abs(qr_bow/sum(qr_bow)-db_bow/sum(db_bow)));
new_output_img = [];
%% Plot BoW shared words
inliers_fg = [];
inliers_bg = [];
if size(frame1_fg, 2)>0
	[inliers_fg, H] = geometricVerification(frame1_fg, frame2_fg, matches_fg, 'numRefinementIterations', 10);
	% draw shared words of foreground and db image
	for i=1:length(inliers_fg)
		x_qr = qr_keypoint_fg(2,iqr_fg(inliers_fg(i)));
		y_qr = qr_keypoint_fg(1,iqr_fg(inliers_fg(i)));
		x_db = db_keypoint(2,idb_fg(inliers_fg(i)));
		y_db = w+db_keypoint(1,idb_fg(inliers_fg(i)));
		[x, y] = bresenham(x_qr, y_qr, x_db, y_db);
		for j=1:length(x)
			I(x(j), y(j), :) = [255, 0, 0];
		end
	end
end
if size(frame1_bg, 2) > 0
	[inliers_bg, H] = geometricVerification(frame1_bg, frame2_bg, matches_bg, 'numRefinementIterations', 10);
	% draw shared words of background and db image
	for i=1:length(inliers_bg)
		x_qr = qr_keypoint_bg(2,iqr_bg(inliers_bg(i)));
		y_qr = qr_keypoint_bg(1,iqr_bg(inliers_bg(i)));
		x_db = db_keypoint(2,idb_bg(inliers_bg(i)));
		y_db = w+db_keypoint(1,idb_bg(inliers_bg(i)));
		[x, y] = bresenham(x_qr, y_qr, x_db, y_db);
		for j=1:length(x)
			I(x(j), y(j), :) = [0, 255, 0];
		end
	end
end

nshares_fg = size(inliers_fg,2);
nshares_bg = size(inliers_bg,2);
new_output_img = [output_image '_' num2str(size(inliers_fg,2)) '_' num2str(size(inliers_bg,2)) '_' num2str(score) '.jpg' ];
imwrite(I, new_output_img);
fileattrib(new_output_img, '+w', 'a');

end