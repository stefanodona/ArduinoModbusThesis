close all; clear; clc;

date        = "2023-12-22";
% date        = "2024-03-11";

if date == "2023-12-22"
    spidernames = {"07714532B-1",...
                   "07714532B-2",...
                   "07714532C-1",...
                   "07714532C-2"};
    n_char      = 2;
elseif date=="2024-03-11"
    spidernames = {"HM077x145x38AA-1",...
                   "HM077x145x38AA-2",...
                   "HM077x145x38AB-1",...
                   "HM077x145x38AB-2",...
                   "GRPCNT1454A-1",...
                   "GRPCNT1454A-2",...
                   "GRPCNT1454A-3"};
    n_char      = 3;
end


% for ii=1:length(spidernames)
for ii=1
spidername  = spidernames{ii};
% date        = "2024-01-18"; 
folder      = "STATICA_"+date;
spiname     = char(spidername);
spiname     = spiname(end-n_char:end);

save_path = "C:\Users\stefa\Desktop\Donà Stefano - Master Thesis\Images\appendix\"+spiname;

%%
file_folder = "Statica_"+spidername;
file_name   = file_folder+".txt";
file_path   = fullfile(folder, file_folder, file_name);

FID = fopen(file_path);
datacell = textscan(FID, '%f%f%f%f%f%f%f%f', CommentStyle='#');
fclose(FID);

x_forw = -datacell{1};
f_forw = -datacell{3};
x_back = -datacell{5};
f_back = -datacell{7};

fit_force_obj_forw = fit(x_forw, f_forw, 'poly5');
fit_coeff_forw = coeffvalues(fit_force_obj_forw)
fit_coeff_forw(end)

f_forw_dc = interp1(x_forw, f_forw, 0);
f_back_dc = interp1(x_back, f_back, 0);

% f_forw = f_forw-f_forw_dc;
% f_back = f_back-f_back_dc;


delta_f     = 0.16; % [N]
delta_x     = 0.02; % [mm]

delta_k_rel_forw = sqrt((delta_f./f_forw).^2+(delta_x./x_forw).^2);
delta_k_rel_back = sqrt((delta_f./f_back).^2+(delta_x./x_back).^2);
delta_k_abs_forw = delta_k_rel_forw.*(-f_forw./x_forw);
delta_k_abs_back = delta_k_rel_back.*(-f_back./x_back);

figure()
plot(x_forw, -f_forw./x_forw, LineWidth=1.1, DisplayName="Forw Acquisition");
hold on
plot(x_back, -f_back./x_back, LineWidth=1.1, DisplayName="Back Acquisition");
grid on
title("Acquired Stiffness", Interpreter="latex", FontSize=20)
subtitle(spiname, Interpreter="latex", FontSize=16)
xlabel("$x$ [mm]", Interpreter="latex", FontSize=14)
ylabel("$K$ [N/mm]", Interpreter="latex", FontSize=14)
legend(Interpreter="latex", FontSize=12, Location="north")
ylim([0,7])
% ylim([0,5])
% plot(-x_klip, k_klip, DisplayName="Klippel")
saveas(gcf, save_path+"\st_stiff_"+date+"_"+spiname+".svg", 'svg')

%%
kms_inc_forw = gradient(-f_forw, x_forw);
kms_inc_back = gradient(-f_back, x_back);

poly_deg = 6;

poly6 = 'k6*x^6 + k5*x^5 + k4*x^4 + k3*x^3 + k2*x^2 + k1*x + k0';
poly4 = 'k4*x^4 + k3*x^3 + k2*x^2 + k1*x   + k0';
poly3 = 'k3*x^3 + k2*x^2 + k1*x   + k0';
poly2 = 'k2*x^2 + k1*x   + k0';

if poly_deg ==2
    poly = poly2;
elseif poly_deg == 3
    poly = poly3;
elseif poly_deg == 4
    poly = poly4;
elseif poly_deg == 6
    poly = poly6;
end

% fit_obj_forw = fit(x_forw, gradient(-f_forw, x_forw), poly4,...
%     'Weights', 1./abs(delta_k_abs_forw),...
%     'Algorithm', 'Levenberg-Marquardt')
% fit_obj_back = fit(x_back, gradient(-f_back, x_back), poly4,...
%     'Weights', 1./abs(delta_k_abs_back),...
%     'Algorithm', 'Levenberg-Marquardt')

fit_obj_forw = fit(x_forw, gradient(-f_forw, x_forw), poly,...
    'Algorithm', 'Levenberg-Marquardt')
fit_obj_back = fit(x_back, gradient(-f_back, x_back), poly,...
    'Algorithm', 'Levenberg-Marquardt')

kms_inc_forw_coeff = flip(coeffvalues(fit_obj_forw));
kms_inc_back_coeff = flip(coeffvalues(fit_obj_back));

kms_forw_coeff = kms_inc_forw_coeff./flip(1:poly_deg+1)
kms_back_coeff = kms_inc_back_coeff./flip(1:poly_deg+1)

