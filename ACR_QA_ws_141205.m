clear all;
close all;
addpath W:\wayne\software\matlab_code\general

options.date = '141205';
options.magnet ='HSC-MR2';
options.coil = '8ch Head';
options.philips = 1;

dir_base = ['S:\QA\ACR\data\' options.magnet];
dir_out = ['S:\QA\ACR\reports\' options.magnet '\' options.date];

list_series = {'301-ACR-Ax-T1-SE'};
num_series = length(list_series);

list_short_names = {'ACR-AxT1'};

options.figure = 0;

curr_series = '101-Survey';     options.short_name = 'Survey';
options.fname_base = [dir_out '\' options.short_name];
ACR_QA_gen_GA_loc([dir_base '\' options.date ], curr_series, options); 


options.figure = 0;
for count_series = 1:num_series,
    curr_series = list_series{count_series};
    options.short_name = list_short_names{count_series};
    options.fname_base =     [dir_out '\' options.short_name];

    ACR_QA_gen_LC([dir_base '\' options.date ], curr_series, options);   
    ACR_QA_gen_IU([dir_base '\' options.date ], curr_series, options);         
    ACR_QA_gen_SR([dir_base '\' options.date ], curr_series, options);
    options.height_offset = -110;       
    ACR_QA_gen_SA([dir_base '\' options.date ], curr_series, options); 
    options=rmfield(options,'height_offset');
    
    ACR_QA_gen_GA_Ax([dir_base '\' options.date], curr_series, options);  
    ACR_QA_gen_ST([dir_base '\' options.date ], curr_series, options);
end

