% table = struct2table(data(1).cnt(1).params.model_coeff)
% table2 = struct2table(data(1).cnt(2).params.model_coeff)

for cnt_index=1:length(myFolders)

    T = struct2table(data(cnt_index).cnt)
    sorted = sortrows(T, "displ_val")
    data(cnt_index).cnt = table2struct(sorted)
    
    x_l = length(data(cnt_index).cnt)
    par_l = length(data(cnt_index).cnt(1).params.model_coeff)
    
    my_table = [];
    
    my_table = struct2table(data(cnt_index).cnt(1).params.model_coeff)
    
    my_table.Properties
    my_table = renamevars(my_table, ["value"], ["meas 1"]) 
    % mytable.("meas 2") = [data(1).cnt(2).params.model_coeff.value]'
    
    for ii=2:x_l
        lab = strcat("meas ", num2str(ii));
        my_table.(lab) = [data(cnt_index).cnt(ii).params.model_coeff.value]';
    end
    my_table
    
    col = "B";
    row = 2+13*(cnt_index-1);
    cell = col+num2str(row);
    excel_file = "SpiderStaticParams.xlsx";
    writetable(my_table, excel_file,'Sheet', 1, 'Range', cell)
end
% table_sorted = sortrows(my_table, "displ")

