close all; clear; clc;



cnt_name = "07714532B-1"
% LOAD TIMES
track_file = strcat("TRACKING/Tracking_", cnt_name,"/Tracking_",cnt_name, ".txt");
FID = fopen(track_file);
tracking = textscan(FID, '%f%f%f', CommentStyle='#'); 
fclose(FID);

tracking_time = tracking{3}/1000;
tracking_force = -tracking{2};

to_ignore = 1/0.25*3*10;
tracking_time(end-to_ignore+1:end)=[];
tracking_force(end-to_ignore+1:end)=[];

figure(3)
plot(tracking_time, tracking_force, '.-', LineWidth=1, MarkerSize=10)
grid on
title("Force vs Time", Interpreter="latex", FontSize=20)
subtitle("CNT07714532B-1", Interpreter="latex")
xlabel("Time [s]", Interpreter="latex", FontSize=14)
ylabel("Force [N]", Interpreter="latex", FontSize=14)
xlim([202.5,225])

%%
load MisureRilassamento_cnt077145.mat

% open static measurements values
folders = {"STATICA_2023-12-22", "STATICA_2024-01-11", "TRACKING"};
cnt_name = "07714532B-1-1"
filename = strcat("Statica_", cnt_name);

f_idx = 3 % select static folder


jj=1; % select spider

    figure('Renderer', 'painters', 'Position', [100 100 1000 650]);
    c0=[];c1=[];c2=[];c3=[];c4=[];
          r1=[];r2=[];r3=[];r4=[];
    displ = [];
    for ii=1:length(data(jj).cnt)
    %     displ = [data(1).cnt.displ_val];
    
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

%     subplot 211
    figure('Renderer', 'painters', 'Position', [100 100 1000 650]);
    plot(displ, 10*c0,LineWidth=1);
%     plot(displ, c0);
    hold on
    plot(displ, c1,LineWidth=1);
    hold on
    plot(displ, c2,LineWidth=1);
    hold on
    plot(displ, c3,LineWidth=1);
    hold on
    plot(displ, c4,LineWidth=1);
    hold off
    grid on
    xlabel("Displacement [m]", Interpreter="latex", FontSize=14)
    ylabel("Compliance [m/N]", Interpreter="latex", FontSize=14)
    title("Compliance curve", Interpreter="latex", FontSize=20)
    subtitle(strcat("CNT",data(jj).name), Interpreter="latex")

    legend(["$10C_0$", "$C_1$", "$C_2$", "$C_3$", "$C_4$"], Interpreter="latex", Location="eastoutside", FontSize=12)

%     subplot 212
    figure('Renderer', 'painters', 'Position', [100 100 1000 650]);
    subplot 141
    plot(displ, r1,LineWidth=1);
    title("$R_1$", Interpreter="latex", FontSize=14)
    xlabel("Displacement [m]", Interpreter="latex", FontSize=14)
    ylabel("Resistance [N*s/m]", Interpreter="latex", FontSize=14)
    grid on
    ylim([0, 3000])
    xlim([-0.011, 0.011])
%     hold on
    subplot 142
    plot(displ, r2,LineWidth=1);
    title("$R_2$", Interpreter="latex", FontSize=14)
    xlabel("Displacement [m]", Interpreter="latex", FontSize=14)
    ylabel("Resistance [N*s/m]", Interpreter="latex", FontSize=14)
    grid on
    ylim([0, 1000])
    xlim([-0.011, 0.011])
%     hold on
    subplot 143
    plot(displ, r3,LineWidth=1);
    title("$R_3$", Interpreter="latex", FontSize=14)
    xlabel("Displacement [m]", Interpreter="latex", FontSize=14)
    ylabel("Resistance [N*s/m]", Interpreter="latex", FontSize=14)
    grid on
    ylim([0, 10000])
    xlim([-0.011, 0.011])
%     hold on
    subplot 144
    plot(displ, r4,LineWidth=1);
    title("$R_4$", Interpreter="latex", FontSize=14)
%     hold off
    grid on
    xlabel("Displacement [m]", Interpreter="latex", FontSize=14)
    ylabel("Resistance [N*s/m]", Interpreter="latex", FontSize=14)
    sgtitle({"Resistance curve", strcat("CNT",data(jj).name)}, Interpreter="latex", FontSize=20)
%     subtitle(strcat("CNT",data(jj).name), Interpreter="latex")
    ylim([0,2e5])
    xlim([-0.011, 0.011])

%     legend(["$R_1$", "$R_2$", "$R_3$", "$R_4$"], Interpreter="latex", Location="eastoutside", FontSize=12)
% end
% close 
cnt_name = data(jj).name

%% mesh spaziale 
x = min(displ): 0.25e-3 : max(displ);

params = [c0;c1;c2;c3;c4;r1;r2;r3;r4];

for i=1:size(params, 1)
    params_int(i,:) = interp1(displ, params(i,:), x);
end


%% EXTRACT TIMING

t = 0:0.1:300;

% SORT DISPLACEMENT
[x_sort, iii] = sort(abs(x), 'descend');
iii=flip(iii);


