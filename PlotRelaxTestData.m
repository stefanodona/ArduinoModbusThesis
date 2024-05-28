close all; clear; clc

load MisureRilassamento_cnt077145.mat
% load MisureRilassamento_HM077x145x38.mat
% load MisureRilassamento_GRPCNT145.mat
comsol = load("Kms_CNT07714532A_sim_100MPa_2.txt");
% save_path = "C:\Users\stefa\Desktop\Donà Stefano - Master Thesis\Images\chapter04\relax";

saving   = 0;
save_svg = 0;
spi_idx  = 2;
displ    = 5; % [mm]
n_char   = 3;


for jj=1:length(data)
    spi_idx=jj;
disp_idx = find([data(spi_idx).cnt.displ_val]==displ);

spiname = data(spi_idx).name(end-n_char:end);
save_path = "C:\Users\stefa\Desktop\Donà Stefano - Master Thesis\Images\appendix\"+spiname;

% t = data(spi_idx).cnt(disp_idx).curve.time;
% f = data(spi_idx).cnt(disp_idx).curve.force;
% 
% t_end = num2str(round(t(end)));

% coeff_val = [data(spi_idx).cnt(disp_idx).params.model_coeff.value];
% coeff_val(1)=[]
% coeff_val(1:5)=1./coeff_val(1:5)

% str = "";
% for ii = 1:length(coeff_val)
%     str = str + (num2str(coeff_val(ii))+ " & ");
% end
% disp(str)

% figure()
% plot(t,f, LineWidth=1.1)
% title("Relaxation force evolution", Interpreter="latex", FontSize=20)
% subtitle("$x="+num2str(displ)+"$ mm - "+spiname, Interpreter="latex", FontSize=16)
% xlabel("$t$ [s]", Interpreter="latex", FontSize=14)
% ylabel("$F$ [N]", Interpreter="latex", FontSize=14)
% grid on
% ylim([15,19])
% saveas(gcf, save_path+"\relax_force_"+num2str(displ)+"mm_"+t_end+"s_"+spiname+".svg", 'svg')

x  = zeros(1 ,length(data(spi_idx).cnt));
ks = zeros(5 ,length(data(spi_idx).cnt));
rs = zeros(4 ,length(data(spi_idx).cnt));

for ii=1:length(data(spi_idx).cnt)
    coeff_val = [data(spi_idx).cnt(ii).params.model_coeff.value];
    x(ii) = -coeff_val(1);
    coeff_val(1)   = [];
    coeff_val(1:5) = 1./coeff_val(1:5);
    
    ks(:,ii) = coeff_val(1:5)';
    rs(:,ii) = coeff_val(6:end)';
    
%     ks(:,ii) = flip(ks(:,ii));
%     rs(:,ii) = flip(rs(:,ii));
end 

kms_comsol = comsol(:,2);
x_comsol = comsol(:,1);

x_comsol(1:2) = [];
x_comsol(end-1:end) = [];

kms_comsol(1:2) = [];
kms_comsol(end-1:end) = [];

kms1_com = kms_comsol(x_comsol==-0.5);
kms2_com = kms_comsol(x_comsol==0.5);

if contains(spiname, "B")
    b=2;
else 
    b=1.176;
end

a = b/mean([kms1_com,kms2_com]);

figure()
plot(x, ks(1,:), LineWidth=1.1)
hold on
% plot(x_comsol, a*kms_comsol, LineWidth=1) % kms comsol
grid on
title("Spatial Trend of $K^{(0)}$", Interpreter="latex", FontSize=20)
subtitle(spiname, Interpreter="latex", FontSize=16)
xlabel("$x$ [mm]", Interpreter="latex", FontSize=14)
ylabel("$K$ [N/mm]", Interpreter="latex", FontSize=14)
% ylim([0,5.5])
ylim([0,7])
% if save_svg saveas(gcf, save_path+"\relax_stiff_K0_"+spiname+".svg", 'svg'), end
%%
figure()
plot([x;x;x;x]', ks(2:end,:)', LineWidth=1.1)
grid on
title("Spatial Trend of $K^{(1,2,3,4)}$", Interpreter="latex", FontSize=20)
subtitle(spiname, Interpreter="latex", FontSize=16)
xlabel("$x$ [mm]", Interpreter="latex", FontSize=14)
ylabel("$K$ [N/mm]", Interpreter="latex", FontSize=14)
legend(["$K^{(1)}$", "$K^{(2)}$", "$K^{(3)}$", "$K^{(4)}$"],Interpreter="latex", FontSize=12)
ylim([0,0.5])
% if save_svg saveas(gcf, save_path+"\relax_stiff_K1234_"+spiname+".svg", 'svg'), end

