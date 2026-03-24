% estimate_HALAJ_HIPP_step2.m
% Step 2: Estimate structural parameters by minimizing the distance between
% the empirical and structural covariance matrices.
%
% Data inputs (user must load / set these):
%   Aex, Lex, Aen, Wmat, DMB, RA, dRA, lambda, Theta, S_static
%   Sigma_empirical: N x N x T_eval array from Step 1.
%
% Outputs:
%   out.theta_tv: Estimated structural parameters over time.
%   out.A_tv, out.B_tv: Estimated structural matrices.
%   out.se_tv: Standard errors (approximated from Hessian).
%

function out = estimate_HALAJ_HIPP_step2(Aex, Lex, Aen, Wmat, DMB, RA, dRA, lambda, Theta, S_static, Sigma_empirical, opts)
    % --- Options ---
    if nargin < 12, opts = struct(); end
    if ~isfield(opts, 'h'), opts.h = 13; end
    if ~isfield(opts, 't_eval'), opts.t_eval = 1:size(Aex, 3); end
    if ~isfield(opts, 'verbose'), opts.verbose = true; end
    if ~isfield(opts, 'parallel'), opts.parallel = false; end
    if ~isfield(opts, 'init_theta'), opts.init_theta = []; end
    if ~isfield(opts, 'warmstart'), opts.warmstart = true; end
    if ~isfield(opts, 'use_static_S'), opts.use_static_S = false; end
    if ~isfield(opts, 'fmincon'), opts.fmincon = false; end
    if ~isfield(opts, 'display'), opts.display = 'iter'; end

    % --- Sizes ---
    [N, Kex, T_full] = size(Aex);
    [~, HL, ~] = size(Lex);
    [~, Ken, ~] = size(Aen);
    [M, ~, ~] = size(Wmat);
    nC = size(Theta, 2);
    nL = HL/N;
    T_eval = numel(opts.t_eval);
    
    nparams = M + nL + Ken + nC + N;  % gamma, delta, betaG, betaC, betaI
    if opts.verbose
        fprintf('Step 2: Estimating structural parameters (nparams=%d)\n', nparams);
    end

    % --- Initial guess ---
    if isempty(opts.init_theta)
        % Using level scale for all parameters, with non-negative lower bounds
        theta0 = [
            0.1 * ones(M, 1);    % gamma (price-mediated)
            0.1 * ones(nL, 1);   % delta (market-based)
            0.1 * ones(Ken, 1);  % betaG (interbank)
            0.1 * ones(nC, 1);   % betaC (common exposure)
            0.1 * ones(N, 1)     % betaI (idiosyncratic)
        ];
    else
        theta0 = opts.init_theta(:);
        if numel(theta0) ~= nparams, error('init_theta length mismatch'); end
    end
    
    % lb = zeros(nparams, 1); % All sensitivities should be non-negative
    lb = [1e-5*ones(M,1); 1e-5*ones(nL,1); 1e-5*ones(Ken,1); 1e-5*ones(nC,1); 1e-5*ones(N,1)];
    ub = [100*ones(M,1); 100*ones(nL,1); 100*ones(Ken,1); 10*ones(nC,1); 10*ones(N,1)];

    % --- Containers ---
    theta_tv = nan(nparams, T_eval);
    se_tv = nan(nparams, T_eval);
    A_tv = nan(N, N, T_eval);
    B_tv = nan(N, nC + N, T_eval);
    fval_tv = nan(1,T_eval);
    
    % --- Optimization options ---
    optimopts = optimoptions('fminunc', ...
        'Algorithm', 'quasi-newton', ...
        'Display', opts.display, ...
        'OptimalityTolerance', 1e-8, ...
        'StepTolerance', 1e-8, ...
        'MaxIterations', 50000, ...
        'MaxFunctionEvaluations', 1e7);
    
    if opts.fmincon
        optimopts = optimoptions('fmincon', ...
            'Algorithm', 'interior-point', ...
            'Display', opts.display, ...
            'OptimalityTolerance', 1e-8, ...
            'FunctionTolerance', 1e-16, ...
            'MaxIterations', 50000, ...
            'MaxFunctionEvaluations', 1e8);
    end

    % --- Main loop ---
    for idx = 1:T_eval
        t_eval = opts.t_eval(idx);
        Sigma_emp_t = Sigma_empirical(:, :, idx);
        
        if opts.verbose, fprintf('Estimating structural parameters for t=%d (%d/%d)\n', t_eval, idx, T_eval); end

        % Warm start
        if idx > 1 && opts.warmstart
            theta_init = theta_tv(:, idx-1) + 0.02*rand(nparams,1);
        else
            theta_init = theta0 + 0.01*rand(nparams,1);                 % added some random noise to check
        end

        % Objective function
        objFun = @(th) obj_structural_match(th, t_eval, Aex, Lex, Aen, Wmat, DMB, RA, dRA, lambda, Theta, S_static, Sigma_emp_t, opts);
        
        if opts.fmincon
            [theta_hat, fval, exitflag, output, ~, ~, hess] = fmincon(objFun, theta_init, [], [], [], [], lb, ub, [], optimopts);
        else
            [theta_hat, fval, exitflag, output, ~, hess] = fminunc(objFun, theta_init, optimopts);
        end
        if exitflag ~= 1
            fprintf('Convergence not achieved. try manually\n');
            % if T_eval ~= 1
            %     [theta_init, ~] = manual_check(idx, Aex, Lex, Aen, Wmat, DMB, RA, dRA, lambda, Theta, S_static, Sigma_empirical, opts);
            %     [theta_hat, fval, exitflag, output, ~, ~, hess] = fmincon(objFun, theta_init, [], [], [], [], lb, ub, [], optimopts);
            % end
        end
        fprintf('t=%d Algorithm terminated after %d iterations. (exitflag: %d)\n', idx, output.iterations, exitflag);
        fprintf('fval=%d is the likelihood value.\n', fval);
        if exitflag ~= 1 && opts.verbose
            fprintf('Convergence not achieved for t=%d (exitflag: %d)\n', t_eval, exitflag);
        end
        fprintf('t=%d, Objective value: %f\n', t_eval, fval);

        % Recover matrices
        [At, Bt, ~] = maps_theta_to_matrices(theta_hat, t_eval, Aex, Lex, Aen, Wmat, DMB, RA, dRA, lambda, Theta, S_static, opts);
        
        % Store results
        theta_tv(:, idx) = theta_hat;
        
        if ~isempty(hess)
            cov = pinv(hess);
            se = sqrt(max(diag(cov), 0));
        else
            se = nan(nparams, 1);
        end
        se_tv(:, idx) = se;
        A_tv(:,:,idx) = At;
        B_tv(:,:,idx) = Bt;
        fval_tv(:,idx) = fval;
    end

    % --- Pack outputs ---
    out.theta_tv = theta_tv;
    out.se_tv = se_tv;
    out.A_tv = A_tv;
    out.B_tv = B_tv;
    out.Sigma_tv = Sigma_empirical; % Re-using the empirical Sigma for consistency
    out.opts = opts;
    out.t_eval = opts.t_eval;
    out.fval_tv = fval_tv;
end



