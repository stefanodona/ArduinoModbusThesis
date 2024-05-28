close all; clc; clear;

spidernames = {"HM077x145x38AA-1",...
               "HM077x145x38AA-2",...
               "HM077x145x38AB-1",...
               "HM077x145x38AB-2",...
               "GRPCNT1454A-1",...
               "GRPCNT1454A-2",...
               "GRPCNT1454A-3"};

date = "2024-02-01";
mainfolder = "TRACKING_"+date;

samples  = 9;
for ii=1:length(spidernames)
cnt_name = spidernames{ii};
% LOAD TIMES
track_file = strcat(mainfolder, "/Tracking_", cnt_name,"/Tracking_",cnt_name, ".txt");
FID = fopen(track_file);
tracking = textscan(FID, '%f%f%f', CommentStyle='#'); 
fclose(FID);

tracking_time = tracking{3}/1000;
tracking_force = -tracking{2};
tracking_pos = -tracking{1};

x = 1e-3*(-11:0.25:11);
l = length(tracking_time);


jj          = 0;
acq_per_sec = 10;                 
% acq_per_sec = 50;
nums_sample = 3; 
leg_lab     = [];

nums_sample = samples;
ns = samples;

jj    = 0;
force = [];
pos   = [];
for ii = 1 : length(x)-1
    if mod((jj+1),3)==0
        jj=jj+1;
    end

    ind         = jj*acq_per_sec + nums_sample;
    pos         = [pos,     tracking_pos(ind)];
    force       = [force,   tracking_force(ind)];

    jj = jj+1;
end

[pos_sorted, idx_sorted] = sort(pos, 'ascend');
force_sorted             = force(idx_sorted);
f_forw                   = force_sorted;
x_forw                   = pos_sorted;

kms_f  = -f_forw./x_forw;

nums_sample = samples;

jj    = 0;
force = [];
pos   = [];
for ii = 1 : length(x)-1
    if mod((jj+1),3)==0
        jj=jj+1;
    end

    ind         = jj*acq_per_sec + nums_sample + length(tracking_force)/2;
    pos         = [pos,     tracking_pos(ind)];
    force       = [force,   tracking_force(ind)];

    jj = jj+1;
end

[pos_sorted, idx_sorted] = sort(pos, 'ascend');
force_sorted             = force(idx_sorted);
f_back                   = force_sorted;
x_back                   = pos_sorted;

%%
save_main_folder = "STATICA_2024-03-11";
save_folder = "Statica_"+cnt_name;
save_file = save_folder+".txt";

save_path_folder = fullfile(save_main_folder, save_folder)
save_path_file = fullfile(save_path_folder, save_file);


if exist("save_path_folder", 'dir')~=7
    mkdir(save_path_folder);
end

filler = zeros(1, length(x_forw));

fileID = fopen(save_path_file, 'w');
fprintf(fileID, '%9.5f %9.5f %9.5f %9.5f %9.5f %9.5f %9.5f %9.5f \r\n', [x_forw; filler; f_forw; filler; x_back; filler; f_back; filler]);
fclose(fileID);

end

