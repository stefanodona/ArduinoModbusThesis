close all; clear; clc


myFolders = dir("CR*");
% length(myFolders)
% myFolders(1).name
len = length(myFolders);
stiff = zeros(1,len);
f= zeros(1,len);
pos = zeros(1,len);
figure()

for i=1:len
    foldername = myFolders(i).name;
    filename = strcat(foldername,'/',foldername,'.txt');

    pos_name = foldername(4:end-2);
    if(pos_name(1)=='m') pos_name(1)='-'; end
    pos(i) = str2num(pos_name);

    FID=fopen(filename);
    datacell = textscan(FID, '%f%f%f', CommentStyle='#'); 
    fclose(FID);
    
    time = datacell{1};
    force = datacell{2};
    stiffness = datacell{3};

%     stiff(i) = stiffness(12);
    stiff(i) = stiffness(50);
    f(i) = force(50);
    plot(time, force);
    hold on
end

legend(myFolders.name)

[pos,I] = sort(pos);
stiff = stiff(I);
f = f(I);

figure(2)
plot(pos, stiff)
grid on


figure(3);
plot(pos, f)
grid on

%%
f_positive = f(f>0);
f_negative = f(f<0);

f_p = f_positive(1);
f_n = f_negative(end);

x_p = pos(f==f_p);
x_n = pos(f==f_n);

x_0 = x_n + (x_p-x_n)/(f_p-f_n)*(-f_n);

new_pos = pos-x_0;
new_stiff = f./new_pos;

figure(2)
hold on
plot(new_pos,new_stiff)






