function data = ACR_QA_get_dcm(path_dcm, options) 
% data = ACR_QA_get_dcm(path_dcm, options) 
%   Loads a dicom slice into a data object 
%       Also calculates some general image parameters
% 
%   INPUTS
%       path_dcm - full path to the dicom file being loaded
%       options - possible options
%           .init_min - Initial min level to find centre [0.2 of max]
% 
%   OUTPUTS
%       data - structure with the following
%           .img - imaging data
%           .hdr - dicom header information
%           .centre_y - center of phantom in image (row)
%           .centre_x - center of phantom in image (col)
% 
%   NOTES
% 
%   Created - 2014 July 8th by Wayne Lee

% OPTIONS
opt_def = {};
opt_def.init_min = 0.2;
opt_def.slice_target = 1;
opt_def.philips = 0;

list_options = fieldnames(opt_def);
num_options = length(list_options);

% if no options are supplied set default options
if nargin < 2,
    options = opt_def;
end

% If options is missing default field, set to default values
for count_opt = 1:num_options,
    opt_name = list_options{count_opt};
    if isfield(options, opt_name) == 0,
        options.(opt_name) = opt_def.(opt_name);
    end
end


data.img = double(squeeze(dicomread(path_dcm)));
data.img = squeeze(data.img(:,:, options.slice_target));
data.hdr = dicominfo(path_dcm);
if options.philips,
    data.hdr.PixelSpacing = data.hdr.PerFrameFunctionalGroupsSequence.Item_1.PixelMeasuresSequence.Item_1.PixelSpacing;
    data.hdr.Rows = size(data.img(:,:,1),1);
    data.hdr.Columns = size(data.img(:,:,1),2);
end

data.img(1,:,:) = 0;
data.img(data.hdr.Rows,:,:) = 0;
data.img(:,1,:) = 0;
data.img(:,data.hdr.Columns,:) = 0;

data.centre_y = floor(find(data.img(:,floor(data.hdr.Columns/2),1)> options.init_min*max(data.img(:)),1,'first') /2 + ...
    find(data.img(:,floor(data.hdr.Columns/2),1)> options.init_min*max(data.img(:)),1,'last') /2);
    
    
data.centre_x = floor(find(data.img(data.centre_y,:,1)> options.init_min*max(data.img(:)),1,'first') /2 + ...
    find(data.img(data.centre_y,:,1)> options.init_min*max(data.img(:)),1,'last') /2);

data.hdr.Rows = double(data.hdr.Rows);
data.hdr.Columns = double(data.hdr.Columns);

