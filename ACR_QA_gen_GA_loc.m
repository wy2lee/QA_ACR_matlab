function ACR_QA_gen_GA_loc(dir_base, dir_series, options)
% ACR_QA_gen_GA_loc(dir_base, dir_series, options)
%   Calculates geometric accuracy for localizer only
% 
%   INPUTS
%       dir_base - base subject directory
%       dir_series - series directory with dicoms
%       options - possible options
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
opt_def.height = 50;
opt_def.height_offset = -100;
opt_def.water_height = 40;
opt_def.water_offset = -opt_def.water_height -10;
opt_def.width = 40;
opt_def.width_offset = opt_def.width/2; 
opt_def.init_min = 0.15;
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

list_files = dir([dir_base '\' dir_series ]);
if options.philips,
    fname_cur = list_files(end).name;
    options.slice_target = 1;
else
    fname_cur = '0001.dcm';
    options.slice_target = 1;
end
path_curr = [dir_base '\' dir_series '\' fname_cur];


data = ACR_QA_get_dcm(path_curr, options);

% Find Display Window (99th%)
sorted_values = sort(data.img(:));
num_sorted = length(sorted_values);
max_level = sorted_values(floor(num_sorted*0.99));
min_level = options.init_min * max_level;

vert_range = zeros(2, data.hdr.Columns);

data_show = repmat(data.img/max_level,[1 1 3]);

for count_col = 1:data.hdr.Columns
    if length(find(data.img(:,count_col) > min_level,1,'first'))>0 
        vert_range(1,count_col) = data.hdr.Columns - find(data.img(:,count_col) > min_level,1,'first');
        vert_range(2,count_col) = data.hdr.Columns - find(data.img(:,count_col) > min_level,1,'last');
        data_show(data.hdr.Columns - vert_range(1,count_col),count_col, :) = [1 0 0];
        data_show(data.hdr.Columns - vert_range(2,count_col),count_col, :) = [1 0 0];
    else
        vert_range(:,count_col) = [data.hdr.Columns/2; data.hdr.Columns/2];
    end
end
E2E_len = (vert_range(1,:) - vert_range(2,:)) * data.hdr.PixelSpacing(1);
index_E2E = find(E2E_len>140 & E2E_len<156);
E2E_bins = [143:153];

E2E_hist = hist(E2E_len(index_E2E), E2E_bins);


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


subplot('Position',[0.05, 0.05,0.4, 0.9]), 
    imshow(data_show);
    title({[options.magnet ' - ' options.coil ' - ' options.date ' - ' options.short_name] , ...
    [  ' End to End ']});

subplot('Position',[0.55, 0.15,0.4, 0.7]), 
    bar(E2E_bins, E2E_hist);
    hold on
    plot([145.5 145.5],[0 max(E2E_hist)*1.1], 'r', 'LineWidth',3);
    plot([150.5 150.5],[0 max(E2E_hist)*1.1], 'r', 'LineWidth',3);
    hold off
    set(gca,'FontSize',8);
    axis([143 153 0 max(E2E_hist)*1.1]);
    xlabel('End to End Length (mm)','FontSize',10); 
    ylabel('Counts','FontSize',10); 
    title({['Mean End to End '],[ num2str(mean(E2E_len(index_E2E)),'%4.1f') ' mm ' ...
        '(Target = 148 ' setstr(177) '2)']},'FontSize',12); 

saveas(h_fig,[options.fname_base '-End_to_End.jpg']);