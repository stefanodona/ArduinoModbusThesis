close all; clear; clc;
% QUESTO SCRIPT SI PROPONE DI VERIFICARE COME VARIANO I PARAMETRI TROVATI
% NEL FIT ESPONENZIALE IN FUNZIONE DELLA FINESTRA DI OSSERVAZIONE
%
% Si andrà a controllare l'effetto e il numero di esponenziali a 
% 2 min
% 5 min
% 10 min
% 30 min
% 60 min
%
% estrapolandoli da una misura durata un'ora


% file loading
filename = "CREEP_1h_2024-01-22/Creep_5mm_07714532B-1_1h/Creep_5mm_07714532B-1_1h.txt";

FID = fopen(filename);
datacell = textscan(FID, '%f%f%f', CommentStyle='#');
fclose(FID);

% recupero dei dati e pulizia degli errori
time    = datacell{1};
force   = -datacell{2};

time    = time(4:end)/1000;
force   = force(4:end);

upper_bound = force(1)   + 1;
lower_bound = force(end) - 1;

ind_to_delete = find(force>upper_bound | force<lower_bound);

time(ind_to_delete)  =  [];
force(ind_to_delete) =  [];

figure()
plot(time, force)

%%

window_02m = 2*60;        % [s]
window_05m = 5*60;        % [s]
window_10m = 10*60;       % [s]
window_30m = 30*60;       % [s]
window_60m = 60*60;       % [s]

ind_02m    = find(time<window_02m);
ind_05m    = find(time<window_05m);
ind_10m    = find(time<window_10m);
ind_30m    = find(time<window_30m);
ind_60m    = find(time<window_60m);


t_fit_02m = time(ind_02m);
f_fit_02m = force(ind_02m);

t_fit_05m = time(ind_05m);
f_fit_05m = force(ind_05m);

t_fit_10m = time(ind_10m);
f_fit_10m = force(ind_10m);

t_fit_30m = time(ind_30m);
f_fit_30m = force(ind_30m);

t_fit_60m = time(ind_60m);
f_fit_60m = force(ind_60m);


