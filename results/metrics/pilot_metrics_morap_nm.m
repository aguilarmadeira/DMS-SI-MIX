function R = pilot_metrics_morap_nm(Plist, Flist, State, front_csv, delta_hv)
%PILOT_METRICS_MORAP_NM Metrics of one driver_morap_nm run vs the exact front.
%
%   R = pilot_metrics_morap_nm(Plist, Flist, State)
%   R = pilot_metrics_morap_nm(Plist, Flist, State, front_csv, delta_hv)
%
% Compares one run of driver_morap_nm against the FROZEN exact front
% (default file 'morap_nm_exact_front.csv', the MATLAB/Python
% cross-validated enumeration: 578 decisions, all objective vectors
% distinct). Identity-based matching (Protocol v2.1 D3): the problem is
% all-finite, so identity = exact integer equality of the decision
% (z1,n1,z2,n2,z3,n3). delta_hv defaults to 0.1 (Protocol D4).
%
% Prints the pilot summary and returns struct R with:
%   recall, precision, n_exact_hit  (identity-based, vs 578)
%   hv, hv_ref, hv_gap, igd         (metrics_objective, frozen delta)
%   func_eval, frac_space           (N_eval, N_eval/34300)
%   polls, mean_new_per_poll, coverage_final   (from State.PollLog)
%   variant, budget_ok
%
% Pilot acceptance checks printed (Protocol v1 S5 / v2.1 S8):
%   budget: func_eval <= max_fevals (strict policy);
%   list consistency: returned Plist size equals State list size.
%
% NOTE (rev.8 review, item 2): this function's hv_gap uses
% metrics_objective.m, whose reference point r is built from
% union(Flist, Fex) for THIS run alone. Calling this function once per
% variant therefore does not guarantee the same r across variants (it
% coincides only if every variant's archive is a subset of Fex, which
% MORAP-NM precision figures show is not the case). For a cross-variant
% comparison whose HV gaps must share one r, use
% morap_common_reference_metrics.m instead, on the same set of Flist
% archives, and use ITS hv_gap values in any table that compares
% variants side by side.
%
% Author: J. F. A. Madeira (2026). Phase B harness.

    if nargin < 4 || isempty(front_csv)
        front_csv = 'morap_nm_exact_front.csv';
    end
    if nargin < 5 || isempty(delta_hv)
        delta_hv = 0.1;
    end

    T   = readmatrix(front_csv);
    Xex = T(:, 1:6);
    Fex = T(:, 7:9);
    assert(size(Xex, 1) == 578, ...
        'pilot_metrics_morap_nm: expected the frozen 578-point front.');

    % --- decode returned list to integer decision rows -------------------
    p    = numel(Plist);
    Xret = zeros(p, 6);
    for k = 1:p
        x = Plist{k};
        for i = 1:3
            v = sscanf(x{2*i - 1}, sprintf('S%d_T%%d', i));
            assert(~isempty(v), ...
                'pilot_metrics_morap_nm: unexpected label %s.', x{2*i - 1});
            Xret(k, 2*i - 1) = v;        % z_i (type index)
            Xret(k, 2*i)     = x{2*i};   % n_i (redundancy level)
        end
    end

    % --- identity-based matching (exact integer equality) ----------------
    hit_ex  = ismember(Xex,  Xret, 'rows');
    hit_ret = ismember(Xret, Xex,  'rows');
    R.recall      = mean(hit_ex);
    R.precision   = mean(hit_ret);
    R.n_exact_hit = sum(hit_ex);

    % --- objective-space metrics (frozen HV reference formula) -----------
    M        = metrics_objective(Flist, Fex', delta_hv);
    R.hv     = M.hv;
    R.hv_ref = M.hv_ref;
    R.hv_gap = M.hv_gap;
    R.igd    = M.igd;

    % --- cost and instrumentation ----------------------------------------
    R.func_eval  = State.func_eval;
    R.frac_space = State.func_eval / 34300;
    if isfield(State, 'poll_variant')
        R.variant = State.poll_variant;
    else
        R.variant = 'UNKNOWN (pre-Phase-B dms_si_mix: update to rev. 4)';
        warning(['pilot_metrics_morap_nm: State has no poll_variant / ' ...
                 'PollLog -- you are running a pre-Phase-B dms_si_mix.m. ' ...
                 'The ''full'' variant and the per-poll instrumentation ' ...
                 'require the rev. 4 file (generate_mixed_poll_set).']);
    end
    if isfield(State, 'PollLog') && ~isempty(State.PollLog.iter)
        L = State.PollLog;
        R.polls             = numel(L.iter);
        R.mean_new_per_poll = mean(L.new_evals);
        R.mean_gen_per_poll = mean(L.trials_generated);
        R.coverage_final    = L.coverage(end);
    end

    % --- pilot acceptance checks -----------------------------------------
    if isfield(State, 'parameters') && isfield(State.parameters, 'max_fevals')
        R.budget_ok = State.func_eval <= State.parameters.max_fevals;
    else
        R.budget_ok = true;   % cannot verify on this State version
    end
    list_ok     = (p == size(State.Flist, 2));

    fprintf('--- MORAP-NM pilot: variant %s ---\n', R.variant);
    fprintf('recall    %.4f   precision %.4f   (%d / 578 exact points)\n', ...
            R.recall, R.precision, R.n_exact_hit);
    fprintf('HV gap    %.6g   IGD %.6g   (delta = %g)\n', ...
            R.hv_gap, R.igd, delta_hv);
    fprintf('N_eval    %d (%.3f%% of the 34300-point space)\n', ...
            R.func_eval, 100 * R.frac_space);
    if isfield(R, 'polls')
        fprintf('polls     %d   trials/poll %.2f   new evals/poll %.2f   cat. coverage %.3f\n', ...
                R.polls, R.mean_gen_per_poll, R.mean_new_per_poll, ...
                R.coverage_final);
    end
    if R.budget_ok, s1 = 'PASS'; else, s1 = 'FAIL'; end
    if list_ok,     s2 = 'PASS'; else, s2 = 'FAIL'; end
    fprintf('checks    strict budget: %s   list consistency: %s\n', s1, s2);
    if ~R.budget_ok || ~list_ok
        warning('pilot_metrics_morap_nm: an acceptance check FAILED.');
    end
end
