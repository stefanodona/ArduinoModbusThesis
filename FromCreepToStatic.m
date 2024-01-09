clear; close all; clc;
load MisureRilassamento_cnt077145.mat


for jj=1:1
    T = struct2table(data(jj).cnt); % convert the struct array to a table
    sortedT = sortrows(T, 'displ_val'); % sort the table by 'DOB'
    data(jj).cnt = table2struct(sortedT); % change it back to struct array if necessary
    
    figure()
    c0=[];c1=[];c2=[];c3=[];c4=[];
          r1=[];r2=[];r3=[];r4=[];
    displ = [];
    for ii=1:10
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
%     displ = 1e3*displ;

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
end

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


t = 0:0.1:300;
for ii = 1:length(x)
    F_0 = x(ii)/params_int(1,ii);
    F_1 = x(ii)/params_int(2,ii);
    F_2 = x(ii)/params_int(3,ii);
    F_3 = x(ii)/params_int(4,ii);
    F_4 = x(ii)/params_int(5,ii);
    tau_1 = params_int(2,ii)*params_int(6,ii);
    tau_2 = params_int(3,ii)*params_int(7,ii);
    tau_3 = params_int(4,ii)*params_int(8,ii);
    tau_4 = params_int(5,ii)*params_int(9,ii);

    force = F_0 + F_1*exp(-t./tau_1) + F_2*exp(-t./tau_2) + F_3*exp(-t./tau_3) + F_4*exp(-t./tau_4);
end

% SORT DISPLACEMENT
[x_sort, iii] = sort(abs(x), 'descend');
iii=flip(iii);


fname = './STATICA_2023-12-22/Statica_07714532B-1/Statica_07714532B-1.json'; 
fid = fopen(fname); 
raw = fread(fid,inf); 
str = char(raw'); 
fclose(fid); 
json = jsondecode(str);

measTime = 0.1;

x_sort = x(iii);



max_iter = 0;
for ii = 2:length(x)
    cnt = get_iter(x_sort(ii), json);
    max_iter = max_iter + cnt;
end


x_long = [x_sort(1)];
for ii = 2:2:length(x)
%     disp("------")
    x_actual = x_sort(ii)*1000;
    cnt = get_iter(x_actual, json);
    
    for jj = 1:cnt
        x_long = [x_long; x_sort(ii); x_sort(ii+1)];
    end
end

t_x_rise = zeros(length(x_long),1);
t_x_fall = zeros(length(x_long),1);
% x_long = x_long; % [mm]
for ii = 2:length(x_long)
    abs(x_long(ii) - x_long(ii-1))
    if (ii<=3)
        t_x_rise(ii) = abs(x_long(ii)) / (json.vel_max*5);% + t_x_fall(ii-1);
        t_x_fall(ii) = t_x_rise(ii) + measTime + json.wait_time*1e-3;
    else
        t_x_rise(ii) = abs(x_long(ii) - x_long(ii-1)) / (json.vel_max*5);% + t_x_fall(ii-1) + json.wait_time*1e-3;
        t_x_fall(ii) = t_x_rise(ii) + measTime + json.wait_time*1e-3;
    end
end

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




