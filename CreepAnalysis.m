

a = struct()

a.cnt = struct()
a.cnt.name = "07714532B-1"

%%
clear; close all; clc;
data = struct();
data.cnt = struct();

myFolders = dir("CREEP/077*");

idx=1;

% for idx=1:length(myFolders)
for idx=1:1
    nm = myFolders(idx).name
    fd = myFolders(idx).folder
    
    data(idx).name = nm;
%     data(idx).cnt.name = nm;
    
    spiFolder = dir(strcat(fd, "\", nm, "\Creep*"));

    for jj=1:length(spiFolder)
        filename = spiFolder(jj).name;
        filename_folder = spiFolder(jj).folder; 
        meas_name = split(filename, '_');
        displ_name = meas_name{2};
        displ = str2num(displ_name(1:end-2));
       
        data(idx).cnt(jj).displ_val = displ_name;
        data(idx).cnt(jj).params = struct();
        data(idx).cnt(jj).params.fit_coeff = struct();
        data(idx).cnt(jj).params.model_coeff = struct();
        
        FID = fopen(strcat(filename_folder,"/",filename,"/",filename,".txt"));
        datacell = textscan(FID, '%f%f%f', CommentStyle='#'); 
        fclose(FID);
        
        t = datacell{1};
        f = datacell{2};

        % cleaning data
        t = t(4:end)/1000;
        f = -sign(displ)*f(4:end);
    
        upper_bound = f(1) + 1;
        lower_bound = f(end) - 1;
        
        ind_to_delete = find(f>upper_bound | f<lower_bound);
        
        t(ind_to_delete)=[];
        f(ind_to_delete)=[];

        fit_func = @(f0,f1,f2,f3,f4,tau1,tau2,tau3,tau4, x) f0+f1*exp(-x/tau1)+f2*exp(-x/tau2)+f3*exp(-x/tau3)+f4*exp(-x/tau4);

        coeff = fit(t, f, fit_func, ...
            'StartPoint', [2, 0.2, 0.2, 0.2, 0.2, 0.5, 1, 50, 2500], ...
            'Lower', [0.01, 0.01, 0.01, 0.01, 0.01, 0.01, 0.1, 0.1, 0.1], ...
            'Upper', [80, 3, 3, 3, 3, 2, 25, 1000, 50000], ...
            'Robust', 'LAR', ...
            'Algorithm', 'Levenberg-Marquardt', ...
            'MaxFunEval', 10000, ...
            'MaxIter', 1000)
        
        coeff_val = coeffvalues(coeff);
        coeff_names = coeffnames(coeff);

        forces = coeff_val(1:5);
        taus = coeff_val(6:9);
        
        
        C_ms = abs(displ)./forces;
        R_ms = taus./C_ms(2:end);

        C_lab = {'C0','C1','C2','C3','C4'};
        R_lab = {'R1','R2','R3','R4'};
        
        values = [C_ms, R_ms]
        labels = [C_lab, R_lab];

        for kk=1:length(coeff_val)
            data(idx).cnt(jj).params.fit_coeff(kk).symbol = coeff_names{kk};
            data(idx).cnt(jj).params.fit_coeff(kk).value  = coeff_val(kk);
            
            data(idx).cnt(jj).params.model_coeff(kk).symbol = labels{kk};
            data(idx).cnt(jj).params.model_coeff(kk).value  = values(kk);

        end

    end

end

% 
% for i=1:length(myFolders)
%     cnt = myFolders(i).name
% end