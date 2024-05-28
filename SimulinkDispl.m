close all; clear; clc;

folder = "STATICA_2024-01-18";
file_folder = "Statica_07714532B-1";
times_file = fullfile(folder, file_folder, "times.txt");
FID = fopen(times_file);
times = textscan(FID, '%f%f%f%f%f%f%f%f', CommentStyle='#');
fclose(FID);



t_x_start = [0; times{1}/1000];
t_x_rise = [0; times{3}/1000];
t_x_fall = [0; times{5}/1000];
t_x_stop = [0; times{7}/1000];

t_x_start = round(t_x_start,1);
t_x_rise = round(t_x_rise,1);
t_x_fall = round(t_x_fall,1);
t_x_stop = round(t_x_stop,1);

x_measured = -[0; times{2}];

load MisureRilassamento_cnt077145.mat
spi_idx = 1;
spiname = data(spi_idx).name;

k0 = data(spi_idx).coeffs(1).val;
k1 = data(spi_idx).coeffs(2).val;
k2 = data(spi_idx).coeffs(3).val;
k3 = data(spi_idx).coeffs(4).val;
k4 = data(spi_idx).coeffs(5).val;

r1 = data(spi_idx).coeffs(6).val;
r2 = data(spi_idx).coeffs(7).val;
r3 = data(spi_idx).coeffs(8).val;
r4 = data(spi_idx).coeffs(9).val;

t_final = 5+t_x_fall(end);
dt = 0.1;

time = (0:dt:t_final)';

displ = zeros(length(time), 1);


for ii=2:length(t_x_fall)
    ind = find(time>=t_x_rise(ii) & time<=t_x_fall(ii));
    displ(ind)=x_measured(ii);

    idx_rise = find(time>=t_x_start(ii)-0.01 & time<=t_x_rise(ii)+0.01);
    time_extremis = [time(idx_rise(1)), time(idx_rise(end))];

    for jj=idx_rise
        displ(jj) = interp1(time_extremis , [0, x_measured(ii)], time(jj));
    end

    idx_fall = find(time>=t_x_fall(ii)-0.01 & time<=t_x_stop(ii)+0.01);
    time_extremis = [time(idx_fall(1)), time(idx_fall(end))];

    for jj=idx_fall
        displ(jj) = interp1(time_extremis , [x_measured(ii),0], time(jj));
    end

%     displ(idx_rise) = interp1(time, displ, time(idx_rise));
end



figure()
plot(time, displ)
xlim([200,300])
xline(t_x_stop(50))

figure()
plot(x_measured, polyval(k0, x_measured), '.')

figure()
plot(x_measured, polyval(k1, x_measured), '.')
hold on
plot(x_measured, polyval(k2, x_measured), '.')
plot(x_measured, polyval(k3, x_measured), '.')
plot(x_measured, polyval(k4, x_measured), '.')

figure()
semilogy(x_measured, polyval(r1, x_measured), '.')
hold on
semilogy(x_measured, polyval(r2, x_measured), '.')
semilogy(x_measured, polyval(r3, x_measured), '.')
semilogy(x_measured, polyval(r4, x_measured), '.')

displ_in.time = time;
displ_in.signals.values = displ;


%%
close all

A = 11; % [mm]
% tau = 0.77;
% tau = 4.88;
% tau = 25.81;
tau = 200;
% freq = 0.001; % [Hz]
freq = 1/tau/4/5; % [Hz]
% freq = 1e4; % [Hz]
f_s = 100*freq;
% f_s = 10;
final_sim_time = 1/freq*100;

out = sim("Relaxation2.slx", final_sim_time);

save_path = "C:\Users\stefa\Desktop\Donà Stefano - Master Thesis\Images\chapter04\simulations";
x_meas_sorted = sort(x_measured);

k_tot = polyval(k0, x_meas_sorted)+...
    polyval(k1, x_meas_sorted)+...
    polyval(k2, x_meas_sorted)+...
    polyval(k3, x_meas_sorted)+...
    polyval(k4, x_meas_sorted);

k_t2 = polyval(k0, x_meas_sorted)+...
    polyval(k2, x_meas_sorted)+...
    polyval(k3, x_meas_sorted)+...
    polyval(k4, x_meas_sorted);

k_t3 = polyval(k0, x_meas_sorted)+...
    polyval(k3, x_meas_sorted)+...
    polyval(k4, x_meas_sorted);

