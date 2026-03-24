%%%%%%%%%%%%%%%%%%%%%%%%
% 1. Step 1: Estimate time varying sigma
% opts.h = 13;
% opts.t_eval = 1:225;
% 
% out = estimate_HALAJ_HIPP_step1(d_lambda, opts);
% 
% Sigma_empirical = out.Sigma_tv;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 2. Find best initial start through random initializations for first
% period.
% opts.t_eval = 1:1;
% opts.warmstart = true;
% opts.fmincon = true;
% out2 = estimate_HALAJ_HIPP_step2(A_ex_tilde, L_ex_tilde, A_en_tilde, W, D_MB, RA, d_RA, lambda, Theta, S, Sigma_empirical, opts);

% nSample = 1000;
% check_initial = zeros(nSample,27);
% check_final = zeros(nSample,27);
% check_fval = zeros(nSample,1)
% best_theta = [];
% best_fval = 10;
% for i= 1:nSample
%     opts.init_theta = rand(27,1);
%     check_initial(i,:) = opts.init_theta';
%     out2 = estimate_HALAJ_HIPP_step2(A_ex_tilde, L_ex_tilde, A_en_tilde, W, D_MB, RA, d_RA, lambda, Theta, S, Sigma_empirical, opts);
%     check_final(i,:) = out2.theta_tv';
%     check_fval(i,:) = out2.fval_tv';
%     %pause;
%     if out2.fval_tv < best_fval
%         best_fval = out2.fval_tv;
%         best_theta = out2.theta_tv';
%     end
% end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 3. Run through whole sample with best initial values
% opts.h = 13;
% opts.t_eval = 1:225;
% opts.warmstart = true;
% opts.fmincon = true;
% opts.init_theta = best_theta;
% opts.display = 'off';
% 
% out3 = estimate_HALAJ_HIPP_step2(A_ex_tilde, L_ex_tilde, A_en_tilde, W, D_MB, RA, d_RA, lambda, Theta, S, Sigma_empirical, opts);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 4. Check identification
% identification = zeros(225,4);              % rank, nparams, moments, fullrank check
% for t = 1:225
%     theta_hat = out3.theta_tv(:,t);
% 
%     info = check_identification_rank(theta_hat, t, A_ex_tilde, L_ex_tilde, A_en_tilde, W, D_MB, RA, d_RA, lambda, Theta, S, opts);
%     identification(t,1) = info.rank;
%     identification(t,2) = info.nparams;
%     identification(t,3) = info.moments;
%     identification(t,4) = info.fullrank;
% end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 5. Plot results
plot_results3ab(d_lambda, RA, Sigma_empirical)


