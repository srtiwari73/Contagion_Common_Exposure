% Example variables (replace all below with your actual data)
dates     = datetime(2005,7,1) + calmonths(0:224);
assets    = common_by_layer(1,:)';
liability = common_by_layer(2,:)';
foreign   = common_by_layer(3,:)';
business  = common_by_layer(4,:)';
house     = common_by_layer(5,:)';
share     = common_by_layer(6,:)';
tradeable = common_by_layer(7,:)';
total     = assets + liability + foreign + business + house + share + tradeable;

% Crisis periods
crisis1 = [datetime(2007,12,1), datetime(2009,6,1)];
crisis2 = [datetime(2015,6,1), datetime(2017,11,1)];
crisis3 = [datetime(2020,3,1), datetime(2020,8,1)];
crisis_ranges = [crisis1; crisis2; crisis3];

% Stack area data
areaData = [assets, liability, foreign, business, house, share, tradeable];

% Colors (match the sample as closely as possible)
colorAssets    = [0.00 0.45 0.74];  % blue
colorLiability = [0.00 0.00 0.54];  % navy (deep blue)
colorForeign   = [0.13 0.26 0.78];
colorBusiness  = [0.49 0.18 0.56];  % purple
colorHouse     = [0.26 0.62 0.20];  % green
colorShare     = [0.30 0.70 1.00];  % light blue
colorTrade     = [1.00 0.50 0.25];  % orange
colors = [colorAssets; colorLiability; colorForeign; colorBusiness; colorHouse; colorShare; colorTrade];

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
