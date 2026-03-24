%% --- Helper function for betaAt ---
function Scaling_factor = scaling(K)
    Scaling_factor = (sqrt(2) / K) * gamma((K + 1) / 2) / gamma(K / 2);
end