k_t4 = polyval(k0, x_meas_sorted)+...
        polyval(k4, x_meas_sorted);

force = out.sim_force.Data;
defl = out.defl.Data;
sim_time = out.sim_force.Time;

figure()
plot(sim_time, force, '-', LineWidth=1.1, DisplayName="$K_{sim}$")
hold on
% plot(x_meas_sorted, polyval(k0, x_meas_sorted), '-', LineWidth=1.1, DisplayName="$K^{(0)}$")
% plot(x_meas_sorted, k_tot, '-', LineWidth=1.1, DisplayName="$K^{(tot)}$")
grid on
title("Force time trend", Interpreter="latex", FontSize=20)
subtitle(num2str(freq)+" Hz - "+spiname(end-2:end), Interpreter="latex", FontSize=16)
xlabel("$x$ [mm]", Interpreter="latex", FontSize=14)
ylabel("$F$ [N]", Interpreter="latex", FontSize=14)
legend(Interpreter="latex", FontSize=16, Location="north")
% ylim([0,7])

i_0 = find(abs(defl)<=0.25);

defl(i_0)  = [];
force(i_0) = [];

figure()
plot(defl, force)

i1 = 9727;
i2 = 9776;
% 74:123

defl_1 = defl(i1:i2);
force_1 = -force(i1:i2);
force_1_dc = interp1(defl_1, force_1, 0);
force_1 = force_1  - force_1_dc;

kms_inc_coeff = polyfit(defl_1, gradient(-force_1, defl_1),6);
kms_coeff     = kms_inc_coeff./flip(1:7);

cols = {'#0072BD','#D95319','#EDB120'}

k0_c = 1./0.52829;      % [N/mm]
k1_c = -0.048785;
k2_c = 0.026573;
k3_c = -0.00024292;
k4_c = 3.9698e-5;

x_klip = -11:0.1:11; %[mm]
k_klip = polyval([k4_c k3_c k2_c k1_c k0_c], x_klip);


figure()
hold on
plot(x_meas_sorted, polyval(k0, x_meas_sorted), '-', LineWidth=1.1, DisplayName="$K^{(0)}$", Color=cols{2})
plot(x_meas_sorted, k_tot, '-', LineWidth=1.1, DisplayName="$K^{(tot)}$", Color=cols{3})
plot(defl_1, -force_1./defl_1, '--', LineWidth=1.1, DisplayName="$K_{sim}$", Color=cols{1})
% plot(x_klip, k_klip, '-', LineWidth=1.1, DisplayName="$K_{klip}$")
plot(x_meas_sorted, k_t4, '-', LineWidth=1.1, DisplayName="$K^{(t4)}$")
plot(x_meas_sorted, k_t3, '-', LineWidth=1.1, DisplayName="$K^{(t3)}$")
plot(x_meas_sorted, k_t2, '-', LineWidth=1.1, DisplayName="$K^{(t2)}$")
grid on
title("Simulated stiffness comparison", Interpreter="latex", FontSize=20)
subtitle(num2str(freq)+" Hz - "+spiname(end-2:end), Interpreter="latex", FontSize=16)
xlabel("$x$ [mm]", Interpreter="latex", FontSize=14)
ylabel("$K$ [N/mm]", Interpreter="latex", FontSize=14)
legend(Interpreter="latex", FontSize=14, Location="north")
ylim([0,7])
% saveas(gcf, save_path+"\sim_stiff_"+num2str(freq)+"_Hz_"+spiname(end-2:end)+".svg", 'svg')

defl_1 = defl(74:123);
force_1 = -force(74:123);
force_1_dc = interp1(defl_1, force_1, 0);
force_1 = force_1  - force_1_dc;

kms_inc_coeff = polyfit(defl_1, gradient(-force_1, defl_1),6);
kms_coeff     = kms_inc_coeff./flip(1:7);

% figure()
% plot(defl_1, -force_1./defl_1)


%%
close all
force = out.sim_force.Data;
defl = out.defl.Data;
sim_time = out.sim_force.Time;

t_rise = t_x_rise;
t_rise(1)=[];
t_fall = t_x_fall;
t_fall(1)=[];

l = length(t_rise);
t_rise_forw = t_rise(1:l/2);
t_fall_forw = t_fall(1:l/2);

t_rise_back = t_rise(l/2+1:end);
t_fall_back = t_fall(l/2+1:end);

x_meas = x_measured;
x_meas(1)=[];

x_meas_forw = x_meas(1:l/2);
x_meas_back = x_meas(l/2+1:end);

