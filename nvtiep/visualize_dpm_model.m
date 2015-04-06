function visualize_dpm_model(all_dpm_model_dir)
% Example run: 
% visualize_dpm_model('/net/per610a/export/das11f/ledduy/trecvid-ins-2014/model/ins-dpm/tv2013/query2013')

close all;
%startup();
addpath('/net/per900c/raid0/ledduy/github-projects/kaori-ins2014/voc-release5/vis');
model_folders = dir(all_dpm_model_dir);

for i=1:length(model_folders)
	if ~model_folders(i).isdir || strcmp(model_folders(i).name(1), '.')
		continue;
	end
	model_file = fullfile(all_dpm_model_dir, model_folders(i).name, ['query_' model_folders(i).name '_final.mat']);
	load(model_file);
	fig = figure;
	visualizemodel(model);
	model_img_file = fullfile(all_dpm_model_dir, [model_folders(i).name, '.png']);
	saveas(fig, model_img_file);
	close all;
	
	% Detect object
	%img = imread('/net/per610a/export/das11g/caizhizhu/ins/ins2013/frames_png/shot101_1122/01:00:40.24_000001.png')
	%im = imresize(im, 2, 'lanczos3');
	% perform detection
	%pyra = featpyramid(im, model);
	%[ds, bs] = gdetect(pyra, model, -2);
	%figure; imshow(im);
	%for j=1:2
		% format: KeyFrameID #$# ShotID #$# DPMScore #$# Left #$# Top #$# Right #$# Bottom #$# ComponentID
	%	left = ds(j,1);
	%	top  = ds(j,2);
	%	right = ds(j,3);
	%	bottom = ds(j,4);
	%	for jj = left:right
    %        im(top, jj, :) = [0, 0, 255];
    %        im(bottom, jj, :) = [0, 0, 255];
    %    end
    %    for ii = top:bottom
    %        im(ii, left, :) = [0, 0, 255];
    %        im(ii, right, :) = [0, 0, 255];
    %    end
	%end
	%pause;
	% free memory 
	%clear pyra;
	%clear ds;
	%clear bs;
end

end