% kms_forw_fit = polyval(kms_inc_forw_coeff, x_forw);
kms_forw_fit = polyval(kms_forw_coeff, x_forw);
kms_back_fit = polyval(kms_back_coeff, x_back);

k0_c = 1./0.52829;      % [N/mm]
k1_c = -0.048785;
k2_c = 0.026573;
k3_c = -0.00024292;
k4_c = 3.9698e-5;

x_klip = -11:0.1:11; %[mm]
k_klip = polyval([k4_c k3_c k2_c k1_c k0_c], x_klip);

figure()
plot(x_forw, kms_forw_fit, LineWidth=1.1, DisplayName="Forw Integration");
hold on
grid on
% plot(x_forw, (-f_forw./x_forw).*(1+delta_k_rel_forw), 'k--',LineWidth=1.1, DisplayName="Forw Error Band");
% plot(x_forw, (-f_forw./x_forw).*(1-delta_k_rel_forw), 'k--',LineWidth=1.1, HandleVisibility="off");
plot(x_back, kms_back_fit, LineWidth=1.1, DisplayName="Back Integration");
% plot(x_back, (-f_back./x_back).*(1+delta_k_rel_back), 'k--',LineWidth=1.1, DisplayName="Forw Error Band");
% plot(x_back, (-f_back./x_back).*(1-delta_k_rel_back), 'k--',LineWidth=1.1, HandleVisibility="off");
% plot(x_klip, k_klip)
title("Fitted Stiffness", Interpreter="latex", FontSize=20)
subtitle(spiname, Interpreter="latex", FontSize=16)
xlabel("$x$ [mm]", Interpreter="latex", FontSize=14)
ylabel("$K$ [N/mm]", Interpreter="latex", FontSize=14)
legend(Interpreter="latex", FontSize=12, Location="north")
ylim([0,7])
% ylim([0,5])
% plot(-x_klip, k_klip, DisplayName="Klippel")
% saveas(gcf, save_path+"\st_stiff_"+date+"_"+spiname(end-2:end)+".svg", 'svg')
saveas(gcf, save_path+"\st_fit_stiff_"+date+"_"+spiname+".svg", 'svg')

figure()
plot(x_forw, f_forw, LineWidth=1.1, DisplayName="Forw Acquisition");
hold on
plot(x_back, f_back, LineWidth=1.1, DisplayName="Back Acquisition");
grid on
title("Force", Interpreter="latex", FontSize=20)
subtitle(spiname, Interpreter="latex", FontSize=16)
xlabel("$x$ [mm]", Interpreter="latex", FontSize=14)
ylabel("$F$ [N]", Interpreter="latex", FontSize=14)
legend(Interpreter="latex", FontSize=12, Location="north")
if spiname(end-2)=='C'
    ylim([-50,50])
else
    ylim([-80,80])
end
saveas(gcf, save_path+"\st_force_"+date+"_"+spiname+".svg", 'svg')
end


% figure(3)
% subplot 121
% plot(x_forw, kms_inc_forw, '.', LineWidth=1.1, DisplayName="Forw Inc")
% hold on
% plot(x_forw, polyval(kms_inc_forw_coeff, x_forw), LineWidth=1.1, DisplayName="Forw Fit")
% grid on
% xlabel("displ [mm]", Interpreter="latex", FontSize=14)
% ylabel("stiffness [N/mm]", Interpreter="latex", FontSize=14)
% legend(Interpreter="latex", FontSize=12)
% ylim([0,18])
% 
% subplot 122
% plot(x_back, kms_inc_back, '.', LineWidth=1.1, DisplayName="Back")
% hold on
% plot(x_back, polyval(kms_inc_back_coeff, x_back), LineWidth=1.1, DisplayName="Back Fit")
% grid on
% % title("Incremental Stiffness", Interpreter="latex", FontSize=20)
% % subtitle(spiname(end-2:end), Interpreter="latex", FontSize=16)
% xlabel("displ [mm]", Interpreter="latex", FontSize=14)
% ylabel("stiffness [N/mm]", Interpreter="latex", FontSize=14)
% legend(Interpreter="latex", FontSize=12)
% ylim([0,18])

% figure(1)
%%
% 0.067 N
% figure(3)
% plot(x_back, f_back)
% grid on

