close all; clear; clc;


date = "2024-02-27";
mainfolder = "TRACKING_"+date;

cnt_name = '07714532B-1';
spiname = cnt_name(end-2:end);
save_path = "C:\Users\stefa\Desktop\Donà Stefano - Master Thesis\Images\chapter04\tracking";

% LOAD TIMES
track_file = strcat(mainfolder+"/Tracking_", cnt_name,"/Tracking_",cnt_name, ".txt");
FID = fopen(track_file);
tracking = textscan(FID, '%f%f%f', CommentStyle='#'); 
fclose(FID);

tracking_time = tracking{3}/1000;
tracking_force = -tracking{2};

l=length(tracking_time);

% to_ignore = 1/0.25*3*10;
% tracking_time(end-to_ignore+1:end)=[];
% tracking_force(end-to_ignore+1:end)=[];

figure('Renderer','painters','Position',[100, 100, 900, 420])
plot(tracking_time, tracking_force, '.-', LineWidth=1.1, MarkerSize=10)
grid on
title("Time Evolution of Force", Interpreter="latex", FontSize=20)
subtitle(cnt_name(end-2:end), Interpreter="latex", FontSize=16)
xlabel("t [s]", Interpreter="latex", FontSize=14)
ylabel("F [N]", Interpreter="latex", FontSize=14)
xline(tracking_time(l/2), 'k--', LineWidth=1)
text(tracking_time(l/4), max(tracking_force)/4*3, "Forw. Seq.", Interpreter="latex", FontSize=16, HorizontalAlignment="center")
text(tracking_time(l/4*3), max(tracking_force)/4*3, "Back. Seq.", Interpreter="latex", FontSize=16, HorizontalAlignment="center")
% xlim([200,225])
saveas(gcf, save_path+"\tracking_force_vs_time_"+spiname+"_"+date+".svg", 'svg')



figure()
plot(tracking_time, tracking_force, '.-', LineWidth=1.1, MarkerSize=10)
grid on
title("Time Evolution of Force (particular)", Interpreter="latex", FontSize=20)
subtitle(cnt_name(end-2:end), Interpreter="latex", FontSize=16)
xlabel("t [s]", Interpreter="latex", FontSize=14)
ylabel("F [N]", Interpreter="latex", FontSize=14)
xlim([200,225])
saveas(gcf, save_path+"\zoomed_tracking_force_vs_time_"+spiname+"_"+date+".svg", 'svg')
