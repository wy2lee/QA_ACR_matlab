function ACR_QA_gen_SA(dir_base, dir_series, options)
% ACR_QA_gen_SA(dir_base, dir_series, options)
%   Displays low contrast slices for evaluation
% 
%   INPUTS
%       dir_base - base subject directory
%       dir_series - series directory with dicoms
%       options - possible options
%           .slices - Should be 1,11
%           .height - Height of insert (mm) [50]
%           .height_offset - Insert offset 'below' centre (mm) [-100]
%           .water_height - Offset for water_reference roi [40]
%           .water_offset - Offset for water_reference roi [-water_height - 10]
%           .width - Width of insert (mm) [40]
%           .width_offset - Offset of left of center (mm) [ width/2]
%                   ie. move insert 60mm to the left to centre it
%           .init_min - Initial min level to find centre [0.2 of max]
% 
%   OUTPUTS
%       Creates a figure showing low contrast slices for evaluation
% 
%   NOTES
% 
%   Created - 2014 July 8th by Wayne Lee

opt_def = {};
opt_def.slices = [1,11];
opt_def.height = 50;
opt_def.height_offset = -90;
opt_def.water_height = 40;
opt_def.water_offset = -opt_def.water_height -10;
opt_def.width = 40;
opt_def.width_offset = opt_def.width/2; 
opt_def.init_min = 0.45;
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


num_slices = length(options.slices);
if num_slices > 2,
    error('TOO MANY SLICES');
end


if options.philips,
    list_files = dir([dir_base '\' dir_series ]);
    fname_cur = list_files(end).name;
    path_curr = [dir_base '\' dir_series '\' fname_cur];
    options.slice_target = options.slices;
    data_base = ACR_QA_get_dcm(path_curr,options);
    data = data_base;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Prep figure output
if options.figure<1,
    h_fig = figure();
else
    h_fig = figure(options.figure);
end
set(h_fig,'units','inches','outerposition',[0 0 6 6],...
    'position',[0 0 6 6], 'resize','on'); 
set(h_fig,'PaperUnits','inches','PaperPosition',[0 0 6 6],'PaperSize',[6 6]);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

plot_space = 0.45;
plot_sz = 0.4;

for count_slice = 1:num_slices,
    curr_slice = options.slices(count_slice);

    
    if not(options.philips),
        path_curr = [dir_base '\' dir_series '\' num2str(curr_slice,'%0.4d') '.dcm' ];
        options.slice_target = 1;
        data = ACR_QA_get_dcm(path_curr,options);
    else
        data.img = data_base.img(:,:,count_slice);
    end

    % Define extent of slice inserts
    index_rows = floor( [0: options.height/data.hdr.PixelSpacing(1)] ...
        + options.height_offset/data.hdr.PixelSpacing(1)) + data.centre_y ;
    index_cols = floor( [0: options.width/data.hdr.PixelSpacing(1)] ...
        - options.width_offset/data.hdr.PixelSpacing(1)) + data.centre_x ;


    data.small = data.img(index_rows, index_cols);


    index_water_r = floor( [0: options.water_height/data.hdr.PixelSpacing(1)] ...
        + options.water_offset /data.hdr.PixelSpacing(1)) + data.centre_y ;


    data.water = data.img(index_water_r, index_cols);

    min_level = mean(data.water(:) * options.init_min);
    max_level = min_level+1;

    data_show = repmat((data.small - min_level),[1 1 3]);

    % Find some row in the middle of the Slice Accuracy insert
    index_SA_insert = find(data.small(:,floor(length(index_cols)/2)) < min_level, 1,'last');

    SA_offset = 10;

    % Find the L / R bounds on the Slice Accuracy Insert
    %   The Slice Accuracy Insert should be centered in the small image
    index_left =  find( data.small( floor(length(index_rows)/2), :)<min_level,1,'first');
    index_right = find( data.small( floor(length(index_rows)/2), :)<min_level,1,'last');
    index_mid = floor( (index_left + index_right) / 2);

    index_A = (index_left + 1) : (index_mid   - 1);
    index_B = (index_mid  + 1) : (index_right - 1);

    ramp_length = zeros(index_right,1);
    for index_horz = index_left : index_right
        ramp_length(index_horz) = find(data.small(:,index_horz) < min_level, 1,'last');
    end

    ramp_A_slice = mean(ramp_length(index_A));
    ramp_B_slice = mean(ramp_length(index_B));

    subplot('Position',[0.05 ,...
        0.95 - count_slice * plot_space,  plot_sz, plot_sz], ...
        'units','normalized')
    
        imshow(data.small,[ ])
        title(['Slice '  num2str(curr_slice) ]);
        axis equal
        
    subplot('Position',[0.55,...
        0.95 - count_slice * plot_space,  plot_sz, plot_sz], ...
        'units','normalized')
    
        imshow(data_show,[min_level max_level]);
        
        title(['Target < 4mm']);
        line( [index_left+1 index_mid-1], [ramp_A_slice ramp_A_slice],...
            'Color','r','LineWidth',3);
        line( [index_mid-1 size(data_show,2)*0.9], [ramp_A_slice ramp_A_slice],...
            'Color','r','LineWidth',1);
        line( [index_mid+1 index_right-1], [ramp_B_slice ramp_B_slice],...
            'Color','g','LineWidth',3);
        line( [index_right-1 size(data_show,2)*0.9], [ramp_B_slice ramp_B_slice],...
            'Color','g','LineWidth',1);
        axis equal
        text(size(data_show,2)*0.9, min(ramp_A_slice,ramp_B_slice)-5,...
            [num2str((ramp_A_slice - ramp_B_slice)*data.hdr.PixelSpacing(1),'%4.2f') ' mm'],...
            'HorizontalAlignment','Left');
end

text(-12,-68,[options.magnet ' - ' options.coil ' - ' options.date ' - '...
    options.short_name ' - Slice Accuracy'],...
    'FontSize',14,'HorizontalAlignment','center');
saveas(h_fig,[options.fname_base '-Slice_Accuracy.jpg']);
