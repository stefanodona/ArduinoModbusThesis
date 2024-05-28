close all; clear; clc;
clear; clc;

save_path = "C:\Users\stefa\Desktop\Donà Stefano - Master Thesis\Images\chapter04";

folder      = "Prove_Preliminari";
spidername  = "07714532B";

% diventano 5 colonne da prova 52
% diventano 8 colonne da prova 61
% da prova 51 a 68 comprese si esamina il 32C
n_prova     = 17
n_col       = 3;
char        ='%f';

file_folder = dir(folder+"/Prova"+num2str(n_prova)+"_*").name
file_name   = file_folder+".txt";
file_path   = fullfile(folder, file_folder, file_name);

FID = fopen(file_path);
datacell = textscan(FID, repmat(char,1,n_col), CommentStyle='#');
fclose(FID);

if n_col==3
    x_forw = datacell{1}
    f_forw = -datacell{2};
    f_back = datacell{3};
elseif n_col==5
    x_forw = datacell{1}
    f_forw = -datacell{3};
    x_back = datacell{5}
    f_back = -datacell{n_col-1};
elseif n_col==8
    x_forw = datacell{1}
    f_forw = -datacell{3};
    x_back = datacell{5}
    f_back = -datacell{n_col-1};
end

poly5 = 'f5*x^5+f4*x^4+f3*x^3+f2*x^2+f1*x+f0';
f_fit = fit(x_forw, f_forw, poly5, ...
    'Algorithm', 'Levenberg-Marquardt')
f_dc = interp1(x_forw, f_forw, 0);
% f_dc = 

delta_f     = 0.16; % [N]
delta_x     = 0.02; % [mm]

delta_k_rel = sqrt((delta_f./f_forw).^2+(delta_x./x_forw).^2);
delta_k_abs = delta_k_rel.*(-f_forw./x_forw);
poly_deg = 2;
k_fit = polyval(polyfit(x_forw, (f_forw-f_dc)./x_forw, poly_deg), x_forw);

figure(1)
plot(x_forw, f_forw, DisplayName='acquired forw', LineWidth=1.1)
grid on
% legend(Interpreter="latex")
title("Force Curve", Interpreter="latex", FontSize=20)
subtitle("B model", Interpreter="latex", FontSize=16)
xlabel("$x$ [mm]", Interpreter="latex", FontSize=14)
ylabel("$F$ [N]", Interpreter="latex", FontSize=14)
% saveas(gcf, save_path+"\st_force_test"+num2str(n_prova)+".svg", 'svg')

figure(2)
plot(x_forw, -(f_forw)./x_forw, DisplayName='Acquired', LineWidth=1.1)
hold on
% plot(x_back, (f_back)./x_back, DisplayName='acquired forw')
grid on
plot(x_forw, -(f_forw-f_dc)./x_forw, DisplayName='No DC-force', LineWidth=1.1)
% plot(x_forw, smooth(-(f_forw-f_dc)./x_forw,20,'lowess'), LineWidth=1.1)
% plot(x_forw, k_fit)
% plot(x_forw, k_fit.*(1+delta_k_rel), 'k--')
% plot(x_forw, k_fit.*(1-delta_k_rel), 'k-.')
legend(Interpreter="latex", FontSize=12)
% title("Prova "+num2str(n_prova))
title("Adjusted Stiffness Curve", Interpreter="latex", FontSize=20)
subtitle("B model", Interpreter="latex", FontSize=16)
xlabel("$x$ [mm]", Interpreter="latex", FontSize=14)
ylabel("$K$ [N/mm]", Interpreter="latex", FontSize=14)
% saveas(gcf, save_path+"\st_stiff_test"+num2str(n_prova)+".svg", 'svg')
% saveas(gcf, save_path+"\st_stiff_post_test"+num2str(n_prova)+".svg", 'svg')
    


f_integral = cumtrapz(x_forw, gradient(f_forw-f_dc,x_forw));
f_dc_integral = interp1(x_forw, f_integral, 0);
f_integral = f_integral-f_dc_integral;
if n_col>3 
    f_integral_b = cumtrapz(x_back, gradient(f_back,x_back));
    f_dc_integral_b = interp1(x_back, f_integral_b, 0);
    f_integral_b = f_integral_b-f_dc_integral_b;
else
    f_integral_b = cumtrapz(x_forw, gradient(f_back,x_forw));
    f_dc_integral_b = interp1(x_forw, f_integral_b, 0);
    f_integral_b = f_integral_b-f_dc_integral_b;
end

figure(3)
plot(x_forw, gradient(-f_forw, x_forw), DisplayName=num2str(n_prova), LineWidth=1.1)
grid on
hold on
title("Incremental Stiffness Curve", Interpreter="latex", FontSize=20)
subtitle("B model", Interpreter="latex", FontSize=16)
xlabel("$x$ [mm]", Interpreter="latex", FontSize=14)
ylabel("$K_{inc}$ [N/mm]", Interpreter="latex", FontSize=14)
% saveas(gcf, save_path+"\st_inc_stiff_test"+num2str(n_prova)+".svg", 'svg')
% plot(x_forw, smooth(gradient(-f_forw, x_forw),20,'lowess'), LineWidth=1.1)
% legend
%%
close all

