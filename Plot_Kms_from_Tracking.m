function [x_forw, x_back, kms_f, kms_b] = Plot_Kms_from_Tracking(mainfolder, spidername, samples, plotting, fitting, poly_deg)


% cnt_name = "HM077x145x38AB-2"
cnt_name = spidername;
% LOAD TIMES
track_file = strcat(mainfolder, "/Tracking_", cnt_name,"/Tracking_",cnt_name, ".txt");
FID = fopen(track_file);
tracking = textscan(FID, '%f%f%f', CommentStyle='#'); 
fclose(FID);

tracking_time = tracking{3}/1000;
tracking_force = -tracking{2};
tracking_pos = -tracking{1};

x = 1e-3*(-11:0.25:11);
l = length(tracking_time);
% to_ignore = 1/0.25*3*10;
% tracking_time(end-to_ignore+1:end)=[];
% tracking_force(end-to_ignore+1:end)=[];
if plotting
    figure(3)
    plot(tracking_time, tracking_force, '.-', LineWidth=1, MarkerSize=10)
    grid on
    title("Time evolution of force", Interpreter="latex", FontSize=20)
    subtitle(cnt_name, Interpreter="latex")
    xlabel("$t$ [s]", Interpreter="latex", FontSize=14)
    ylabel("$F$ [N]", Interpreter="latex", FontSize=14)
    hold on
    xline(tracking_time(l/2), 'k--', LineWidth=1.1);
    text(tracking_time(3/4*l), 60, "Back. Seq.", Interpreter="latex", FontSize=14, HorizontalAlignment="center")
    text(tracking_time(1/4*l), 60, "Forw. Seq.", Interpreter="latex", FontSize=14, HorizontalAlignment="center")

%     figure(5)
%     plot(tracking_time, tracking_pos, '.-', LineWidth=1, MarkerSize=10)
end
% xlim([202.5,225])


jj          = 0;
acq_per_sec = 10;                 
% acq_per_sec = 50;
nums_sample = 3; 
leg_lab     = [];
% ns = 5;
% for ns = 9:9
nums_sample = samples;
ns = samples;

jj    = 0;
force = [];
pos   = [];
for ii = 1 : length(x)-1
    if mod((jj+1),3)==0
        jj=jj+1;
    end

    ind         = jj*acq_per_sec + nums_sample;
    pos         = [pos,     tracking_pos(ind)];
    force       = [force,   tracking_force(ind)];

    jj = jj+1;
end

[pos_sorted, idx_sorted] = sort(pos, 'ascend');
force_sorted             = force(idx_sorted);
f_forw                   = force_sorted;
x_forw                   = pos_sorted;

kms_f  = -f_forw./x_forw;


% if plotting
%     figure(1)
%     plot(x_forw, f_forw)
%     hold on
%     grid on
%     
%     figure(2)
%     plot(x_forw, f_forw./x_forw)
%     hold on
%     grid on
%     
%     leg_lab = [leg_lab; num2str(ns*100)+" ms forward"]
%     % end
%     
%     figure(2)
%     xlabel("$x$ [mm]", Interpreter="latex", FontSize=14)
%     ylabel("$K$ [N/mm]", Interpreter="latex", FontSize=14)
%     title("Stiffness curve", Interpreter="latex", FontSize=20)
%     subtitle(cnt_name, Interpreter="latex", FontSize=14)
%     legend(leg_lab, Interpreter="latex")
% end


% ritorno
% for ns = 9:9
%     nums_sample = ns;
nums_sample = samples;

jj    = 0;
force = [];
pos   = [];
for ii = 1 : length(x)-1
    if mod((jj+1),3)==0
        jj=jj+1;
    end

    ind         = jj*acq_per_sec + nums_sample + length(tracking_force)/2;
    pos         = [pos,     tracking_pos(ind)];
    force       = [force,   tracking_force(ind)];

    jj = jj+1;
end

[pos_sorted, idx_sorted] = sort(pos, 'ascend');
force_sorted             = force(idx_sorted);
f_back                   = force_sorted;
x_back                   = pos_sorted;

kms_b = -f_back./x_back;

if fitting
    poly6 = 'k6*x^6 + k5*x^5 + k4*x^4 + k3*x^3 + k2*x^2 + k1*x + k0';
    poly4 = 'k4*x^4 + k3*x^3 + k2*x^2 + k1*x   + k0';
    poly3 = 'k3*x^3 + k2*x^2 + k1*x   + k0';
    poly2 = 'k2*x^2 + k1*x   + k0';
    
    if poly_deg ==2
        poly = poly2;
    elseif poly_deg == 3
        poly = poly3;
    elseif poly_deg == 4
        poly = poly4;
    elseif poly_deg == 6
        poly = poly6;
    end

    kms_inc_forw = gradient(-f_forw, x_forw);
    kms_inc_back = gradient(-f_back, x_back);

    fit_obj_forw = fit(x_forw', kms_inc_forw', poly,...
        'Algorithm', 'Levenberg-Marquardt')
    fit_obj_back = fit(x_back', kms_inc_back', poly,...
        'Algorithm', 'Levenberg-Marquardt')

    kms_inc_forw_coeff = flip(coeffvalues(fit_obj_forw));
    kms_inc_back_coeff = flip(coeffvalues(fit_obj_back));
    
    kms_forw_coeff = kms_inc_forw_coeff./flip(1:poly_deg+1)
    kms_back_coeff = kms_inc_back_coeff./flip(1:poly_deg+1)

    kms_forw_fit = polyval(kms_forw_coeff, x_forw);
    kms_back_fit = polyval(kms_back_coeff, x_back);

    kms_f = kms_forw_fit;
    kms_b = kms_back_fit;
end
% 
% if plotting
%     figure(1)
%     plot(x_back, f_back)
%     hold on
%     grid on
%     
%     figure(2)
%     plot(x_back, f_back./x_back)
%     hold on
%     grid on
%     
%     leg_lab = [leg_lab; num2str(ns*100)+" ms backward"]
%     % end
%     
%     
%     figure(2)
%     legend(leg_lab, Interpreter="latex", FontSize=12, Location="bestoutside")
% end

if plotting
    figure(1)
    plot(x_forw, f_forw)
    hold on
    plot(x_back, f_back)
    grid on
    
    figure(2)
    plot(x_forw, f_forw./x_forw, DisplayName=strcat(num2str(ns*100)," ms forward"))
    hold on
    plot(x_back, f_back./x_back, DisplayName=strcat(num2str(ns*100)," ms backward"))
    grid on
    
%     leg_lab = [leg_lab; num2str(ns*100)+" ms forward"]
    % end
    
    figure(2)
    xlabel("$x$ [mm]", Interpreter="latex", FontSize=14)
    ylabel("$K$ [N/mm]", Interpreter="latex", FontSize=14)
    title("Stiffness curve", Interpreter="latex", FontSize=20)
    subtitle(cnt_name, Interpreter="latex", FontSize=14)
    legend(Interpreter="latex", FontSize=12)
end


end