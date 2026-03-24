% estimate_HALAJ_HIPP_step1.m
% Step 1: Kernel-weighted estimation of the time-varying covariance matrix Sigma_t
% This step estimates the reduced-form covariance matrix of dLambda.
%
% Data inputs (must be set in workspace or passed in):
%   dLambda: N x T matrix of changes in capital ratios.
%
% Outputs:
%   out.Sigma_tv: N x N x T_eval array of estimated time-varying covariance matrices.
%   out.t_eval: Time points where estimation was performed.

function out = estimate_HALAJ_HIPP_step1(dLambda, opts)
    % --- Options ---
    if nargin < 2, opts = struct(); end
    if ~isfield(opts, 'h'), opts.h = 13; end
    if ~isfield(opts, 'kernel'), opts.kernel = 'normal'; end
    if ~isfield(opts, 't_eval'), opts.t_eval = 1:size(dLambda, 2); end
    if ~isfield(opts, 'verbose'), opts.verbose = true; end

    % --- Sizes ---
    [N, T] = size(dLambda);
    t_centers = opts.t_eval(:);
    nT_eval = numel(t_centers);
    
    if opts.verbose
        fprintf('Step 1: Estimating time-varying covariance matrix (N=%d, T=%d, nT_eval=%d)\n', N, T, nT_eval);
    end

    % --- Precompute kernel weights matrix ---
    bw = opts.h;
    Wweights = zeros(T, nT_eval);
    for ii = 1:nT_eval
        t0 = t_centers(ii);
        z = ((1:T)' - t0) / bw;
        switch lower(opts.kernel)
            case 'normal'
                w = exp(-0.5 * z.^2);
            otherwise
                error('Only normal kernel implemented');
        end
        w = w / sum(w);
        Wweights(:, ii) = w;
    end

    % --- Containers ---
    Sigma_tv = nan(N, N, nT_eval);

    % --- Main loop for estimation ---
    for idx = 1:nT_eval
        if opts.verbose, fprintf('Estimating Sigma at t0=%d (%d/%d)\n', t_centers(idx), idx, nT_eval); end
        
        w = Wweights(:, idx);
        dLambda_w = dLambda .* sqrt(w'); % Weighted data for covariance calculation
        
        % Compute the weighted covariance matrix
        Sigma_hat = dLambda_w * dLambda_w';
        
        % Ensure symmetry and positive definiteness
        Sigma_hat = (Sigma_hat + Sigma_hat') / 2;
        [~, p] = chol(Sigma_hat);
        if p ~= 0
            warning('Sigma matrix at t=%d is not positive definite. Adding regularization.', t_centers(idx));
            Sigma_hat = Sigma_hat + 1e-6 * eye(N);
        end
        
        Sigma_tv(:,:,idx) = Sigma_hat;
    end

    % --- Pack outputs ---
    out.Sigma_tv = Sigma_tv;
    out.t_eval = t_centers;
    out.opts = opts;
end
