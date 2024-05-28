close all;
clear; clc;

date = "2024-02-01";
% date = "2024-02-27";
mainfolder = "TRACKING_"+date;

% spidernames = {"HM077x145x38AA-1",...
%                "HM077x145x38AA-2",...
%                "HM077x145x38AB-1",...
%                "HM077x145x38AB-2",...
%                "GRPCNT1454A-1",...
%                "GRPCNT1454A-2",...
%                "GRPCNT1454A-3"};


if date=="2024-02-27"
    spidernames = {"07714532B-1",...
                   "07714532B-2",...
                   "07714532C-1",...
                   "07714532C-2"};
else 
    spidernames = {"HM077x145x38AA-1",...
                   "HM077x145x38AA-2",...
                   "HM077x145x38AB-1",...
                   "HM077x145x38AB-2"};
end

% save_path = "C:\Users\stefa\Desktop\Donà Stefano - Master Thesis\Images\chapter04\measures";
save_path = "C:\Users\stefa\Desktop\Donà Stefano - Master Thesis\Images\chapter04\tracking";
n_char = 3;
figure(1)
hold on
figure(2)
hold on
for ii=1:length(spidernames)
    [x_f, x_b, k_f, k_b] = Plot_Kms_from_Tracking(mainfolder, spidernames{ii}, 10, false, true, 6);
    data(ii).spiname     = char(spidernames{ii});
    data(ii).x_f         = x_f;
    data(ii).x_b         = x_b;
    data(ii).k_f         = k_f;
    data(ii).k_b         = k_b;
  
    figure(1)
    plot(x_f, k_f, DisplayName=data(ii).spiname(end-n_char:end), LineWidth=1.1)
    figure(2)
    plot(x_b, k_b, DisplayName=data(ii).spiname(end-n_char:end), LineWidth=1.1)

end
figure(1)
legend(Interpreter="latex", FontSize=12, Location="north")
ylim([0,7])
title("Stiffness Comparison", Interpreter="latex", FontSize=20)
subtitle("TRK-Forward Sequence", Interpreter="latex", FontSize=16)
xlabel("$x$ [mm]", Interpreter="latex", FontSize=14)
ylabel("$K$ [N/mm]", Interpreter="latex", FontSize=14)
grid on

figure(2)
legend(Interpreter="latex", FontSize=12, Location="north")
ylim([0,7])
title("Stiffness Comparison", Interpreter="latex", FontSize=20)
subtitle("TRK-Backward Sequence", Interpreter="latex", FontSize=16)
xlabel("$x$ [mm]", Interpreter="latex", FontSize=14)
ylabel("$K$ [N/mm]", Interpreter="latex", FontSize=14)
grid on
%%
close all
spls = [3,5,10];
spi_idx = 1; 

for ii=1:length(spls)
    [x_f, x_b, k_f, k_b] = Plot_Kms_from_Tracking(mainfolder, spidernames{spi_idx}, spls(ii), false, true, 6);
    
    lab = num2str(spls(ii)*100)+" ms";
    figure(1)
    plot(x_f, k_f, DisplayName=lab, LineWidth=1.1)
    hold on
    figure(2)
    plot(x_b, k_b, DisplayName=lab, LineWidth=1.1)
    hold on
end

figure(1)
legend(Interpreter="latex", FontSize=12, Location="north")
% ylim([0,7])
% xlim([-5,5])
title("Stiffness Comparison", Interpreter="latex", FontSize=20)
subtitle("TRK-Forward Sequence "+data(spi_idx).spiname(end-n_char:end), Interpreter="latex", FontSize=16)
xlabel("$x$ [mm]", Interpreter="latex", FontSize=14)
ylabel("$K$ [N/mm]", Interpreter="latex", FontSize=14)
grid on
% saveas(gcf, save_path+"\stiffness_evolution_forw_"+data(spi_idx).spiname(end-n_char:end)+"_"+date+".svg", 'svg')

figure(2)
legend(Interpreter="latex", FontSize=12, Location="north")
% ylim([0,7])
title("Stiffness Comparison", Interpreter="latex", FontSize=20)
subtitle("TRK-Backward Sequence "+data(spi_idx).spiname(end-n_char:end), Interpreter="latex", FontSize=16)
xlabel("$x$ [mm]", Interpreter="latex", FontSize=14)
ylabel("$K$ [N/mm]", Interpreter="latex", FontSize=14)
grid on

%% plot force vs time in TRK test
close all
Plot_Kms_from_Tracking(mainfolder, spidernames{spi_idx}, spls(ii), true, false, 6);
figure(3)
subtitle(data(spi_idx).spiname(end-n_char:end) , Interpreter="latex", FontSize=16)


hold off
Plot_Kms_from_Tracking(mainfolder, spidernames{spi_idx}, spls(ii), true, false, 6);
figure(3)
subtitle(data(spi_idx).spiname(end-n_char:end) , Interpreter="latex", FontSize=16)
title("Zoomed time evolution of force", Interpreter="latex", FontSize=20)
xlim([200,224])
% saveas(gcf, save_path+"\zoomed_tracking_force_vs_time_"+data(spi_idx).spiname(end-n_char:end)+"_"+date+".svg", 'svg')

%%


close all
figure(3)
idx = round(length(data(1).k_f)/2);
offset = data(2).k_f(idx) - data(4).k_f(idx); 
offset2 = data(2).k_f(idx) - data(3).k_f(idx); 

% offset = data(2).k_f(idx) / data(4).k_f(idx); 
% offset2 = data(2).k_f(idx) / data(3).k_f(idx); 

plot(data(1).x_f, data(1).k_f, LineWidth=1.1, DisplayName=data(1).spiname(end-n_char:end))
hold on
plot(data(2).x_f, data(2).k_f, LineWidth=1.1, DisplayName=data(2).spiname(end-n_char:end))
plot(data(3).x_f, offset2+data(3).k_f, LineWidth=1.1, DisplayName=strcat(data(3).spiname(end-n_char:end), '+offset'))
plot(data(4).x_f, offset+data(4).k_f, LineWidth=1.1, DisplayName=strcat(data(4).spiname(end-n_char:end), '+offset'))
title("Stiffness Comparison", Interpreter="latex", FontSize=20)
subtitle("Forward Sequence", Interpreter="latex", FontSize=16)
xlabel("$x$ [mm]", Interpreter="latex", FontSize=14)
ylabel("$K$ [N/mm]", Interpreter="latex", FontSize=14)
legend(Interpreter="latex", FontSize=12, Location="north")
grid on
hold off
% saveas(gcf, save_path+"\st_stiff_comparison_offset_"+date+".svg", 'svg')