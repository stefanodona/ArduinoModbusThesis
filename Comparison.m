close all; clear; clc;

load MisureRilassamento_cnt077145.mat;
comsol = load("Kms_CNT07714532A_sim_100MPa.txt");

kms_comsol = comsol(:,2);
x_comsol = comsol(:,1);

% 1 = B-1
% 2 = B-2
% 3 = C-1
% 4 = C-2
jj=1; % select spider


c0=[];c1=[];c2=[];c3=[];c4=[];
      r1=[];r2=[];r3=[];r4=[];
displ = [];
for ii=1:length(data(jj).cnt)
    if abs(data(jj).cnt(ii).params.model_coeff(1).value)==1e-3
        continue
    end
    displ = [displ, data(jj).cnt(ii).params.model_coeff(1).value];
    c0 = [c0, data(jj).cnt(ii).params.model_coeff(2).value];
    c1 = [c1, data(jj).cnt(ii).params.model_coeff(3).value];
    c2 = [c2, data(jj).cnt(ii).params.model_coeff(4).value];
    c3 = [c3, data(jj).cnt(ii).params.model_coeff(5).value];
    c4 = [c4, data(jj).cnt(ii).params.model_coeff(6).value];

    r1 = [r1, data(jj).cnt(ii).params.model_coeff(7).value];
    r2 = [r2, data(jj).cnt(ii).params.model_coeff(8).value];
    r3 = [r3, data(jj).cnt(ii).params.model_coeff(9).value];
    r4 = [r4, data(jj).cnt(ii).params.model_coeff(10).value];
end

k0=1./c0;
folder = "STATICA_2024-01-18/Statica_07714532B-1"
spidername = "07714532B-1"

[displ_1, K_ms_a, K_ms_r] = process_static_Kms(folder, spidername);

kms1_com = kms_comsol(x_comsol==-0.5);
kms2_com = kms_comsol(x_comsol==0.5);

if contains(spidername, "B")
    b=2;
else 
    b=1.176;
end

a = b/mean([kms1_com,kms2_com]);

k0_c = 1./0.52829;      % [N/mm]
k1_c = -0.048785;
k2_c = 0.026573;
k3_c = -0.00024292;
k4_c = 3.9698e-5;

x_klip = -11:0.1:11; %[mm]
k_klippel = polyval([k4_c k3_c k2_c k1_c k0_c], x_klip);

figure('Renderer', 'painters', 'Position', [100 100 1000 650]);
plot(x_comsol/1000, a*comsol(:,2)*1e3, LineWidth=1) % kms comsol
hold on
plot(displ, k0, LineWidth=1)                    % k0 creep
plot(displ_1/1000, K_ms_a*1000, LineWidth=1)    % kms statica
plot(x_klip/1000, k_klippel*1000, LineWidth=1)        % kms klippel
grid on
xlim([-0.011, 0.011])
ylim([0, 10000])
xlabel("displacement [m]", Interpreter="latex", FontSize=14)
ylabel("Stiffness [N/m]", Interpreter="latex", FontSize=14)
title("Stiffness comparation", Interpreter="latex", FontSize=20);
legend(["COMSOL", "$K_0$ creep", "$K_{ms}$ static", "$K_{ms} klippel$"], Interpreter="latex", FontSize=12, Location="northwest")
subtitle(strcat("CNT", spidername), Interpreter="latex")

%%

% h = 1.1;

close all
figure('Renderer', 'painters', 'Position', [100 100 1000 650]);
plot(displ, k0, LineWidth=1)                    % k0 creep
hold on
plot(displ_1/1000, K_ms_a*1000, LineWidth=1)    % kms statica
plot(displ_1/1000, K_ms_r*1000, LineWidth=1)    % kms statica
plot(x_klip/1000, flip(k_klippel)*1000, LineWidth=1)        % kms klippel
plot(x_comsol/1000, a*comsol(:,2)*1e3, LineWidth=1) % kms comsol
grid on
xlim([-0.015, 0.015])
ylim([0, 10000])
xlabel("displacement [m]", Interpreter="latex", FontSize=14)
ylabel("Stiffness [N/m]", Interpreter="latex", FontSize=14)
title("Stiffness comparison", Interpreter="latex", FontSize=20);
legend(["$K_0$ creep", "$K_{ms}$ static forward","$K_{ms}$ static backward", "$K_{ms}$ klippel", "COMSOL"], Interpreter="latex", FontSize=12, Location="northwest")
subtitle(strcat("CNT", spidername), Interpreter="latex")
