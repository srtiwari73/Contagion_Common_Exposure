% Example Setup
% Replace with your actual data vectors:
%syetem_d_lambda = zeros(225,1);
% Calculate market share weights
w_mkt = RA ./ sum(RA, 1);

% Calculate aggregate changes
dLambda = sum(w_mkt .* d_lambda, 1)*1e4;
% dLambda = d_lambda(1,:)*100;                       % 3-month diff in capital ratio (basis points)
dates = datetime(2005,7,1) + calmonths(0:224);      % Monthly dates from July 2005

% Crisis periods (edit these as needed for your context!)
crisis1 = [datetime(2007,12,1), datetime(2009,6,1)];
crisis2 = [datetime(2015,6,1), datetime(2017,11,1)];
crisis3 = [datetime(2020,3,1), datetime(2020,8,1)];
crisis_ranges = [crisis1; crisis2; crisis3];

% Color coding (change points to use a colormap, similar effect as your example)
clrs = zeros(length(dLambda),3);
cmap = jet(256);                   % Use colormap 'jet' for nice gradient
dmin = min(dLambda(:));
dmax = max(dLambda(:));
for i = 1:length(dLambda)
    cidx = round(1 + (dLambda(i)-dmin)/(dmax-dmin)*255);
    cidx = min(max(cidx,1),256);
    clrs(i,:) = cmap(cidx,:);
end

% Begin figure
figure;
hold on;

% Plot shaded areas for crisis periods
ylims = [dmin-0.5 dmax+0.5];                  % Adjust this to match your y-axis
for k = 1:size(crisis_ranges,1)
    % Draw rectangle: [x, y, width, height] for fill
    x1 = crisis_ranges(k,1);
    x2 = crisis_ranges(k,2);
    fill([x1 x2 x2 x1], ylims([1 1 2 2]), [0.8 0.8 0.8], ...
        'EdgeColor','none','FaceAlpha',0.6)
end

% Plot time series line
plot(dates, dLambda, 'b-', 'LineWidth',1)

% Overlay color-coded markers
scatter(dates, dLambda, 40, clrs, 'filled')

% Axes, labels, limits
ylim(ylims)
xlim([dates(1) dates(end)])

xlabel('Time')
ylabel('Difference in System Capital Ratio (bps)')

% Make it look similar to your sample
set(gca,'FontSize',12)
box on

% Optional: change x-ticks to annual
ax = gca;
years = year(dates(1)):2:year(dates(end));
xticks(datetime(years,1,1))
datetick('x','yyyy','keepticks','keeplimits')
%print(gcf, fullfile('Figures', 'hdfc_fig3a.jpeg'), '-djpeg', '-r600')
hold off
