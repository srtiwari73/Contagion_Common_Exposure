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

function [common_contribution, common_by_layer] = compute_common(out, Aex, Lex, Aen, Wmat, DMB, RA, dRA, lambda, Theta, S_static, N, nC, Ken, M, nL)
    
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
    
    common_contribution = zeros(1, T_eval);
    
    
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
        
        % --- Calculate Common Exposure Contribution (Equation 18) ---
        common_shock_idx = 1:nC;
        common_shocks_vector = zeros(K, 1);
        common_shocks_vector(common_shock_idx) = 1;
        sigma_sys_unscaled = w_t(:,t)' * Bt * Ct * common_shocks_vector;
        common_contribution(t) = sigma_sys_unscaled * scaling_factor * 1e4;
                
    end
    
    % Assuming Theta and the systematic exposures are structured correctly
    common_by_layer = zeros(nC, T_eval);
    common_names = {};
    for c = 1:nC
        common_shock_vector = zeros(K, 1);
        common_shock_vector(c) = 1;
        for t = 1:T_eval
            current_theta = theta_tv(:,t);
            betaC = current_theta(M+nL+Ken+1:M+nL+Ken+nC);
            betaI = current_theta(M+nL+Ken+nC+1:end);
            Cdiag = [betaC; betaI];
            Ct = diag(Cdiag);
            Bt = squeeze(B_tv(:,:,t));
            common_by_layer(c, t) = w_t(:,t)' * Bt * Ct * common_shock_vector * scaling_factor * 1e4;
        end
        % Use placeholder names, you should replace with your specific shock names
        common_names{c} = ['Shock ', num2str(c)];
    end
    
end
