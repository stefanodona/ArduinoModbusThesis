close all;
clear;
clc;


load MisureRilassamento_cnt077145.mat

folder = "STATICA_10mm/Statica_07714532B-1"
spidername = "07714532B-1"

[displ, K_ms_a, K_ms_r, coeff] = simulate_Kms(folder, spidername, data, true);

%%
close all

figure('Renderer', 'painters', 'Position', [100 100 1000 650]);
plot(displ, K_ms_a, LineWidth=1)
hold on
plot(displ, K_ms_r, LineWidth=1)
grid on
legend(["Forward", "Backward"], Interpreter="latex", FontSize=12)

xlabel("displacement [mm]", Interpreter="latex", FontSize=14)
ylabel("Stiffness [N/mm]", Interpreter="latex", FontSize=14)
subtitle(strcat("CNT", spidername), Interpreter="latex")
title("Stiffness simulation", Interpreter="latex", FontSize=20)


%%
close all
for ii=1:length(coeff)
    c(ii, :) = coeffvalues(coeff{ii});
end

% for ii=1:5
%     c(ii, :) = 1./c(ii,:);
% end

x = -0.015:0.0001:0.015;
labels = {"c_0",
    "c_1",
    "c_2",
    "c_3",
    "c_4",
    "r_1",
    "r_2",
    "r_3",
    "r_4"}
for ii=1:length(coeff)
    c_i = polyval(c(ii,:), x);
%     if ii<=5
%         c_i=1./c_i;
%     end
    figure()
    plot(x, c_i)
    title(labels{ii})
end
