close all;
clear;
clc;


load MisureRilassamento_cnt077145.mat

folder = "STATICA_2024-01-11/Statica_07714532C-2"
spidername = "07714532C-2"

[displ, K_ms] = simulate_Kms(folder, spidername, data)


[displ_1, K_ms_1] = process_static_Kms(folder, spidername)

%%
close all;

figure('Renderer', 'painters', 'Position', [100 100 1000 600]);
plot(displ, K_ms,'o')
hold on
plot(displ_1/1000, K_ms_1*1000, LineWidth=1)
hold off
grid on
xlabel("displ [m]",Interpreter="latex", FontSize=14)
ylabel("stiffness [N/m]",Interpreter="latex", FontSize=14)
title("Stiffness", Interpreter="latex", FontSize=20)
subtitle(strcat("CNT",spidername), Interpreter="latex")
legend(["Simulated","Measured"], Interpreter="latex", FontSize=12, Location="northwest")
