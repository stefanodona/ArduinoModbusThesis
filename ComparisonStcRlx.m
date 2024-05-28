close all; clear; clc;

StaticIncrementalStiffnessFit
%%
load MisureRilassamento_cnt077145.mat
spi_idx = 1;

spiname = data(spi_idx).name;
save_path = "C:\Users\stefa\Desktop\Donà Stefano - Master Thesis\Images\chapter04\simulations";

% folder = char(folder);
% folder(end-9:end)='2024-01-18';
% folder = string(folder);


folder      = "STATICA_2024-01-18";
file_folder = "Statica_07714532B-1";
times_file = fullfile(folder, file_folder, "times.txt")
FID = fopen(times_file);
times = textscan(FID, '%f%f%f%f%f%f%f%f', CommentStyle='#');
fclose(FID);

t_x_rise = [0; times{3}/1000];
t_x_fall = [0; times{5}/1000];
x_measured = -[0; times{2}];

t_x_rise = round(t_x_rise,1);
t_x_fall = round(t_x_fall,1);

t_end = 300;
t_final = t_x_fall(end)+t_end;

dt = 0.1;
time  = 0:dt:t_final;

displ = 10;
x = -displ : 0.25 : displ;
[x_sort, iii] = sort(abs(x), 'descend');
iii=flip(iii);

x_sort = x(iii)';
x_sort = -[x_sort; flip(-x_sort(2:end))]

data(spi_idx).coeffs(1).val
%%
forces = []
force = []
for ind = 1:length(x_measured)
%     ii = find(x_sort(ind)==x);
    x_m = x_measured(ind);
    F_0 = -x_m.*polyval(data(spi_idx).coeffs(1).val, x_m); % x*k0
    F_1 = -x_m.*polyval(data(spi_idx).coeffs(2).val, x_m); % x*k1
    F_2 = -x_m.*polyval(data(spi_idx).coeffs(3).val, x_m); % x*k2
    F_3 = -x_m.*polyval(data(spi_idx).coeffs(4).val, x_m); % x*k3
    F_4 = -x_m.*polyval(data(spi_idx).coeffs(5).val, x_m); % x*k4
    
    tau_1 = polyval(data(spi_idx).coeffs(6).val, x_m) ./ polyval(data(spi_idx).coeffs(2).val, x_m); % R1/k1
    tau_2 = polyval(data(spi_idx).coeffs(7).val, x_m) ./ polyval(data(spi_idx).coeffs(3).val, x_m); % R2/k2
    tau_3 = polyval(data(spi_idx).coeffs(8).val, x_m) ./ polyval(data(spi_idx).coeffs(4).val, x_m); % R3/k3
    tau_4 = polyval(data(spi_idx).coeffs(9).val, x_m) ./ polyval(data(spi_idx).coeffs(5).val, x_m); % R4/k4
    
    force = F_0 + F_1*exp(-time./tau_1) + F_2*exp(-time./tau_2) + F_3*exp(-time./tau_3) + F_4*exp(-time./tau_4);
    force_neg = -force;
    

    rise_ind = find(time>=t_x_rise(ind)-0.01 & time<=t_x_rise(ind)+0.01);
    fall_ind = find(time>=t_x_fall(ind)-0.01 & time<=t_x_fall(ind)+0.01);
%     num_of_zeros_rise = round(t_x_rise(ind),2)/dt;
%     num_of_zeros_fall = round(t_x_fall(ind),2)/dt;
    
    force = circshift(force, rise_ind);
    force_neg = circshift(force_neg, fall_ind);

    force(1:rise_ind) = 0;
    force_neg(1:fall_ind) = 0;
%     force = circshift(force, int64(num_of_zeros_rise));
%     force(1:int64(num_of_zeros_rise)) = 0;
%     force_neg = circshift(force_neg, int64(num_of_zeros_fall));
%     force_neg(1:int64(num_of_zeros_fall)) = 0;

    forces = [forces; force; force_neg];

end
%%
close all
figure()
plot(time, sum(forces,1), LineWidth=1.1)
grid
xlabel("$t$ [s]",Interpreter="latex", FontSize=14)
ylabel("$F$ [N]",Interpreter="latex", FontSize=14)
title("Simulated force evolution", Interpreter="latex", FontSize=20)
xlim([0,600])
subtitle(spiname(end-2:end), Interpreter="latex", FontSize=16)

figure()
plot(time, sum(forces,1), LineWidth=1.1)
grid
xlabel("$t$ [s]",Interpreter="latex", FontSize=14)
ylabel("$F$ [N]",Interpreter="latex", FontSize=14)
title("Simulated force evolution (particular)", Interpreter="latex", FontSize=20)
xlim([200,225])
subtitle(spiname(end-2:end), Interpreter="latex", FontSize=16)


