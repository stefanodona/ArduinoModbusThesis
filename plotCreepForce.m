close all; clear; clc;

main_folder = "CREEP_1h_2024-01-22";
spidername  = "07714532B-1";
foldername  = "Creep_5mm_"+spidername+"_1h";
filename    = "Creep_5mm_"+spidername+"_1h.txt";
path        = main_folder+"/"+foldername+"/"+filename;

displ_name  = "5mm";
displ       = 5;


FID         = fopen(path);
datacell    = textscan(FID, '%f%f%f', CommentStyle='#'); 
fclose(FID);

t = datacell{1};
f = datacell{2};

t = t(5:end)/1000;
f = -sign(displ)*f(5:end);

upper_bound = f(1) + 1;
lower_bound = f(end) - 1;

ind_to_delete = find(f>upper_bound | f<lower_bound);

t(ind_to_delete)=[];
f(ind_to_delete)=[];

figure()
plot(t,f, LineWidth=1.5)
grid on
ylabel("Force [N]", Interpreter="latex", FontSize=14)
xlabel("Time [s]", Interpreter="latex", FontSize=14)
title("CNT"+spidername, Interpreter="latex", FontSize=20)
subtitle(strcat("at x=", displ_name), Interpreter="latex", FontSize=12)