function b3a_conformity_morap_nm()
%B3A_CONFORMITY_MORAP_NM Representation-invariance conformity test (B3a).
%
% Protocol v2.1, Section 4.4, B3a: renames every category label (order
% and physics UNCHANGED — the label list keeps the same positions, and
% the objective lookup is transported consistently), then verifies that
% the run is identical to the published-label run. This is an
% implementation-conformity check of Theorem 3.6(c): the algorithm reads
% only canonical positions, never the label strings, so the entire
% trajectory must be bit-identical. NO superiority claim follows from
% this test (a Fixed geometry also passes it).
%
% Granularity of the comparison: final canonical list (Plist_z, Flist,
% alfa, rhoK, in order), global counters, and the ENTIRE per-poll
% instrumentation series (PollLog: iter, alpha, trials, kept, hits,
% new_evals, accepted, success, coverage) — a per-poll trajectory
% fingerprint over all ~15k polls.
%
% Run with the CC-DNR configuration in parameters_dms_si_mix.m
% (dnr_mode = 1; poll_variant = 'cc_dnr').
%
% Author: J. F. A. Madeira (2026). Phase B harness.

    % --- Run 1: published labels -----------------------------------------
    [~, ~, ~, ~, ~, S1] = driver_morap_nm();

    % --- Run 2: renamed labels, consistently transported ------------------
    data = morap_nm_data();
    new_labels = cell(1, 3);
    for i = 1:3
        for j = 1:data.m(i)
            new_labels{i}{j} = sprintf('RENAMED_%d_%d', i, j);
        end
    end
    ProblemData = { new_labels{1}, {(1:7)'}, ...
                    new_labels{2}, {(1:7)'}, ...
                    new_labels{3}, {(1:7)'} };
    func_F = @(x) obj_renamed(x, data, new_labels);
    [~, ~, ~, ~, ~, S2] = dms_si_mix(1, func_F, [], [], [], ProblemData, []);

    % --- Comparison -------------------------------------------------------
    fprintf('\n=== B3a: representation-invariance conformity (Thm 3.6) ===\n');
    ok = true;
    ok = check(ok, 'canonical list (Plist_z)', isequal(S1.Plist_z, S2.Plist_z));
    ok = check(ok, 'objective vectors (Flist)', isequal(S1.Flist,  S2.Flist));
    ok = check(ok, 'step sizes (alfa)',         isequal(S1.alfa,   S2.alfa));
    ok = check(ok, 'rotation counters (rhoK)',  isequal(S1.rhoK,   S2.rhoK));
    ok = check(ok, 'func_eval / iter / iter_suc', ...
        isequal([S1.func_eval S1.iter S1.iter_suc], ...
                [S2.func_eval S2.iter S2.iter_suc]));
    ok = check(ok, 'per-poll trajectory fingerprint (PollLog)', ...
        isequal(S1.PollLog, S2.PollLog));
    if ok
        fprintf('B3a RESULT: PASS — identical run under consistent relabeling.\n');
    else
        fprintf('B3a RESULT: FAIL — implementation reads label content somewhere.\n');
    end
end


function ok = check(ok, name, cond)
    if cond
        fprintf('  %-42s PASS\n', name);
    else
        fprintf('  %-42s FAIL\n', name);
        ok = false;
    end
end


function F = obj_renamed(x, data, new_labels)
% Same physics as morap_nm_objectives, keyed to the renamed labels:
% position j of the renamed list is the SAME physical type as position j
% of the published list (consistent transport, order unchanged).
    R = 1.0; C = 0.0; W = 0.0;
    for i = 1:3
        lab = x{2*i - 1};
        n_i = x{2*i};
        j   = find(strcmp(new_labels{i}, lab), 1);
        assert(~isempty(j), 'b3a: unknown label %s.', lab);
        R = R * (1 - (1 - data.r{i}(j))^n_i);
        C = C + data.c{i}(j) * n_i;
        W = W + data.w{i}(j) * n_i;
    end
    F = [1 - R; C; W];
end
