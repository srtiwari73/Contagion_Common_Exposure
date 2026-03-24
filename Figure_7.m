% Example variables (replace all below with your actual data)
dates     = datetime(2005,7,1) + calmonths(0:224);
pricemediated       = cont_multi_by_layer(1,:)';
marketbased         = cont_multi_by_layer(2,:)';
shortterm           = cont_multi_by_layer(3,:)';
lending             = cont_multi_by_layer(4,:)';

total               = contagion_multiplication(1,:)';

% Crisis periods
crisis1 = [datetime(2007,12,1), datetime(2009,6,1)];
crisis2 = [datetime(2015,6,1), datetime(2017,11,1)];
crisis3 = [datetime(2020,3,1), datetime(2020,8,1)];
crisis_ranges = [crisis1; crisis2; crisis3];

% Stack area data
areaData = [shortterm, lending, marketbased, pricemediated]; 

% Colors for each series (try to match your sample)
colorShortTerm   = [0.00 0.45 0.74]; % blue
colorLending     = [0.49 0.18 0.56]; % purple
colorMarketBased = [0.55 0.27 0.07]; % brown
colorPriceMed    = [0.87 0.49 0.00]; % orange-brown

colors = [colorShortTerm; colorLending; colorMarketBased; colorPriceMed];

figure; hold on;

% Plot shaded crisis areas (exclude from legend)
ylims = [0, max(total)];
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

% Overlay total line
h_total = plot(dates, total, 'k-', 'LineWidth', 2);

xlabel('Time');
ylabel('Contribution to Standard Deviation (bps)');
set(gca, 'FontSize', 12)
xlim([dates(1) dates(end)]);
ylim(ylims);
box on;

years = year(dates(1)):2:year(dates(end));
xticks(datetime(years,1,1));

% Legend
legend([ha(:); h_total], ...
    {'Assets', 'Liabilities', 'Foreign',  'Business', 'Housing', 'Shares', 'Tradeables', 'Total'}, ...
    'Location','northeast','FontSize',10);

hold off;
