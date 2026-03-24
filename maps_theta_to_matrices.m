%% --- Helper function to map parameters to matrices ---
function [At, Bt, Ct] = maps_theta_to_matrices(theta, t, Aex, Lex, Aen, Wmat, DMB, RA, dRA, lambda, Theta, S_static, opts)
    % Unpack sizes
    [N, Kex, ~] = size(Aex);
    Ken = size(Aen, 2);
    nC = size(Theta, 2);
    M = size(Wmat, 1);
    HL = size(Lex, 2);
    nL = HL/N;

    % parameter indices
    idx = 1;
    gamma = theta(idx:idx+M-1); idx = idx+M;
    delta = theta(idx:idx+nL-1); idx = idx+nL;
    betaG = theta(idx:idx+Ken-1); idx = idx+Ken;
    betaC = theta(idx:idx+nC-1); idx = idx+nC;
    betaI = theta(idx:idx+N-1);

    % --- Build At matrix ---
    At = eye(N);
    
    % Interbank contagion
    betaG_t = zeros(Ken,N);
    for k = 1:Ken
        betaG_t(k,:) = betaG(k);            % making betaG Ken x N
    end
    At = At - squeeze(Aen(:,:,t)) * betaG_t;    % N x N

    % Price mediated contagion
    betaA_t = compute_betaA_t(t, gamma, Wmat, RA, dRA, lambda, S_static);           % Kex x N
    At = At - squeeze(Aex(:,:,t)) * betaA_t;

    % Market network contagion
    betaL_t = kron(DMB(:,:,t), delta);          % N*H x N
    At = At - squeeze(Lex(:,:,t)) * betaL_t;    % liability channel (scalar)

    % --- Build Bt matrix ---
    Bt_base = [squeeze(Aex(:,:,t)), -squeeze(Lex(:,:,t))];
    Bt_sys = Bt_base * Theta;
    Bt = [Bt_sys, eye(N)];

    % --- Build Ct matrix ---
    Cdiag = [betaC; betaI];
    Ct = diag(Cdiag);
end

