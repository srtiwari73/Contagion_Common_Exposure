% plot_results.m
% Generates plots similar to Figure 3(a) and 3(b) from the paper.
%
% This script assumes the following variables are in the workspace:
%   dLambda: N x T matrix of changes in capital ratios.
%   RA: N x T matrix of risky assets for each bank.
%   Sigma_tv: N x N x T_eval array from estimate_HALAJ_HIPP_step1.m.
%   t_eval: Time points where Sigma_tv was estimated.
%   t_full: Full time vector for dLambda (e.g., 1:T).
%
% The script also assumes you have defined the crisis periods
% for the shaded areas, as in the paper.
% Example:
% gfc = [find(t_full == 33), find(t_full == 49)]; % Example dates for GFC

function plot_results3ab(dLambda, RA, Sigma_tv)             % t_eval, t_full, crisis_periods

    % --- Figure 3(a): Aggregate Changes in Capital Ratio ---
    % Calculate market share weights
    w_mkt = RA ./ sum(RA, 1);
    
    % Calculate aggregate changes
    dLambda_system = sum(w_mkt .* dLambda, 1)*1e4;
    
    dates = datetime(2005,7,1) + calmonths(0:224);      % Monthly dates from July 2005
    % Crisis periods (edit these as needed for your context!)
    crisis1 = [datetime(2007,12,1), datetime(2009,6,1)];        % GFC
    crisis2 = [datetime(2015,6,1), datetime(2017,11,1)];        % TBS
    crisis3 = [datetime(2020,3,1), datetime(2020,8,1)];         % Covid
    crisis_ranges = [crisis1; crisis2; crisis3];
    
    % Color coding (change points to use a colormap, similar effect as your example)
    clrs = zeros(length(dLambda_system),3);
    cmap = jet(256);                   % Use colormap 'jet' for nice gradient
    dmin = min(dLambda_system(:));
    dmax = max(dLambda_system(:));
    for i = 1:length(dLambda_system)
        cidx = round(1 + (dLambda_system(i)-dmin)/(dmax-dmin)*255);
        cidx = min(max(cidx,1),256);
        clrs(i,:) = cmap(cidx,:);
    end

    figure;
    hold on;

    % Plot shaded areas for crisis periods
    ylims = [dmin-0.001 dmax+0.001];                  % Adjust this to match your y-axis
    for k = 1:size(crisis_ranges,1)
        % Draw rectangle: [x, y, width, height] for fill
        x1 = crisis_ranges(k,1);
        x2 = crisis_ranges(k,2);
        fill([x1 x2 x2 x1], ylims([1 1 2 2]), [0.8 0.8 0.8], ...
            'EdgeColor','none','FaceAlpha',0.6)
    end
    
    % Plot time series line
    plot(dates, dLambda_system, 'b-', 'LineWidth',1)
    
    % Overlay color-coded markers
    scatter(dates, dLambda_system, 40, clrs, 'filled')
    % Add horizontal line at zero
    yline(0, '--', 'LineWidth', 1);
    % Axes, labels, limits
    ylim(ylims)
    xlim([dates(1) dates(end)])
    
    xlabel('Time')
    ylabel('Change in System Capital Ratio (bps)')
    
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
    

    % --- Figure 3(b): Standard Deviation and Correlation ---
    [N, T] = size(dLambda);

    % Calculate system standard deviation from Sigma_tv
    sys_std_dev = zeros(1, T);
    for i = 1:T
        Sigma_t = Sigma_tv(:,:,i);
        sys_std_dev(i) = sqrt(sum(diag(abs(Sigma_t)))) * 1e3;     % multiplying by 1000 after dividing 10000/10
    end

    % Calculate average pairwise correlation
    avg_pairwise_corr = zeros(1, T);
    for i = 1:T
        Sigma_t = Sigma_tv(:,:,i);
        corr_mat = corrcov(Sigma_t);
        % Get the upper triangular part (excluding diagonal)
        corr_mat_upper = triu(corr_mat, 1);
        % Calculate the average of off-diagonal elements
        avg_pairwise_corr(i) = sum(corr_mat_upper(:)) / (N * (N - 1) / 2);
    end
    

    figure;
    hold on;
    
    % Plot shaded areas for crisis periods. Do NOT add fill objects to legend.
    ylims1 = [min(sys_std_dev)-1 max(sys_std_dev)+1];
    for k = 1:size(crisis_ranges,1)
        x1 = crisis_ranges(k,1);
        x2 = crisis_ranges(k,2);
        % Add 'Annotation' off so fill does not go in legend
        fill([x1 x2 x2 x1], ylims1([1 1 2 2]), [0.8 0.8 0.8], ...
            'EdgeColor','none','FaceAlpha',0.6, 'HandleVisibility','off');
    end

    % Plot curves and save their handles
    yyaxis left
    h_std = plot(dates, sys_std_dev, '-', 'Color', [0 0.45 0.74], 'LineWidth',2); % orange
    ylabel('Standard Deviation (bps)');
    ylim(ylims1);
    
    yyaxis right
    h_corr = plot(dates, avg_pairwise_corr, '--', 'Color', [0.82 0.37 0.19], 'LineWidth',2); % blue
    ylabel('Pairwise Correlation');
    ylim([-0.5 0.5]);
    
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

    % yyaxis left;
    % plot(t_eval, sys_std_dev, 'LineWidth', 2);
    % ylabel('Standard Deviation (bps)');
    % ylim([0 16]);
    % 
    % yyaxis right;
    % plot(t_eval, avg_pairwise_corr, '--', 'LineWidth', 2);
    % ylabel('Pairwise Correlation');
    % ylim([-0.05 0.3]);
    % 
    % % Shade crisis periods (adjust x-axis to match t_eval)
    % for i = 1:size(crisis_periods, 1)
    %     patch([crisis_periods(i, 1) crisis_periods(i, 2) crisis_periods(i, 2) crisis_periods(i, 1)], ...
    %           [-100 -100 100 100], colors(mod(i-1, size(colors,1))+1, :), 'EdgeColor', 'none', 'FaceAlpha', 0.5);
    % end
    % 
    % grid on;
    % xlabel('Time');
    % title('Time-Varying System Standard Deviation and Average Pairwise Correlation');
    % legend('System Standard Deviation', 'Average Pairwise Correlation', 'Location', 'best');
    % hold off;
end
