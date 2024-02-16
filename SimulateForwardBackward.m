close all;
clear;
clc;


load MisureRilassamento_cnt077145.mat

folder = "STATICA_10mm/Statica_07714532B-1"
spidername = "07714532B-1"

[displ, K_ms_a, K_ms_r, coeff] = simulate_Kms(folder, spidername, data, true);
[displ_1, K_ms_a1, K_ms_r1] = process_static_Kms(folder, spidername, false);

%%
close all

figure('Renderer', 'painters', 'Position', [100 100 1000 650]);
plot(displ, K_ms_a, LineWidth=1)
hold on
plot(displ, K_ms_r, LineWidth=1)
% plot(displ_1*1e-3, K_ms_a1*1e3, LineWidth=1)
% plot(displ_1*1e-3, K_ms_r1*1e3, LineWidth=1)
grid on
% legend(["Forward Sim", "Backward Sim", "Forward Mis", "Backward Mis"], Interpreter="latex", FontSize=12)
legend(["Forward Sim", "Backward Sim"], Interpreter="latex", FontSize=12)

xlabel("displacement [mm]", Interpreter="latex", FontSize=14)
ylabel("Stiffness [N/mm]", Interpreter="latex", FontSize=14)
subtitle(strcat("CNT", spidername), Interpreter="latex")
title("Stiffness simulation", Interpreter="latex", FontSize=20)


%%
% close all
for ii=1:length(coeff)
    c(ii, :) = coeffvalues(coeff{ii});
end

% for ii=1:5
%     c(ii, :) = 1./c(ii,:);
% end

% x = -0.015:0.0001:0.015;
% labels = {"c_0",
%     "c_1",
%     "c_2",
%     "c_3",
%     "c_4",
%     "r_1",
%     "r_2",
%     "r_3",
%     "r_4"}
% for ii=1:length(coeff)
%     c_i = polyval(c(ii,:), x);
% %     if ii<=5
% %         c_i=1./c_i;
% %     end
%     figure()
%     plot(x, c_i)
%     title(labels{ii})
% end

k0 = c(1,:);
k1 = c(2,:);
k2 = c(3,:);
k3 = c(4,:);
k4 = c(5,:);

r1 = c(6,:);
r2 = c(7,:);
r3 = c(8,:);
r4 = c(9,:);

%%
x = displ;
[x_sort, iii] = sort(abs(x), 'descend');
iii=flip(iii);
x_sort = x(iii)';
x_sort = [x_sort,flip(-x_sort)];


folder = "STATICA_10mm/Statica_07714532B-1"
spidername = "07714532B-1"
times_file = strcat(folder, "/times.txt");
FID = fopen(times_file);
times = textscan(FID, '%f%f%f%f%f%f%f%f', CommentStyle='#');
fclose(FID);

x_prova = [];
for ii=1:2:length(x_sort)
    x_prova = [x_prova, x_sort(ii), x_sort(ii+1), 0];
end

t_x_rise = [0; times{3}/1000];
t_x_fall = [0; times{5}/1000];

t_seq=t_x_fall-t_x_rise;

%%
save("07714532B-1_polycoeff.mat",...
    "k0",...
    "k1",...
    "k2",...
    "k3",...
    "k4",...
    "r1",...
    "r2",...
    "r3",...
    "r4");
