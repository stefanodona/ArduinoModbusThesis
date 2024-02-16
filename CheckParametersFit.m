close all; clc; clear;

% load MisureRilassamento_GRPCNT145.mat
% spidername = "GRPCNT1454A-3";

% load MisureRilassamento_HM077x145x38.mat
% spidername = "HM077x145x38AB-2";

load MisureRilassamento_cnt077145.mat
spidername = "07714532B-1";
% folder = "STATICA_2024-01-11/Statica_07714532B-1"

coeff = retrieveFittedParameters(data, spidername, 'poly4')

% displ = 1e-3*(-11:0.25:11);
displ = 1e-3*(-11:0.25:11);
total_stiff = zeros(1, length(displ));


% close all
figure()

for ii=1:5
    subplot(2,3,ii)
    stiff(ii,:) = polyval(coeffvalues(coeff{2,ii}), displ);
    if ii==1
        k_0 = stiff(ii,:);
    end
    plot(displ*1e3, stiff(ii,:)*1e-3,LineWidth=1)

    grid on
    title("$"+coeff{1,ii}+"(x)$", Interpreter="latex", FontSize=16)
    xlabel("displacement [mm]", Interpreter="latex", FontSize=14)
    ylabel("stiffness [N/mm]", Interpreter="latex", FontSize=14)
    
    if ii==1
        ylim([0, 1e-3*1.1*max(stiff(ii,:))])
    else
        ylim([0, 1e-3*500])
    end
    

    total_stiff = total_stiff+stiff(ii,:);
end
sgtitle("Stiffness CNT"+spidername, Interpreter="latex", FontSize=20)

figure()
for ii=1:4
    subplot(2,2,ii)
    res = polyval(coeffvalues(coeff{2,ii+5}), displ);
    resistance(ii,:)=res;
    plot(displ*1e3, res*1e-3, LineWidth=1)
    grid on
    title("$"+coeff{1,ii+5}+"(x)$", Interpreter="latex", FontSize=16)
    xlabel("displacement [mm]", Interpreter="latex", FontSize=14)
    ylabel("resistance [N*s/mm]", Interpreter="latex", FontSize=14)

    ylim([0, 1e-3*2*max(res)])
end
sgtitle("Resistance CNT"+spidername, Interpreter="latex", FontSize=20)
%%

figure()
plot(displ*1e3, 1e-3*stiff(1,:)/10, LineWidth=1, DisplayName="$k_0(x)/10$")
hold on
plot(displ*1e3, 1e-3*stiff(2,:), LineWidth=1, DisplayName="$k_1(x)$")
plot(displ*1e3, 1e-3*stiff(3,:), LineWidth=1, DisplayName="$k_2(x)$")
plot(displ*1e3, 1e-3*stiff(4,:), LineWidth=1, DisplayName="$k_3(x)$")
plot(displ*1e3, 1e-3*stiff(5,:), LineWidth=1, DisplayName="$k_4(x)$")

legend(Interpreter="latex", FontSize=12)
grid on
% ylim([0, 1.1e-4*max(stiff,[],'all')])
ylim([0, 0.6])
xlabel("displacement [mm]", Interpreter="latex", FontSize=14)
ylabel("stiffness [N/mm]", Interpreter="latex", FontSize=14)
title("Stiffness components", Interpreter="latex", FontSize=20)
subtitle(spidername, Interpreter="latex", FontSize=16)

%%
% close all
figure()
plot(displ*1e3, total_stiff*1e-3, LineWidth=1.1)
hold on
plot(displ*1e3, k_0*1e-3, LineWidth=1.1)
title("$K_{ms}(x)$", Interpreter="latex", FontSize=20)
subtitle(spidername,  Interpreter="latex", FontSize=14)
xlabel("displacement [mm]", Interpreter="latex", FontSize=14)
ylabel("stiffness [N/mm]", Interpreter="latex", FontSize=14)
% ylim([0, 1.1*max([max(total_stiff),max(k_0)])])
grid on
legend(["$K_{total}$", "$K_0$"], Interpreter="latex", FontSize=12)


% [displ_1, K_ms_a1, ~] = process_static_Kms(folder, spidername, true, false);
% plot(displ_1, K_ms_a1, LineWidth=1.1)
% 
% calcolo dopo un secondo 
t_ist = 0.5;
dyn_stiff = stiff;
dyn_stiff(1,:)=[];
tau   = resistance./dyn_stiff;  


k_ist = stiff(1,:) +...
        stiff(2,:).*exp(-t_ist./(tau(1,:))) +...
        stiff(3,:).*exp(-t_ist./(tau(2,:))) +...
        stiff(4,:).*exp(-t_ist./(tau(3,:))) +...
        stiff(5,:).*exp(-t_ist./(tau(4,:))) ;
        
plot(displ*1e3, k_ist*1e-3, LineWidth=1.1, DisplayName="$K(t="+t_ist+"s)$")

spls = t_ist/0.1;
[d_trk, kms_a_trk, kms_r_trk] = Plot_Kms_from_Tracking(spidername, spls, false); 
plot(d_trk, kms_a_trk, LineWidth=1.1, DisplayName="$K(t=0."+spls+"s)_{trk}$")

% legend(["$K_{total}$", "$K_0$", "$K_{mis}$", "$K(t=1s)$"], Interpreter="latex", FontSize=12)


% %%
% close all
% folder = "STATICA_2023-12-22/Statica_07714532B-1"
% [displ_22, K_ms_a22, ~] = process_static_Kms(folder, spidername, false, false);
% folder = "STATICA_2024-01-11/Statica_07714532B-1"
% [displ_11, K_ms_a11, ~] = process_static_Kms(folder, spidername, false, false);
% folder = "STATICA_2024-01-18/Statica_07714532B-1"
% [displ_18, K_ms_a18, ~] = process_static_Kms(folder, spidername, false, false);
% 
% 
% figure();
% plot(displ_22, K_ms_a22, LineWidth=1)
% hold on
% plot(displ_11, K_ms_a11, LineWidth=1)
% plot(displ_18, K_ms_a18, LineWidth=1)
% grid on
% 
% 
% legend(["2023-12-22", "2024-01-11", "2024-01-18"])