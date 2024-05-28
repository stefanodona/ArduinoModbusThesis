close all; clear; clc;
% clear; clc;

date        = "2023-12-22";
% date        = "2024-01-11"; 
folder      = "STATICA_"+date;

spidernames = {"07714532B-1",...
               "07714532B-2",...
               "07714532C-1",...
               "07714532C-2"}

% spidername  = "07714532C-1";

for ii=1:length(spidernames)
    spidername= spidernames{ii};
spiname     = char(spidername);

save_path = "C:\Users\stefa\Desktop\Donà Stefano - Master Thesis\Images\chapter04\measures";

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

data(ii).spiname = spiname;
data(ii).x_f = x_forw;
data(ii).k_f = kms_forw_fit;

figure(1)
plot(x_forw, kms_forw_fit, LineWidth=1.1, DisplayName=spiname(end-2:end));
hold on
grid on
% plot(x_back, kms_back_fit, LineWidth=1.1, DisplayName="Back Integration");
title("Stiffness Comparison", Interpreter="latex", FontSize=20)
subtitle("Forward Sequence", Interpreter="latex", FontSize=16)
xlabel("$x$ [mm]", Interpreter="latex", FontSize=14)
ylabel("$K$ [N/mm]", Interpreter="latex", FontSize=14)
legend(Interpreter="latex", FontSize=12, Location="north")
ylim([0,7])


figure(2)
plot(x_back, kms_back_fit, LineWidth=1.1, DisplayName=spiname(end-2:end));
hold on
grid on
title("Stiffness Comparison", Interpreter="latex", FontSize=20)
subtitle("Backward Sequence", Interpreter="latex", FontSize=16)
xlabel("$x$ [mm]", Interpreter="latex", FontSize=14)
ylabel("$K$ [N/mm]", Interpreter="latex", FontSize=14)
legend(Interpreter="latex", FontSize=12, Location="north")
ylim([0,7])

end

figure(1)
% plot(data(4).x_f, data(4).k_f.*1.15, 'k--');
% plot(data(4).x_f, data(4).k_f.*0.85, 'k--');
% saveas(gcf, save_path+"\st_stiff_comparison_forward_"+date+".svg", 'svg')


figure(2)
% saveas(gcf, save_path+"\st_stiff_comparison_backward_"+date+".svg", 'svg')

%%
close all
figure(3)
idx = round(length(kms_forw_fit)/2);
offset = data(2).k_f(idx) - data(4).k_f(idx); 
offset2 = data(2).k_f(idx) - data(3).k_f(idx); 

plot(data(1).x_f, data(1).k_f, LineWidth=1.1, DisplayName=data(1).spiname(end-2:end))
hold on
plot(data(2).x_f, data(2).k_f, LineWidth=1.1, DisplayName=data(2).spiname(end-2:end))
% plot(offset2+data(3).k_a)
plot(data(3).x_f, offset2+data(3).k_f, LineWidth=1.1, DisplayName=strcat(data(3).spiname(end-2:end), '+offset'))
plot(data(4).x_f, offset+data(4).k_f, LineWidth=1.1, DisplayName=strcat(data(4).spiname(end-2:end), '+offset'))
title("Stiffness Comparison", Interpreter="latex", FontSize=20)
subtitle("Forward Sequence", Interpreter="latex", FontSize=16)
xlabel("$x$ [mm]", Interpreter="latex", FontSize=14)
ylabel("$K$ [N/mm]", Interpreter="latex", FontSize=14)
legend(Interpreter="latex", FontSize=12, Location="north")
grid on
hold off
% saveas(gcf, save_path+"\st_stiff_comparison_offset_"+date+".svg", 'svg')











