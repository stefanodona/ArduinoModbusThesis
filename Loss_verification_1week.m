load MisureRilassamento_cnt077145.mat

coeff = [data(1).cnt(13).params.model_coeff.value]
displ = coeff(1);

k0 = 1/coeff(2);
k1 = 1/coeff(3);
k2 = 1/coeff(4);
k3 = 1/coeff(5);
k4 = 1/coeff(6);

r1 = coeff(7);
r2 = coeff(8);
r3 = coeff(9);
r4 = coeff(10);

k_s = [k0,k1,k2,k3,k4];
r_s = [r1,r2,r3,r4];


loss = 0.055;
percent = 1-loss;

k_p = k_s*percent;
% k_p = k_s;
k_p(2:end) = k_s(2:end)*percent;

loss = 0.01;
percent = 1-loss;
r_p = r_s*percent;


x = 0.005;
time = 0:0.01:300;

f_s =   x * k_s(1) + ...
        x * k_s(2) * exp(-time*k_s(2)/r_s(1)) + ...
        x * k_s(3) * exp(-time*k_s(3)/r_s(2)) + ...
        x * k_s(4) * exp(-time*k_s(4)/r_s(3)) + ...
        x * k_s(5) * exp(-time*k_s(5)/r_s(4));

f_p =   x * k_p(1) + ...
        x * k_p(2) * exp(-time*k_p(2)/r_p(1)) + ...
        x * k_p(3) * exp(-time*k_p(3)/r_p(2)) + ...
        x * k_p(4) * exp(-time*k_p(4)/r_p(3)) + ...
        x * k_p(5) * exp(-time*k_p(5)/r_p(4));



figure();
plot(time, f_s);
hold on
plot(time, f_p);

grid on
title("distanza di 10 giorni simulati")
legend("100%", "95%")


figure();
plot(time, (f_s-f_p));
title ("uno meno l'altro simulato")
grid on