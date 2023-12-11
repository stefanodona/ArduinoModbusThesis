close all; 
% clear; clc

filename = "Prova50_ST_07714532B";
% FID=fopen("Prova14_ST_07714532B\Prova14_ST_07714532B.txt");
FID=fopen(strcat(filename,"/",filename,".txt"));
% FID=fopen("Prova16_ST_0714532B\Prova16_ST_0714532B.txt");
datacell = textscan(FID, '%f%f%f', CommentStyle='#'); 
fclose(FID);

x_pres = datacell{1};
force_forw_pres = datacell{2};
kms_presunta = force_forw_pres./x_pres;

figure();
plot(x_pres, kms_presunta)
grid on
title("$K_{ms}$ misurata", Interpreter="latex")


figure()
plot(x_pres, force_forw_pres, '*-')
grid on
title("forza contro x")

f_pos = force_forw_pres(force_forw_pres>0);
f_neg = force_forw_pres(force_forw_pres<0);

f_p = f_pos(1);
f_n = f_neg(end);

x_p = x_pres(force_forw_pres==f_p);
x_n = x_pres(force_forw_pres==f_n);

x_0 = x_n + ((x_p-x_n)./(f_p-f_n))*(-f_n);
hold on
plot(x_0,0, 'o')


x_ricostruita = x_pres - x_0;
hold on
plot(x_ricostruita, force_forw_pres, '-')


figure()
plot(x_ricostruita, force_forw_pres./x_ricostruita)
grid on
title("K_{ms} ricostruita")

kms_diff = diff(force_forw_pres)./diff(x_pres);
x_nuova =  x_pres(1:end-1)-0.05;


figure()
plot(x_nuova, kms_diff)
grid on
%%
idx_p = find(x_nuova<0.5 & x_nuova>-0.5);
x_p_tofit = x_nuova(idx_p);
k_p_tofit = kms_diff(idx_p);

func_to_fit = 1./k_p_tofit;

fitted = fit(x_p_tofit, func_to_fit, 'poly1')

func = feval(fitted, x_nuova).^(-1);
% hold on
% plot(x_nuova, func)

legend("K_{ms} diff", "K_{ms} fitted")
title("Differential Stiffness")
% x_p_tofit = x_p_tofit(x_p_tofit>0);

%%
close all
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


% kms_diff_vera = diff(f_vera)./diff(x_vera);
kms_diff_vera = gradient(f_vera, x_vera);
kms_pres = f_vera./x_pres;
kms_vera = f_vera./x_vera;

fit_obj = fit(x_vera, kms_diff_vera, 'poly5');

poly_deg = 4;

coeff = polyfit(x_vera, kms_diff_vera, poly_deg);

coeff_stiff = zeros(poly_deg+1,1);
coeff_div = linspace(poly_deg+1, 1, poly_deg+1);

for i = 1 : poly_deg+1
    coeff_stiff(i)=coeff(i)./coeff_div(i); 
end

stiff_vera = polyval(coeff_stiff, x_vera+x_0);
forza_post_processata = stiff_vera.*(x_vera+x_0) + f_0;


err_forza = force_forw_pres - forza_post_processata;

figure()
plot(x_pres, err_forza)
title("errori")
grid on

figure();
plot(x_pres, polyval(coeff, x_pres))
hold on
plot(x_pres, stiff_vera)
hold on
plot(x_pres, kms_presunta)
% hold on
% plot(x_presCopy, kms_presuntaCopy)

legend("Fit incrementale", "fit reale", "presunta", "presunta decimata")
title("Confronto K_{ms}")
grid on

figure()
plot(x_pres, force_forw_pres)
hold on
plot(x_pres, forza_post_processata, '--')
grid on

kms_fit = feval(fit_obj, x_vera);

figure()
plot(x_pres, force_forw_pres, x_vera, force_forw_pres, x_vera, f_vera)
grid on
legend("x_p F_p", "x_v F_p", "x_v F_v")
xlim([-0.1,0.1])
title("Forze varie")

figure();
% plot(kms_presunta)
% hold on
plot(x_vera, kms_diff_vera)
hold on
% plot(x_vera, kms_vera)
% hold on
plot(x_vera, kms_fit)
title("$K_{ms}$", Interpreter="latex")
% legend("presunta", "vera", "fit")
legend("diff_{vera}", "fit")
grid on
xlabel("$x$ [mm]", Interpreter="latex");ylabel("$K_{ms}$ [N/mm]", Interpreter="latex");
% legend("presunta", "post presunta", "vera")

weights = zeros(length(x_vera), 1);
weights(find(x_vera>0.5 | x_vera<-0.5))=1;