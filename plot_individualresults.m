function plot_individualresults(individual)             % t_eval, t_full, crisis_periods

    % Unpack estimates 
    indi_idio = individual.idio;
    indi_common = individual.common;
    indi_contagion = individual.contagion;
    indi_contagion_by_price = individual.price;
    indi_contagion_by_mkt = individual.market;
    indi_contagion_by_short = individual.short;
    indi_contagion_by_lending = individual.lending;
    
    dates = datetime(2005,7,1) + calmonths(0:224);      % Monthly dates from July 2005
    
    banks = ["SBI", "HDFC", "ICICI", "BOB", "PNB", "CAN", "AXIS", "BOI", "UBI", "KMB"];

    % Colors for each series (try to match your sample)
    colorShortTerm   = [0.00 0.45 0.74]; % blue
    colorLending     = [0.49 0.18 0.56]; % purple
    colorMarketBased = [0.55 0.27 0.07]; % brown
    colorPriceMed    = [0.87 0.49 0.00]; % orange-brown
    
    colors = [colorShortTerm; colorLending; colorMarketBased; colorPriceMed];

    % figure;
    % for b=1:10
    %     subplot(5,2,b);
    %     hold on;
    % 
    %     areaData = [indi_contagion_by_short(b,:)', indi_contagion_by_lending(b,:)', indi_contagion_by_mkt(b,:)', indi_contagion_by_price(b,:)'];
    %     % Plot each curve, save handle for legend
    %     % Stacked area chart
    %     ha = area(dates, areaData, 'LineStyle', 'none');
    %     for i = 1:numel(ha)
    %         ha(i).FaceColor = colors(i,:);
    %     end
    % 
    %     xlim([dates(1) dates(end)]);
    %     % ylim(ylims)
    %     box on
    % 
    %     years = year(dates(1)):4:year(dates(end));
    %     xticks(datetime(years,1,1));
    % 
    %     title(banks(b));
    %     hold off;
    % end

    figure;
    for i=1:10
        subplot(5,2,i);
        hold on;

        % Plot each curve, save handle for legend
        h_idio   = plot(dates, indi_idio(i,:),     'Color', [0 0.45 0.74], 'LineWidth', 2); % blue
        h_comm   = plot(dates, indi_common(i,:),'Color', [0.85 0.33 0.10], 'LineWidth', 2); % orange
        h_contag = plot(dates, indi_contagion(i,:),   'Color', [0.93 0.69 0.13], 'LineWidth', 2); % yellow

        xlim([dates(1) dates(end)]);
        % ylim(ylims)
        box on

        years = year(dates(1)):4:year(dates(end));
        xticks(datetime(years,1,1));

        title(banks(i));
        hold off;
    end


    
end
