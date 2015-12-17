function ACR_QA_gen_ST(dir_base, dir_series, options)
% ACR_QA_gen_ST(dir_base, dir_series, options)
%   Displays Slice Thickness Evaluation
% 
%   INPUTS
%       dir_base - base subject directory
%       dir_series - series directory with dicoms
%       options - possible options
%           .max_level_pct - % of max signal for max level [0.07]
%           .slice - Slice location of high resolution insert [1]
%           .height - Height of insert (mm) [15]
%           .height_offset - Insert offset 'below' centre (mm) [-height/2]
%           .width - Width of insert (mm) [120]
%           .width_offset - Offset of left of center (mm) [ width/2]
%                   ie. move insert 60mm to the left to centre it
% 
%   OUTPUTS
%       Creates a figure showing low contrast slices for evaluation
% 
%   NOTES
% 
%   Created - 2014 July 8th by Wayne Lee

% Define default options
opt_def = {};
opt_def.max_level_pct = 0.07;
opt_def.slice_target = 1;
opt_def.height = 15;
opt_def.height_offset = -opt_def.height/2;
opt_def.width = 120;
opt_def.width_offset = opt_def.width/2; 
opt_def.philips = 0;
opt_def.figure = 0;


list_options = fieldnames(opt_def);
num_options = length(list_options);

% if no options are supplied set default options
if nargin < 3,
    options = opt_def;
end

% If options is missing default field, set to default values
for count_opt = 1:num_options,
    opt_name = list_options{count_opt};
    if isfield(options, opt_name) == 0,
        options.(opt_name) = opt_def.(opt_name);
    end
end
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % 

