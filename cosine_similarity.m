N = size(A_ex_tilde,1);
T = size(A_ex_tilde,3);
Nsys = size(Theta,2);

exposures = zeros(N, Nsys, T);
for t = 1:T
    exposures(:,:,t) = [squeeze(A_ex_tilde(:,:,t)), -squeeze(L_ex_tilde(:,:,t))] * Theta;
    % Bt_sys = Bt_base * Theta;
    % Bt = [Bt_sys, eye(N)];
end

% exposures: 10 x 7 x 225 matrix of bank exposures by type over time

num_banks = size(exposures,1);
num_months = size(exposures,3);

% Initialize matrix to store sum of cosine similarities over time
cos_sim_sum = zeros(num_banks);

% Iterate over months
for t = 1:num_months
    % Extract exposures for month t (10 banks x 7 types)
    X = exposures(:,:,t);
    
    % Normalize rows to unit length for cosine similarity
    norms = sqrt(sum(X.^2, 2));
    % To avoid division by zero, set zero norms to 1 (or handle separately)
    norms(norms == 0) = 1;
    X_normalized = X ./ norms;
    
    % Compute cosine similarity as X_normalized * X_normalized'
    cos_sim_t = X_normalized * X_normalized';
    
    % Accumulate sum
    cos_sim_sum = cos_sim_sum + cos_sim_t;
end

% Average over months
average_cos_sim = cos_sim_sum / num_months;

% Display or return average_cos_sim as the average cosine similarity matrix
writematrix(average_cos_sim, 'cosine_similarity.xlsx', 'Sheet', 'cosine'); 