% Define time axis (monthly points)
dates = datetime(2005,7,1):calmonths(1):datetime(2024,3,1);

% Kernel centers
center1 = datetime(2008,8,1);  % August 2008
center2 = datetime(2020,3,1);  % March 2020

% Bandwidth for kernel (adjust for shape)
bandwidth = calmonths(13);
dateNum = datenum(dates);
centerNum1 = datenum(center1);
centerNum2 = datenum(center2);
bw = datenum(center1 + bandwidth) - centerNum1;

% Gaussian kernel weights
kernel = @(x, c, b) exp(-0.5 * ((x-c)/b).^2);
w1 = kernel(dateNum, centerNum1, bw); w1 = w1 / sum(w1);
w2 = kernel(dateNum, centerNum2, bw); w2 = w2 / sum(w2);

% Shaded crisis periods
crises = [datetime(2007,12,1), datetime(2009,6,1);
          datetime(2015,10,1), datetime(2016,4,1);
          datetime(2020,2,1), datetime(2020,7,1)];

figure; hold on;

% Crisis shading (do not add to legend)
for i = 1:size(crises,1)
    fill([crises(i,1) crises(i,2) crises(i,2) crises(i,1)],...
        [0 0 3.5 3.5], [0.7 0.7 0.7], 'LineStyle','none', 'FaceAlpha',0.4);
end

% Plot kernel weights (store handles for legend)
h2 = plot(dates, w2*100, 'color', [0.85 0.33 0.10], 'LineWidth',2);
h1 = plot(dates, w1*100, 'color', [0 0.45 0.74], 'LineWidth',2);

% Formatting
xlabel('Time');
ylim([0 3.5]);
ylabel('Estimation weight');
set(gca, 'YTick', 0:0.5:3.5, 'YTickLabel', arrayfun(@(x) sprintf('%.1f%%',x),0:0.5:3.5, 'UniformOutput',false));
box on; grid on;

% Legend (specify only kernel lines)
legend([h2 h1], {'Kernel-weights for 03-2020','Kernel-weights for 08-2008'}, 'Location','northwest');

xticks(datetime([2008 2010 2012 2014 2016 2018 2020 2022 2024],1,1));
set(gcf, 'Color', 'w');
hold off;
