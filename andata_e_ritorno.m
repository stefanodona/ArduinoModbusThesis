% close all; 
clear; clc; close all;

% filename = "Prova63_ST_07714532C";
folders = {"STATICA_2023-12-21", "STATICA_2023-12-22"};

filename = "Statica_07714532B-"
filenames = {strcat(folders{1},"/",filename,"1/",filename,"1.txt"),
    strcat(folders{1},"/",filename,"2/",filename,"2.txt")}
% filenames = {"Prova74_ST_07714532C-1", "Prova75_ST_07714532C-1"};
lab = {"ieri", "oggi"};

% for j=1:length(folders)
for j=1:length(filenames)
    filename = filenames{j};
    % filename = "ProvaZeri";
    % filename = "ST01_07714532B-1";
    % FID = fopen(strcat("Measures/",filename,"/",filename,".txt"));
%     FID = fopen(strcat(folders{j},"/",filename,"/",filename,".txt"));
    FID = fopen(filename);
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
    plot(x_vera(:,1), force_vera(:,1))
    hold on
    plot(x_vera(:,2), force_vera(:,2))
    hold on
    grid on
%     legend("andata", "ritorno")
    
    
    figure(2);
    plot(x_vera(:,1), kms_vera(:,1))
    hold on
    plot(x_vera(:,2), kms_vera(:,2))
    hold on
    grid on
    
    
    x_vera_forw = x_vera(:,1);
    x_vera_back = x_vera(:,2);
    
    kms_vera_forw = kms_vera(:,1);
    kms_vera_back = kms_vera(:,2);

    kms_inc_forw = gradient(-force_forw, x_forw);
    kms_inc_back = gradient(-force_back, x_back);

    figure(4)
    plot(x_forw, kms_inc_forw)
    hold on
    plot(x_back, kms_inc_back)
    hold on
   
    figure(3)
    plot(x_forw, force_forw)
    hold on
    plot(x_back, force_back)
    grid on
    % 

    figure(5);
    plot(x_che_passa_per_0(:,1), forza_che_passa_per_0(:,1))
    hold on
    plot(x_che_passa_per_0(:,2), forza_che_passa_per_0(:,2))
    hold on
    grid on
end
cnt = split(filename, '_');
cnt = cnt(3)

figure(1)
fig = figure(1);
fig.Name = cnt;
hold off
title("Forza Elastica")
subtitle("postprocessata")
legend("B-1 andata", "B-1 ritorno", "B-2 andata", "B-2 ritorno")

figure(3)
fig = figure(3);
fig.Name = cnt;
hold off
title("Forza Elastica Misurata")
legend("B-1 andata", "B-1 ritorno", "B-2 andata", "B-2 ritorno")

figure(4)
fig = figure(4);
fig.Name = cnt;
hold off
title("K_{ms} incrementale")
legend("B-1 andata", "B-1 ritorno", "B-2 andata", "B-2 ritorno")
grid minor

figure(2)
fig = figure(2);
fig.Name = cnt;
hold off
title("K_{ms}")
legend("B-1 andata", "B-1 ritorno", "B-2 andata", "B-2 ritorno")


figure(5)
hold off
