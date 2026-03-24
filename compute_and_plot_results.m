% This function computes and plots the contributions of different risk channels
% for Figures 4, 5, 6, and D.2 from the Hałaj and Hipp paper.
%
% It assumes the following variables are available in the workspace or passed in:
%   out: A struct containing the results from the two-step estimation (estimate_HALAJ_HIPP_step2.m).
%     out.theta_tv: Estimated parameters (nparams x T_eval)
%     out.A_tv: Estimated A matrices (N x N x T_eval)
%     out.B_tv: Estimated B matrices (N x (nC+N) x T_eval)
%     out.Sigma_tv: Empirical Sigma matrices (N x N x T_eval)
%     out.opts: The options used in the estimation
%     out.t_eval: The time points for which results were estimated
%   RA: N x T matrix of risky assets for each bank.
%   Aen: N x Ken x T array for interbank exposures.
%   Aex: N x Kex x T array for exogenous assets.
%   Lex: N x N*nL x T array for liabilities.
%   Wmat: M x N x T array for illiquid marketable assets.
%   DMB: N x N x T array for the market-based network.
%   Theta: (Kex + N*nL) x nC selection matrix for common exposures.
%   S_static: Kex x M static mapping for marketable assets.
%   crisis_periods: A matrix of start and end indices for shaded crisis areas.
%   N: Number of banks.
%   nC: Number of common shocks.
%   Ken: Number of endogenous asset classes (e.g., interbank exposures).
%   M: Number of marketable asset types.
%   nL: Number of liability types.

