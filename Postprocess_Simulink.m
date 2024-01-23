close all; clear; clc;

load displacement.mat
load force.mat
load 07714532B-1_polycoeff.mat

f_s =   24000;  % [Hz], frequenza di campionamento 
f   =   10;     % [Hz], frequenza dello stimolo sinusoidale

t = force.Time; % [s], asse dei tempi 

dt = t(2)-t(1); % [s]

forza   = -force.Data; % [N], forza
x       = displ.Data; % [m], spostamento


%% calcolo valore medio per ogni ciclo 

% per un ciclo il valore medio può essere calcolato come l'integrale della
% sinusoide nel periodo, pesata per il periodo

% trovo gli indici temporali per cui il tempo è minore di un periodo.
for ii=1:t(end)*f
    cyc = ii;
    ind = find(t>=(cyc-1)/f & t<cyc/f);
    
    val_medio(ii) = mean(forza(ind));
   
%     figure(1)
%     plot(t(ind), forza(ind))
%     hold on
%     yline(val_medio, 'r--')
%     grid on
end

%%
figure()
plot((1:3000)/f, val_medio)
grid on
xlabel("time [s]")
ylabel("mean force on cycle [N]")
title("Mean force time trend")

%%
close all
figure()
for ii=1:10
    cyc = ii;
    ind = find(t>=(cyc-1)/f & t<cyc/f);
    
    plot(x(ind), -x(ind)./forza(ind))
    hold on
    
end
legend(["ciclo #1",...
        "ciclo #2",...
        "ciclo #3",...
        "ciclo #4",...
        "ciclo #5",...
        "ciclo #6",...
        "ciclo #7",...
        "ciclo #8",...
        "ciclo #9",...
        "ciclo #10"])
grid on
hold off
ylim([0,5e-4])
title("Stiffness variation w/ cycles")
xlabel("displacement [m]")
ylabel("Stiffness [N]")



%%
figure()
plot(x, forza)
