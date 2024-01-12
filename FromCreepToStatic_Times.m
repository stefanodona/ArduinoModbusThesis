clear; close all; clc;
load MisureRilassamento_cnt077145.mat


% for jj=3:3
jj=3; % select spider

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

%% mesh spaziale 
x = min(displ): 0.25e-3 : max(displ);

params = [c0;c1;c2;c3;c4;r1;r2;r3;r4];
close all
figure()
for i=1:size(params, 1)
    params_int(i,:) = interp1(displ, params(i,:), x);
    
    plot(x, params_int(i,:), '.-');
    hold on
    plot(displ, params(i,:), '*');
    hold on
end
hold off
grid on


%% EXTRACT TIMING

t = 0:0.1:300;

% SORT DISPLACEMENT
[x_sort, iii] = sort(abs(x), 'descend');
iii=flip(iii);

% open static measurements values
folders = {"STATICA_2023-12-22", "STATICA_2024-01-11"};
filename = "Statica_07714532C-1"

f_idx = 2 % select static folder

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
times = textscan(FID, '%f%f%f%f', CommentStyle='#'); 
fclose(FID);

t_x_rise = [0; times{1}/1000];
t_x_fall = [0; times{3}/1000];
x_measured = [0; times{2}/1000];



t_final = t(end)+t_x_fall(end);

dt = 0.01;
time = 0 : dt : t_final;


%%
forces = []
% x_long = -x_long;
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

%     x_0_ind = find(x==0);
%     F_0 = x(ii)/params_int(1,x_0_ind); % x/C0(0)
%     F_1 = x(ii)/params_int(2,x_0_ind); % x/C1(0)
%     F_2 = x(ii)/params_int(3,x_0_ind); % x/C2(0)
%     F_3 = x(ii)/params_int(4,x_0_ind); % x/C3(0)
%     F_4 = x(ii)/params_int(5,x_0_ind); % x/C4(0)
%     tau_1 = params_int(2,x_0_ind)*params_int(6,x_0_ind); % C1*R1(0)
%     tau_2 = params_int(3,x_0_ind)*params_int(7,x_0_ind); % C2*R2(0)
%     tau_3 = params_int(4,x_0_ind)*params_int(8,x_0_ind); % C3*R3(0)
%     tau_4 = params_int(5,x_0_ind)*params_int(9,x_0_ind); % C4*R4(0)
% 
%     force_neg = F_0 + F_1*exp(-time./tau_1) + F_2*exp(-time./tau_2) + F_3*exp(-time./tau_3) + F_4*exp(-time./tau_4);
%     force_neg = -force_neg;
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
figure()
plot(time, sum(forces,1))
grid

%% stiffness computation
close all
t_x_fall = round(t_x_fall,2);
ind = t_x_fall/dt;
forces_sum = sum(forces,1);
stiff = zeros(1, length(x_long));
for ii=2:length(x_long)
    jj = int64(ind(ii));
    f = forces_sum(jj-2);
    stiff(ii) = f/x_long(ii);
end

x_to_plot = x_long;
x_to_plot(1)=[];
stiff(1)=[];
[x_long_sorted, x_l_ind] = sort(x_to_plot, 'ascend');
stiff = stiff(x_l_ind);

figure(1)
plot(x_long_sorted*1000, stiff/1000, 'o')
grid on
hold on


% folders = {"STATICA_2023-12-22"};
% 
% filename = "Statica_07714532B-1"
file_name = strcat(folders{f_idx},"/",filename,"/",filename,".txt");
%     strcat(folders{1},"/",filename,"2/",filename,"2.txt")}
% filenames = {"Prova74_ST_07714532C-1", "Prova75_ST_07714532C-1"};
lab = {"ieri", "oggi"};

% for j=1:length(folders)
    
    FID = fopen(file_name);
    datacell = textscan(FID, '%f%f%f%f%f%f%f%f', CommentStyle='#'); 
    fclose(FID);
    
    x_forw = datacell{1};
    force_forw = datacell{3};
    x_back = datacell{5};
    force_back = datacell{7};
    
    kms_presunta_forw = -force_forw./x_forw;
    kms_presunta_back = -force_back./x_back;
    
    x_mis = [x_forw, x_back];
    force_mis = [force_forw, force_back];
    kms_mis = [kms_presunta_forw, kms_presunta_back];
    
    for i=1:2
        x = x_mis(:,i);
        force = force_mis(:,i);
        
        x_pos = x(x>0);
        x_neg = x(x<0);
        
        x_p = x_pos(1)
        x_n = x_neg(end)
    
        f_p = force(x==x_p)
        f_n = force(x==x_n)
    
    %     f_pos = force(force>0);
    %     f_neg = force(force<0);
    %     
    %     f_p = f_pos(end);
    %     f_n = f_neg(1);
    %     
    %     x_p = x(force==f_p);
    %     x_n = x(force==f_n);
    %     
    %     x_0 = x_n + ((x_p-x_n)./(f_p-f_n))*(-f_n)
%         f_0 = f_n + ((f_p-f_n)./(x_p-x_n))*(-x_n)
        f_0 = f_p - ((f_p-f_n)./(x_p-x_n))*(x_p)
        f_vera = force-f_0;

        forza_che_passa_per_0(:,i) = force-f_0; 
        x_che_passa_per_0(:,i) = x; 
        kms_vera_aux = -f_vera./x;
    
        idx = find(x==x_n);
        f_vera(idx)
        f_vera(idx+1)
        f_vera(idx) = 0;
        f_vera(idx+1) = [];
    
        x(idx) = 0;
        x(idx+1) = [];
        
        kms_vera_aux(idx+1) = [];
    %     kms_vera(:,i) = -force./x_vera(:,i);
        force_vera(:,i) = f_vera;
        kms_vera(:,i) = kms_vera_aux;
        x_vera(:,i) = x;
    end
    
    
    figure(1);
    plot(x_vera(:,1), kms_vera(:,1))
    hold on
%     plot(x_vera(:,2), kms_vera(:,2))
%     hold on
    grid on

% end
cnt = split(filename, '_');
cnt = cnt(3)

legend("Computed", "Measured")

%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% FUNCTIONS
function cnt = get_iter(val, json)
    cnt = 1;
    if abs(round(val,3)) <= json.th3_val
        cnt = json.th3_avg;
    end
    if abs(round(val,3)) <= json.th2_val
        cnt = json.th2_avg;
    end
    if abs(round(val,3)) <= json.th1_val
        cnt = json.th1_avg;
    end
%     disp(cnt)
end

% function t_1 = getTime(disp,acc,dec,v_max)
%     x_acc = .5*(v_max)^2/acc
%     dec = -abs(dec)
%     if x_acc>disp/2
%         denom = (acc*dec)/(2*(dec-acc));
%         t_1 = sqrt(disp/denom)
%     else
%         t_acc = sqrt(2*x_acc/acc)
%         t_dec = -v_max/dec
% 
%         x_dec = .5*(-dec)*t_dec^2;
%         t_vel=0
%         if (x_acc+x_dec)<disp
%             t_vel = (disp-(x_acc+x_dec))/v_max
%         end
% %     
% %         % polynomial to solve
% %         p = [.5*dec, v_max, disp-x_acc];
% %         t_dec = roots(p)
% %         t_dec = t_dec(t_dec>0);
%     
%         t_1 = t_acc+t_dec+t_vel;
%     end
% end

