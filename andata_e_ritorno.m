close all; 
clear; clc

% filename = "Prova63_ST_07714532C";
filenames = {"Prova63_ST_07714532C", "Prova64_ST_07714532C"};
lab = {"su", "giù"};

for j=1:2
    filename = filenames{j};
    % filename = "ProvaZeri";
    % filename = "ST01_07714532B-1";
    % FID = fopen(strcat("Measures/",filename,"/",filename,".txt"));
    FID = fopen(strcat(filename,"/",filename,".txt"));
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
    
        f_p = force(x==x_n);
        f_n = force(x==x_p);
    
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
        f_0 = f_n + ((f_p-f_n)./(x_p-x_n))*(-x_n)
        f_vera = force-f_0;
        kms_vera_aux = -f_vera./x;
    
        idx = find(x==x_n);
        f_vera(idx)
        f_vera(idx+1)
        f_vera(idx) = (f_p+f_n)/2-f_0;
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
    legend("andata", "ritorno")
    
    
    figure(2);
    plot(x_vera(:,1), kms_vera(:,1))
    hold on
    plot(x_vera(:,2), kms_vera(:,2))
    hold on
    grid on
    legend("andata", "ritorno")
    
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
   
    legend("andata", "ritorno")

    figure(3)
    plot(x_forw, force_forw)
    hold on
    plot(x_back, force_back)
    grid on
    % 
end
figure(3)
legend("su andata", "su ritorno", "giù andata", "giù ritorno")

figure(4)
legend("su andata", "su ritorno", "giù andata", "giù ritorno")
grid minor
% figure()
% plot(x_forw, kms_presunta_forw)
% hold on
% plot(x_back, kms_presunta_back)
% grid on