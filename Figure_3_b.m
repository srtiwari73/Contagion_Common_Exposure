% Example variables (replace with your actual data)
stdDev = kernel_weighted_std(d_lambda,1,13)*100;
[corrAvg, ~] = time_varying_corr(d_lambda(1,:)', d_lambda(2,:)', 13);
dates = datetime(2005,7,1) + calmonths(0:224);

% Crisis periods (edit for your data)
crisis1 = [datetime(2008,3,1), datetime(2009,5,1)];
crisis2 = [datetime(2015,6,1), datetime(2016,6,1)];
crisis3 = [datetime(2020,3,1), datetime(2020,8,1)];
crisis_ranges = [crisis1; crisis2; crisis3];

figure;
hold on;

% Plot shaded areas for crisis periods. Do NOT add fill objects to legend.
ylims1 = [min(stdDev)-0.1 max(stdDev)+0.1];
for k = 1:size(crisis_ranges,1)
    x1 = crisis_ranges(k,1);
    x2 = crisis_ranges(k,2);
    % Add 'Annotation' off so fill does not go in legend
    fill([x1 x2 x2 x1], ylims1([1 1 2 2]), [0.8 0.8 0.8], ...
        'EdgeColor','none','FaceAlpha',0.6, 'HandleVisibility','off');
end

% Plot curves and save their handles
yyaxis left
h_std = plot(dates, stdDev, '-', 'Color', [0.82 0.37 0.19], 'LineWidth',2); % orange
ylabel('Standard Deviation (bps)');
ylim(ylims1);

yyaxis right
h_corr = plot(dates, corrAvg, '--', 'Color', [0 0.45 0.74], 'LineWidth',2); % blue
ylabel('Pairwise Correlation');
ylim([0 1]);

xlabel('Time');
set(gca, 'FontSize',12);
xlim([dates(1) dates(end)]);
box on;
years = year(dates(1)):2:year(dates(end));
xticks(datetime(years,1,1));

% Legend ONLY for curves
legend([h_std h_corr], {'System Standard Deviation', 'Average Pairwise Correlation'}, ...
    'Location','northeast','FontSize',10);

hold off;
