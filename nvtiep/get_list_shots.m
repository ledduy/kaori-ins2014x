function get_list_shots(shot_dir, lst_shot_mat_file)
% Example run 
% get_list_shots('/net/per610a/export/das11f/ledduy/trecvid-ins-2014/keyframe-5/tv2014/query2014', '/net/per610a/export/das11f/ledduy/trecvid-ins-2014/metadata/keyframe-5/tv2014/query2014.lst_shots.mat')
lst_shots = dir(shot_dir);
lst_index = zeros(1,length(lst_shots));
for i=1:length(lst_shots)
	if isempty(strfind(lst_shots(i).name(1), '.'))&& lst_shots(i).isdir
		lst_index(i) = 1;
	end
end
lst_shots = {lst_shots.name};
lst_shots = lst_shots(lst_index~=0);
save(lst_shot_mat_file, 'lst_shots');

end