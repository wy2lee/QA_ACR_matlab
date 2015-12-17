% function ACR_QA_gen_GA(dir_base, dir_series, options)
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
opt_def.slices = [1,11];
opt_def.height = 50;
opt_def.height_offset = -100;
opt_def.water_height = 40;
opt_def.water_offset = -opt_def.water_height -10;
opt_def.width = 40;
opt_def.width_offset = opt_def.width/2; 
opt_def.init_min = 0.45;
options = opt_def;

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



dir_base = 'T:\mrdata\QA\ACR'
dir_scan = 'ACR_L_QA-140523';
dir_series_loc = '002-ACR-Sag-Loc-SE';
dir_series_T1 = '002-ACR-Sag-Loc-SE';


min_level_pct = 0.15;

% GEOMETRIC ACCURACY

% End-to-end length of Localizer
path_curr = [dir_base '\' dir_scan '\' dir_ACR_Loc '\0001.dcm' ];
data_Loc = double(dicomread(path_curr));
hdr_Loc = (dicominfo(path_curr));

[rows cols] = size(data_Loc);

% Find Display Window
max_level = max(data_Loc(:));
min_level = min_level_pct * max_level;

vert_range = zeros(2,cols);

data_show = repmat(data_Loc/max_level,[1 1 3]);

for count_col = 1:cols
    if length(find(data_Loc(:,count_col) > min_level,1,'first'))>0 
        vert_range(1,count_col) = cols - find(data_Loc(:,count_col) > min_level,1,'first');
        vert_range(2,count_col) = cols - find(data_Loc(:,count_col) > min_level,1,'last');
        data_show(cols-vert_range(1,count_col),count_col, :) = [1 0 0];
        data_show(cols-vert_range(2,count_col),count_col, :) = [1 0 0];
    else
        vert_range(:,count_col) = [cols/2; cols/2];
    end
end
E2E_len = (vert_range(1,:) - vert_range(2,:)) * hdr_Loc.PixelSpacing(1);
index_E2E = find(E2E_len>140 & E2E_len<156);
E2E_bins = [143:153];

E2E_hist = hist(E2E_len(index_E2E), E2E_bins);

% 
figure(1),
subplot(2,2,1), 
    imshow(data_show);
    title('Sag Loc - End to End Length edge detection');
subplot(2,2,3), 
    bar(E2E_bins, E2E_hist);
    hold on
    plot([145.5 145.5],[0 max(E2E_hist)*1.1], 'r', 'LineWidth',3);
    plot([150.5 150.5],[0 max(E2E_hist)*1.1], 'r', 'LineWidth',3);
    hold off
    axis([143 153 0 max(E2E_hist)*1.1]);
    xlabel('End to End Length (mm)'); ylabel('Counts');
    title(['Mean End to End Length = ' num2str(mean(E2E_len(index_E2E)),'%4.1f') ' mm ' ...
        '(Target = 148 ' setstr(177) '2)']);

% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % 
% Diameter of T1 - Slice 1

min_level_pct = 0.2;


path_curr = [dir_base '\' dir_scan '\' dir_ACR_T1 '\0001.dcm' ];
data_Loc = double(dicomread(path_curr));
hdr_Loc = (dicominfo(path_curr));

[rows cols] = size(data_Loc);

% Find Display Window
max_level = max(data_Loc(:));
min_level = min_level_pct * max_level;

vert_range = zeros(2,cols);
horz_range = zeros(2,cols);

data_show = repmat(data_Loc/max_level,[1 1 3]);

for count_col = floor(cols*0.4):ceil(cols*0.6)
    if length(find(data_Loc(:,count_col) > min_level,1,'first'))>0 
        vert_range(1,count_col) = find(data_Loc(:,count_col) > min_level,1,'first');
        vert_range(2,count_col) = find(data_Loc(:,count_col) > min_level,1,'last');
    else
        vert_range(:,count_col) = [cols/2; cols/2];
    end
end
E2E_len_TB = (vert_range(2,:) - vert_range(1,:)) * hdr_Loc.PixelSpacing(1);
[max_diam_TB,index_max_diam_TB] = max(E2E_len_TB );

for count_row = floor(rows*0.4):ceil(rows*0.6)
    if length(find(data_Loc(:,count_row) > min_level,1,'first'))>0 
        horz_range(1,count_row) = find(data_Loc(count_row,:) > min_level,1,'first');
        horz_range(2,count_row) = find(data_Loc(count_row,:) > min_level,1,'last');
    else
        horz_range(:,count_row) = [rows/2; rows/2];
    end
end
E2E_len_LR = (horz_range(2,:) - horz_range(1,:)) * hdr_Loc.PixelSpacing(1);
[max_diam_LR index_max_diam_LR] = max(E2E_len_LR );

% Calculate real centre based on halfway point of max distance lines
index_TB = floor(mean(horz_range(:,index_max_diam_LR)));
index_LR = floor(mean(horz_range(:,index_max_diam_TB)));



TB_line = vert_range(1,index_TB):vert_range(2,index_TB);
LR_line = horz_range(1,index_LR):horz_range(2,index_LR);

data_show(TB_line , index_TB+[-1:1],1) = 1;
data_show(TB_line , index_TB+[-1:1],2) = 0;
data_show(TB_line , index_TB+[-1:1],3) = 0;

data_show(index_LR+[-1:1], LR_line, 1) = 0;
data_show(index_LR+[-1:1], LR_line, 2) = 1;
data_show(index_LR+[-1:1], LR_line, 3) = 0;

% 
subplot(2,2,2), 
    imshow(data_show);
    title(['Ax T1 Slice 1 - Diameter Check (Target = 190 ' setstr(177) ' 2mm)']);
    text(cols/2, cols*0.08,[num2str(max_diam_TB,'%4.1f')  'mm'],'Color','r',...
        'HorizontalAlignment','Center');
    text(cols*0.08, rows/2,[num2str(max_diam_LR,'%4.1f') ' mm'],'Color','g',...
        'HorizontalAlignment','Center','Rotation',90);
    
    
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % 
% Diameter of T1 - Slice 5
path_curr = [dir_base '\' dir_scan '\' dir_ACR_T1 '\0005.dcm' ];
data_Loc = double(dicomread(path_curr));
hdr_Loc = (dicominfo(path_curr));

[rows cols] = size(data_Loc);

% Find Display Window
max_level = max(data_Loc(:));
min_level = min_level_pct * max_level;

vert_range = zeros(2,cols);
horz_range = zeros(2,cols);

data_show = repmat(data_Loc/max_level,[1 1 3]);

for count_col = floor(cols*0.4):ceil(cols*0.6)
    if length(find(data_Loc(:,count_col) > min_level,1,'first'))>0 
        vert_range(1,count_col) = find(data_Loc(:,count_col) > min_level,1,'first');
        vert_range(2,count_col) = find(data_Loc(:,count_col) > min_level,1,'last');
    else
        vert_range(:,count_col) = [cols/2; cols/2];
    end
end
E2E_len_TB = (vert_range(2,:) - vert_range(1,:)) * hdr_Loc.PixelSpacing(1);
[max_diam_TB,index_max_diam_TB] = max(E2E_len_TB );

for count_row = floor(rows*0.4):ceil(rows*0.6)
    if length(find(data_Loc(:,count_row) > min_level,1,'first'))>0 
        horz_range(1,count_row) = find(data_Loc(count_row,:) > min_level,1,'first');
        horz_range(2,count_row) = find(data_Loc(count_row,:) > min_level,1,'last');
    else
        horz_range(:,count_row) = [rows/2; rows/2];
    end
end
E2E_len_LR = (horz_range(2,:) - horz_range(1,:)) * hdr_Loc.PixelSpacing(1);
[max_diam_LR index_max_diam_LR] = max(E2E_len_LR );

% Calculate real centre based on halfway point of max distance lines
index_TB = floor(mean(horz_range(:,index_max_diam_LR)));
index_LR = floor(mean(horz_range(:,index_max_diam_TB)));


TB_line = vert_range(1,index_TB):vert_range(2,index_TB);
LR_line = horz_range(1,index_LR):horz_range(2,index_LR);

data_show(TB_line , index_TB+[-1:1],1) = 1;
data_show(TB_line , index_TB+[-1:1],2) = 0;
data_show(TB_line , index_TB+[-1:1],3) = 0;

data_show(index_LR+[-1:1], LR_line, 1) = 0;
data_show(index_LR+[-1:1], LR_line, 2) = 1;
data_show(index_LR+[-1:1], LR_line, 3) = 0;

% Create index for diagonal lines which run through index_TB / index_LR
index_diag_TL_BR(1,:) = index_TB + ([1:rows] - floor(rows/2));
index_diag_TL_BR(2,:) = index_LR + ([1:rows] - floor(rows/2));

index_diag_BL_TR(1,:) = index_TB + ([1:rows] - floor(rows/2));
index_diag_BL_TR(2,:) = index_LR - ([1:rows] - floor(rows/2) - 1); %Correct index slightly

% Move along diag to find first value above min level 
index_TL_BR_s = 0;
index_counter = 0;
while index_TL_BR_s == 0;
    index_counter = index_counter +1;
    index_r = index_diag_TL_BR(1, index_counter);
    index_c = index_diag_TL_BR(2, index_counter);
    data_Loc(index_r, index_c);
    if data_Loc(index_r,index_c) > min_level
        index_TL_BR_s = index_counter;
    end
end

index_BL_TR_s = 0;
index_counter = 0;
while index_BL_TR_s == 0;
    index_counter = index_counter +1;
    index_r = index_diag_BL_TR(1, index_counter);
    index_c = index_diag_BL_TR(2, index_counter);
    data_Loc(index_r, index_c);
    if data_Loc(index_r,index_c) > min_level
        index_BL_TR_s = index_counter;
    end
end


% Move along diag to find last value above min level 
index_TL_BR_e = 0;
index_counter = rows+1;
while index_TL_BR_e == 0;
    index_counter = index_counter -1;
    index_r = index_diag_TL_BR(1, index_counter);
    index_c = index_diag_TL_BR(2, index_counter);
    data_Loc(index_r, index_c);
    if data_Loc(index_r,index_c) > min_level
        index_TL_BR_e = index_counter;
    end
end

index_BL_TR_e = 0;
index_counter = rows+1;
while index_BL_TR_e == 0;
    index_counter = index_counter -1;
    index_r = index_diag_BL_TR(1, index_counter);
    index_c = index_diag_BL_TR(2, index_counter);
    data_Loc(index_r, index_c);
    if data_Loc(index_r,index_c) > min_level
        index_BL_TR_e = index_counter;
    end
end

% Calculate distances, colour in display
for index_counter = index_TL_BR_s:index_TL_BR_e,
    index_r = index_diag_TL_BR(1, index_counter);
    index_c = index_diag_TL_BR(2, index_counter);
    data_show(index_r, index_c, :) = [1 0 1];
end

% Calculate distances, colour in display
for index_counter = index_BL_TR_s:index_BL_TR_e,
    index_r = index_diag_BL_TR(1, index_counter);
    index_c = index_diag_BL_TR(2, index_counter);
    data_show(index_r, index_c, :) = [0 1 1];
end

max_diam_TL_BR = [index_TL_BR_e - index_TL_BR_s + 1] * hdr_Loc.PixelSpacing(1) * sqrt(2); 
max_diam_BL_TR = [index_BL_TR_e - index_BL_TR_s + 1] * hdr_Loc.PixelSpacing(1) * sqrt(2); 

% 
subplot(2,2,4), 
    imshow(data_show);
    title(['Ax T1 Slice 5 - Diameter Check (Target = 190 ' setstr(177) ' 2mm)']);
    text(cols/2, cols*0.08,[num2str(max_diam_TB,'%4.1f') ' mm'],'Color','r',...
        'HorizontalAlignment','Center');
    text(cols*0.08, rows/2,[num2str(max_diam_LR,'%4.1f') ' mm'],'Color','g',...
        'HorizontalAlignment','Center','Rotation',90);
    text(cols*0.2, cols*0.2,[num2str(max_diam_TL_BR,'%4.1f') ' mm'],'Color','m',...
        'HorizontalAlignment','Center','Rotation',45);
    text(cols*0.8, cols*0.2,[num2str(max_diam_BL_TR,'%4.1f') ' mm'],'Color','c',...
        'HorizontalAlignment','Center','Rotation',-45);

    
