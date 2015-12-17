function ACR_QA_gen_LC(dir_base, dir_series, options)
% ACR_QA_gen_LC(dir_base, dir_series, options)
%   Displays low contrast slices for evaluation
% 
%   INPUTS
%       dir_base - base subject directory
%       dir_series - series directory with dicoms
%       options - possible options
%           .slices - Should be 8:11
%           .y_shift - Set to 10mm (non-centered LC disk)
%           .LC_rad - Set to 45mm (LC Disk Radius)
%           .init_min - Initial min level to find centre [0.2 of max]
% 
%   OUTPUTS
%       Creates a figure showing low contrast slices for evaluation
% 
%   NOTES
% 
%   Created - 2014 July 8th by Wayne Lee

% Define default options
opt_def = {};
opt_def.slices = [8:11];
opt_def.y_shift = 10;
opt_def.LC_rad = 45;
opt_def.init_min = 0.2;
opt_def.philips = 0;
opt_def.figure = 0;
opt_def.fname_base = ['./' dir_series];
opt_def.short_name = [dir_series];

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


if options.philips,
    list_files = dir([dir_base '\' dir_series ]);
    fname_cur = list_files(end).name;
    path_curr = [dir_base '\' dir_series '\' fname_cur];
    options.slice_target = options.slices;
    data_base = ACR_QA_get_dcm(path_curr,options);
    data = data_base;
    % adjust_centre_y 10 mm down because LC insert is not centered
    data.centre_y = data.centre_y + floor(options.y_shift / data.hdr.PixelSpacing(1)); 
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

plot_sz = 0.4;
plot_space = 0.45;

for count_slice = 1:num_slices,
    curr_slice = options.slices(count_slice);
    
    if not(options.philips),
        path_curr = [dir_base '\' dir_series '\' num2str(curr_slice,'%0.4d') '.dcm' ];
        options.slice_target = 1;
        data = ACR_QA_get_dcm(path_curr,options);
        % adjust_centre_y 10 mm down because LC insert is not centered
        data.centre_y = data.centre_y + floor(options.y_shift / data.hdr.PixelSpacing(1)); 
    else
        data.img = data_base.img(:,:,count_slice);
    end
    

    % Contrast insert diameter ~ 9cm, create a 10cm square focus
    CL_rad = ceil( options.LC_rad / data.hdr.PixelSpacing(1));
    index_y = [-CL_rad:CL_rad] + data.centre_y;
    index_x = [-CL_rad:CL_rad] + data.centre_x;

    data_small = data.img(index_y, index_x);

    level_min = 0.95*mean(data_small(:));
    level_max = max(data_small(:));

    subplot('Position',[0.05 + mod(count_slice-1,2) * plot_space,...
        0.9 - ceil(count_slice/2) * plot_space,  plot_space, plot_sz], ...
        'units','normalized')
    imshow(data_small,[level_min level_max ])
    
    title(['Slice - ' num2str(curr_slice) ]);

    axis equal
end

text(-6,-130,[options.magnet ' - ' options.coil ' - ' options.date ' - '...
    options.short_name ' - Low Contrast'],...
    'FontSize',14,'HorizontalAlignment','center');
saveas(h_fig,[options.fname_base '-Low_contrast.jpg']); 