% find(time<t_fall_forw(l/2)+0.01 & time>t_fall(l/2)-0.01);
% t_fall_forw(l/2);

ddt = 1e2;

t_idx = find(sim_time==t_fall_forw(ii));

%%
% ANDATA
for ii=1:l/2
%     t_idx = find(sim_time<=t_fall_forw(ii)+ddt & sim_time>=t_fall_forw(ii)-ddt)-2;
    t_idx = find(sim_time>=t_fall_forw(ii)-0.0001 & sim_time<=t_fall_forw(ii)+0.0001)-1;
    stiff_forw(ii) = force(t_idx)./defl(t_idx);
end

% RITORNO

for ii=1:l/2
%     t_idx = find(time<t_fall_back(ii)+0.01 & time>t_fall_back(ii)-0.01)-2;
    t_idx = find(sim_time>=t_fall_back(ii)-0.0001 & sim_time<=t_fall_back(ii)+0.0001)-1;
    stiff_back(ii) = force(t_idx)./defl(t_idx);
end

figure();
plot(sim_time, defl);
hold on
plot(sim_time, force);
xline(t_fall_back(3))


[x_forw_sorted, i_f]=sort(x_meas_forw, 'ascend');
stiff_forw_sorted = stiff_forw(i_f);

[x_back_sorted, i_b]=sort(x_meas_back, 'ascend');
stiff_back_sorted = stiff_back(i_b);

figure()
plot(-x_meas_forw, stiff_forw, '.')
hold on
plot(-x_meas_back, stiff_back, '.')

%%
K_ms = @(x,t)   polyval(k0,x) + ... % k0(x)
                polyval(k1,x).*exp(-t.*polyval(k1,x)./polyval(r1,x))+... % k1(x)*exp(-t*r1(x)/k1(x))
                polyval(k2,x).*exp(-t.*polyval(k2,x)./polyval(r2,x))+... % k2(x)*exp(-t*r2(x)/k2(x))
                polyval(k3,x).*exp(-t.*polyval(k3,x)./polyval(r3,x))+... % k3(x)*exp(-t*r3(x)/k3(x)) 
                polyval(k4,x).*exp(-t.*polyval(k4,x)./polyval(r4,x));    % k4(x)*exp(-t*r4(x)/k4(x))


% displ = x_sum;
resp = zeros(1,numel(time));

for ii = 1:length(time)
%     gr = [diff(displ(1:ii))];
    gr = gradient(displ(1:ii));
    for jj = 1:ii
%         resp(ii) = resp(ii) + K_ms(displ(jj), time(ii)-time(jj))*(displ(jj)-displ(jj-1));
        resp(ii) = resp(ii) + K_ms(displ(jj), time(ii)-time(jj))*gr(jj);
    end
    percent = ii./length(time)*100;
    disp(round(percent));
end
disp("Done")
%%
close all
save('resp.mat','resp')
figure()
% plot(time(1:end-1),diff(displ))

% plot(resp)

for ii=1:l
    t_idx = find(time<t_rise(ii)+0.01 & time>t_rise(ii)-0.01);
    resp(t_idx) = resp(t_idx+2);
end

for ii=1:l
    t_idx = find(time<t_fall(ii)+0.01 & time>t_fall(ii)-0.01);
    resp(t_idx) = resp(t_idx+2);
end

plot(time, medfilt1(resp))
% xline(t_rise(100))
%%

resp = medfilt1(resp);

% ANDATA
for ii=1:l/2
    t_idx = find(time<t_fall_forw(ii)+0.01 & time>t_fall_forw(ii)-0.01)-1;
    stiff_forw(ii) = resp(t_idx)./displ(t_idx);
end

% RITORNO

for ii=1:l/2
    t_idx = find(time<t_fall_back(ii)+0.01 & time>t_fall_back(ii)-0.01)-1;
    stiff_back(ii) = resp(t_idx)./displ(t_idx);
end

figure()
plot(x_meas_forw, stiff_forw, '.')
hold on
plot(x_meas_back, stiff_back, '.')

k_tot = polyval(k0, x_meas_forw)+...
        polyval(k1, x_meas_forw)+...
        polyval(k2, x_meas_forw)+...
        polyval(k3, x_meas_forw)+...
        polyval(k4, x_meas_forw);

plot(x_meas_forw, k_tot, '.')
% figure()
% plot(displ, force, '.')
% grid on

% plot(gr)
