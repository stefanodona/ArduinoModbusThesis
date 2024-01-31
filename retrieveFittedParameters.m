function coeff = retrieveFittedParameters(data, spider_name, poly_order)
    jj = find({data.name}==spider_name);
    coeff={};
    
    figure()
    c0=[];c1=[];c2=[];c3=[];c4=[];
          r1=[];r2=[];r3=[];r4=[];
    displ = [];
    for ii=1:length(data(jj).cnt)
        %     displ = [data(1).cnt.displ_val];
    
        if abs(data(jj).cnt(ii).params.model_coeff(1).value)==1e-3
            continue
        end
        displ = [displ, data(jj).cnt(ii).params.model_coeff(1).value];
        c0 = [c0, data(jj).cnt(ii).params.model_coeff(2).value];
        c1 = [c1, data(jj).cnt(ii).params.model_coeff(3).value];
        c2 = [c2, data(jj).cnt(ii).params.model_coeff(4).value];
        c3 = [c3, data(jj).cnt(ii).params.model_coeff(5).value];
        c4 = [c4, data(jj).cnt(ii).params.model_coeff(6).value];
    
        r1 = [r1, data(jj).cnt(ii).params.model_coeff(7).value];
        r2 = [r2, data(jj).cnt(ii).params.model_coeff(8).value];
        r3 = [r3, data(jj).cnt(ii).params.model_coeff(9).value];
        r4 = [r4, data(jj).cnt(ii).params.model_coeff(10).value];
    end

        subplot 211
    plot(displ, 10*c0);
    hold on
    plot(displ, c1);
    hold on
    plot(displ, c2);
    hold on
    plot(displ, c3);
    hold on
    plot(displ, c4);
    hold off
    grid on
    xlabel("Displacement [m]", Interpreter="latex")
    ylabel("Compliance [m/N]", Interpreter="latex")
    title("Compliance curve", Interpreter="latex", FontSize=14)
    subtitle(data(jj).name, Interpreter="latex")
    
    legend(["$10C_0$", "$C_1$", "$C_2$", "$C_3$", "$C_4$"], Interpreter="latex")
    
    subplot 212
    semilogy(displ, r1);
    hold on
    semilogy(displ, r2);
    hold on
    semilogy(displ, r3);
    hold on
    semilogy(displ, r4);
    hold off
    grid on
    xlabel("Displacement [m]", Interpreter="latex")
    ylabel("Resistance [N*s/m]", Interpreter="latex")
    title("Resistance curve", Interpreter="latex", FontSize=14)
    subtitle(data(jj).name, Interpreter="latex")
    
    legend(["$R_1$", "$R_2$", "$R_3$", "$R_4$"], Interpreter="latex")
    
    k0 = 1./c0;
    k1 = 1./c1;
    k2 = 1./c2;
    k3 = 1./c3;
    k4 = 1./c4;
    
    params2 = [k0;k1;k2;k3;k4;r1;r2;r3;r4]';
    labels = ["k_0";"k_1";"k_2";"k_3";"k_4";"r_1";"r_2";"r_3";"r_4"]
    displ2 = displ';

    for ii=1:size(params2,2)
        coeff{1,ii} = labels(ii); 
        coeff{2,ii} = fit(displ2, params2(:,ii), poly_order, ...
            'Robust', 'Off')
        coeff{2,ii}
        figure()
        plot(coeff{2,ii}, displ, params2(:,ii));
        title(labels(ii,:))
    end

end