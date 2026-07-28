function b2_rotation_diagnostics(out_dir)
%B2_ROTATION_DIAGNOSTICS Did CC-DNR rotation actually trigger in B2?
%
% Post-hoc diagnosis from the saved b2_*.mat States (no reruns). The
% rotation counter rho_{i,j} advances only after a complete UNSUCCESSFUL
% poll of an entry whose categorical variable i is in its rank-one
% regime, alpha < 3/(2 m_i). Hypothesis under test: in the
% budget-limited large-cardinality B2 runs (m up to 126, thresholds
% 0.012-0.017, alpha0 = 0.1, success-dominated trajectories), rotation
% rarely triggers, so 'cc_dnr' operates mostly at epoch 0 -- i.e. as a
% DIFFERENT FIXED permutation (the first Walecki cycle, not the
% identity) -- and the Fixed-vs-CC-DNR contrast on the pairs is partly
% an indexing effect (B3b type), not accumulated rotation.
%
% For each pair and each variant in {fixed, cc_dnr}, reports:
%   * polls, successes, unsuccessful polls (PollLog.success);
%   * per categorical variable: rank-one threshold 3/(2m) and the
%     fraction of executed polls whose center step size was in the
%     rank-one regime (PollLog.alpha);
%   * final-list counter statistics from State.rhoK: fraction of
%     entries with ANY counter > 0, max and mean counter;
%   * final cumulative pair coverage (PollLog.coverage).
%
% Reading: if rho is ~all-zero and rank-one occupancy is ~0, cc_dnr ran
% as a static zig-zag geometry; if counters advanced materially, the
% rotation mechanism was active.
%
% Author: J. F. A. Madeira (2026). Phase B harness.

    if nargin < 1 || isempty(out_dir), out_dir = '.'; end

    pairs = {'DPAM1_mix', 'FES1_mix', 'QV1_mix', 'DTLZ2_mix', ...
             'ZDT3_mix', 'ZDT1_mix'};
    % categorical cardinalities per pair (from the wrappers)
    mK = containers.Map();
    mK('DPAM1_mix') = [90, 42, 32];
    mK('FES1_mix')  = [55, 24, 94];
    mK('QV1_mix')   = [20, 101, 30];   %#ok<NASGU> % QV1: confirmed at runtime below
    mK('DTLZ2_mix') = [47, 103, 44, 56];
    mK('ZDT3_mix')  = [];              % filled from State (n_K varies)
    mK('ZDT1_mix')  = [];

    tags = {'fixed', 'cc_dnr'};

    for p = 1:numel(pairs)
        name = pairs{p};
        fprintf('\n=== %s ===\n', name);
        for v = 1:numel(tags)
            f = fullfile(out_dir, sprintf('b2_%s_%s.mat', name, tags{v}));
            if ~exist(f, 'file')
                fprintf('  %s: file missing, skipped\n', tags{v});
                continue;
            end
            S  = load(f);
            St = S.State;
            L  = St.PollLog;

            n_polls = numel(L.iter);
            n_suc   = sum(L.success ~= 0);
            n_unsuc = n_polls - n_suc;

            % cardinalities from covK (always present in rev. 4 States)
            mvec = cellfun(@(c) size(c, 1), St.covK);

            % rank-one occupancy per categorical variable
            occ = zeros(1, numel(mvec));
            for i = 1:numel(mvec)
                thr    = 1.5 / mvec(i);        % round(alpha*m) < 1.5
                occ(i) = mean(L.alpha < thr);
            end

            % final-list counters
            R        = St.rhoK;
            frac_any = mean(any(R > 0, 1));
            fprintf(['  %-7s polls %5d (suc %5d, unsuc %5d) | ' ...
                     'rank-one occupancy per K var: %s | ' ...
                     'entries with rho>0: %.1f%% | max rho %d | ' ...
                     'mean rho %.2f | coverage %.4f\n'], ...
                    tags{v}, n_polls, n_suc, n_unsuc, ...
                    mat2str(round(occ, 3)), 100 * frac_any, ...
                    max(R(:)), mean(R(:)), L.coverage(end));
        end
    end

    fprintf(['\nInterpretation aid: rank-one thresholds are 3/(2m) -> ' ...
             'e.g. m=24: 0.0625; m=56: 0.0268; m=94: 0.0160; m=126: 0.0119.\n' ...
             'alpha0 = 0.1 requires 1-4 halvings of an entry''s OWN step ' ...
             'to enter the regime; each halving costs one complete ' ...
             'unsuccessful poll of that entry.\n']);
end
