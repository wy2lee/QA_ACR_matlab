function ACR_QA_gen_IU(dir_base, dir_series, options)
% ACR_QA_gen_IU(dir_base, dir_series, options)
%   Calculate Image Uniformity and Ghosting 
% 
%   INPUTS
%       dir_base - base subject directory
%       dir_series - series directory with dicoms
%       options - possible options
%           .large_roi_size - 20000 mm^3
%           .small_roi_size - 100 mm^3
%           .ghost_roi_size - 1000 mm^3
%           .slice_target - 7  [which slices to use]
% 
%   OUTPUTS
%       Creates a figure showing low contrast slices for evaluation
% 
%   NOTES
% 
%   Created - 2014 July 8th by Wayne Lee

% Define default options
opt_def = {};
opt_def.large_roi_size = 20000;
opt_def.small_roi_size = 100;
opt_def.ghost_roi_size = 1000;
opt_def.slice_target = 7;
opt_def.image_width = 0.9;
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
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % 


if options.philips,
    list_files = dir([dir_base '\' dir_series ]);
    fname_cur = list_files(end).name;
    path_curr = [dir_base '\' dir_series '\' fname_cur];
    options.slice_target = options.slice_target;
    data = ACR_QA_get_dcm(path_curr,options);
else
    path_curr = [dir_base '\' dir_series '\' num2str(options.slice_target,'%0.4d') '.dcm' ];
    options.slice_target=1;
    data = ACR_QA_get_dcm(path_curr,options);
end


radius_mask = ceil(sqrt(20000 / pi())/data.hdr.PixelSpacing(1));

options.large_grid = [data.hdr.Columns data.hdr.Rows];
options.centre = [data.centre_x  data.centre_y+5];

mask.large.img = make_ellipse_mask(radius_mask, radius_mask, options);
temp = vol2vec(data.img, mask.large.img);
mask.large.mean = mean(temp.values);
mask.large.sd = std(temp.values);
% Mask image to isolate voxels 
temp = data.img .* mask.large.img;

radius_roi = ceil(sqrt( 100 / pi())/ data.hdr.PixelSpacing(1));
mask_roi = make_ellipse_mask(radius_roi, radius_roi);
mask_roi = mask_roi / sum(mask_roi(:));

% Make a smaller mask to restrict roi search to within Large ROI
mask.small.img = make_ellipse_mask(radius_mask - radius_roi, radius_mask - radius_roi,options);

data_smoothed = mask.small.img .* conv2(temp, mask_roi, 'same');

% find maximum and minium ROI
mask.high_IU.mean = max(data_smoothed(:));
temp = data_smoothed;
temp(~temp) = inf;
mask.low_IU.mean = min(temp(:));

% get locations
[mask.high_IU.y, mask.high_IU.x ] = find(data_smoothed == mask.high_IU.mean);
[mask.low_IU.y, mask.low_IU.x ] = find(data_smoothed == mask.low_IU.mean);

% add rois to data_show
options.centre = [mask.high_IU.x, mask.high_IU.y ];
mask.high_IU.img = make_ellipse_mask(radius_roi, radius_roi,options);
options.centre = [mask.low_IU.x, mask.low_IU.y ];
mask.low_IU.img = make_ellipse_mask(radius_roi, radius_roi,options);



% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % 
%  GHOSTING

mask.left = ACR_QA_create_ghost_ROI(data, 'left');
mask.right = ACR_QA_create_ghost_ROI(data, 'right');
mask.top = ACR_QA_create_ghost_ROI(data, 'top');
mask.bot = ACR_QA_create_ghost_ROI(data, 'bot');


temp = 1 - edge(mask.large.img) - edge(mask.high_IU.img) - edge(mask.low_IU.img);   % Inverse mask to zero out edge voxels
data_show = repmat(temp.*data.img/max(data.img(:)),[1 1 3]);

% add edge to create colour
data_show(:,:,3) = data_show(:,:,3)+ edge(mask.large.img);
% add edge to create colour
data_show(:,:,1) = data_show(:,:,1)+ edge(mask.high_IU.img);
% add edge to create colour
data_show(:,:,1) = data_show(:,:,1)+ edge(mask.low_IU.img);
data_show(:,:,3) = data_show(:,:,3) +edge(mask.low_IU.img);

data_show = data_show + repmat(edge(mask.left.img),[ 1 1 3]) ...
    + repmat(edge(mask.right.img),[ 1 1 3]) ...
    + repmat(edge(mask.top.img),[ 1 1 3]) ...
    + repmat(edge(mask.bot.img),[ 1 1 3]);

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
set(h_fig,'inverthardcopy','off'); 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

pooled_SD = sqrt( mean(mask.top.sd^2 + mask.bot.sd^2 + mask.left.sd^2 + mask.right.sd^2));

subplot('position',[0.05 0 options.image_width options.image_width])
imshow(data_show,[ ])
title({[options.magnet ' - ' options.coil ' - ' options.date ' - ' options.short_name] , ...
    [  ' Uniformity = ' ...
    num2str(  ( 1 - (mask.high_IU.mean-mask.low_IU.mean) ...
    /(mask.high_IU.mean + mask.low_IU.mean)),'%4.2f')...
    ' [>0.82];  Ghosting Ratio = ' ...
    num2str( abs((mask.top.mean + mask.bot.mean)-( mask.left.mean + mask.right.mean)) ...
        / (2 * mask.large.mean),'%4.4f')...
    ' [<0.025]'],['SNR - ' num2str(mask.large.mean/pooled_SD,'%4.2f') ...
    ' [Pooled noise = ' num2str(pooled_SD,'%4.2f') ']']});
axis equal
text(mask.high_IU.x, mask.high_IU.y - radius_roi, ['HIU - ' num2str(mask.high_IU.mean,'%4.2f') ],...
    'HorizontalAlignment','Center', 'VerticalAlignment','Bottom',...
    'Color','r');
text(mask.low_IU.x, mask.low_IU.y - radius_roi, ['LIU - ' num2str(mask.low_IU.mean,'%4.2f') ],...
    'HorizontalAlignment','Center', 'VerticalAlignment','Bottom',...
    'Color','m');
text(mask.top.x, mask.top.y, [num2str(mask.top.mean,'%4.2f') ' ± ' num2str(mask.top.sd,'%4.2f')],...
    'HorizontalAlignment','Center', 'VerticalAlignment','Middle',...
    'Color','w');
text(mask.bot.x, mask.bot.y, [num2str(mask.bot.mean,'%4.2f') ' ± ' num2str(mask.bot.sd,'%4.2f')],...
    'HorizontalAlignment','Center', 'VerticalAlignment','Middle',...
    'Color','w');
text(mask.left.x, mask.left.y, [num2str(mask.left.mean,'%4.2f') ' ± ' num2str(mask.left.sd,'%4.2f')],...
    'HorizontalAlignment','Center', 'VerticalAlignment','Middle',...
    'Color','w','Rotation',90);
text(mask.right.x, mask.right.y, [num2str(mask.right.mean,'%4.2f') ' ± ' num2str(mask.right.sd,'%4.2f')],...
    'HorizontalAlignment','Center', 'VerticalAlignment','Middle',...
    'Color','w','Rotation',90);
text(data.centre_x, data.centre_y, [num2str(mask.large.mean,'%4.2f') ' ± ' num2str(mask.large.sd,'%4.2f')],...
    'HorizontalAlignment','Center', 'VerticalAlignment','Middle',...
    'Color','b');

saveas(h_fig,[options.fname_base '-Uniformity_Ghosting.jpg']);    