function mask = ACR_QA_create_ghost_ROI(data, location, options)
% data = ACR_QA_create_ghost_ROI(data, mask, options) 
%   Creates an ellipitical roi for examining ghosting to Left, Right, Top 
%       or Bottom of phantom
% 
%   INPUTS
%       data - structure with image data
%       location - where ghost is to be located
%           allowable = 'left', 'right', 'top', 'bot'
%       options - possible options
%           .roi_vol - Volume of ROI to create
%           .init_min - Initial min level to find centre [0.2 of max]
%           .roi_width - Width of roi minor axis as % of gap between
%                  phantom edge and FOV
% 
%   OUTPUTS
%       mask - structure with the following
%           .img - imaging data
%           .mean - mean of data within mask
%           .sd - std dev of data within mask
%               
% 
% 
%   NOTES
% 
%   Created - 2014 July 8th by Wayne Lee

% % % % % % % % % % % % % % % % % % % % % % % % % % 
% Define default options
opt_def = {};
opt_def.init_min = 0.2;
opt_def.roi_vol = 1000;
opt_def.roi_width = 0.5;

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

% % % % % % % % % % % % % % % 

if strcmp(location, 'left'),
    mask.x = ceil(find(data.img(data.centre_y,:)> options.init_min * max( data.img (:)),1,'first') / 2);
    mask.y = data.centre_y;
    radius_x = floor(mask.x * options.roi_width);
    radius_y = ceil( options.roi_vol / pi() / ...
        (data.hdr.PixelSpacing(1)* radius_x) / data.hdr.PixelSpacing(1));
elseif strcmp(location, 'right'),
    mask.x = ceil(data.hdr.Columns/2 + find(data.img(data.centre_y,:)> options.init_min * max(data.img(:)),1,'last')/2);
    mask.y = data.centre_y;
    radius_x = floor( (data.hdr.Columns - mask.x ) * options.roi_width);
    radius_y = ceil( options.roi_vol / pi() / ...
        (data.hdr.PixelSpacing(1)* radius_x) / data.hdr.PixelSpacing(1));
elseif strcmp(location, 'top'),
    mask.x = data.centre_x;
    mask.y = ceil(find(data.img(:,data.centre_x)> options.init_min * max(data.img(:)),1,'first') / 2);
    radius_y = floor(mask.y * options.roi_width);
    radius_x = ceil( options.roi_vol / pi() / ...
        (data.hdr.PixelSpacing(1)* radius_y) / data.hdr.PixelSpacing(1));
elseif strcmp(location, 'bot'),
    mask.x = data.centre_x;
    mask.y = ceil(data.hdr.Rows/2 + find(data.img(:,data.centre_x)> options.init_min * max(data.img(:)),1,'last')/2);
    radius_y = floor((data.hdr.Rows - mask.y) * options.roi_width);
    radius_x = ceil( options.roi_vol / pi() / ...
        (data.hdr.PixelSpacing(1)* radius_y) / data.hdr.PixelSpacing(1));
else
    error('Bad location');
end

mask_options.large_grid = [data.hdr.Columns, data.hdr.Rows];
mask_options.centre = [mask.x, mask.y];

mask.img = make_ellipse_mask(radius_x, radius_y, mask_options);
[index_x, index_y] = find(mask.img == 1);
temp = vol2vec(data.img, mask.img);
mask.mean = mean(temp.values);
mask.sd = std(temp.values);