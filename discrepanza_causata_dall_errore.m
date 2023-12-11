x=-4:.25:4;
x = x(x~=0);

stiff = @(x) fit_obj.p1*x.^2 + fit_obj.p2*x + fit_obj.p3; 
close all
% figure();
% plot(x, stiff(x))
% grid on

force = stiff(x).*x;


%% introduciamo un errore
% tendenzialmente il pistone sbaglia di 2-3 punti quando si considera
% arrivato: è quindi facile capire quanto sia lo l'errore di spostamento
% introdotto

err_x = (3*5)/2048; % [mm]

% mentre la cella di carico dichiara di avere il 0.05% d'errore sul
% fondoscala, in questo caso 3kg

err_f = 10*9.81*0.03/100;


x_con_err = x-err_x;
f_con_err = stiff(x_con_err).*x_con_err-err_f;

figure()
plot(x, stiff(x))
hold on
plot(x_con_err, f_con_err./x_con_err)
grid on

hold on
plot(x_pres, force_forw_pres./x_pres)
hold on
plot(x_pres, kms_fvera)

legend("ideale", "ideale con errore", "misurata", "post processata")

%% f_vera_vera

f_vera_vera = f_vera-err_f;
x_vera_vera = x_vera+err_x
hold on
plot(x_vera_vera, f_vera_vera./x_vera_vera)


%%
figure()
plot(x, )
