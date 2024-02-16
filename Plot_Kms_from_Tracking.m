function [displ, kms_a, kms_r] = Plot_Kms_from_Tracking(spidername, samples, plotting)


% cnt_name = "HM077x145x38AB-2"
cnt_name = spidername;
% LOAD TIMES
track_file = strcat("TRACKING_2024-02-01/Tracking_", cnt_name,"/Tracking_",cnt_name, ".txt");
FID = fopen(track_file);
tracking = textscan(FID, '%f%f%f', CommentStyle='#'); 
fclose(FID);

tracking_time = tracking{3}/1000;
tracking_force = -tracking{2};
tracking_pos = tracking{1};

x = 1e-3*(-11:0.25:11);

% to_ignore = 1/0.25*3*10;
% tracking_time(end-to_ignore+1:end)=[];
% tracking_force(end-to_ignore+1:end)=[];
if plotting
    figure(3)
    plot(tracking_time, tracking_force, '.-', LineWidth=1, MarkerSize=10)
    grid on
    title("Force vs Time", Interpreter="latex", FontSize=20)
    subtitle(cnt_name, Interpreter="latex")
    xlabel("Time [s]", Interpreter="latex", FontSize=14)
    ylabel("Force [N]", Interpreter="latex", FontSize=14)
end
% xlim([202.5,225])



jj          = 0;
acq_per_sec = 10;
nums_sample = 3; 
leg_lab     = [];
% ns = 5;
% for ns = 9:9
nums_sample = samples;

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

x_pos = pos_sorted(pos_sorted>0);
x_neg = pos_sorted(pos_sorted<0);

x_p = x_pos(1)
x_n = x_neg(end)

f_p = force_sorted(pos_sorted==x_p)
f_n = force_sorted(pos_sorted==x_n)

f_0 = f_p - ((f_p-f_n)./(x_p-x_n))*(x_p)
f_vera = force_sorted-f_0;

displ = pos_sorted;
kms_a = f_vera./pos_sorted;
% kms_a = force_sorted./pos_sorted;

if plotting
    figure(1)
    plot(pos_sorted, f_vera)
    hold on
    grid on
    
    figure(2)
    plot(pos_sorted, f_vera./pos_sorted)
    hold on
    grid on
    
    leg_lab = [leg_lab; num2str(ns*100)+" ms andata"]
    % end
    
    figure(2)
    xlabel("displacement $[mm]$", Interpreter="latex", FontSize=14)
    ylabel("stiffness $[N/mm]$", Interpreter="latex", FontSize=14)
    title("Stiffness curve", Interpreter="latex", FontSize=20)
    subtitle(cnt_name, Interpreter="latex", FontSize=14)
    legend(leg_lab, Interpreter="latex")
end


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

x_pos = pos_sorted(pos_sorted>0);
x_neg = pos_sorted(pos_sorted<0);

x_p = x_pos(1)
x_n = x_neg(end)

f_p = force_sorted(pos_sorted==x_p)
f_n = force_sorted(pos_sorted==x_n)

f_0 = f_p - ((f_p-f_n)./(x_p-x_n))*(x_p)
f_vera = force_sorted-f_0;

kms_r = f_vera./pos_sorted;

if plotting
    figure(1)
    plot(pos_sorted, f_vera)
    hold on
    grid on
    
    figure(2)
    plot(pos_sorted, f_vera./pos_sorted)
    hold on
    grid on
    
    leg_lab = [leg_lab; num2str(ns*100)+" ms ritorno"]
    % end
    
    
    figure(2)
    legend(leg_lab, Interpreter="latex", FontSize=12, Location="bestoutside")
end

end