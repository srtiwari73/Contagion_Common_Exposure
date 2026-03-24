%% --- Helper function for betaAt ---
function betaAt = compute_betaA_t(t, gamma, Wmat, RA, dRA, lambda, S_static)
    % betaA = S*diag(gamma)*W*diag(RA+dRA)*diag(lambda)^-1 
    diag_gamma = diag(gamma);
    % Robust calculation of diag_RA_lambda (adding eps for numerical stability)
    
    diag_RA_lambda = diag((RA(:,t) + dRA(:,t)) ./ (lambda(:,t) + 1e-8));
    diag_RA_lambda = diag(1 ./ (RA(:,t) + 1e-8)) * diag_RA_lambda;      % normalizing with total illiquid assets
    betaAt = S_static * diag_gamma * squeeze(Wmat(:,:,t)) * diag_RA_lambda;
end