fname = strcat(folders{f_idx},"/",filename,"/",filename,".json");
fid = fopen(fname); 
raw = fread(fid,inf); 
str = char(raw'); 
fclose(fid); 
json = jsondecode(str);

x_sort = x(iii)';

max_iter = 0;
for ii = 2:length(x)
    cnt = get_iter(x_sort(ii), json);
    max_iter = max_iter + cnt;
end


x_long = [x_sort(1)];
for ii = 2:2:length(x)
    x_actual = x_sort(ii)*1000;
    cnt = get_iter(x_actual, json);
    
    for jj = 1:cnt
        x_long = [x_long; x_sort(ii); x_sort(ii+1)];
    end
end


% LOAD TIMES
times_file = strcat(folders{f_idx},"/",filename,"/times.txt");
FID = fopen(times_file);
times = textscan(FID, '%f%f%f%f%f%f%f%f', CommentStyle='#'); 
fclose(FID);

t_x_rise = [0; times{3}/1000];
t_x_fall = [0; times{5}/1000];
x_measured = [0; times{2}/1000];

t_x_rise(end-7:end) = [];
t_x_fall(end-7:end) = [];

t_final = t(end)+t_x_fall(end);

dt = 0.01;
time = 0 : dt : t_final;


%%
forces = []
force = []
deformations=[]

for ind = 1:length(x_long)
    ii = find(x_long(ind)==x);
    F_0 = x(ii)/params_int(1,ii); % x/C0
    F_1 = x(ii)/params_int(2,ii); % x/C1
    F_2 = x(ii)/params_int(3,ii); % x/C2
    F_3 = x(ii)/params_int(4,ii); % x/C3
    F_4 = x(ii)/params_int(5,ii); % x/C4
    tau_1 = params_int(2,ii)*params_int(6,ii); % C1*R1
    tau_2 = params_int(3,ii)*params_int(7,ii); % C2*R2
    tau_3 = params_int(4,ii)*params_int(8,ii); % C3*R3
    tau_4 = params_int(5,ii)*params_int(9,ii); % C4*R4

    force = F_0 + F_1*exp(-time./tau_1) + F_2*exp(-time./tau_2) + F_3*exp(-time./tau_3) + F_4*exp(-time./tau_4);

    force_neg = -force;

    deformation = ones(length(time),1)'*x(ii);
    deformation_neg = -ones(length(time),1)'*x(ii);


    num_of_zeros_rise = round(t_x_rise(ind),2)/dt;
    num_of_zeros_fall = round(t_x_fall(ind),2)/dt;

    force = circshift(force, int64(num_of_zeros_rise));
    force(1:int64(num_of_zeros_rise)) = 0;
    force_neg = circshift(force_neg, int64(num_of_zeros_fall));
    force_neg(1:int64(num_of_zeros_fall)) = 0;

    deformation = circshift(deformation , int64(num_of_zeros_rise));
    deformation (1:int64(num_of_zeros_rise)) = 0;
    deformation_neg = circshift(deformation_neg, int64(num_of_zeros_fall));
    deformation_neg(1:int64(num_of_zeros_fall)) = 0;

    forces = [forces; force; force_neg];
    deformations = [deformations;deformation;deformation_neg];

end
%% Time alignment


ii=0;
tracking_t_delay=zeros(length(tracking_time), 1);
for idx = 2:length(t_x_rise)
    if mod((ii+1), 3)==0
        ii=ii+1;
    end
    jj = ii*10+1;
    delay = t_x_rise(idx)-tracking_time(jj);
    tracking_t_delay(jj:end) = tracking_time(jj:end)+delay;
    ii=ii+1;
end


%% PLOTTING
figure()
plot(tracking_t_delay, tracking_force, '.') 
hold on
plot(time, sum(forces,1))
grid on
hold off
xlabel("time [s]",Interpreter="latex")
ylabel("force [N]",Interpreter="latex")
title("Force evolution in time fixed", Interpreter="latex")
subtitle(cnt_name, Interpreter="latex")
xlim([0, 275])
% ylim([-200, 200])

figure()
plot(tracking_time, tracking_force, '.') 
hold on
plot(time, sum(forces,1))
grid on
hold off
xlabel("time [s]",Interpreter="latex")
ylabel("force [N]",Interpreter="latex")
title("Force evolution in time", Interpreter="latex")
subtitle(cnt_name, Interpreter="latex")
xlim([0, 275])

% figure()
% plot(time, sum(deformations,1))
% xlabel("time [s]",Interpreter="latex")
% ylabel("force [N]",Interpreter="latex")
% title("Force evolution in time", Interpreter="latex")

%% FUNCTIONS

function cnt = get_iter(val, json)
    cnt = 1;
    if json.avg_flag
        if abs(round(val,3)) <= json.th3_val
            cnt = json.th3_avg;
        end
        if abs(round(val,3)) <= json.th2_val
            cnt = json.th2_avg;
        end
        if abs(round(val,3)) <= json.th1_val
            cnt = json.th1_avg;
        end
    end
end