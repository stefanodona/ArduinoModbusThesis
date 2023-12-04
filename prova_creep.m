close all; clear; clc


myFolders = dir("CR*");
% length(myFolders)
% myFolders(1).name
len = length(myFolders);
stiff = zeros(1,len);
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

    stiff(i) = stiffness(12);
    plot(time, force);
    hold on
end

legend(myFolders.name)

[pos,I] = sort(pos);
stiff = stiff(I)

figure()
plot(pos, stiff)






