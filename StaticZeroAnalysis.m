close all; clear; clc;

date        = "2023-12-22"; 
folder      = "STATICA_"+date;
spidername  = "07714532B-1";
spiname     = char(spidername);

save_path = "C:\Users\stefa\Desktop\Donà Stefano - Master Thesis\Images\chapter04\measures";

file_folder = "Statica_"+spidername;
file_name   = "zero_"+file_folder+".txt";
file_path   = fullfile(folder, file_folder, file_name);

FID = fopen(file_path);
datacell = textscan(FID, '%f%f', CommentStyle='#');
fclose(FID);

pos   = datacell{1};
force = -datacell{2};
time  = 6*(1:length(force));
l = length(force);

% force = smooth(force, 10, 'rloess')
force = smooth(force, 'rloess');

force_forw = force(1:l/2);
force_back = force(l/2:end);

% force_forw = smooth(force_forw);
% force_back = smooth(force_back);

time_forw = time(1:l/2);
time_back = time(l/2:end);

figure
plot(time_forw, force_forw, DisplayName="Forw Seq", LineWidth=1.1)
hold on
plot(time_back, force_back, DisplayName="Back Seq", LineWidth=1.1)
% plot(time, smooth(force)+0.16, 'k--', DisplayName="Error Band")
% plot(time, smooth(force)-0.16, 'k--', HandleVisibility='off')
grid on
xlim([0, max(time)])
ylim([-0.4, 0.4])
title("Time Trend of Force at Null Displacement", Interpreter="latex", FontSize=20)
subtitle(spiname(end-2:end), Interpreter="latex", FontSize=16)
xlabel("time [s]", Interpreter="latex", FontSize=14)
ylabel("$F$ [N]", Interpreter="latex", FontSize=14)
legend(Interpreter="latex", FontSize=12, Location="north")
saveas(gcf, save_path+"\st_zero_"+date+"_"+spiname(end-2:end)+".svg", 'svg')

% figure
% plot(smooth(force, 20, 'rloess'))