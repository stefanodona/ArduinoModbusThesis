close all; clear; clc;

load MisureRilassamento_cnt077145.mat

cnt_idx = 4;
param_idx = 1;
cnt_name = data(cnt_idx).name
param_name = data(cnt_idx).Ks(param_idx).name

filename = strcat(cnt_name,'_',param_name,'.txt')
% fileID = fopen('output.txt', 'w');
fileID = fopen(filename, 'w');

x = data(cnt_idx).x;
y = data(cnt_idx).Ks(param_idx).curve;

% Scrivere i dati incolonnati nel file
% '%f %f\n' indica che scriviamo due numeri float per riga, separati da uno spazio
for i = 1:length(x)
    fprintf(fileID, '%f %f\n', x(i), y(i));
end

% Chiudere il file
fclose(fileID);