function [idio_contribution, common_contribution, contagion_contribution, contagion_by_layer, common_by_layer, avg_contagion_mult] = compute_and_plot_results(out, Aex, Lex, Aen, Wmat, DMB, RA, dRA, lambda, Theta, S_static, N, nC, Ken, M, nL)
    
    % Unpack variables from the 'out' struct for convenience
    theta_tv = out.theta_tv;
    A_tv = out.A_tv;
    B_tv = out.B_tv;
    Sigma_tv = out.Sigma_tv;
    t_eval = out.t_eval;
    
    T_eval = numel(t_eval);
    nparams = size(theta_tv, 1);
    
    % --- Pre-calculate market share weights (w_t) ---
    [~, ra_idx] = ismember(t_eval, 1:size(RA, 2));
    RA_eval = RA(:, ra_idx);
    w_t = RA_eval ./ sum(RA_eval, 1);

    % --- Scaling factor D(K) from paper, footnote 8 ---
    K = N + nC;
    scaling_factor = scaling(K);
    
    % --- Initialize arrays for contributions ---
    idio_contribution = zeros(1, T_eval);
    common_contribution = zeros(1, T_eval);
    contagion_contribution = zeros(1, T_eval);
    
    % Initialize arrays for layered contagion (Figures 5 & D.2)
    contagion_by_layer = zeros(1 + 1 + Ken, T_eval);
    layer_names = {};
    % Initialize arrays for layered common exposure (Figures 6)
    common_by_layer = zeros(nC, T_eval);
    common_names = {};
    
    % --- Loop through time to calculate contributions ---
    for t = 1:T_eval
        % Get parameters for the current time point
        current_theta = theta_tv(:, t);
        
        % Unpack parameters based on step2.m indexing
        idx = 1;
        gamma = current_theta(idx:idx+M-1); idx = idx+M;
        delta = current_theta(idx:idx+nL-1); idx = idx+nL;
        betaG = current_theta(idx:idx+Ken-1); idx = idx+Ken;
        betaC = current_theta(idx:idx+nC-1); idx = idx+nC;
        betaI = current_theta(idx:idx+N-1);
        
        % Build C_t matrix
        Cdiag = [betaC; betaI];
        Ct = diag(Cdiag);
        
        % Get A_t and B_t matrices
        At = squeeze(A_tv(:,:,t));
        Bt = squeeze(B_tv(:,:,t));
        Ainv = inv(At);

        % --- Calculate Idiosyncratic Contribution (Equation 16) ---
        idio_shock_idx = (nC + 1):K;
        idio_shocks_vector = zeros(K, 1);
        idio_shocks_vector(idio_shock_idx) = 1;
        sigma_idio_unscaled = w_t(:,t)' * Bt * Ct * idio_shocks_vector;
        idio_contribution(t) = sigma_idio_unscaled * scaling_factor * 1e4;
        
        % --- Calculate Common Exposure Contribution (Equation 18) ---
        common_shock_idx = 1:nC;
        common_shocks_vector = zeros(K, 1);
        common_shocks_vector(common_shock_idx) = 1;
        sigma_sys_unscaled = w_t(:,t)' * Bt * Ct * common_shocks_vector;
        common_contribution(t) = sigma_sys_unscaled * scaling_factor * 1e4;
        
        % --- Calculate Contagion Contribution (Equation 19) ---
        ones_vector = ones(K, 1);
        contagion_term = w_t(:,t)' * (Ainv - eye(N)) * Bt * Ct * ones_vector;
        contagion_contribution(t) = contagion_term * scaling_factor * 1e4;

        % --- Calculate Contagion by Layer (for Figures 5 and D.2) ---
        layer_idx = 1;
        % Price-mediated Contagion (from gamma)
        At_no_gamma = At + squeeze(Aex(:,:,t)) * compute_betaA_t(t, gamma, Wmat, RA, dRA, lambda, S_static);
        cont_gamma = w_t(:,t)' * (Ainv - inv(At_no_gamma)) * Bt * Ct * ones_vector;
        contagion_by_layer(layer_idx, t) = cont_gamma * scaling_factor * 1e4;
        layer_names{layer_idx} = 'Price-Mediated Cont.'; layer_idx = layer_idx + 1;

        % Market-based Contagion (from delta)
        At_no_delta = At + squeeze(Lex(:,:,t)) * kron(squeeze(DMB(:,:,t)), delta);
        cont_delta = w_t(:,t)' * (Ainv - inv(At_no_delta)) * Bt * Ct * ones_vector;
        contagion_by_layer(layer_idx, t) = cont_delta * scaling_factor * 1e4;
        layer_names{layer_idx} = 'Market-Based Cont.'; layer_idx = layer_idx + 1;
        
        % Interbank Contagion (from betaG)
        betaG_t0 = zeros(Ken,N);
        for k = 1:Ken
            betaG_t0(k,:) = betaG(k);            % making betaG Ken x N            
        end
        for k_g = 1:Ken
            At_no_betaG = At + squeeze(Aen(:,k_g,t)) * betaG_t0(k_g,:);
            cont_betaG = w_t(:,t)' * (Ainv - inv(At_no_betaG)) * Bt * Ct * ones_vector;
            contagion_by_layer(layer_idx, t) = cont_betaG * scaling_factor * 1e4;
            layer_names{layer_idx} = ['Interbank (betaG ', num2str(k_g), ')']; layer_idx = layer_idx + 1;
        end

        % --- Calculate Common exposure by Layer (for Figures 5 and D.2) ---
        common_by_layer = zeros(nC, T_eval);
        common_names = {};
        for c = 1:nC
            common_shock_vector = zeros(K, 1);
            common_shock_vector(c) = 1;
            
            common_by_layer(c, t) = w_t(:,t)' * Bt * Ct * common_shock_vector * scaling_factor * 1e4;
            
            % Use placeholder names, you should replace with your specific shock names
            common_names{c} = ['Shock ', num2str(c)];
        end
    end
    avg_contagion_mult = sum(contagion_by_layer, 1) ./ sum(contagion_contribution, 1);
    % --- Plotting ---

    % Figure 4: Decomposition of System Standard Deviation
    dates = datetime(2005,7,1) + calmonths(0:224);
    idio = idio_contribution;                 % Idiosyncratic component
    commonExp = common_contribution;             % Common exposure component
    contag = contagion_contribution;                % Contagion component
    total = idio + commonExp + contag;                 % Total (or use real data)

    % Crisis periods (edit these as needed)
    crisis1 = [datetime(2008,3,1), datetime(2009,5,1)];
    crisis2 = [datetime(2015,6,1), datetime(2016,6,1)];
    crisis3 = [datetime(2020,3,1), datetime(2020,8,1)];
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
        'Location','best','FontSize',10);

    hold off;

    % colors = [0.8 0.8 0.8]; 
    % for i = 1:size(crisis_periods, 1)
    %     patch([t_eval(crisis_periods(i, 1)) t_eval(crisis_periods(i, 2)) t_eval(crisis_periods(i, 2)) t_eval(crisis_periods(i, 1))], ...
    %           [-100 -100 100 100], colors, 'EdgeColor', 'none', 'FaceAlpha', 0.5);
    % end
    % contributions = [idio_contribution; common_contribution; contagion_contribution];
    % area(t_eval, contributions', 'LineWidth', 1.5);
    % sys_std_dev = zeros(1, T_eval);
    % for i = 1:T_eval
    %     Sigma_t = Sigma_tv(:,:,i);
    %     sys_std_dev(i) = sqrt(sum(sum(Sigma_t))) * 1e4;
    % end
    % plot(t_eval, sys_std_dev, 'LineWidth', 2, 'Color', 'k', 'DisplayName', 'Total');
    % hold off;
    % grid on;
    % xlabel('Time');
    % ylabel('Contribution to Standard Deviation (bps)');
    % title('Figure 4: Decomposition of System Standard Deviation');
    % legend('Idiosyncratic', 'Common Exposure', 'Contagion', 'Total', 'Location', 'best');
    % ylim([0 max(sys_std_dev) * 1.1]);

    % Figure 5: Average Contagion by Layer
    marketBased = contagion_by_layer(2,:);          % Market-Based Contagion
    priceMediated = contagion_by_layer(1,:);            % Price-Mediated Contagion
    shortTerm = contagion_by_layer(3,:);              % Short Term Money Placement
    lending = contagion_by_layer(4,:);                  % Lending
    % avgMult = bank_measures(:,16)*100;                % Average Contagion Multiplication (%)

    % Stack the area series in a matrix (columns = series in stack, left axis)
    areaData = [shortTerm, lending, marketBased, priceMediated]; 

    % Colors for each series (try to match your sample)
    colorShortTerm   = [0.00 0.45 0.74]; % blue
    colorLending     = [0.49 0.18 0.56]; % purple
    colorMarketBased = [0.55 0.27 0.07]; % brown
    colorPriceMed    = [0.87 0.49 0.00]; % orange-brown

    colors = [colorShortTerm; colorLending; colorMarketBased; colorPriceMed];

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
    xlabel('Date');
    set(gca, 'FontSize',12)
    xlim([dates(1), dates(end)]);
    ylim(ylims)
    box on

    % x-axis ticks every 2 years
    years = year(dates(1)):2:year(dates(end));
    xticks(datetime(years,1,1));

    % Build legend for curves
    % yyaxis left
    legend([ha(:); h_mult], ...
        {'Short Term', 'Lending', 'Market-Based Cont.', 'Price-Mediated Cont.', ...
        'Av. Contagion Multiplication (right axis)'}, ...
        'Location', 'best', 'FontSize',10);

    hold off


    % figure;
    % hold on;
    % area(t_eval, contagion_by_layer', 'LineWidth', 1.5);
    % plot(t_eval, sum(contagion_by_layer, 1), 'LineWidth', 2, 'Color', 'k', 'DisplayName', 'Total Contagion');
    % hold off;
    % grid on;
    % xlabel('Time');
    % ylabel('Contribution to Standard Deviation (bps)');
    % title('Figure 5: Average Contagion by Layer');
    % legend(layer_names, 'Location', 'best');

    % Figure 6: Common Exposure Contribution
    assets    = common_by_layer(1,:);
    liability = common_by_layer(2,:);
    foreign   = common_by_layer(3,:);
    business  = common_by_layer(4,:);
    housing   = common_by_layer(5,:);
    shares    = common_by_layer(6,:);
    tradeables= common_by_layer(7,:);
    total_common     = assets + liability + foreign + business + housing + shares + tradeables;

    % Stack area data
    areaData = [assets, liability, foreign, business, housing, shares, tradeables];

    % Colors (match the sample as closely as possible)
    colorAssets    = [0.00 0.45 0.74];  % blue
    colorLiability = [0.00 0.00 0.54];  % navy (deep blue)
    colorForeign   = [0.52 0.26 0.39];
    colorBusiness  = [0.49 0.18 0.56];  % purple
    colorHousing   = [0.26 0.62 0.20];  % green
    colorShare     = [0.30 0.70 1.00];  % light blue
    colorTrade     = [1.00 0.50 0.25];  % orange
    colors = [colorAssets; colorLiability; colorForeign; colorBusiness; colorHousing; colorShare; colorTrade];

    figure;
    hold on;

    % Plot shaded crisis areas (exclude from legend)
    ylims = [0, max(total_common)];
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
    h_total = plot(dates, total_common, 'k-', 'LineWidth', 2);

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
        {'Assets', 'Liabilities', 'Household', 'Business', 'Shares', 'Tradeables', 'Total'}, ...
        'Location','best','FontSize',10);

    hold off;






    % Assuming Theta and the systematic exposures are structured correctly
    % common_by_layer = zeros(nC, T_eval);
    % common_names = {};
    % for c = 1:nC
    %     common_shock_vector = zeros(K, 1);
    %     common_shock_vector(c) = 1;
    %     for t = 1:T_eval
    %         current_theta = theta_tv(:,t);
    %         betaC = current_theta(M+nL+Ken+1:M+nL+Ken+nC);
    %         betaI = current_theta(M+nL+Ken+nC+1:end);
    %         Cdiag = [betaC; betaI];
    %         Ct = diag(Cdiag);
    %         Bt = squeeze(B_tv(:,:,t));
    %         common_by_layer(c, t) = w_t(:,t)' * Bt * Ct * common_shock_vector * scaling_factor * 1e4;
    %     end
    %     % Use placeholder names, you should replace with your specific shock names
    %     common_names{c} = ['Shock ', num2str(c)];
    % end
    % area(t_eval, common_by_layer', 'LineWidth', 1.5);
    % plot(t_eval, common_contribution, 'LineWidth', 2, 'Color', 'k', 'DisplayName', 'Total Common Exposure');
    % hold off;
    % grid on;
    % xlabel('Time');
    % ylabel('Contribution to Standard Deviation (bps)');
    % title('Figure 6: Common Exposure Contribution');
    % legend(common_names, 'Location', 'best');

    % Figure D.2: Average Contagion Multiplication
    figure;
    hold on;
    avg_contagion_mult = sum(contagion_by_layer, 1) ./ sum(contagion_contribution, 1);
    plot(t_eval, avg_contagion_mult * 100, 'LineWidth', 2, 'Color', 'k');
    hold off;
    grid on;
    xlabel('Time');
    ylabel('Average Contagion Multiplication (%)');
    title('Figure D.2: Average Contagion Multiplication by Layer');
    
end
