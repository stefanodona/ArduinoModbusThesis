close all; 
clear; clc

% PROVA di confronto degli errori nel fit e nella forza tra metodo di
% centraggio della curva solo con offset nelle x, oppure con offset sia x
% che f. Poi viene sempre applicato il metodo differenziale

filename = "Prova47_ST_07714532B";
FID=fopen(strcat(filename,"/",filename,".txt"));
datacell = textscan(FID, '%f%f%f', CommentStyle='#'); 
fclose(FID);

x_pres = datacell{1};
force_forw_pres = datacell{2};
kms_presunta = force_forw_pres./x_pres;


%% metodo solo x
f_pos = force_forw_pres(force_forw_pres>0);
f_neg = force_forw_pres(force_forw_pres<0);

f_p = f_pos(1);
f_n = f_neg(end);

x_p = x_pres(force_forw_pres==f_p);
x_n = x_pres(force_forw_pres==f_n);

x_0 = x_n + ((x_p-x_n)./(f_p-f_n))*(-f_n);
x_vera = x_pres - x_0;

kms_diff_x = gradient(force_forw_pres, x_vera);


% FIT
deg = 4;
c_fit_diff = polyfit(x_vera, kms_diff_x, deg);
c_fit = zeros(deg+1, 1);

for i=1:deg+1
    c_fit(end-i+1) = c_fit_diff(end-i+1)/i;
end

kms_from_fit = polyval(c_fit, x_vera);
kms_presunta_from_fit = polyval(c_fit, x_pres);



forza = kms_presunta_from_fit.*x_pres;

figure();
plot(x_vera, kms_diff_x);
hold on
plot(x_vera, polyval(c_fit_diff, x_vera));
grid on
title("K_{ms} incrementale")
legend("misurata", "fit")


figure()
plot(x_pres, kms_presunta)
hold on
plot(x_vera, kms_from_fit)
grid on
title("K_{ms} non incrementale")
legend("misurata", "fit")

figure()
plot(x_pres, force_forw_pres)
hold on
plot(x_pres, forza, '--')
grid on
title("Forza elastica")
legend("misurata", "ricostruita dal fit")

figure()
plot(x_pres, force_forw_pres-forza)
hold on
avg = mean(force_forw_pres-forza);
plot(x_pres, ones(length(force_forw_pres),1)*avg, '--')
grid on
title("Errori sulla stima della forza")






