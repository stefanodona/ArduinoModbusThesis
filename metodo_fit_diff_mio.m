close all; 
clear; clc

filename = "Prova53_ST_07714532C";
FID=fopen(strcat("Prove_Preliminari/",filename,"/",filename,".txt"));
datacell = textscan(FID, '%f%f%f%f%f', CommentStyle='#'); 
fclose(FID);

x_pres = datacell{1};
force_forw_pres = datacell{3};
kms_presunta = force_forw_pres./x_pres;
kms_max = max(kms_presunta);
kms_min = min(kms_presunta);

x_max = x_pres(kms_presunta==kms_max);
x_min = x_pres(kms_presunta==kms_min);

x_0 = (x_max+x_min)/2;

x_vera = x_pres - x_0;

x_pos = x_vera(x_vera>0);
x_neg = x_vera(x_vera<0);

x_p = x_pos(1);
x_n = x_neg(end);

f_p = force_forw_pres(x_vera==x_p);
f_n = force_forw_pres(x_vera==x_n);

f_0 = f_n + (f_p-f_n)/(x_p-x_n)*(-x_n);

f_vera = force_forw_pres - f_0;

kms_diff = gradient(f_vera, x_vera);

deg = 6;
c_fit_diff = polyfit(x_vera, kms_diff, deg);
c_fit = zeros(deg+1, 1);

for i=1:deg+1
    c_fit(end-i+1) = c_fit_diff(end-i+1)/i;
end

kms_from_fit = polyval(c_fit, x_vera);
kms_presunta_from_fit = polyval(c_fit, x_vera+x_0);

f_from_fit = kms_from_fit.*x_vera;
f_presunta_from_fit  = kms_presunta_from_fit .* (x_vera+x_0) + f_0; 



figure()
subplot 121
plot(x_pres, force_forw_pres)
grid on
title("forza misurata")
subplot 122
plot(x_pres, kms_presunta)
grid on
title("K_{ms} misurata")

figure()
plot(x_vera, kms_diff)
hold on
plot(x_vera, polyval(c_fit_diff, x_vera))
grid on
title("K_{ms} differenziale")
legend("misurata", "fit")


figure()
plot(x_pres, force_forw_pres)
hold on
plot(x_vera+x_0, f_presunta_from_fit, '--')
grid on
title("Forza elastica")
legend("misurata", "ricostruita")

figure()
stem(x_pres, force_forw_pres-f_presunta_from_fit)
grid on
title("errori sulla forza")


kms_presunta_ricostruita = f_presunta_from_fit./(x_vera+x_0);
figure()
plot(x_pres, kms_presunta)
hold on
plot(x_pres, kms_presunta_ricostruita, '--')
grid on
title("K_{ms} non incrementale")
legend("misurata", "ricostruita")

figure()
stem(x_pres, kms_presunta-kms_presunta_ricostruita)
grid on
title("errori sulla K_{ms}")



figure()
plot(x_pres, kms_presunta)
hold on
plot(x_pres, kms_presunta_from_fit)
grid on


