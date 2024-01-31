close all; clc; clear;
load MisureRilassamento_GRPCNT145.mat
% load MisureRilassamento_HM077x145x38.mat
% load MisureRilassamento_cnt077145.mat

spidername = "GRPCNT1454A-2";
% spidername = "07714532C-1";
% spidername = "HM077x145x38AA-1";
coeff = retrieveFittedParameters(data, spidername, 'poly4')

% displ = 1e-3*(-11:0.25:11);
displ = 1e-3*(-9:0.25:9);
total_stiff = zeros(1, length(displ));


close all
figure()

for ii=1:5
    subplot(2,3,ii)
    stiff = polyval(coeffvalues(coeff{2,ii}), displ);
    if ii==1
        k_0 = stiff;
    end
    plot(displ, stiff)
    grid on
    title("$"+coeff{1,ii}+"(x)$", Interpreter="latex")
    xlabel("displacement [m]", Interpreter="latex")
    ylabel("stiffness [N/m]", Interpreter="latex")
    ylim([0, 1.1*max(stiff)])

    total_stiff = total_stiff+stiff;
end
sgtitle("Stiffness "+spidername, Interpreter="latex")

figure()
for ii=1:4
    subplot(2,2,ii)
    res = polyval(coeffvalues(coeff{2,ii+5}), displ);
    plot(displ, res)
    grid on
    title("$"+coeff{1,ii+5}+"(x)$", Interpreter="latex")
    xlabel("displacement [m]", Interpreter="latex")
    ylabel("resistance [N*s/m]", Interpreter="latex")

    ylim([0, 2*max(res)])
end
sgtitle("Resistance "+spidername, Interpreter="latex")



figure()
plot(displ, total_stiff)
hold on
plot(displ, k_0)
title("$K_{ms}(x)$", Interpreter="latex")
subtitle(spidername,  Interpreter="latex")
xlabel("displacement [m]", Interpreter="latex")
ylabel("stiffness [N/m]", Interpreter="latex")
grid on
legend(["K_{total}", "K_0"])


