%% -------------------- identification rank check (Rothenberg) --------------------
function info = check_identification_rank(theta_hat, t_eval, Aex, Lex, Aen, Wmat, DMB, RA, dRA, lambda, Theta, S_static, opts)
    % Numerically compute Jacobian J = d vech(Sigma_t)/ d theta at theta_hat and compute rank
    eps = 1e-6;
    [N, ~, ~] = size(Aex);
    nparams = numel(theta_hat);
    % baseline Sigma
    [At0, Bt0, Ct0] = maps_theta_to_matrices(theta_hat, t_eval, Aex, Lex, Aen, Wmat, DMB, RA, dRA, lambda, Theta, S_static, opts);
    % Check for numerical stability
    if rcond(At0) < 1e-8
        fprintf('at t=%d, check matrix A (it is near singular)', t_eval)
        pause;
    end
    
    % Calculate structural covariance matrix
    A0inv = inv(At0 + 1e-8*eye(N));
    Sigma0 = A0inv * Bt0 * Ct0 * Ct0' * Bt0' * A0inv';

    vech_idx = tril(true(N));
    m = sum(vech_idx(:));
    J = zeros(m, nparams);
    for j = 1:nparams
        th_up = theta_hat; th_up(j) = th_up(j) + eps;
        [At, Bt, Ct] = maps_theta_to_matrices(th_up, t_eval, Aex, Lex, Aen, Wmat, DMB, RA, dRA, lambda, Theta, S_static, opts);
        Ainv = inv(At + 1e-8*eye(N));
        S_up = Ainv * Bt * Ct * Ct' * Bt' * Ainv';
        dS = (S_up - Sigma0) / eps;
        J(:,j) = dS(vech_idx);
    end
    r = rank(J, 1e-8);
    info.J = J;
    info.rank = r;
    info.nparams = nparams;
    info.moments = m;
    info.fullrank = (r == nparams);
end
