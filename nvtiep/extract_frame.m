function extract_frame(sID, eID)

INS = 'cmu2015';

sampling_hz = 0.2;    % frame per second
work_dir = fullfile('/net/per610a/export/das11f/ledduy/trecvid-ins-2014');
clip_dir= fullfile(work_dir, 'video', INS);
frame_parent_dir = fullfile(work_dir, ['keyframe-' num2str(sampling_hz)], INS, 'test');

% Load list clips
load(fullfile(clip_dir, 'lstClips.mat'));

nclip = length(lstClips);

for i=sID:eID
	fprintf('\rProcessing video: %d (%d - %d)', i, sID, eID);
    clip_id = i;
    clip_name = lstClips{i};
    clip_filename = fullfile(clip_dir,clip_name);
    shot_name = ['shot_' num2str(clip_id)];
    
    start_time = '00:00:00.0';
 
    frame_dir = fullfile(frame_parent_dir,shot_name);
    
    % in case failed in last time
    need_ext_flag = true;
    if exist(frame_dir,'dir')
        shot_frames= dir(fullfile(frame_dir,'*.png'));
        if length({shot_frames(:).name}) > 0
            need_ext_flag = false;
        end
    else
        mkdir(frame_dir);
    end
    
    if need_ext_flag
        cmd_line = sprintf('ffmpeg -ss %s -i %s -r %0.1f %s/%s',...
            start_time, clip_filename, sampling_hz,...
            frame_dir, [start_time '_%06d.png']);

        unix([cmd_line,'>/dev/null 2>&1']);
        
        list_file = fullfile(frame_dir,'frames.txt');
        list_fid=fopen(list_file,'w');
		shot_frames= dir(fullfile(frame_dir,'*.png'));
        ext_frame_num = length({shot_frames(:).name});
        for j=1:ext_frame_num
            assert(exist(sprintf('%s/%s_%06d.png',frame_dir,start_time,j),'file')~=0);
            fprintf(list_fid,'%s_%06d.png\n',start_time,j);
        end
        fclose(list_fid);
    end            
end


