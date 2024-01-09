clear; close all; clc;

myFolders = dir("CREEP/07714532C-1/Creep*");
length(myFolders)
idx=2;


Kms = [];
x = [];
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
%     f = f(4:end);

    upper_bound = f(1) + 1;
    lower_bound = f(end) - 1;
    
    ii = find(f>upper_bound | f<lower_bound);
    
    t(ii)=[];
    f(ii)=[];
    

    t_1100 = find(t<1.050 & t>0.950);
    Kms = [Kms, f(t_1100)/abs(displ)];
    x = [x,displ];
        
end

[x, sort_idx] = sort(x);

Kms = Kms(sort_idx);

figure(1)
plot(x, Kms, 'o')
hold on
grid on


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%5

folders = {"STATICA_2023-12-22"};

filename = "Statica_07714532C-1"
filename = strcat(folders{1},"/",filename,"/",filename,".txt");
%     strcat(folders{1},"/",filename,"2/",filename,"2.txt")}
% filenames = {"Prova74_ST_07714532C-1", "Prova75_ST_07714532C-1"};
lab = {"ieri", "oggi"};

for j=1:length(folders)
%     filename = "Statica_07714532B-1"
    
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
    plot(x_vera(:,1), kms_vera(:,1))
    hold on
    plot(x_vera(:,2), kms_vera(:,2))
    hold on
    grid on


%     figure(1);
%     plot(x_mis(:,1), kms_mis(:,1))
%     hold on
%     plot(x_mis(:,2), kms_mis(:,2))
%     hold on
%     grid on
end
cnt = split(filename, '_');
cnt = cnt(3)


