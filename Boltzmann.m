close all;
clear;
clc;

load 07714532B-1_polycoeff.mat

static_folder = "STATICA_2024-01-18/Statica_07714532B-1"
spidername = "07714532B-1";




f = dir(fullfile(static_folder, '*.json'));
fname = strcat(f.folder, '/', f.name);
fid = fopen(fname); 
raw = fread(fid,inf); 
str = char(raw'); 
fclose(fid); 
json = jsondecode(str);

x = 1e-3*(json.min_pos : json.step_pos : json.max_pos);

% SORT DISPLACEMENT
[x_sort, iii] = sort(abs(x), 'descend');
iii=flip(iii);


x_sort = x(iii)';

if json.ar_flag
    x_sort = [x_sort; flip(-x_sort(2:end))];
end

x_long = x_sort;

% LOAD TIMES

times_file = strcat(static_folder, "/times.txt");
FID = fopen(times_file);
times = textscan(FID, '%f%f%f%f%f%f%f%f', CommentStyle='#'); 
fclose(FID);

t_x_rise = [0; times{3}/1000];
t_x_fall = [0; times{5}/1000];
x_measured = [0; times{2}/1000];


to_delete = find(abs(x_measured)>json.max_pos);

if to_delete
    delay = t_x_rise(to_delete(end)) - t_x_rise(to_delete(1));
    
    t_x_rise(to_delete(1):end)=t_x_fall(to_delete(1):end)-delay;
    t_x_fall(to_delete(1):end)=t_x_fall(to_delete(1):end)-delay;

    t_x_rise(to_delete)=[];
    t_x_fall(to_delete)=[];
    x_measured(to_delete)=[];

end


t_final = 300+t_x_fall(end);

dt = 0.1;
time = 0 : dt : t_final;

ind_t_rise = round(t_x_rise, 2)./dt;
ind_t_fall = round(t_x_fall, 2)./dt;

x_sum = zeros(1, length(time));
for ii = 2:length(x_long)
    i_r = int64(ind_t_rise(ii));
    i_f = int64(ind_t_fall(ii));

    x_sum(i_r:i_f) = x_long(ii)*ones(1, int64(i_f-i_r)+1);
end



%%

K_ms = @(x,t)   polyval(k0,x) + ... % k0(x)
                polyval(k1,x).*exp(-t.*polyval(k1,x)./polyval(r1,x))+... % k1(x)*exp(-t*r1(x)/k1(x))
                polyval(k2,x).*exp(-t.*polyval(k2,x)./polyval(r2,x))+... % k2(x)*exp(-t*r2(x)/k2(x))
                polyval(k3,x).*exp(-t.*polyval(k3,x)./polyval(r3,x))+... % k3(x)*exp(-t*r3(x)/k3(x)) 
                polyval(k4,x).*exp(-t.*polyval(k4,x)./polyval(r4,x));    % k4(x)*exp(-t*r4(x)/k4(x))



% f = 0.01;
% A = 11e-3;
% t_end = 10/f;
% 
% f_s = 100*f; % [Hz]
% 
% time = 0 : 1/f_s : t_end-1/f_s;
% displ = A*sin(2*pi*f*time);
% 
% a = 1;
% b = 0.01;
% exp_1   = b*exp(time(time<=t_end/2)/a);
% exp_2   = b*exp(-(time(time>t_end/2)-time(end))/a);
% exp_fun = [exp_1,exp_2];


displ = x_sum;
resp = zeros(1,numel(time));

for ii = 1:length(time)

%     gr = gradient(displ(1:ii));
    gr = [diff(displ(1:ii)),0];
    for jj = 1:ii
%         resp(ii) = resp(ii) + K_ms(displ(jj), time(ii)-time(jj))*(displ(jj)-displ(jj-1));
        resp(ii) = resp(ii) + K_ms(displ(jj), time(ii)-time(jj))*gr(jj);
    end

end

%%
close all
figure()
plot(time, resp)
grid on


t_x_fall = round(t_x_fall,2);
ind = t_x_fall/dt;

half_length = (length(x_long)+1)/2;

stiff_a = zeros(1, half_length);
stiff_r = zeros(1, half_length-1);
    

% ANDATA
for ii=2:half_length
    jj = int64(ind(ii));
    f = resp(jj-2);
    stiff_a(ii) = f/x_long(ii);
end

% RITORNO
for ii=half_length+1:length(x_long)
    jj = int64(ind(ii));
    f = resp(jj-1);
    stiff_r(ii-half_length) = f/x_long(ii);
end

x_to_plot_a = x_long(1:half_length);
x_to_plot_a(1)=[];
stiff_a(1)=[];
[x_long_sorted, x_l_ind] = sort(x_to_plot_a, 'ascend');
K_ms_a = stiff_a(x_l_ind);

x_to_plot_r = x_long(half_length+1:end);
[x_long_sorted, x_l_ind] = sort(x_to_plot_r, 'ascend');
K_ms_r = stiff_r(x_l_ind);

displ = x_long_sorted;
figure()
plot(x_long_sorted*1000, K_ms_a/1000, '-')
if json.ar_flag
    hold on
    plot(x_long_sorted*1000, K_ms_r/1000, '-')
    legend("Andata", "Ritorno")
end
grid on


%%

% close all
% figure()
% plot(time, fun)


% figure()
% plot(time, resp)
% hold on
% plot(time, displ*1e3)
% title("Total force response", Interpreter="latex")
% xlabel("time [s]", Interpreter="latex")
% ylabel("force [N]", Interpreter="latex")
% grid on
% % ylim([-20,20])
% 
% 
% % last mumber of cycles to plot
% num=10;
% 
% figure(4)
% 
% % for ii=1:t_end*f-1
%     num=1;
%     displ_to_plot = displ(end-f_s*num/f+1:end);
%     resp_to_plot = resp(end-f_s*num/f+1:end);
%     
% %     displ_to_plot = displ(f_s*num/f:f_s*(num+1)/f);
% %     resp_to_plot = resp(f_s*num/f:f_s*(num+1)/f);
%     
%     plot(displ_to_plot, resp_to_plot)
%     hold on
%     title("force vs displ response", Interpreter="latex")
%     xlabel("displacment [m]", Interpreter="latex")
%     ylabel("force [N]", Interpreter="latex")
%     grid on
%     ylim([-100, 100])
% %     ylim([0, 7000])
%     xlim([-1.5e-2, 1.5e-2])
% %     pause(0.2);
% % end
