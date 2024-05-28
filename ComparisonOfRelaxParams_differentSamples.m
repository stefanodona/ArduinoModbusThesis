close all
clear; clc;

% load MisureRilassamento_GRPCNT145.mat
load MisureRilassamento_HM077x145x38.mat
% load MisureRilassamento_cnt077145.mat
% save_path = "C:\Users\stefa\Desktop\Donà Stefano - Master Thesis\Images\chapter04\relax";
save_path = "C:\Users\stefa\Desktop\Donà Stefano - Master Thesis\Images\appendix\comparisons";
save_svg = 0;

% model = "AB";
model = "AA";
% model = "4A";
% model = "B-C"
% model = "AA-AB"

% if model=="AA"
%     i1=1;
%     i2=2;
% else
%     i1=3;
%     i2=4;
% end

i1=1;
i2=2;


model1_name = char(data(i1).name)
model2_name = char(data(i2).name)
model1_name = model1_name(end-3:end);
model2_name = model2_name(end-3:end);

%%
close all

figure(1)
hold on
plot(data(i1).x, data(i1).Ks(1).curve, LineWidth=1.1)
plot(data(i2).x, data(i2).Ks(1).curve, LineWidth=1.1)
grid on
title("$K^{(0)}$ Comparison", Interpreter="latex", FontSize=20)
subtitle("between "+model+" samples", Interpreter="latex", FontSize=16)
xlabel("$x$ [mm]", Interpreter="latex", FontSize=14)
ylabel("$K$ [N/mm]", Interpreter="latex", FontSize=14)
legend([model1_name; model2_name],Interpreter="latex", FontSize=12)
ylim([0,7])
% if save_svg saveas(gcf, save_path+"\relax_K0_comparison_"+model+".svg", 'svg'), end
if save_svg saveas(gcf, save_path+"\relax_K0_comparison_"+[model1_name,'_', model2_name]+".svg", 'svg'), end


cols = {'#0072BD';
        '#D95319';
        '#EDB120';
        '#7E2F8E'};

fake_x = data(i1).x;
fake_data = 1000*ones(1,length(fake_x));

K=struct();
figure(2)
% Ax(1) = axes(f2);
hold on 
for ii=2:5
    K(ii).p = plot(NaN, NaN, '-', LineWidth=1.5, Color=cols{ii-1})
    plot(data(i1).x, data(i1).Ks(ii).curve, ':', LineWidth=1.5, Color=cols{ii-1})
    plot(data(i2).x, data(i2).Ks(ii).curve, '--', LineWidth=1.1, Color=cols{ii-1})
end
grid on
ylim([0,0.4])
p1 = plot(fake_x, fake_data, 'k:', LineWidth=1.5);
p2 = plot(fake_x, fake_data, 'k--', LineWidth=1.1);
set = [p1(1) p2(1)];
legend(set, [model1_name; model2_name], Interpreter="latex", FontSize=12)
title("$K^{(1,2,3,4)}$ Comparison", Interpreter="latex", FontSize=20)
subtitle("between "+model+" samples", Interpreter="latex", FontSize=16)
xlabel("$x$ [mm]", Interpreter="latex", FontSize=14)
ylabel("$K$ [N/mm]", Interpreter="latex", FontSize=14)

% figure(10)
% a=axes('position',get(gca,'position'),'visible','off');
% axis off
% box off
% legend(a,[K(2).p K(3).p K(4).p K(5).p],'$K^{(1)}$','$K^{(4)}$','$K^{(3)}$', '$K^{(4)}$', Interpreter="latex", FontSize=12, Location='south', Orientation='horizontal');

% if save_svg saveas(gcf, save_path+"\relax_K1234_comparison_"+model+".svg", 'svg'), end
if save_svg saveas(gcf, save_path+"\relax_K1234_comparison_"+[model1_name,'_', model2_name]+".svg", 'svg'), end

figure(3)
R=struct();
for ii=1:4
    semilogy(data(i1).x, data(i1).Rs(ii).curve, ':', LineWidth=1.5, Color=cols{ii})
    hold on
    semilogy(data(i2).x, data(i2).Rs(ii).curve, '--', LineWidth=1.1, Color=cols{ii})
    R(ii).p = semilogy(fake_x, 100*fake_data, '-', LineWidth=1.5, Color=cols{ii})
end
ylim([1e-2,1e4])
p1 = semilogy(fake_x, 100*fake_data, 'k:', LineWidth=1.5);
p2 = semilogy(fake_x, 100*fake_data, 'k--', LineWidth=1.1);
set = [p1(1) p2(1)];
legend(set, [model1_name; model2_name], Interpreter="latex", FontSize=12)
grid on
title("$R^{(1,2,3,4)}$ Comparison", Interpreter="latex", FontSize=20)
subtitle("between "+model+" samples", Interpreter="latex", FontSize=16)
xlabel("$x$ [mm]", Interpreter="latex", FontSize=14)
ylabel("$R$ [Ns/mm]", Interpreter="latex", FontSize=14)

% figure()
% a=axes('position',get(gca,'position'),'visible','off');
% axis off
% box off
% legend(a,[R(1).p R(2).p R(3).p R(4).p],'$R^{(1)}$','$R^{(4)}$','$R^{(3)}$', '$R^{(4)}$', Interpreter="latex", FontSize=12, Location='south', Orientation='horizontal');

% if save_svg saveas(gcf, save_path+"\relax_R1234_comparison_"+model+".svg", 'svg'), end
if save_svg saveas(gcf, save_path+"\relax_R1234_comparison_"+[model1_name,'_', model2_name]+".svg", 'svg'), end
