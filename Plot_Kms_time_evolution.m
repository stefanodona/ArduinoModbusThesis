close all; clear; clc;



cnt_name = "07714532B-1"
% LOAD TIMES
track_file = strcat("TRACKING/Tracking_", cnt_name,"/Tracking_",cnt_name, ".txt");
FID = fopen(track_file);
tracking = textscan(FID, '%f%f%f', CommentStyle='#');
fclose(FID);

tracking_time = tracking{3}/1000;
tracking_force = -tracking{2};
tracking_displ = tracking{1};

% to_ignore = 1/0.25*3*10;
% tracking_time(end-to_ignore+1:end)=[];
% tracking_force(end-to_ignore+1:end)=[];

figure(3)
plot(tracking_time, tracking_force, '.-', LineWidth=1, MarkerSize=10)
grid on
title("Force vs Time", Interpreter="latex", FontSize=20)
subtitle("CNT07714532B-1", Interpreter="latex")
xlabel("Time [s]", Interpreter="latex", FontSize=14)
ylabel("Force [N]", Interpreter="latex", FontSize=14)
% xlim([202.5,225])

% ii=0;
% % tracking_t_delay=zeros(length(tracking_time), 1);
% for idx = 1:80
%     if mod((ii+1), 3)==0
%         ii=ii+1;
%     end
%     jj = ii*10+1;
%     delay = t_x_rise(idx)-tracking_time(jj);
%     tracking_t_delay(jj:end) = tracking_time(jj:end)+delay;
%     ii=ii+1;
% end


num_cyc = length(tracking_displ)/10/3*2;


stiff_2 = [];
stiff_3 = [];

spls = [3,5,10];
labels = {};
figure()
for kk=1:length(spls)
    spl = spls(kk)
    displ = [];
    stiff_1 = [];
    
    ii=1;
    for jj=1:num_cyc
        idx=spl+(ii-1)*10;

        f_1 = tracking_force(idx);
        x_1 = tracking_displ(idx);
        stiff_1 = [stiff_1; f_1/x_1];
        displ = [displ; x_1];
        ii=ii+1;
        if mod(ii, 3)==0
            ii=ii+1;
        end
    end
    [x_sort, idx_sort] = sort(displ, 'ascend');
    stiff_1 = stiff_1(idx_sort);
    labels{end+1} = strcat(num2str(spl*100),'ms');

    plot(x_sort, stiff_1, LineWidth=1)
    hold on
end
hold off
grid on
title("Time Evolution of Stiffness", Interpreter="latex", FontSize=20)
subtitle(strcat("CNT",cnt_name), Interpreter="latex")
legend(labels, Interpreter="latex", Location="northwest", FontSize=12)
xlabel("displacement [mm]", Interpreter="latex", FontSize=14)
ylabel("Stiffness [N/mm]", Interpreter="latex", FontSize=14)
ylim([0,7])