poly4 = 'k4*x^4 + k3*x^3 + k2*x^2 + k1*x + k0';
poly3 = 'k3*x^3 + k2*x^2 + k1*x + k0';
poly2 = 'k2*x^2 + k1*x + k0';
[fit_obj4, ~, out4] = fit(x_forw, gradient(-f_forw, x_forw), poly4,...
    'Weights', 1./delta_k_abs,...
    'Algorithm', 'Levenberg-Marquardt')
[fit_obj3, ~, out3] = fit(x_forw, gradient(-f_forw, x_forw), poly3,...
    'Weights', 1./delta_k_abs,...
    'Algorithm', 'Levenberg-Marquardt')
[fit_obj2, ~, out2] = fit(x_forw, gradient(-f_forw, x_forw), poly2,...
    'Weights', 1./delta_k_abs,...
    'Algorithm', 'Levenberg-Marquardt')

figure(4)
h = gobjects(3,1)
h(1) = plot(x_forw, polyval(flip(coeffvalues(fit_obj2)), x_forw), DisplayName="$2^{nd}$ order fit", LineWidth=1.1)
hold on
h(3) = plot(x_forw, polyval(flip(coeffvalues(fit_obj4)), x_forw), 'b', DisplayName="$4^{nd}$ order")
h(2) = plot(x_forw, gradient(-f_forw, x_forw), '*', DisplayName="Acquired")
grid on
legend(h([2,1]),Interpreter="latex", FontSize=12)
title("Incremental Stiffness Curve Fit", Interpreter="latex", FontSize=20)
subtitle("B model", Interpreter="latex", FontSize=16)
xlabel("$x$ [mm]", Interpreter="latex", FontSize=14)
ylabel("$K_{inc}$ [N/mm]", Interpreter="latex", FontSize=14)
% saveas(gcf, save_path+"\st_inc_stiff_fit_test"+num2str(n_prova)+".svg", 'svg')


% k_integral = polyval(flip(coeffvalues(fit_obj2)./(1:3)), x_forw);
k_integral = polyval(flip(coeffvalues(fit_obj4)./(1:5)), x_forw);
delta_k_abs_int = k_integral.*delta_k_rel;

figure('Renderer', 'painters', 'Position', [100 100 800 500]);
% figure(6)
plot(x_forw, -f_forw./x_forw, LineWidth=1, DisplayName="Acquired")
hold on
plot(x_forw, k_integral, DisplayName="Integration of Incremental", LineWidth=1.1)
plot(x_forw, -f_forw./x_forw+delta_k_abs, 'k--', LineWidth=0.5, DisplayName="Uncertainty Band")
plot(x_forw, -f_forw./x_forw-delta_k_abs, 'k--', LineWidth=0.5, HandleVisibility='off')
% plot(x_forw, k_integral.*(1+delta_k_rel), 'k--', LineWidth=0.5, DisplayName="Uncertainty Band")
% plot(x_forw, k_integral.*(1-delta_k_rel), 'k--', LineWidth=0.5, HandleVisibility='off')
grid on
legend(Interpreter="latex", FontSize=12)
title("Adjusted Stiffness Curve", Interpreter="latex", FontSize=20)
subtitle("B model", Interpreter="latex", FontSize=16)
xlabel("$x$ [mm]", Interpreter="latex", FontSize=14)
ylabel("$K$ [N/mm]", Interpreter="latex", FontSize=14)
ylim([2,4])
saveas(gcf, save_path+"\st_stiff_fit_test"+num2str(n_prova)+".svg", 'svg')


% figure(5)
% plot(out2.residuals, 'o', DisplayName="$2^{nd}$ order")
% hold on
% % plot(out3.residuals, 'o', DisplayName="poly3")
% plot(out4.residuals, 'o', DisplayName="$4^{th}$ order")
% 
% grid on
% legend(Interpreter="latex", FontSize=12)
% ylim([-0.8, 0.8])
% title("Fit Residuals", Interpreter="latex", FontSize=20)
% subtitle("of Incremental Stiffness", Interpreter="latex", FontSize=16)
% xlabel("$x$ [mm]", Interpreter="latex", FontSize=14)
% ylabel("$K_{inc}$ [N/mm]", Interpreter="latex", FontSize=14)


% figure(2)
% plot(x_forw, -f_integral./x_forw, DisplayName='Integral of Incremental')
% hold off
% legend

% figure(2)
% plot(x_back, (f_back)./x_back, DisplayName='acquired forw')
% hold on
% plot(x_back, (f_back-interp1(x_back, f_back, 0))./x_back, DisplayName='acquired forw')
% plot(x_back, f_integral_b./x_back, DisplayName='Integral of Incremental')
% close 


% figure(20)
% plot(x_forw, -(f_forw)./x_forw, DisplayName='Acquired', LineWidth=1.1)
% hold on
% plot(x_forw, -(f_forw-f_dc)./x_forw, DisplayName='No DC-Force', LineWidth=1.1)
% plot(x_forw, -f_integral./x_forw, DisplayName='Integral of Incremental', LineWidth=1.1)
% grid on
% legend
% xlabel("$x$ [mm]", Interpreter="latex", FontSize=14)
% ylabel("$K$ [N/mm]", Interpreter="latex", FontSize=14)

% figure(3)
% plot(x_forw, f_forw-f_dc)
% hold on
% plot(x_forw, f_integral)
% grid on