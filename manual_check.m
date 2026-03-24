function [theta_hat, fval] = manual_check(t, Aex, Lex, Aen, Wmat, DMB, RA, dRA, lambda, Theta, S_static, Sigma_empirical, opts)
    opts.t_eval = t:t;
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
        out2 = estimate_HALAJ_HIPP_step2(Aex, Lex, Aen, Wmat, DMB, RA, dRA, lambda, Theta, S_static, Sigma_empirical, opts);
        check_final(i,:) = out2.theta_tv';
        check_fval(i,:) = out2.fval_tv';
        %pause;
        if out2.fval_tv < best_fval 
            best_fval = out2.fval_tv;
            best_theta = out2.theta_tv';
        end
    end
    theta_hat = best_theta;
    fval = best_fval;
end
