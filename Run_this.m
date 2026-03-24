clear; clc; close all

rng(73);            % setting seed for random numbers 
% ==== PART 1: DATA IMPORT AND STRUCTURING =====
% Define data folder and filenames (update paths accordingly)
% Load data
load("data_spline/Full_data_Spline.mat");

% Extract metadata examples - Customize these based on your tables' structure
%dates = datetime(exogenous_assets.Date); % assuming all tables aligned by Date column
N = size(Aex,1); % Number of banks 
T = size(Aex,3); % number of time points
Kex = size(Aex,2); % Exogenous asset categories 
Ken = size(Aen,2); % Endogenous exposures count
Hliab = size(Lex,2)/N; % Liability categories

%==== PART 2: DATA PREPARATION ====
%Normalization by risky assets (per bank and time) as per Eq (3)
lambda = lambda.';    % change dimension
d_lambda = d_lambda.';
RA = RA.';
d_RA = d_RA.';


% Normalize exogenous/endogeneous assets and liabilities
A_ex_tilde = zeros(N, Kex, T);
L_ex_tilde = zeros(N, Hliab*N, T);
A_en_tilde = zeros(N, Ken, T);
for t=1:T
    D_inv = diag(1./RA(:,t));
    A_en_tilde(:,:,t) = D_inv * Aen(:,:,t);
    A_ex_tilde(:,:,t) = D_inv * Aex(:,:,t);
    L_ex_tilde(:,:,t) = D_inv * Lex(:,:,t);
end

%%%%%%%%%%%%%%%%%%%%%%%%
% 1. Step 1: Estimate time varying sigma
opts.h = 13;
opts.t_eval = 1:225;

out = estimate_HALAJ_HIPP_step1(d_lambda, opts);

Sigma_empirical = out.Sigma_tv;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 2. Find best initial start through random initializations for first
% period.
opts.t_eval = 1:1;
opts.warmstart = true;
opts.fmincon = true;
opts.display = 'off';

nSample = 100;
check_initial = zeros(nSample,27);
check_final = zeros(nSample,27);
check_fval = zeros(nSample,1);
best_theta = [];
best_fval = 10;
for i= 1:nSample
    opts.init_theta = rand(27,1);
    check_initial(i,:) = opts.init_theta';
    out2 = estimate_HALAJ_HIPP_step2(A_ex_tilde, L_ex_tilde, A_en_tilde, W, D_MB, RA, d_RA, lambda, Theta, S, Sigma_empirical, opts);
    check_final(i,:) = out2.theta_tv';
    check_fval(i,:) = out2.fval_tv';
    %pause;
    if out2.fval_tv < best_fval
        best_fval = out2.fval_tv;
        best_theta = out2.theta_tv';
    end
end
writematrix([check_initial, check_final, check_fval], 'convergence_check.xlsx', 'Sheet', 'Check'); 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 3. Run through whole sample with best initial values
opts.h = 13;
opts.t_eval = 1:225;
opts.warmstart = true;
opts.fmincon = true;
opts.init_theta = best_theta;
opts.display = 'off';

out3 = estimate_HALAJ_HIPP_step2(A_ex_tilde, L_ex_tilde, A_en_tilde, W, D_MB, RA, d_RA, lambda, Theta, S, Sigma_empirical, opts);
writematrix(out3.theta_tv', 'Estimated_parameters.xlsx', 'Sheet', 'con_bounded');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 4. Check identification
identification = zeros(225,4);              % rank, nparams, moments, fullrank check
for t = 1:225
    theta_hat = out3.theta_tv(:,t);

    info = check_identification_rank(theta_hat, t, A_ex_tilde, L_ex_tilde, A_en_tilde, W, D_MB, RA, d_RA, lambda, Theta, S, opts);
    identification(t,1) = info.rank;
    identification(t,2) = info.nparams;
    identification(t,3) = info.moments;
    identification(t,4) = info.fullrank;
end
writematrix(identification, 'identification_check.xlsx', 'Sheet', 'Check');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 5. Plot results

N = 10;
nC = 7;
Ken = 2;
M = 2;
nL = 6;
idio_contribution = compute_idio(out3, A_ex_tilde, L_ex_tilde, A_en_tilde, W, D_MB, RA, d_RA, lambda, Theta, S, N, nC, Ken, M, nL);
[common_contribution, common_by_layer] = compute_common(out3, A_ex_tilde, L_ex_tilde, A_en_tilde, W, D_MB, RA, d_RA, lambda, Theta, S, N, nC, Ken, M, nL);
[contagion_contribution, contagion_by_layer] = compute_contagion(out3, A_ex_tilde, L_ex_tilde, A_en_tilde, W, D_MB, RA, d_RA, lambda, Theta, S, N, nC, Ken, M, nL);

% [contagion_multiplication, cont_multi_by_layer] = compute_multiplication(out3, A_ex_tilde, L_ex_tilde, A_en_tilde, W, D_MB, RA, d_RA, lambda, Theta, S, N, nC, Ken, M, nL);
% Figures
Figure_3_a
print(gcf, fullfile('Figures', 'System_fig3a.jpeg'), '-djpeg', '-r600')
plot_results3ab(d_lambda, RA, Sigma_empirical)
print(gcf, fullfile('Figures', 'System_fig3b.jpeg'), '-djpeg', '-r600')
Figure_4
print(gcf, fullfile('Figures', 'System_fig4.jpeg'), '-djpeg', '-r600')
Figure_5
print(gcf, fullfile('Figures', 'System_fig5.jpeg'), '-djpeg', '-r600')
Figure_6
print(gcf, fullfile('Figures', 'System_fig6.jpeg'), '-djpeg', '-r600')
% Figure_7

individual_results = compute_individual(out3, A_ex_tilde, L_ex_tilde, A_en_tilde, W, D_MB, RA, d_RA, lambda, Theta, S, N, nC, Ken, M, nL);
plot_individualresults(individual_results)
% print(gcf, fullfile('Figures', 'Indi_fig8.jpeg'), '-djpeg', '-r600')
% price_contagion_mult = sum(contagion_by_layer, 1) ./ sum(contagion_contribution, 1);

Figure_D1
print(gcf, fullfile('Figures', 'Kernels_figd1.jpeg'), '-djpeg', '-r600')