%%
% t_x_fall = round(t_x_fall,2);
% ind = t_x_fall/dt;
forces_sum = sum(forces,1);
% half_length = (length(x_sort)+1)/2;

t_fall   = t_x_fall;
t_fall(1)= [];
l = length(t_fall);

t_fall_forw = t_fall(1:l/2);
t_fall_back = t_fall(l/2+1:end);

x_meas    = x_measured;
x_meas(1) = [];

x_meas_forw = x_meas(1:l/2);
x_meas_back = x_meas(l/2+1:end);

stiff_a = zeros(1, l/2);
stiff_r = zeros(1, l/2);

% ANDATA
for ii=1:l/2
%     jj = int64(ind(ii));
    fall_ind = find(time>=t_fall_forw(ii)-0.01 & time<=t_fall_forw(ii)+0.01);
    f = forces_sum(fall_ind-1);
    stiff_a(ii) = -f/x_meas_forw(ii);
end




% RITORNO
% for ii=half_length+1:length(x_sort)
%     jj = int64(ind(ii));
%     f = forces_sum(jj-2);
%     stiff_r(ii-half_length) = f/x_sort(ii);
% end

% RITORNO
for ii=1:l/2
%     jj = int64(ind(ii));
    fall_ind = find(time>=t_fall_back(ii)-0.01 & time<=t_fall_back(ii)+0.01);
    f = forces_sum(fall_ind-1);
    stiff_r(ii) = -f/x_meas_back(ii);
end

% x_to_plot_a = x_sort(1:half_length);
% x_to_plot_a(1)=[];
% stiff_a(1)=[];
% [x_sort_sorted, x_l_ind] = sort(x_to_plot_a, 'ascend');
% K_ms_a = stiff_a(x_l_ind);
% 
% x_to_plot_r = x_sort(half_length+1:end);
% [x_sort_sorted, x_l_ind] = sort(x_to_plot_r, 'ascend');
% K_ms_r = stiff_r(x_l_ind);

k0_c = 1./0.52829;      % [N/mm]
k1_c = -0.048785;
k2_c = 0.026573;
k3_c = -0.00024292;
k4_c = 3.9698e-5;

x_klip = -11:0.25:11; %[mm]
k_klip = polyval([k4_c k3_c k2_c k1_c k0_c], x_klip);

P = 8;%
sc = -0.156*(log10(P).^2)  + 0.036*log10(P) + 1.6;
sc=1./sc;




close all
figure(3)
plot(x_meas_forw, stiff_a, '.', DisplayName="Sim", MarkerSize=10)
% plot(x_sort_sorted, K_ms_a, '-')
hold on
plot(x_forw, kms_forw_fit, DisplayName="Meas", LineWidth=2)
% plot(x_klip, k_klip, DisplayName="Klipp", LineWidth=1.1)
% plot(x_meas_forw, stiff_a.*sc, '.', DisplayName="scaled", LineWidth=1.1)
% plot(x_meas_back, stiff_r, '.')
% plot(x_sort_sorted, K_ms_r, '-')
grid on
title("Stiffness comparison", Interpreter="latex", FontSize=20)
% subtitle(spiname(end-2:end), Interpreter="latex", FontSize=16)
xlabel("$x$ [mm]", Interpreter="latex", FontSize=14)
ylabel("$K$ [N/mm]", Interpreter="latex", FontSize=14)
legend(Interpreter="latex", FontSize=14, Location="north")
ylim([0,7])
% saveas(gcf, save_path+"\st_stiff_sim_"+spiname(end-2:end)+"_forw.svg", 'svg')


%%
[x_m_f_sorted, ii_f] = sort(x_meas_forw);
[x_m_b_sorted, ii_b] = sort(x_meas_back);
stiff_f_sorted = stiff_a(ii_f);
stiff_b_sorted = stiff_r(ii_b);

figure()
plot(x_m_f_sorted, stiff_f_sorted, DisplayName="Forward", LineWidth=2)
hold on
plot(x_m_b_sorted, stiff_b_sorted, DisplayName="Backward", LineWidth=2)
% plot(x_forw, kms_forw_fit, DisplayName="Meas Forw", LineWidth=1.2)
% plot(x_back, kms_back_fit, DisplayName="Meas Back", LineWidth=1.2)

grid on
title("Simulated stiffness", Interpreter="latex", FontSize=20)
% subtitle("Boltzmann superposition principle "+spiname(end-2:end), Interpreter="latex", FontSize=16)
xlabel("$x$ [mm]", Interpreter="latex", FontSize=14)
ylabel("$K$ [N/mm]", Interpreter="latex", FontSize=14)
legend(Interpreter="latex", FontSize=12, Location="north")
ylim([0,7])
% saveas(gcf, save_path+"\stiff_sim_"+spiname(end-2:end)+"_forwback.svg", 'svg')