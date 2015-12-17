function ACR_QA_gen_GA(dir_base, dir_series, options)
% ACR_QA_gen_GA(dir_base, dir_series, options)
%   Calculates geometric accuracy
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
opt_def.slices = [1,5];
opt_def.height = 50;
opt_def.height_offset = -100;
opt_def.water_height = 40;
opt_def.water_offset = -opt_def.water_height -10;
opt_def.width = 40;
opt_def.width_offset = opt_def.width/2; 
opt_def.init_min = 0.20;
opt_def.philips = 0;
opt_def.figure = 0;


% if no options are supplied set default options
if nargin < 3,
    options = opt_def;
end

list_options = fieldnames(opt_def);
num_options = length(list_options);


% If options is missing default field, set to default values
for count_opt = 1:num_options,
    opt_name = list_options{count_opt};
    if isfield(options, opt_name) == 0,
        options.(opt_name) = opt_def.(opt_name);
    end
end


% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %


% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % 
% Diameter of T1 - Slice 1

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
set(h_fig,'units','inches','outerposition',[0 0 6 3.5],...
    'position',[0 0 6 3.5], 'resize','on'); 
set(h_fig,'PaperUnits','inches','PaperPosition',[0 0 6 3.5],'PaperSize',[6 3.5]);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


for count_slice = 1:num_slices,
    curr_slice = options.slices(count_slice);

    if not(options.philips),
        path_curr = [dir_base '\' dir_series '\' num2str(curr_slice,'%0.4d') '.dcm' ];
        options.slice_target = 1;
        data = ACR_QA_get_dcm(path_curr,options);
        % adjust_centre_y 10 mm down because LC insert is not centered
%         data.centre_y = data.centre_y + floor(options.y_shift / data.hdr.PixelSpacing(1)); 
    else
        data.img = data_base.img(:,:,count_slice);
    end

    % Find Display Window
    max_level = max(data.img(:));
    min_level = options.init_min * max_level;

    vert_range(1) = find(data.img(:, data.centre_x) > min_level,1,'first');
    vert_range(2) = find(data.img(:, data.centre_x) > min_level,1,'last');
    max_diam_TB = (vert_range(2)-vert_range(1)+1) * data.hdr.PixelSpacing(1);

    horz_range(1) = find(data.img(data.centre_y, :) > min_level,1,'first');
    horz_range(2) = find(data.img(data.centre_y, :) > min_level,1,'last');
    max_diam_LR = (horz_range(2)-horz_range(1)+1) * data.hdr.PixelSpacing(1);

    data_show = repmat(data.img/max_level,[1 1 3]);

    data_show(vert_range(1):vert_range(2), data.centre_x + [-1:1],1) = 1;
    data_show(vert_range(1):vert_range(2), data.centre_x + [-1:1],2) = 0;
    data_show(vert_range(1):vert_range(2), data.centre_x + [-1:1],3) = 0;

    data_show(data.centre_y + [-1:1], horz_range(1):horz_range(2), 1) = 0;
    data_show(data.centre_y + [-1:1], horz_range(1):horz_range(2), 2) = 1;
    data_show(data.centre_y + [-1:1], horz_range(1):horz_range(2), 3) = 0;

% DIAGONAL LINES
%    Use diag and flip to quickly extract values along the diagonals
%    'Shift' image so that phantom center is at centre of diag
    data_diag = data.img( [vert_range(1):vert_range(2)], [horz_range(1):horz_range(2)]);

    diag_TL_BR(1) = find( diag(data_diag) > min_level,1,'first');
    diag_TL_BR(2) = find( diag(data_diag) > min_level,1,'last');
    max_diam_TL_BR = [diag_TL_BR(2) - diag_TL_BR(1) + 1] * data.hdr.PixelSpacing(1) * sqrt(2);
    
    diag_BL_TR(1) = find( diag(flipdim(data_diag,1)) > min_level,1,'first');
    diag_BL_TR(2) = find( diag(flipdim(data_diag,1)) > min_level,1,'last');
    max_diam_BL_TR = [diag_BL_TR(2) - diag_BL_TR(1) + 1] * data.hdr.PixelSpacing(1) * sqrt(2);

     % Calculate distances, colour in display
    for index_counter = diag_TL_BR(1):diag_TL_BR(2),
        data_show(index_counter + vert_range(1), index_counter + horz_range(1) -1, :) = [1 0 1];
    end

    for index_counter = diag_BL_TR(1):diag_BL_TR(2),
        data_show( vert_range(2) - index_counter  , ...
            index_counter + horz_range(1) - 2, :) = [0 1 1];
    end
    
    subplot('position',[0.05 + 0.45*(count_slice-1), 0,0.45,0.8]), 
        axis equal;
        imshow(data_show);
        title(['Slice ' num2str(curr_slice) ' (Target = 190 ' setstr(177) ' 2mm)']);
        text(data.centre_x, ...
            vert_range(1) - 0.05 * max_diam_TB/data.hdr.PixelSpacing(1) , ...
            [num2str(max_diam_TB,'%4.1f')  'mm'],'Color','r',...
            'HorizontalAlignment','Center');
        text(horz_range(1) - 0.05 * max_diam_LR/data.hdr.PixelSpacing(1) , ...
            data.centre_y, ...
            [num2str(max_diam_LR,'%4.1f') ' mm'],'Color','g',...
            'HorizontalAlignment','Center','Rotation',90);
        text(horz_range(1) + 0.05 * max_diam_LR/data.hdr.PixelSpacing(1) * sqrt(2) , ...
             vert_range(1) + 0.05 * max_diam_TB/data.hdr.PixelSpacing(1) * sqrt(2) , ...
            [num2str(max_diam_TL_BR,'%4.1f') ' mm'],'Color','m',...
            'HorizontalAlignment','Center','Rotation',45);
        text(horz_range(2) - 0.05 * max_diam_LR/data.hdr.PixelSpacing(1) * sqrt(2) , ...
             vert_range(1) + 0.05 * max_diam_TB/data.hdr.PixelSpacing(1) * sqrt(2) , ...
            [num2str(max_diam_BL_TR,'%4.1f') ' mm'],'Color','c',...
            'HorizontalAlignment','Center','Rotation',-45);

end

text(0,-50,[options.magnet ' - ' options.coil ' - ' options.date ' - '...
    options.short_name ' - Geom Acc'],...
    'FontSize',14,'HorizontalAlignment','center');
saveas(h_fig,[options.fname_base '-Geom_Acc_Diam.jpg']);
