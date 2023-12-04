close all; clear; clc

filename = "Prova22_ST_07714532B";
% FID=fopen("Prova14_ST_07714532B\Prova14_ST_07714532B.txt");
FID=fopen(strcat(filename,"/",filename,".txt"));
% FID=fopen("Prova16_ST_0714532B\Prova16_ST_0714532B.txt");
datacell = textscan(FID, '%f%f%f', CommentStyle='#'); 
fclose(FID);

x_pres = datacell{1};
force_forw_pres = datacell{2};
force_back_pres = datacell{3};
% 
% figure()
% plot(x_pres,force_forw_pres)
% grid on

% f_pos = force_forw_pres(force_forw_pres>0);
% f_neg = force_forw_pres(force_forw_pres<0);
% 
% f_pos(1)
% f_neg(end)

x_pos = x_pres(x_pres>0);
x_neg = x_pres(x_pres<0);

x_p = x_pos(1);
x_n = x_neg(end);

f_p = force_forw_pres(x_pres==x_p);
f_n = force_forw_pres(x_pres==x_n);

f_0 = (f_p+f_n)/2;

f_vera = force_forw_pres - f_0;

figure();
plot(x_pres, force_forw_pres, x_pres, f_vera)
grid on
legend("forza misurata", "forza processata")
xlabel("displacement [mm]")
ylabel("force [N]")


figure()
plot(x_pres, force_forw_pres./x_pres, x_pres, f_vera./x_pres)
grid on
legend("k_{ms} misurata", "k_{ms} processata")
xlabel("displacement [mm]")
ylabel("stiffness [N/mm]")


kms_fvera = f_vera./x_pres;


%%
f_pos = force_forw_pres(force_forw_pres>0);
f_neg = force_forw_pres(force_forw_pres<0);

f_p = f_pos(1);
f_n = f_neg(end);

x_p = x_pres(force_forw_pres==f_p);
x_n = x_pres(force_forw_pres==f_n);

x_0 = x_n + (x_p-x_n)./(f_p-f_n)*(-f_n);


x_vera = x_pres-x_0;

kms_xvera = force_forw_pres./x_vera;


figure()
plot(x_pres, kms_fvera, x_pres, kms_xvera)
grid on
legend("k_{ms} proc su forza", "k_{ms} proc su x")
xlabel("displacement [mm]")
ylabel("stiffness [N/mm]")

%%
% fit_obj = fit(x_vera, kms_xvera, 'cubicin terp')
fit_obj = fit(x_vera, kms_xvera, 'poly2')

kms_fit = feval(fit_obj, x_vera);
figure()
plot(x_vera, kms_xvera, x_vera, kms_fit)
grid on

%%

stiff = @(x) fit_obj.p1 .* x.^2 + fit_obj.p2 .* x + fit_obj.p3;
x_ideale = -7:0.2:7;
x_ideale = x_ideale(x_ideale~=0);

force_ideale = stiff(x_ideale).*x_ideale;

figure()
plot(x_pres, force_forw_pres, x_ideale, force_ideale)
grid on
xline(x_0, 'k--')
legend("pres", "vera")

x_pres_teorica = x_ideale+x_0;
kms_pres_teorica = force_ideale./x_pres_teorica;

figure();
plot(x_pres_teorica, kms_pres_teorica, x_pres, force_forw_pres./x_pres)
grid on
legend("teorica", "misurata")



