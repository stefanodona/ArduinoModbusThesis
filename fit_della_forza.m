close all; 
clear; clc

filename = "Prova50_ST_07714532B";
FID=fopen(strcat(filename,"/",filename,".txt"));
datacell = textscan(FID, '%f%f%f', CommentStyle='#'); 
fclose(FID);

x_pres = datacell{1};
force_forw_pres = datacell{2};

deg_force = 5;
c_force = polyfit(x_pres, force_forw_pres, deg_force);

