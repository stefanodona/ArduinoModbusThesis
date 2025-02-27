close all; 
clear; clc

% filename = "Prova72_ST_07714532B-2";
filename = "Prova2_ST_07714532B";
% filename = "ST01_07714532B-1";
% FID = fopen(strcat("Measures/",filename,"/",filename,".txt"));
FID = fopen(strcat("Prove_Preliminari/",filename,"/",filename,".txt"));
datacell = textscan(FID, '%f%f%f%f%f%f%f%f', CommentStyle='#'); 
fclose(FID);

x_pres = datacell{1};
force_forw_pres = datacell{2};
% force_forw_pres = datacell{3};
% std_force = datacell{4};
% x_pres_back = datacell{5};
% force_back_pres = datacell{7};

kms_presunta = -force_forw_pres./x_pres;
% kms_presunta_back = -force_back_pres./x_pres_back;

figure()
% plot(x_pres, force_forw_pres)
plot(x_pres, force_forw_pres)
hold on
% plot(x_pres_back, force_back_pres)
grid on
title("Forza elastica F_{el}")
subtitle("misurata")
xlabel("x [mm]", Interpreter="latex")
ylabel("$F_{el}(x)$ [N]", Interpreter="latex")


%%
f_pos = force_forw_pres(force_forw_pres>0);
f_neg = force_forw_pres(force_forw_pres<0);

f_p = f_pos(end);
f_n = f_neg(1);

x_p = x_pres(force_forw_pres==f_p);
x_n = x_pres(force_forw_pres==f_n);

x_0 = x_n + ((x_p-x_n)./(f_p-f_n))*(-f_n);

x_vera = x_pres-x_0;

kms_aggiustata = -force_forw_pres./x_vera;

kms_presunta_diff = gradient(-force_forw_pres, x_vera);

deg = 3;
c_fit_diff = polyfit(x_vera, kms_presunta_diff, deg);
c_fit = zeros(deg+1, 1);

kms_diff_fit = polyval(c_fit_diff, x_vera);

for i=1:deg+1
    c_fit(end-i+1) = c_fit_diff(end-i+1)/i;
end
c_fit_fit = polyfit(x_vera, kms_aggiustata, deg);

kms_from_fit = polyval(c_fit, x_vera);
kms_aggiustata_fit = polyval(c_fit_fit, x_vera);

figure();
plot(x_pres, kms_presunta)
hold on
plot(x_pres, kms_aggiustata)
hold on
plot(x_pres, kms_from_fit)
hold on
plot(x_pres, kms_aggiustata_fit)
grid on
legend("misurata", "aggiustata", "fit + int", "agg fit")
xlabel("x [mm]", Interpreter="latex")
ylabel("$K_{ms}(x)$ [N/mm]", Interpreter="latex")
title("K_{ms}")

figure();
plot(x_vera, kms_presunta_diff)
hold on
plot(x_vera, kms_diff_fit)
grid on
legend("diff", "diff_{fit}")
xlabel("x [mm]", Interpreter="latex")
ylabel("$K_{ms, diff}(x)$ [N/mm]", Interpreter="latex")
title("K_{ms} incrementale")


figure()
subplot 211
stem(x_pres, kms_aggiustata-kms_from_fit)
grid on
title ("Errori K_{ms} aggiustata e fittata")
subplot 212
stem(x_pres, kms_presunta_diff-kms_diff_fit)
grid on
title ("Errori K_{inc, ms} aggiustata e fittata")



%% optimal degree of polynomial

min_deg = 3;
max_deg = 9;

% evaluation of r2
% sst = sum((kms_aggiustata-mean(kms_aggiustata)).^2);
% ssr = sum((kms_aggiustata-kms_aggiustata_fit).^2);
% 
% R2 = 1-ssr/sst;


% sono girate perché la forza è girata
x_neg = x_p-x_0;
x_pos = x_n-x_0;

kms_neg = kms_aggiustata(x_vera==x_neg);
kms_pos = kms_aggiustata(x_vera==x_pos);

kms_in_0 = (kms_neg+kms_pos)/2;
idx_neg = find(x_vera==x_neg);

x_vera(idx_neg)=0;
x_vera(idx_neg+1)=[];

kms_aggiustata(idx_neg) = kms_in_0;
kms_aggiustata(idx_neg+1) = [];

R2 = 0;
deg = min_deg;
while R2<=0.9995
    if deg>max_deg
        break;
    end
    coeff = polyfit(x_vera, kms_aggiustata, deg);
    
    kms_fit = polyval(coeff, x_vera);

    sst = sum((kms_aggiustata-mean(kms_aggiustata)).^2);
    ssr = sum((kms_aggiustata-kms_fit).^2);
    
    R2 = 1-ssr/sst;
    deg = deg+1;
end

close all
figure()
plot(x_vera, kms_aggiustata)
hold on
plot(x_vera, kms_fit)
grid on
legend("misurata", "fittata")


