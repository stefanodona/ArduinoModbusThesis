function [displ, K_ms_a, K_ms_r, coeff] = simulate_Kms(static_folder, spider_name, data, fit_flag)

    jj = find({data.name}==spider_name);
    coeff={};
    
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
    
    % mesh spaziale
    x = min(displ): 0.25e-3 : max(displ);
%     x = -4: 0.25e-3 : 4;
    
    params = [c0;c1;c2;c3;c4;r1;r2;r3;r4];
    
%     figure()
    for i=1:size(params, 1)
        params_int(i,:) = interp1(displ, params(i,:), x);
    % 
    %     plot(x, params_int(i,:), '.-');
    %     hold on
    %     plot(displ, params(i,:), '*');
    %     hold on
    end
%     hold off
%     grid on
        
    if fit_flag
        k0 = 1./c0;
        k1 = 1./c1;
        k2 = 1./c2;
        k3 = 1./c3;
        k4 = 1./c4;
        
        params2 = [k0;k1;k2;k3;k4;r1;r2;r3;r4]';
        labels = ["k_0";"k_1";"k_2";"k_3";"k_4";"r_1";"r_2";"r_3";"r_4"]
        displ2 = displ';
%         close all
%         coeff={}
        for ii=1:size(params2,2)
%         for ii=1:1
            coeff{ii} = fit(displ2, params2(:,ii), 'poly4', ...
                'Robust', 'Off')
            coeff{ii}
            figure()
            plot(coeff{ii}, displ, params2(:,ii));
            title(labels(ii,:))
        end
    end

    
    t = 0:0.1:300;
    
    % SORT DISPLACEMENT
    [x_sort, iii] = sort(abs(x), 'descend');
    iii=flip(iii);
    
%     fname = strcat(folders{f_idx},"/",filename,"/",filename,".json");

    f = dir(fullfile(static_folder, '*.json'));
    fname = strcat(f.folder, '/', f.name);
    fid = fopen(fname); 
    raw = fread(fid,inf); 
    str = char(raw'); 
    fclose(fid); 
    json = jsondecode(str);
    
    x_sort = x(iii)';

    if json.ar_flag
        x_sort = [x_sort; flip(-x_sort(2:end))]
    end
    
%     max_iter = 0;
%     for ii = 2:length(x)
%         cnt = get_iter(x_sort(ii), json);
%         max_iter = max_iter + cnt;
%     end
    
    x_long = x_sort;
%     x_long = [x_sort(1)];
%     % for ii = 2:2:length(x)
%     %     x_actual = x_sort(ii)*1000;
%     %     cnt = get_iter(x_actual, json);
%     %     
%     %     for jj = 1:cnt
%     %         x_long = [x_long; x_sort(ii); x_sort(ii+1)];
%     %     end
%     % end
%     for ii = 2:2:length(x)
%         x_long = [x_long; x_sort(ii); x_sort(ii+1)];
%     end
    
    % LOAD TIMES
    
    times_file = strcat(static_folder, "/times.txt");
    FID = fopen(times_file);
    times = textscan(FID, '%f%f%f%f%f%f%f%f', CommentStyle='#'); 
    fclose(FID);
    
    t_x_rise = [0; times{3}/1000];
    t_x_fall = [0; times{5}/1000];
    x_measured = [0; times{2}/1000];
    
    
    to_delete = find(abs(x_measured)>max(displ));

    if to_delete
        delay = t_x_rise(to_delete(end)) - t_x_rise(to_delete(1));
        
        t_x_rise(to_delete(1):end)=t_x_fall(to_delete(1):end)-delay;
        t_x_fall(to_delete(1):end)=t_x_fall(to_delete(1):end)-delay;
    
        t_x_rise(to_delete)=[];
        t_x_fall(to_delete)=[];
        x_measured(to_delete)=[];

    end

    
    t_final = t(end)+t_x_fall(end);
    
    dt = 0.01;
    time = 0 : dt : t_final;
    
    
    %%
    forces = []
    force = []
    % x_long = -x_long;

    if fit_flag
        for ind = 1:length(x_long)
            ii = find(x_long(ind)==x);
            F_0 = x_long(ind)*feval(coeff{1}, x_long(ind)); % x*k0
            F_1 = x_long(ind)*feval(coeff{2}, x_long(ind)); % x*k0
            F_2 = x_long(ind)*feval(coeff{3}, x_long(ind)); % x*k0
            F_3 = x_long(ind)*feval(coeff{4}, x_long(ind)); % x*k0
            F_4 = x_long(ind)*feval(coeff{5}, x_long(ind)); % x*k0

            tau_1 = feval(coeff{6}, x_long(ind))/feval(coeff{2}, x_long(ind)); % R1/k1
            tau_2 = feval(coeff{7}, x_long(ind))/feval(coeff{3}, x_long(ind)); % R1/k1
            tau_3 = feval(coeff{8}, x_long(ind))/feval(coeff{4}, x_long(ind)); % R1/k1
            tau_4 = feval(coeff{9}, x_long(ind))/feval(coeff{5}, x_long(ind)); % R1/k1
            
        
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
    else
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
    end
    %%
%     figure()
%     plot(time, forces(3,:));
%     hold on
%     plot(time, forces(4,:));
%     plot(time, forces(15,:));
%     plot(time, forces(16,:));
%     plot(time, forces(31,:));
%     plot(time, forces(32,:));
%     grid on
%     hold off

    figure()
    plot(time, sum(forces,1))
    grid
    xlabel("time [s]",Interpreter="latex")
    ylabel("force [N]",Interpreter="latex")
    title("Force evolution in time", Interpreter="latex")
    subtitle(spider_name, Interpreter="latex")
    
    %% stiffness computation
    % close all
    t_x_fall = round(t_x_fall,2);
    ind = t_x_fall/dt;
    forces_sum = sum(forces,1);
    half_length = (length(x_long)+1)/2;
    
    stiff_a = zeros(1, half_length);
    stiff_r = zeros(1, half_length-1);
        
    
    % ANDATA
    for ii=2:half_length
        jj = int64(ind(ii));
        f = forces_sum(jj-2);
        stiff_a(ii) = f/x_long(ii);
    end
    
    % RITORNO
    for ii=half_length+1:length(x_long)
        jj = int64(ind(ii));
        f = forces_sum(jj-2);
        stiff_r(ii-half_length) = f/x_long(ii);
    end
    
    x_to_plot_a = x_long(1:half_length);
    x_to_plot_a(1)=[];
    stiff_a(1)=[];
    [x_long_sorted, x_l_ind] = sort(x_to_plot_a, 'ascend');
    K_ms_a = stiff_a(x_l_ind);
    
    x_to_plot_r = x_long(half_length+1:end);
    [x_long_sorted, x_l_ind] = sort(x_to_plot_r, 'ascend');
    K_ms_r = stiff_r(x_l_ind);

    displ = x_long_sorted;
    figure()
    plot(x_long_sorted*1000, K_ms_a/1000, '-')
    if json.ar_flag
        hold on
        plot(x_long_sorted*1000, K_ms_r/1000, '-')
        legend("Andata", "Ritorno")
    end
    grid on

end