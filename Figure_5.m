% Dummy data for illustration (replace with your real data)
dates = datetime(2005,7,1) + calmonths(0:224);
marketBased = contagion_by_layer(2,:)';          % Market-Based Contagion
priceMediated = contagion_by_layer(1,:)';            % Price-Mediated Contagion
shortTerm = contagion_by_layer(3,:)';              % Short Term Money Placement
lending = contagion_by_layer(4,:)';                  % Lending
%avgMult = bank_measures(:,16)*100;                % Average Contagion Multiplication (%)

% Stack the area series in a matrix (columns = series in stack, left axis)
areaData = [shortTerm, lending, marketBased, priceMediated]; 


% Colors for each series (try to match your sample)
colorShortTerm   = [0.00 0.45 0.74]; % blue
colorLending     = [0.49 0.18 0.56]; % purple
colorMarketBased = [0.55 0.27 0.07]; % brown
colorPriceMed    = [0.87 0.49 0.00]; % orange-brown

colors = [colorShortTerm; colorLending; colorMarketBased; colorPriceMed];

% Crisis periods
crisis1 = [datetime(2007,12,1), datetime(2009,6,1)];
crisis2 = [datetime(2015,6,1), datetime(2017,11,1)];
crisis3 = [datetime(2020,3,1), datetime(2020,8,1)];
crisis_ranges = [crisis1; crisis2; crisis3];

figure; hold on;

% Plot shaded areas (not in legend)
ylims = [0, max(sum(areaData,2))];
for k = 1:size(crisis_ranges,1)
    fill([crisis_ranges(k,1) crisis_ranges(k,2) crisis_ranges(k,2) crisis_ranges(k,1)], ...
         [ylims(1) ylims(1) ylims(2) ylims(2)], [0.8 0.8 0.8], ...
         'EdgeColor','none','FaceAlpha',0.6,'HandleVisibility','off');
end

% Stacked area chart
ha = area(dates, areaData, 'LineStyle', 'none');
for i = 1:numel(ha)
    ha(i).FaceColor = colors(i,:);
end

% Plot multiplication index on right axis
% yyaxis right
% h_mult = plot(dates, avgMult, 'k-', 'LineWidth', 2);
% ylabel('Average Multiplication (%)');
% ylim([0 max(avgMult)]);

% yyaxis left
ylabel('Contribution to Standard Deviation (bps)');
xlabel('Time');
set(gca, 'FontSize',12)
xlim([dates(1), dates(end)]);
ylim(ylims)
box on

% x-axis ticks every 2 years
years = year(dates(1)):2:year(dates(end));
xticks(datetime(years,1,1));

% Build legend for curves
% yyaxis left
legend(ha(:), ...
    {'Short Term Money Plcmnt', 'Lending', 'Market-Based Cont.', 'Price-Mediated Cont.'}, ...
    'Location', 'northeast', 'FontSize',10);

hold off
