function [displ, Kms_a, Kms_r] = process_static_Kms(static_folder, spider_name)

Kms_a = [];
Kms_r = [];
f = dir(fullfile(static_folder, '*.txt'));
f = f(1);
file_name = strcat(f.folder, '/', f.name);

FID = fopen(file_name);
datacell = textscan(FID, '%f%f%f%f%f%f%f%f', CommentStyle='#');
fclose(FID);

f = dir(fullfile(static_folder, '*.json'));
fname = strcat(f.folder, '/', f.name);
fid = fopen(fname);
raw = fread(fid,inf);
str = char(raw');
fclose(fid);
json = jsondecode(str);

x_forw = datacell{1};
force_forw = datacell{3};
x_back = datacell{5};
force_back = datacell{7};

kms_presunta_forw = -force_forw./x_forw;
kms_presunta_back = -force_back./x_back;

x_mis = [x_forw, x_back];
force_mis = [force_forw, force_back];
kms_mis = [kms_presunta_forw, kms_presunta_back];

% CHECK ANDATA E RITORNO
if json.ar_flag
    iii=2;
else
    iii=1;
end

for i=1:iii
    x = x_mis(:,i);
    force = force_mis(:,i);

    x_pos = x(x>0);
    x_neg = x(x<0);

    x_p = x_pos(1)
    x_n = x_neg(end)

    f_p = force(x==x_p)
    f_n = force(x==x_n)

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
    force_vera(:,i) = f_vera;
    kms_vera(:,i) = kms_vera_aux;
    x_vera(:,i) = x;
end


%     figure(1);
plot(x_vera(:,1), kms_vera(:,1), LineWidth=1)
hold on
if json.ar_flag
    plot(x_vera(:,2), kms_vera(:,2), LineWidth=1)
    hold on
end
grid on
hold off
legend(["Andata", "Ritorno"], Interpreter="latex", FontSize=12)


% legend("Computed", "Measured")
xlabel("displacement [mm]",Interpreter="latex", FontSize=14)
ylabel("stiffness [N/mm]",Interpreter="latex", FontSize=14)
title("Stiffness", Interpreter="latex", FontSize=20)
% subtitle(spider_name, Interpreter="latex")
subtitle(strcat("CNT",spider_name), Interpreter="latex")


Kms_a = kms_vera(:,1);
if json.ar_flag
    Kms_r = kms_vera(:,2);
end
displ = x_vera(:,1);

end