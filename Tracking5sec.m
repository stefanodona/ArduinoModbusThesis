close all;
clear; clc;

% date = "2024-02-01";
date = "2024-02-27";
mainfolder = "TRACKING_"+date;

if date=="2024-02-27"
    spidernames = {"07714532B-1",...
                   "07714532B-2",...
                   "07714532C-1",...
                   "07714532C-2"};
    n_char = 2;

elseif date=="2024-02-01"
    spidernames = {"HM077x145x38AA-1",...
                   "HM077x145x38AA-2",...
                   "HM077x145x38AB-1",...
                   "HM077x145x38AB-2",...
                   "GRPCNT1454A-1",...
                   "GRPCNT1454A-2",...
                   "GRPCNT1454A-3"};
    n_char = 3;
end


% spidernames = {"HM077x145x38AA-1",...
%                "HM077x145x38AA-2",...
%                "HM077x145x38AB-1",...
%                "HM077x145x38AB-2"};

% mainfolder = "TRACKING_2024-02-27"

% save_path = "C:\Users\stefa\Desktop\Donà Stefano - Master Thesis\Images\chapter04\tracking";


figure(1)
hold on
figure(2)
hold on
for ii=1:length(spidernames)
% for ii=1
    [x_f, x_b, k_f, k_b] = Plot_Kms_from_Tracking(mainfolder, spidernames{ii}, 1, false, true, 6);
    spiname     = char(spidernames{ii});
    data(ii).spiname     = spiname(end-n_char:end);
    data(ii).x_f         = x_f;
    data(ii).x_b         = x_b;
    data(ii).k_f         = k_f;
    data(ii).k_b         = k_b;

end


spls = [3, 5, 10];
% spls = [3,5,10];
for jj=1:length(spidernames)
close all
spi_idx = jj;
save_path = "C:\Users\stefa\Desktop\Donà Stefano - Master Thesis\Images\appendix\"+data(spi_idx).spiname;

kmss = zeros(length(spls), length(data(ii).k_f));

for ii=1:length(spls)
    [x_f, x_b, k_f, k_b] = Plot_Kms_from_Tracking(mainfolder, spidernames{spi_idx}, spls(ii), false, true, 6);
    
    lab = "t="+num2str(spls(ii)/10)+" s";
    
    kmss(ii,:) = k_f;
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
ylim([floor(min(k_f)) ceil(max(k_f))])
% xlim([-5,5])
title("Stiffness time evolution", Interpreter="latex", FontSize=20)
subtitle("TRK-Forward Sequence "+data(spi_idx).spiname, Interpreter="latex", FontSize=16)
xlabel("$x$ [mm]", Interpreter="latex", FontSize=14)
ylabel("$K$ [N/mm]", Interpreter="latex", FontSize=14)
grid on
saveas(gcf, save_path+"\stiffness_evolution_forw_"+data(spi_idx).spiname+"_"+date+".svg", 'svg')

figure(2)
legend(Interpreter="latex", FontSize=12, Location="north")
% ylim([0,7])
ylim([floor(min(k_b)) ceil(max(k_b))])
title("Stiffness Comparison", Interpreter="latex", FontSize=20)
subtitle("TRK-Backward Sequence "+data(spi_idx).spiname, Interpreter="latex", FontSize=16)
xlabel("$x$ [mm]", Interpreter="latex", FontSize=14)
ylabel("$K$ [N/mm]", Interpreter="latex", FontSize=14)
grid on
saveas(gcf, save_path+"\stiffness_evolution_back_"+data(spi_idx).spiname+"_"+date+".svg", 'svg')
end

%%
% close 
% loss=(kmss(1,:)-kmss(4,:))./kmss(1,:);
% figure()
% plot(loss*100)