clear; close all; clc;
data = struct();
data.cnt = struct();

myFolders = dir("CREEP_2024/077*");

idx=1;



% for idx=1:length(myFolders)
for idx=1:1

    nm = myFolders(idx).name
    fd = myFolders(idx).folder
    
    data(idx).name = nm;
%     data(idx).cnt.name = nm;
    
    spiFolder = dir(strcat(fd, "\", nm, "\Creep*"));
    
    start_values = [2, 0.2, 0.2, 0.2, 0.2, 0.1, 1, 10, 100];
    

    % ordering folders
    for jj=1:length(spiFolder)
        filename = spiFolder(jj).name;
        filename_folder = spiFolder(jj).folder; 
        meas_name = split(filename, '_');
        displ_name = meas_name{2};
        displ = str2num(displ_name(1:end-2));
        spiFolder(jj).displ = displ;
    end

    T = struct2table(spiFolder);
    sorted = sortrows(T, "displ");
    spiFolder = table2struct(sorted);
    

    figure(idx+1)
    compliances=[];
    resistances=[];
    displacements=[];

    for jj=1:length(spiFolder)
%     for jj=6:6
        filename = spiFolder(jj).name;
        filename_folder = spiFolder(jj).folder; 
        meas_name = split(filename, '_');
        displ_name = meas_name{2};
        displ = str2num(displ_name(1:end-2));
       
        data(idx).cnt(jj).displ_val = displ;
        data(idx).cnt(jj).displ_um = "mm";
        data(idx).cnt(jj).params = struct();
        data(idx).cnt(jj).params.fit_coeff = struct();
        data(idx).cnt(jj).params.model_coeff = struct();
        
        FID = fopen(strcat(filename_folder,"/",filename,"/",filename,".txt"));
        datacell = textscan(FID, '%f%f%f', CommentStyle='#'); 
        fclose(FID);
        
        t = datacell{1};
        f = datacell{2};

        % cleaning data
        t = t(5:end)/1000;
        f = -sign(displ)*f(5:end);
    
        upper_bound = f(1) + 1;
        lower_bound = f(end) - 1;
        
        ind_to_delete = find(f>upper_bound | f<lower_bound);
        
        t(ind_to_delete)=[];
        f(ind_to_delete)=[];

         % plot data
%         figure(1)
%         plot(t, f);
%         grid on
%         title(strcat(nm, "   ", displ_name))

        fit_func = @(f0,f1,f2,f3,f4,tau1,tau2,tau3,tau4,x) f0+f1*exp(-x/tau1)+f2*exp(-x/tau2)+f3*exp(-x/tau3)+f4*exp(-x/tau4);
    
        
        coeff = fit(t, f, fit_func, ...
            'StartPoint', start_values, ...
            'Lower', [0.01, 0.01, 0.01, 0.01, 0.01, 0.01, 0.1, 0.1, 0.1], ...
            'Upper', [80, 10, 10, 10, 10, 10, 25, 100, 1000], ...
            'Robust', 'LAR', ...
            'Algorithm', 'Trust-Region', ...
            'DiffMinChange', 1e-5, ...
            'DiffMaxChange', 0.1, ...
            'MaxFunEvals', 10000, ...
            'MaxIter', 10000, ...
            'TolFun', 1e-6)
%             'StartPoint', [2, 0.2, 0.2, 0.2, 0.2, 0.1, 1, 10, 100], ...
        
        displ_name
        
        
        coeff_val = coeffvalues(coeff);
        coeff_names = coeffnames(coeff);
        
        start_values = coeff_val;

        forces = coeff_val(1:5);
        taus = coeff_val(6:9);
        
        displ = displ*1e-3;
        C_ms = abs(displ)./forces;
        R_ms = taus./C_ms(2:end);

        displacements = [displacements, displ];
        compliances = [compliances, C_ms'];
        resistances = [resistances, R_ms'];

        figure(idx+1)
        subplot 211
        plot(displacements, 10*compliances(1,:))
        hold on
        plot(displacements, compliances(2,:))
        hold on
        plot(displacements, compliances(3,:))
        hold on
        plot(displacements, compliances(4,:))
        hold on
        plot(displacements, compliances(5,:))
        hold off
        title("Compliance")
        legend("10C0", "C1", "C2", "C3", "C4")
        grid on
        xlim([-1e-2,1e-2])

        subplot 212
        semilogy(displacements, resistances(1,:))
        hold on
        semilogy(displacements, resistances(2,:))
        hold on
        semilogy(displacements, resistances(3,:))
        hold on
        semilogy(displacements, resistances(4,:))
        hold off
        title("Resistance")
        legend("R1", "R2", "R3", "R4")
        grid on
        xlim([-1e-2,1e-2])

        
        x_lab = {'disp'};
        C_lab = {'C0','C1','C2','C3','C4'};
        R_lab = {'R1','R2','R3','R4'};
        
        values = [displ, C_ms, R_ms];
        labels = [x_lab, C_lab, R_lab];

        coeff_val = [displ, coeff_val];
        coeff_names = [{"disp"}; coeff_names];

        um_lab(1) = {"m"};
        um_lab(2:6) = {"m/N"};
        um_lab(7:10) = {"N*s/m"};

        for kk=1:length(coeff_val)
            data(idx).cnt(jj).params.fit_coeff(kk).symbol       = coeff_names{kk};
            data(idx).cnt(jj).params.fit_coeff(kk).value        = coeff_val(kk);
            
            data(idx).cnt(jj).params.model_coeff(kk).sample     = nm;
%             data(idx).cnt(jj).params.model_coeff(kk).displ    = displ;
%             data(idx).cnt(jj).params.model_coeff(kk).displ_um = "m";

            data(idx).cnt(jj).params.model_coeff(kk).symbol     = labels{kk};
            data(idx).cnt(jj).params.model_coeff(kk).value_um   = um_lab(kk);
            data(idx).cnt(jj).params.model_coeff(kk).value      = values(kk);
        end

        


        figure(1)
        plot(coeff, t, f)
        grid on
        title(strcat(nm, "   ", displ_name))
        
    end

end


%% SORTING
% for cnt_index=1:length(myFolders)
%     T = struct2table(data(cnt_index).cnt)
%     sorted = sortrows(T, "displ_val")
%     data(cnt_index).cnt = table2struct(sorted)
% end
%% SAVING
save("MisureRilassamento_cnt077145.mat", "data")
%% LAUNCH PLT SCRIPT
% plot_creep_param