if options.philips,
    list_files = dir([dir_base '\' dir_series ]);
    fname_cur = list_files(end).name;
    path_curr = [dir_base '\' dir_series '\' fname_cur];
    options.slice_target = options.slice_target;
    data = ACR_QA_get_dcm(path_curr,options);
else
    path_curr = [dir_base '\' dir_series '\' num2str(options.slice_target,'%0.4d') '.dcm' ];
    data = ACR_QA_get_dcm(path_curr,options);
end

% Find Display Window
max_level = options.max_level_pct * max(data.img(:));
min_level = max_level-1;

% Find Display Window
index_rows = floor( [0: options.height/data.hdr.PixelSpacing(1)] ...
    + options.height_offset/data.hdr.PixelSpacing(1)) + data.centre_y ;
index_cols = floor( [0: options.width/data.hdr.PixelSpacing(1)] ...
    - options.width_offset/data.hdr.PixelSpacing(1)) + data.centre_x ;

data.small.img = data.img(index_rows, index_cols);

% Check to see if display window is level
first_black_left = find(data.small.img(:,1) < min_level, 1,'first');
first_black_right = find(data.small.img(:,length(index_cols)) < min_level, 1,'first');

if abs(first_black_left-first_black_right) > 1
    rot_angle = 2*360*atan(first_black_right - first_black_left)/length(index_cols) / (2*pi());   
    data_big_temp = imrotate(data.img, rot_angle ,'bilinear','crop');
%     figure, 
%         subplot(1,2,1), imshow(data.img,[]);
%         subplot(1,2,2), imshow(data_big_temp,[]);
%     figure
    data.small.img = data_big_temp(index_rows, index_cols);
end

% Find first black voxel in vertical center
index_start = find(data.small.img(:,floor(length(index_cols)/2)) < min_level, 1,'first');
index_end = find(data.small.img(:,floor(length(index_cols)/2)) < min_level, 1,'last');
index_mid = floor( (index_start + index_end) / 2);

% Can't find insert just do all worws
if index_start == index_mid,
    index_start = 1;
    index_end = length(index_rows);
    index_mid = floor(index_end/2);
end

index_top = (index_start+2) : (index_mid - 1);
index_bot = (index_mid + 1) : (index_end - 2);


data_show = repmat((data.small.img - min_level),[1 1 3]);

ramp_length = zeros(index_end,1);
for index_vert = index_start : index_end
    ramp_length(index_vert) = data.hdr.PixelSpacing(1) * length(find(data.small.img(index_vert,:)>min_level));
    if (index_vert>=min(index_top)) & (index_vert<=max(index_top)),
        data_show(index_vert, find(data.small.img(index_vert,:)>min_level),1) = 1;
        data_show(index_vert, find(data.small.img(index_vert,:)>min_level),2) = 0;
        data_show(index_vert, find(data.small.img(index_vert,:)>min_level),3) = 0;
    end
    if (index_vert>=min(index_bot)) & (index_vert<=max(index_bot)),
        data_show(index_vert, find(data.small.img(index_vert,:)>min_level),1) = 0;
        data_show(index_vert, find(data.small.img(index_vert,:)>min_level),2) = 1;
        data_show(index_vert, find(data.small.img(index_vert,:)>min_level),3) = 0;
    end
end


ramp_top = mean(ramp_length(index_top));
ramp_bot = mean(ramp_length(index_bot));

slice_thickness = 0.2 * (ramp_top * ramp_bot) / (ramp_top + ramp_bot);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Prep figure output
if options.figure<1,
    h_fig = figure();
else
    h_fig = figure(options.figure);
end
set(h_fig,'units','inches','outerposition',[0 0 6 3.5],...
    'position',[0 0 6 3.5], 'resize','on'); 
set(h_fig,'PaperUnits','inches','PaperPosition',[0 0 6 3.5],'PaperSize',[6 3.5]);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


subplot('position',[0.05 0.5 0.4 0.4])
    imshow(data.img,[ ])
    axis equal
subplot('position',[0.45 0.65 0.5 0.2])
    imshow(data.small.img,[0 max_level*1.5])
    title('Contrast Enhanced','FontSize',10);
    axis equal
subplot('position',[0.45 0.43 0.5 0.2])
    imshow(data_show,[min_level max_level])
    title('Masked Slice','FontSize',10);
    axis equal
subplot('position',[0.1 0.1 0.8 0.3])
    bar([index_start:index_end], ramp_length([index_start:index_end]));
    hold on
    plot([min(index_top)-0.5 min(index_top)-0.5 ] , [0 100],'r','LineWidth',2);
    plot([max(index_top)+0.5 max(index_top)+0.5 ] , [0 100],'r','LineWidth',2);
    plot([min(index_bot)-0.5 min(index_bot)-0.5 ] , [0 100],'g','LineWidth',2);
    plot([max(index_bot)+0.5 max(index_bot)+0.5 ] , [0 100],'g','LineWidth',2);
    hold off
    axis([index_start index_end 0 100]);
    set(gca,'FontSize',8);
    text( mean(index_top), 75, ['Top Ramp = ' num2str(ramp_top,'%4.2f'), ' mm'],...
        'HorizontalAlignment','Center');
    text( mean(index_bot), 75, ['Bot Ramp = ' num2str(ramp_bot,'%4.2f'), ' mm'],...
        'HorizontalAlignment','Center');
    xlabel('Vertical Location (voxel)','FontSize',10); 
    ylabel('Ramp Length (mm)','FontSize',10);
    title(['Slice Thickness = ' num2str(slice_thickness,'%4.2f'), ' mm ' ...
        '(Target = 5 ' setstr(177) ' 0.7 mm)'],'FontSize',12);

    % Report ramp length for each 'ramp'
for count_index = (index_start+1):(index_end-1),
    text(count_index, 5,num2str(ramp_length(count_index),'%4.2f'),'Color',[1 1 1],'FontSize',8,...
        'Rotation',90);
end
    
text(mean([index_start,index_end]),285,[options.magnet ' - ' options.coil ' - ' options.date ' - '...
    options.short_name ' - Slice Thick'],...
    'FontSize',14,'HorizontalAlignment','center');    
saveas(h_fig,[options.fname_base '-Slice_thick.jpg']);