close all; clc; clear;


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

date        = "2024-02-27";


spidernames = {"07714532B-1",...
    "07714532B-2",...
    "07714532C-1",...
    "07714532C-2"};


n_char      = 1;

mainfolder = "TRACKING_"+date;

samples  = 9;

cnt_name = spidernames{spi_idx};


% LOAD TIMES
track_file = strcat(mainfolder, "/Tracking_", cnt_name,"/Tracking_",cnt_name, ".txt");
FID = fopen(track_file);
tracking = textscan(FID, '%f%f%f', CommentStyle='#'); 
fclose(FID);

tracking_time = tracking{3}/1000;
tracking_force = -tracking{2};
tracking_pos = -tracking{1};


tracking_time = round(tracking_time,1);
x_neg_idx = 1:30:length(tracking_pos);
x_pos_idx = 11:30:length(tracking_pos);


x_neg = tracking_pos(x_neg_idx)';
x_pos = tracking_pos(x_pos_idx)';

x_measured = reshape([x_neg; x_pos], 1, []);

dt = 0.1;
time = 0:dt:tracking_time(end);

t_rise_neg_idx = 1:30:length(tracking_pos);
t_rise_pos_idx = 11:30:length(tracking_pos);

t_fall_neg_idx = 10:30:length(tracking_pos);
t_fall_pos_idx = 20:30:length(tracking_pos);

t_x_fall = sort([tracking_time(t_fall_pos_idx); tracking_time(t_fall_neg_idx)]);
t_x_rise = sort([tracking_time(t_rise_pos_idx); tracking_time(t_rise_neg_idx)]);


%%

forces = [];
force = [];
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
%%z
close all
figure()
plot(time, sum(forces,1), LineWidth=1.1)
hold on
plot(tracking_time, tracking_force, '.')
grid
xlabel("$t$ [s]",Interpreter="latex", FontSize=14)
ylabel("$F$ [N]",Interpreter="latex", FontSize=14)
title("Simulated force evolution", Interpreter="latex", FontSize=20)
xlim([0,600])