% f_dc           = interp1(x_back, f_back, 0);
% f_back_falsa   = -kms_back_fit.*x_back + f_back_dc;
% kms_back_falsa = -f_back_falsa./x_back;
% 
% f_forw_falsa   = -kms_forw_fit.*x_forw + f_forw_dc;
% kms_forw_falsa = -f_forw_falsa./x_forw;
% 
% % close all
% figure('Renderer', 'painters', 'Position', [100 100 800 500]);
% plot(x_back, -f_back./x_back, DisplayName="Back Acquired", LineWidth=1.1);
% hold on
% plot(x_back, kms_back_falsa, DisplayName="Back Faked", LineWidth=1.1);
% plot(x_back, (-f_back./x_back).*(1+delta_k_rel_back), 'k--', DisplayName="Error Band");
% plot(x_back, (-f_back./x_back).*(1-delta_k_rel_back), 'k--', HandleVisibility='off');
% grid on
% title("Stiffness Comparison", Interpreter="latex", FontSize=20)
% subtitle(spiname(end-2:end), Interpreter="latex", FontSize=16)
% xlabel("$x$ [mm]", Interpreter="latex", FontSize=14)
% ylabel("$K$ [N/mm]", Interpreter="latex", FontSize=14)
% legend(Interpreter="latex", FontSize=12, Location="north")
% % xlim([-11,11])
% ylim([0,6.5])
% % saveas(gcf, save_path+"\st_back_faked_"+date+"_"+spiname(end-2:end)+".svg", 'svg')
% 
% 
% figure('Renderer', 'painters', 'Position', [100 100 800 500]);
% plot(x_forw, -f_forw./x_forw, DisplayName="Forw Acquired", LineWidth=1.1);
% hold on
% plot(x_forw, kms_forw_falsa, DisplayName="Forw Faked", LineWidth=1.1);
% plot(x_forw, (-f_forw./x_forw).*(1+delta_k_rel_forw), 'k--', DisplayName="Error Band");
% plot(x_forw, (-f_forw./x_forw).*(1-delta_k_rel_forw), 'k--', HandleVisibility='off');
% grid on
% title("Stiffness Comparison", Interpreter="latex", FontSize=20)
% subtitle(spiname(end-2:end), Interpreter="latex", FontSize=16)
% xlabel("$x$ [mm]", Interpreter="latex", FontSize=14)
% ylabel("$K$ [N/mm]", Interpreter="latex", FontSize=14)
% legend(Interpreter="latex", FontSize=12, Location="north")
% ylim([0,6.5])
% saveas(gcf, save_path+"\st_forw_faked_"+date+"_"+spiname(end-2:end)+".svg", 'svg')

%%

% kms_forw_fit2 = polyval(polyfit(x_forw, -f_forw./x_forw, poly_deg), x_forw);
% kms_back_fit2 = polyval(polyfit(x_back, -f_back./x_back, poly_deg), x_back);
% 
% figure(5)
% 
% subplot 121
% plot(x_forw, -(f_forw-f_forw_dc)./x_forw, DisplayName="acquisita");
% hold on
% grid on
% plot(x_forw, kms_forw_fit2, DisplayName="fit")
% % plot(x_forw, kms_forw_fit2.*(1+delta_k_rel), 'k--', DisplayName="fit+err")
% % plot(x_forw, kms_forw_fit2.*(1-delta_k_rel), 'k-.', DisplayName="fit-err")
% legend
% title("Forward")
% ylim([0,6])
% 
% subplot 122
% plot(x_back, -(f_back-f_back_dc)./x_back, DisplayName="acquisita");
% hold on
% grid on
% errorbar(x_back, kms_back_fit2, kms_back_fit2.*delta_k_rel,'vertical')
% % plot(x_back, kms_back_fit2, DisplayName="fit")
% % plot(x_back, kms_back_fit2.*(1+delta_k_rel), 'k--', DisplayName="fit+err")
% % plot(x_back, kms_back_fit2.*(1-delta_k_rel), 'k-.', DisplayName="fit-err")
% legend
% title("Backward")
% ylim([0,6])
% %% IDEA
% % l'idea fare un fit polinomiale del quarto ordine  ma usando come pesi
% % l'inverso della incertezza relativa sulla K, così facendo i punti più
% % distanti dall'asse y peseranno di più, essendo "più certi" di quelli
% % vicino allo 0.
% poly4 = 'k4*x^4+k3*x^3+k2*x^2+k1*x+k0';
% 
% % k_forw_noDC = -(f_forw-f_forw_dc)./x_forw;
% k_forw_noDC = -f_forw./x_forw;
% 
% k_fit_obj_forw = fit(x_forw, k_forw_noDC, poly4, 'Weights', 1-delta_k_rel)
% 
% figure()
% plot(k_fit_obj_forw, x_forw, k_forw_noDC)
% hold on
% 
% % k_back_noDC = -(f_back-f_back_dc)./x_back;
% k_back_noDC = -f_back./x_back;
% 
% k_fit_obj_back = fit(x_back, k_back_noDC, poly4, 'Weights', 1-delta_k_rel)
% 
% plot(k_fit_obj_back, x_back, k_back_noDC)

% 
% %% PROVIAMO A FITTARE LA FORZA
% poly5 = 'f5*x^5+f4*x^4+f3*x^3+f2*x^2+f1*x+f0';
% f_fit_obj = fit(x_forw, f_forw, poly5, 'Weights', 1-delta_k_rel)
% f_coeff = coeffvalues(f_fit_obj)
% 
% 
% f_fit = polyval(flip(f_coeff),x_forw);
% 
% figure()
% plot(x_forw, -(f_fit-f_coeff(1))./x_forw)
% hold on
% plot(k_fit_obj_forw, x_forw, k_forw_noDC)

