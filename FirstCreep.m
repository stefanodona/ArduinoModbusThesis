clear; close all; clc;

myFolders = dir("CREEP/07714532B-1/Creep*");
length(myFolders)
idx=2;

data = struct()
data.cnt = struct()

for idx = 1:length(myFolders)
% for idx = 1:1

    filename = myFolders(idx).name;
    folder = strcat(myFolders(idx).folder, "/", filename);
    info = split(filename, "_");
    % nome centratore
    cnt = info{3};
    % spostamento della prova di creep
    displ = str2num(info{2}(1:end-2));
    
    FID = fopen(strcat(folder,"/",filename,".txt"));
    datacell = textscan(FID, '%f%f%f', CommentStyle='#'); 
    fclose(FID);
    
    t = datacell{1};
    f = datacell{2};

    % cleaning data
    t = t(4:end)/1000;
    f = -sign(displ)*f(4:end);

    upper_bound = f(1) + 1;
    lower_bound = f(end) - 1;
    
    ii = find(f>upper_bound | f<lower_bound);
    
    t(ii)=[];
    f(ii)=[];
    
    fit_func = @(f0,f1,f2,f3,f4,tau1,tau2,tau3,tau4, x) f0+f1*exp(-x/tau1)+f2*exp(-x/tau2)+f3*exp(-x/tau3)+f4*exp(-x/tau4);

    coeff = fit(t, f, fit_func, ...
        'StartPoint', [2, 0.2, 0.2, 0.2, 0.2, 0.5, 1, 50, 2500], ...
        'Lower', [0.01, 0.01, 0.01, 0.01, 0.01, 0.01, 0.1, 0.1, 0.1], ...
        'Upper', [80, 3, 3, 3, 3, 2, 25, 1000, 50000], ...
        'Robust', 'LAR', ...
        'Algorithm', 'Levenberg-Marquardt', ...
        'MaxFunEval', 10000, ...
        'MaxIter', 1000)
    
    coeffs(idx, :) = coeffvalues(coeff);

    k_ms(idx, :) = coeffs(idx, 1:5)/abs(displ);

    fig = figure(idx);
    fig.Name=strcat(cnt, " x=", num2str(displ), "mm");
    % plot(t,f, LineWidth=1.2)
    % hold on
    plot(coeff, t, f)
    grid on
        
end
%%

clear; close all; clc;
data = struct();
data.cnt = struct();

myFolders = dir("CREEP/077*");

idx=1;

for idx=1:length(myFolders)
    nm = myFolders(idx).name
    fd = myFolders(idx).folder
    
    data(idx).name = nm;
%     data(idx).cnt.name = nm;
    
    spiFolder = dir(strcat(fd, "\", nm, "\Creep*"))
    for jj=1:length(spiFolder)
        meas_name = split(spiFolder(jj).name, '_');
        displ_name = meas_name{2}
        displ = str2num(displ_name(1:end-2));
       
        data(idx).cnt(jj).displ_val = displ_name;
        data(idx).cnt(jj).params = struct();
        data(idx).cnt(jj).params.fit_coeff = struct();
        data(idx).cnt(jj).params.model_coeff = struct();


    end

end
