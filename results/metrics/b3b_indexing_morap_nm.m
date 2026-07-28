function res = b3b_indexing_morap_nm(variant_tag)
%B3B_INDEXING_MORAP_NM Sensitivity to arbitrary categorical indexing (B3b).
%
% Protocol v2.1, Section 4.4, B3b: keeps the physical problem fixed and
% changes the POSITION each type occupies in the categorical lists, via
% the label_order argument of driver_morap_nm (objectives are looked up
% by label, so the physics travels with the label). Five deterministic
% indexings are used: the published order plus four fixed permutations.
%
% Frozen prior hypothesis (Protocol v2.1): "Fixed may be sensitive to
% the arbitrary indexing of component types, whereas CC-DNR is expected
% to reduce that sensitivity through periodic pair coverage; trajectory
% identity is not expected." B3b therefore compares FINAL METRICS
% (recall, HV gap, IGD, N_eval), never trajectory hashes.
%
% Usage: set the variant in parameters_dms_si_mix.m, then
%   res_fixed = b3b_indexing_morap_nm('fixed');    % dnr_mode=0, 'fixed'
%   res_ccdnr = b3b_indexing_morap_nm('cc_dnr');   % dnr_mode=1, 'cc_dnr'
%   save b3b_results.mat res_fixed res_ccdnr
% The tag is checked against State.poll_variant to prevent mislabeling.
%
% Author: J. F. A. Madeira (2026). Phase B harness.

    data = morap_nm_data();

    % Five deterministic indexings (position permutations per subsystem).
    P = cell(5, 3);
    P(1, :) = { 1:5,          1:4,        1:5         };   % published order
    P(2, :) = { [3 1 5 2 4],  [2 4 1 3],  [5 3 1 4 2] };
    P(3, :) = { 5:-1:1,       4:-1:1,     5:-1:1      };   % reversal
    P(4, :) = { [2 3 4 5 1],  [4 3 2 1],  [3 4 5 1 2] };
    P(5, :) = { [4 5 1 2 3],  [3 1 4 2],  [2 5 4 1 3] };

    n_idx = size(P, 1);
    res   = struct('tag', variant_tag, 'perm', {P}, ...
                   'recall', zeros(1, n_idx), 'precision', zeros(1, n_idx), ...
                   'hv_gap', zeros(1, n_idx), 'igd', zeros(1, n_idx), ...
                   'func_eval', zeros(1, n_idx));

    for q = 1:n_idx
        label_order = cell(1, 3);
        for i = 1:3
            label_order{i} = data.labels{i}(P{q, i});
        end
        fprintf('\n=== B3b (%s): indexing %d of %d ===\n', variant_tag, q, n_idx);
        [Plist, Flist, ~, ~, ~, State] = driver_morap_nm(label_order);
        assert(strcmp(State.poll_variant, variant_tag), ...
            ['b3b: parameters file is set to variant ''%s'' but the tag ' ...
             'is ''%s'' — fix parameters_dms_si_mix.m.'], ...
            State.poll_variant, variant_tag);
        R = pilot_metrics_morap_nm(Plist, Flist, State);
        res.recall(q)    = R.recall;
        res.precision(q) = R.precision;
        res.hv_gap(q)    = R.hv_gap;
        res.igd(q)       = R.igd;
        res.func_eval(q) = R.func_eval;
    end

    fprintf('\n=== B3b summary — variant %s (5 deterministic indexings) ===\n', ...
            variant_tag);
    fprintf('metric      worst        median       best\n');
    fprintf('recall      %-12.4f %-12.4f %-12.4f\n', ...
        min(res.recall), median(res.recall), max(res.recall));
    fprintf('HV gap      %-12.4g %-12.4g %-12.4g\n', ...
        max(res.hv_gap), median(res.hv_gap), min(res.hv_gap));
    fprintf('IGD         %-12.4g %-12.4g %-12.4g\n', ...
        max(res.igd), median(res.igd), min(res.igd));
    fprintf('N_eval      %-12d %-12d %-12d\n', ...
        max(res.func_eval), round(median(res.func_eval)), min(res.func_eval));
end