figure()
semilogy([x;x;x;x]', rs(1:end,:)', LineWidth=1.1)
grid on
title("Spatial Trend of $R^{(1,2,3,4)}$", Interpreter="latex", FontSize=20)
subtitle(spiname, Interpreter="latex", FontSize=16)
xlabel("$x$ [mm]", Interpreter="latex", FontSize=14)
ylabel("$R$ [Ns/mm]", Interpreter="latex", FontSize=14)
legend(["$R^{(1)}$", "$R^{(2)}$", "$R^{(3)}$", "$R^{(4)}$"],Interpreter="latex", FontSize=12)
ylim([1e-2,1e3])
% if save_svg saveas(gcf, save_path+"\relax_res_R1234_"+spiname+".svg", 'svg'), end


%%
close all
clear coeffs

x_plot = -11:0.5:11;
x_plot(x_plot==0)=[];
x_forw = x;
parameters = [ks;rs];

ii=1;
for ii=1:9

    poly_deg = 2;
    
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
    
    
    fit_obj_forw = fit(x_forw', parameters(ii,:)', poly,...
        'Algorithm', 'Levenberg-Marquardt')
    
    param_coeff = flip(coeffvalues(fit_obj_forw));
    coeffs(ii,:) = param_coeff;
    
    param_fit = polyval(param_coeff, x_plot);

    data(spi_idx).coeffs(ii).val = param_coeff;
    data(spi_idx).x= x_plot;

    if ii==1
        figure(10)
        hold on
        K_0 = param_fit;
        plot(x_plot, param_fit, LineWidth=1.1)
        grid on
%         ylim([0,5.5])
        ylim([0,7])
        data(spi_idx).Ks(ii).curve = param_fit;
        data(spi_idx).Ks(ii).name = "K"+num2str(ii-1);
    elseif ii>1 && ii<6
        figure(20)
        hold on
        plot(x_plot, param_fit, LineWidth=1.1)
        grid on
        ylim([0,0.6])
        data(spi_idx).Ks(ii).curve = param_fit;
        data(spi_idx).Ks(ii).name = "K"+num2str(ii-1);
    elseif ii>5
        figure(30)
        semilogy(x_plot, param_fit, LineWidth=1.1)
        hold on
        grid on
        ylim([1e-2,1e3])
        data(spi_idx).Rs(ii-5).curve = param_fit;
        data(spi_idx).Rs(ii-5).name = "R"+num2str(ii-5);
    end

    
end


if saving
    save("MisureRilassamento_cnt077145.mat", "data")
%     save("MisureRilassamento_GRPCNT145.mat", "data")
%     save("MisureRilassamento_HM077x145x38.mat", "data")
end

figure(10)
title("Fitted Trend of $K^{(0)}$", Interpreter="latex", FontSize=20)
subtitle(spiname, Interpreter="latex", FontSize=16)
xlabel("$x$ [mm]", Interpreter="latex", FontSize=14)
ylabel("$K$ [N/mm]", Interpreter="latex", FontSize=14)
if save_svg saveas(gcf, save_path+"\app_relax_fit_stiff_K0_"+spiname+".svg", 'svg'), end

figure(20)
title("Fitted Trend of $K^{(1,2,3,4)}$", Interpreter="latex", FontSize=20)
subtitle(spiname, Interpreter="latex", FontSize=16)
xlabel("$x$ [mm]", Interpreter="latex", FontSize=14)
ylabel("$K$ [N/mm]", Interpreter="latex", FontSize=14)
legend(["$K^{(1)}$", "$K^{(2)}$", "$K^{(3)}$", "$K^{(4)}$"],Interpreter="latex", FontSize=12)
% legend(["$K^{(0)}/10$", "$K^{(1)}$", "$K^{(2)}$", "$K^{(3)}$", "$K^{(4)}$"],Interpreter="latex", FontSize=12)
legend(Location="north")
if save_svg saveas(gcf, save_path+"\app_relax_fit_stiff_K1234_"+spiname+".svg", 'svg'), end

figure(30)
title("Fitted Trend of $R^{(1,2,3,4)}$", Interpreter="latex", FontSize=20)
subtitle(spiname, Interpreter="latex", FontSize=16)
xlabel("$x$ [mm]", Interpreter="latex", FontSize=14)
ylabel("$R$ [Ns/mm]", Interpreter="latex", FontSize=14)
legend(["$R^{(1)}$", "$R^{(2)}$", "$R^{(3)}$", "$R^{(4)}$"],Interpreter="latex", FontSize=12)
if save_svg saveas(gcf, save_path+"\app_relax_fit_res_R1234_"+spiname+".svg", 'svg'), end

end
% close all
% figure(10)
% plot(x_comsol, a*kms_comsol, LineWidth=1) % kms comsol
% legend(["$K^{(0)}$ RLX", "$K^{(0)}$ COM"], Interpreter="latex", FontSize=12)
% title("$K^{(0)}$ Comparison", Interpreter="latex", FontSize=20)
% ylim([0,7])
% saveas(gcf, save_path+"\relax_K0_vsComsol_"+spiname+".svg", 'svg')

% coeffs_to_latex = flip(coeffs');
% 
% r_coeff = coeffs_to_latex(:, 6:9)
% to_divide = repmat(r_coeff(:,1),1,4)
% r_coeff./to_divide

% ratio = a*kms_comsol(20)./K_0(20);

% plot(x_comsol, a*kms_comsol./ratio)