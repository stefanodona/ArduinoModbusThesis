clear; close all; clc;
% deflessione reale del centratore che noi non possiamo indagare
N_punti = 70;
x_vera = -5:0.25:5;  
x_vera = x_vera(x_vera~=0);

% kms_vera = @(x) 0.0282 * x.^2 - 0.01402 * x +   2.938;

kms_vera = @(x) 0.02903 * x.^2 - 0.03194 * x +   3.019;

forza_vera = kms_vera(x_vera).*x_vera;

figure(1);
plot(x_vera, forza_vera, '.-')
grid on
xlabel("displacement [mm]")
ylabel("Force [N]")


% x_offset = -0.01; % mm
% x_offset = -0.011235955056180;
x_offset = 0.011809713905522;
tare = kms_vera(x_offset)*x_offset; % forza pre esercitata dal centratore
% che io considero come tara iniziale e come riferimento, perciò la forza
% presunta (ovvero misurata) sarà riferita a quel valore lì

% asse x costruita sperimentalmente che differisce da x_vera 
% di una quantità x_offset
x_presunta = x_vera-x_offset;

% questa x_presunta fa sì che il mio centratore già eserciti una forza
% sulla cella di carico che io considero essere la mia tara "tare"

% a questo punto la forza presunta, ovvero quella che vado a misurare non è
% altro che la kms_vera (proprietà dell'oggetto) di x_presunta moltiplicata
% appunto per x_presunta

forza_presunta = kms_vera(x_presunta).*x_presunta - tare;
% forza_presunta = kms_vera(x_vera).*x_vera;

hold on
plot(x_vera, forza_presunta, '.-')

legend("vera", "presunta")


% se adesso andassi a calcolarmi la kms misurata però sarebbe la forza
% presunta tolta della tara, fratto la x_presunta(???)

kms_presunta = (forza_presunta)./x_presunta;

figure(2)
plot(x_vera, kms_vera(x_vera));
hold on
plot(x_vera, kms_presunta);
grid on
legend("vera", "presunta")


%% ok abbiamo trovato come sono corrotti i dati 
% adesso bisogna essere in grado di tornare indietro 

% partiamo dal fatto di avere la forza presunta come unico dato 

x_positive = x_vera(x_vera>0);
x_negative = x_vera(x_vera<0); 

x_2 = x_positive(1);
x_1 = x_negative(end);

F_2 = forza_presunta(x_vera==x_2);
F_1 = forza_presunta(x_vera==x_1);

F_0 = (F_1+F_2)/2;

figure(1)
hold on
yline(F_0, 'k--')
hold on
plot(x_vera, forza_presunta-F_0, '--')

%%
f_positive = forza_presunta(forza_presunta>0);
f_negative = forza_presunta(forza_presunta<0);

f_2 = f_positive(1);
f_1 = f_negative(end);

x_2 = x_presunta(forza_presunta==f_2);
x_1 = x_presunta(forza_presunta==f_1);

x_0 = x_1 + (x_2-x_1)./(f_2-f_1)*(-f_1);

hold on
plot(x_presunta-x_0, forza_presunta, '-.')

x_postprocessata = x_presunta-x_0;

nuova_kms = forza_presunta./x_postprocessata;

figure(2)
hold on
plot(x_postprocessata, nuova_kms)

