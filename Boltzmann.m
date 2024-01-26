close all;
clear;
clc;

load 07714532B-1_polycoeff.mat

K_ms = @(x,t)   polyval(k0,x) + ... % k0(x)
                polyval(k1,x).*exp(-t.*polyval(k1,x)./polyval(r1,x))+... % k1(x)*exp(-t*r1(x)/k1(x))
                polyval(k2,x).*exp(-t.*polyval(k2,x)./polyval(r2,x))+... % k2(x)*exp(-t*r2(x)/k2(x))
                polyval(k3,x).*exp(-t.*polyval(k3,x)./polyval(r3,x))+... % k3(x)*exp(-t*r3(x)/k3(x)) 
                polyval(k4,x).*exp(-t.*polyval(k4,x)./polyval(r4,x));    % k4(x)*exp(-t*r4(x)/k4(x))

% syms x t eps z
% 
% K_ms_sym(x,t) = poly2sym(k0,x) + ... % k0(x)
%                 poly2sym(k1,x).*exp(-t.*poly2sym(k1,x)./poly2sym(r1,x))+... % k1(x)*exp(-t*r1(x)/k1(x))
%                 poly2sym(k2,x).*exp(-t.*poly2sym(k2,x)./poly2sym(r2,x))+... % k2(x)*exp(-t*r2(x)/k2(x))
%                 poly2sym(k3,x).*exp(-t.*poly2sym(k3,x)./poly2sym(r3,x))+... % k3(x)*exp(-t*r3(x)/k3(x)) 
%                 poly2sym(k4,x).*exp(-t.*poly2sym(k4,x)./poly2sym(r4,x));    % k4(x)*exp(-t*r4(x)/k4(x))



f_s = 1000; % [Hz]

f = 10;
A = 11e-3;
t_end = 1;

time = 0 : 1/f_s : t_end;
displ = A*sin(2*pi*f*time);

a = 20;
b = 0.1;
exp_1   = b*exp(time(time<=t_end/2)/a);
exp_2   = b*exp(-(time(time>t_end/2)-time(end))/a);
exp_fun = [exp_1,exp_2];

% displ = displ.*exp_fun;
% 
% 
% 
% plot(time, displ)

resp = zeros(1,numel(time));
% d_resp = zeros(numel(time),numel(time));
% for ii = 2:numel(time) 
% %     d_resp = zeros(1,numel(time));
% %     for jj = 2:numel(time)
%         d_resp(ii,:) = K_ms(disp(ii), time-time(ii)).*(disp(ii)-disp(ii-1));
% %     end
% %     resp = resp+d_resp;
% end


% figure()
% for ii=2:numel(time)
%     for jj=1:ii-1
%         resp(ii:end) = resp(ii:end) + K_ms(displ(jj), time(ii:end)-time(jj)).*(displ(jj+1)-displ(jj));
% %         resp(ii:end) = resp(ii:end) + K_ms(displ(jj), time(ii:end)-time(jj)).*displ(jj);
% %         disp(jj);
%     end
% 
%     if ii==3
%         plot(time, resp);
%         hold on
% %         plot(time, displ);
%     end
% end

% zeta = time;
% d_x = gradient(displ, zeta);
% 
% 
% close all
% figure()
% for ii=2:numel(time)
% %     resp(ii:end) = cumtrapz(zeta(ii:end), K_ms(displ(ii:end), time(ii:end)-zeta(ii:end)).*d_x(ii:end));
% 
%     d_resp(ii,:) = cumtrapz(time, K_ms(displ(ii), time-zeta(ii)).*d_x(ii));
% 
%     if mod(ii, 10)==0
%         plot(time, d_resp(ii,:));
%         hold on
%         %         plot(time, displ);
%     end
% end
% 
% resp = sum(d_resp, 2);

% resp = sum(d_resp, 2);
% figure()
% for jj = 1:10:100
%     plot(time, d_resp(jj,:));
%     hold on
% end
% grid on
% legend

% figure()
% plot(time, disp)
% % % 


% for ii = 2:length(time)
%     aux_t = 0:1/f_s:time(ii);
%     ind = find(time<=aux_t(end));
% 
%     fun = K_ms(displ(ii), time(ind)-aux_t).*gradient(displ(ind), aux_t);
%     resp(ii) = trapz(aux_t, fun);
% 
% end

for ii = 1:length(time)

    for jj = 1:ii
        resp(ii) = resp(ii) + K_ms(displ(jj), time(ii)-time(jj))*(displ(jj)-displ(jj-1));
    end

end

%%

close all
% figure()
% plot(time, fun)


figure()
plot(time, resp)
hold on
plot(time, displ*1e3)
title("Total force response", Interpreter="latex")
xlabel("time [s]", Interpreter="latex")
ylabel("force [N]", Interpreter="latex")
grid on
% ylim([-20,20])

num=2;

figure()
plot(displ(end-f_s*num/f:end), resp(end-f_s*num/f:end))
title("force vs displ response", Interpreter="latex")
xlabel("displacment [m]", Interpreter="latex")
ylabel("force [N]", Interpreter="latex")
grid on
% ylim([0, 10000])