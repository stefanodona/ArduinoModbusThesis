clear; close all; clc;

myFolders = dir("CREEP/07714532B-1/Creep*");

idx=2;

filename = myFolders(idx).name;
folder = strcat(myFolders(idx).folder, "/", filename);

FID = fopen(strcat(folder,"/",filename,".txt"));
datacell = textscan(FID, '%f%f%f', CommentStyle='#'); 
fclose(FID);

x = datacell{1};
f = datacell{2};

x = x(4:end);
f = f(4:end);

info = split(filename, "_");
cnt = info{3};
displ = info{2}(1:end-2);

figure()
semilogx(x,f)
grid on
% hold on
% semilogx(x,2.2+0.4*exp(-x/3.5e3)+0.3*exp(-x/700e3))