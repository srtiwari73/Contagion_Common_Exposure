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

function [contagion_multiplication, cont_multi_by_layer] = compute_multiplication(out, Aex, Lex, Aen, Wmat, DMB, RA, dRA, lambda, Theta, S_static, N, nC, Ken, M, nL)
    
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

    contagion_multiplication = zeros(2, T_eval);
    
    % Initialize arrays for layered contagion (Figures 5 & D.2)
    cont_multi_by_layer = zeros(1 + 1 + Ken, T_eval);
    layer_names = {};
   
    
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
        M = inv(At);
      
        % --- Calculate Contagion Multiplication ---
        cum_mult = mean(diag(M));   % average own-shock amplification
        contagion_multiplication(1,t) = cum_mult;
        % or
        cum_mult2 = trace(M*M')/N;  % quadratic amplification
        contagion_multiplication(2,t) = cum_mult2;

        % --- Calculate Contagion multiplication by Layer (for Figures 5 and D.2) ---
        layer_idx = 1;
        % Price-mediated Contagion (from gamma)
        At_no_gamma = At + squeeze(Aex(:,:,t)) * compute_betaA_t(t, gamma, Wmat, RA, dRA, lambda, S_static);
        M_no_gamma = M - inv(At_no_gamma);
        cont_multi_by_layer(layer_idx,t) = mean(diag(M_no_gamma));
        layer_names{layer_idx} = 'Price-Mediated Cont.'; layer_idx = layer_idx + 1;
        
        % Market-based Contagion multiplication (from delta)
        At_no_delta = At + squeeze(Lex(:,:,t)) * kron(squeeze(DMB(:,:,t)), delta);
        M_no_delta = M - inv(At_no_delta);
        cont_multi_by_layer(layer_idx,t) = mean(diag(M_no_delta));
        layer_names{layer_idx} = 'Market-Based Cont.'; layer_idx = layer_idx + 1;
        
        % Interbank Contagion (from betaG)
        betaG_t0 = zeros(Ken,N);
        for k = 1:Ken
            betaG_t0(k,:) = betaG(k);            % making betaG Ken x N            
        end
        for k_g = 1:Ken
            At_no_betaG = At + squeeze(Aen(:,k_g,t)) * betaG_t0(k_g,:);
            M_no_betaG = M - inv(At_no_betaG);
            cont_multi_by_layer(layer_idx,t) = mean(diag(M_no_betaG));
            layer_names{layer_idx} = ['Interbank (betaG ', num2str(k_g), ')']; layer_idx = layer_idx + 1;
        end
        

    end

    
end
