close all;
clear;
clc;


load MisureRilassamento_cnt077145.mat

folder = "STATICA_2024-01-11/Statica_07714532B-1"
spidername = "07714532B-1"

[x_b1, ~, ~, coeff_b1] = simulate_Kms(folder, spidername, data, true);

close all
folder = "STATICA_2024-01-11/Statica_07714532B-2"
spidername = "07714532B-2"

[x_b2, ~, ~, coeff_b2] = simulate_Kms(folder, spidername, data, true);

close all
folder = "STATICA_2024-01-11/Statica_07714532C-1"
spidername = "07714532C-1"

[x_c1, ~, ~, coeff_c1] = simulate_Kms(folder, spidername, data, true);

close all
folder = "STATICA_2024-01-11/Statica_07714532C-2"
spidername = "07714532C-2"

[x_c2, ~, ~, coeff_c2] = simulate_Kms(folder, spidername, data, true);

close all
%%

x = -0.010 : 1e-5 : 0.010; % mm


k0_b1 = polyval(coeffvalues(coeff_b1{1}), x);
k0_b2 = polyval(coeffvalues(coeff_b2{1}), x);
k0_c1 = polyval(coeffvalues(coeff_c1{1}), x);
k0_c2 = polyval(coeffvalues(coeff_c2{1}), x);


figure('Renderer', 'painters', 'Position', [100 100 1000 650]);
plot(x, k0_b1);
grid on
hold on
plot(x, k0_b2);
plot(x, k0_c1);
plot(x, k0_c2);

legend(["CNT07714532B-1",...
    "CNT07714532B-2",...
    "CNT07714532C-1",...
    "CNT07714532C-2"])
title("$K_0$ for different spiders", Interpreter="latex", FontSize=20)
xlabel("displacement [m]", Interpreter="latex", FontSize=14)
ylabel("stiffness [N/m]", Interpreter="latex", FontSize=14)

%%

k1_b1 = polyval(coeffvalues(coeff_b1{2}), x);
k1_b2 = polyval(coeffvalues(coeff_b2{2}), x);
k1_c1 = polyval(coeffvalues(coeff_c1{2}), x);
k1_c2 = polyval(coeffvalues(coeff_c2{2}), x);


figure('Renderer', 'painters', 'Position', [100 100 1000 650]);
plot(x, k1_b1);
grid on
hold on
plot(x, k1_b2);
plot(x, k1_c1);
plot(x, k1_c2);

legend(["CNT07714532B-1",...
    "CNT07714532B-2",...
    "CNT07714532C-1",...
    "CNT07714532C-2"])

title("$K_1$ for different spiders", Interpreter="latex", FontSize=20)
xlabel("displacement [m]", Interpreter="latex", FontSize=14)
ylabel("stiffness [N/m]", Interpreter="latex", FontSize=14)


%%
close all
labels_k = {"$K_0$","$K_1$","$K_2$","$K_3$","$K_4$"};
labels_r = {"$R_1$","$R_2$","$R_3$","$R_4$"};

figure('Renderer', 'painters', 'Position', [100 100 1000 650]);
for ii=1:5
    k_ii_b1 = polyval(coeffvalues(coeff_b1{ii}), x);
    k_ii_b2 = polyval(coeffvalues(coeff_b2{ii}), x);
    k_ii_c1 = polyval(coeffvalues(coeff_c1{ii}), x);
    k_ii_c2 = polyval(coeffvalues(coeff_c2{ii}), x);


    subplot(2,3,ii)
    plot(x, k_ii_b1);
    grid on
    hold on
    plot(x, k_ii_b2);
    plot(x, k_ii_c1);
    plot(x, k_ii_c2);
    title(strcat(labels_k{ii}," for different spiders"), Interpreter="latex", FontSize=20)
    xlabel("displacement [m]", Interpreter="latex", FontSize=14)
    ylabel("stiffness [N/m]", Interpreter="latex", FontSize=14)
    legend(["CNT07714532B-1",...
            "CNT07714532B-2",...
            "CNT07714532C-1",...
            "CNT07714532C-2"], ...
            Interpreter="latex")
    ylim([0, inf])
end

figure('Renderer', 'painters', 'Position', [100 100 1000 650]);
for ii=1:4
    k_ii_b1 = polyval(coeffvalues(coeff_b1{ii+5}), x);
    k_ii_b2 = polyval(coeffvalues(coeff_b2{ii+5}), x);
    k_ii_c1 = polyval(coeffvalues(coeff_c1{ii+5}), x);
    k_ii_c2 = polyval(coeffvalues(coeff_c2{ii+5}), x);


    subplot(2,2,ii)
    plot(x, k_ii_b1);
    grid on
    hold on
    plot(x, k_ii_b2);
    plot(x, k_ii_c1);
    plot(x, k_ii_c2);
    title(strcat(labels_r{ii}," for different spiders"), Interpreter="latex", FontSize=20)
    xlabel("displacement [m]", Interpreter="latex", FontSize=14)
    ylabel("resistance [N*s/m]", Interpreter="latex", FontSize=14)
    legend(["CNT07714532B-1",...
            "CNT07714532B-2",...
            "CNT07714532C-1",...
            "CNT07714532C-2"], ...
            Interpreter="latex")
    ylim([0, inf])
end





