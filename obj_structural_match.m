%% --- Objective function for Step 2 (Structural Match) ---
function f = obj_structural_match(theta, t, Aex, Lex, Aen, Wmat, DMB, RA, dRA, lambda, Theta, S_static, Sigma_emp_t, opts)
    % A helper function to compute structural Sigma and compare to empirical.
    [N, ~, ~] = size(Aex);
    reg_eps = 1e-8;

    % Build structural components from parameters
    [At, Bt, Ct] = maps_theta_to_matrices(theta, t, Aex, Lex, Aen, Wmat, DMB, RA, dRA, lambda, Theta, S_static, opts);
    
    % Check for numerical stability
    if rcond(At) < 1e-8
        f = 1e12; % Penalize near-singular At
        return;
    end
    
    % Calculate structural covariance matrix
    Ainv = inv(At + reg_eps*eye(N));
    Sigma_structural = Ainv * Bt * Ct * Ct' * Bt' * Ainv';
    
    % Sigma_structural = Sigma_structural*10;
    % Sigma_emp_t = Sigma_emp_t*10;
    % Objective: Frobenius norm squared of the difference
    f = norm(Sigma_structural - Sigma_emp_t, 'fro')^2;
end