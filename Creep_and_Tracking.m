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
tracking_time(end-to_ignore:end)=[];
tracking_force(end-to_ignore:end)=[];

figure(1)
plot(tracking_time, tracking_force, '.')
grid on

%%
load MisureRilassamento_cnt077145.mat

% open static measurements values
folders = {"STATICA_2023-12-22", "STATICA_2024-01-11", "TRACKING"};
filename = strcat("Statica_", cnt_name);

f_idx = 2 % select static folder


jj=1; % select spider

    figure()
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

    subplot 211
    plot(displ, 10*c0);
%     plot(displ, c0);
    hold on
    plot(displ, c1);
    hold on
    plot(displ, c2);
    hold on
    plot(displ, c3);
    hold on
    plot(displ, c4);
    hold off
    grid on
    xlabel("Displacement [m]", Interpreter="latex")
    ylabel("Compliance [m/N]", Interpreter="latex")
    title("Compliance curve", Interpreter="latex", FontSize=14)
    subtitle(data(jj).name, Interpreter="latex")

    legend(["$10C_0$", "$C_1$", "$C_2$", "$C_3$", "$C_4$"], Interpreter="latex")

    subplot 212
    semilogy(displ, r1);
    hold on
    semilogy(displ, r2);
    hold on
    semilogy(displ, r3);
    hold on
    semilogy(displ, r4);
    hold off
    grid on
    xlabel("Displacement [m]", Interpreter="latex")
    ylabel("Resistance [N*s/m]", Interpreter="latex")
    title("Resistance curve", Interpreter="latex", FontSize=14)
    subtitle(data(jj).name, Interpreter="latex")

    legend(["$R_1$", "$R_2$", "$R_3$", "$R_4$"], Interpreter="latex")
% end

cnt_name = data(jj).name

%% mesh spaziale 
x = min(displ): 0.25e-3 : max(displ);

params = [c0;c1;c2;c3;c4;r1;r2;r3;r4];
% close all
% figure()
for i=1:size(params, 1)
    params_int(i,:) = interp1(displ, params(i,:), x);
    
%     plot(x, params_int(i,:), '.-');
%     hold on
%     plot(displ, params(i,:), '*');
%     hold on
end
% hold off
% grid on


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



t_final = t(end)+t_x_fall(end);

dt = 0.01;
time = 0 : dt : t_final;


%%
forces = []
force = []

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


    num_of_zeros_rise = round(t_x_rise(ind),2)/dt;
    num_of_zeros_fall = round(t_x_fall(ind),2)/dt;

    force = circshift(force, int64(num_of_zeros_rise));
    force(1:int64(num_of_zeros_rise)) = 0;
    force_neg = circshift(force_neg, int64(num_of_zeros_fall));
    force_neg(1:int64(num_of_zeros_fall)) = 0;

    forces = [forces; force; force_neg];

end
%%



figure(1)
hold on
plot(time, sum(forces,1))
grid on
xlabel("time [s]",Interpreter="latex")
ylabel("force [N]",Interpreter="latex")
title("Force evolution in time", Interpreter="latex")
subtitle(cnt_name, Interpreter="latex")
xlim([0, 275])
%%
function cnt = get_iter(val, json)
    cnt = 1;
%     if abs(round(val,3)) <= json.th3_val
%         cnt = json.th3_avg;
%     end
%     if abs(round(val,3)) <= json.th2_val
%         cnt = json.th2_avg;
%     end
%     if abs(round(val,3)) <= json.th1_val
%         cnt = json.th1_avg;
%     end
end