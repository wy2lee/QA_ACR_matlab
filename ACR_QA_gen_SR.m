function ACR_QA_gen_SR(dir_base, dir_series, options)
% ACR_QA_gen_SR(dir_base, dir_series, options)
%   Displays high resolution insert for evaluation
% 
%   INPUTS
%       dir_base - base subject directory
%       dir_series - series directory with dicoms
%       options - possible options
%           .max_level_pct - % of max signal for max level [0.5]
%           .min_level_pct - % of max signal for min level [0.1]
%           .slice - Slice location of high resolution insert [1]
%           .height - Height of insert (mm) [50]
%           .height_offset - Insert offset 'below' centre (mm) [15]
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
opt_def.min_level_pct = 0.1;
opt_def.max_level_pct = 0.5;
opt_def.slice_target = 1;
opt_def.height = 50;
opt_def.height_offset = 15;
opt_def.width = 120;
opt_def.width_offset = opt_def.width/2; 
opt_def.philips=0;
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
min_level = options.min_level_pct * max(data.img(:));

% 50 mm window 15mm below centre_y of the phantom
index_rows = floor( [0: options.height/data.hdr.PixelSpacing(1)] ...
    + options.height_offset/data.hdr.PixelSpacing(1)) + data.centre_y ;

% 120 mm window in the center_y of the phantom
index_cols = floor( [0: options.width/data.hdr.PixelSpacing(1)] ...
    - options.width_offset/data.hdr.PixelSpacing(1)) + data.centre_x ;

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


subplot('position',[0.05 0.45 0.9 0.4]), 
imshow(data.img(index_rows,index_cols),[])
ylabel('Normal Contrast');
title({[options.magnet ' - ' options.coil ' - ' options.date ' - '...
    options.short_name], ' High Resolution Evaluation'});
axis equal
subplot('position',[0.05 0.0 0.9 0.4]), 
imshow(data.img(index_rows,index_cols),[min_level max_level])
ylabel('Contrast Enhanced');
axis equal

saveas(h_fig,[options.fname_base '-Spatial_Resolution.jpg']); 