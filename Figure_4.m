% Example data -- replace with your actual variables
dates = datetime(2005,7,1) + calmonths(0:224);
idio = idio_contribution;                  % Idiosyncratic component
commonExp = common_contribution;             % Common exposure component
contag = contagion_contribution;                % Contagion component
total = idio + commonExp + contag;                 % Total (or use real data)

% Crisis periods (edit these as needed)
crisis1 = [datetime(2007,12,1), datetime(2009,6,1)];
crisis2 = [datetime(2015,6,1), datetime(2017,11,1)];
crisis3 = [datetime(2020,2,1), datetime(2020,8,1)];
crisis_ranges = [crisis1; crisis2; crisis3];

figure;
hold on;

% Plot shaded areas for crisis periods (but not in legend)
ylims = [0 max(total)+0.5];
for k = 1:size(crisis_ranges,1)
    x1 = crisis_ranges(k,1);
    x2 = crisis_ranges(k,2);
    fill([x1 x2 x2 x1], [ylims(1) ylims(1) ylims(2) ylims(2)], [0.8 0.8 0.8], ...
        'EdgeColor','none','FaceAlpha',0.6, 'HandleVisibility','off');
end

% Plot each curve, save handle for legend
h_idio   = plot(dates, idio,     'Color', [0 0.45 0.74], 'LineWidth', 2); % blue
h_comm   = plot(dates, commonExp,'Color', [0.85 0.33 0.10], 'LineWidth', 2); % orange
h_contag = plot(dates, contag,   'Color', [0.93 0.69 0.13], 'LineWidth', 2); % yellow
h_total  = plot(dates, total,    'Color', 'k', 'LineWidth', 2); % black

xlabel('Time');
ylabel('Contribution to Standard Deviation (bps)');
set(gca, 'FontSize',12);
xlim([dates(1) dates(end)]);
ylim(ylims)
box on

years = year(dates(1)):2:year(dates(end));
xticks(datetime(years,1,1));

% Legend with correct colors and variable names
legend([h_idio h_comm h_contag h_total], ...
    {'Idiosyncratic', 'Common Exposure', 'Contagion', 'Total'}, ...
    'Location','northeast','FontSize',10);

hold off;
