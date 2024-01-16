
Creep_and_Tracking

%%
k0 = 1./c0;
k1 = 1./c1;
k2 = 1./c2;
k3 = 1./c3;
k4 = 1./c4;

params2 = [k0;k1;k2;k3;k4;r1;r2;r3;r4]';
labels = ["k_0";"k_1";"k_2";"k_3";"k_4";"r_1";"r_2";"r_3";"r_4"]
displ2 = displ';
%%
close all
coeff={}
for ii=1:size(params2,2)
    coeff{ii} = fit(displ2, params2(:,ii), 'poly2', ...
        'Robust', 'Off')
    coeff{ii}
    figure()
    plot(coeff{ii}, displ, params2(:,ii));
    title(labels(ii,:))
end

%%
close all
prms=[]
for ii=1:size(params2,2)
    
    prm = feval(coeff{ii}, x);
    
    if ii<6
        figure(1)
        prm=1./prm;
        if ii==1
%             prm=10*prm;
            plot(x, 10*prm)
            hold on
            plot(x, 10*params_int(ii,:))
        else
            plot(x, prm)
            hold on
            plot(x, params_int(ii,:))
        end
        
        hold on
        grid on
    else
        figure(2)
        semilogy(x, prm)
        hold on
        plot(x, params_int(ii,:))
        hold on
        grid on
    end  
    prms = [prms;prm'];
end


%% FORCES
forces = []
force = []

for ind = 1:length(x_long)
    ii = find(x_long(ind)==x);
    F_0 = x(ii)/prms(1,ii); % x/C0
    F_1 = x(ii)/prms(2,ii); % x/C1
    F_2 = x(ii)/prms(3,ii); % x/C2
    F_3 = x(ii)/prms(4,ii); % x/C3
    F_4 = x(ii)/prms(5,ii); % x/C4
    tau_1 = prms(2,ii)*prms(6,ii); % C1*R1
    tau_2 = prms(3,ii)*prms(7,ii); % C2*R2
    tau_3 = prms(4,ii)*prms(8,ii); % C3*R3
    tau_4 = prms(5,ii)*prms(9,ii); % C4*R4

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

figure(5)
plot(tracking_t_delay, tracking_force, '.') 
hold on
plot(time, sum(forces,1))
grid on
hold off
xlabel("time [s]",Interpreter="latex")
ylabel("force [N]",Interpreter="latex")
title("Force evolution in time", Interpreter="latex")
subtitle(cnt_name, Interpreter="latex")
xlim([0, 275])
%%
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

figure()
plot(x_long_sorted*1000, stiff/1000, 'o')
grid on
hold on


filename = strcat("Statica_",cnt_name);
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
    
    for i=1:1
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
    
    
%     figure(1);
    plot(x_vera(:,1), kms_vera(:,1))
    hold on
%     plot(x_vera(:,2), kms_vera(:,2))
%     hold on
    grid on
    hold off

% end

legend("Computed", "Measured")
xlabel("displacement [mm]",Interpreter="latex")
ylabel("stiffnes [N/mm]",Interpreter="latex")
title("Stiffness", Interpreter="latex")
subtitle(cnt_name, Interpreter="latex")



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