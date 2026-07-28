function b3_anytime_morap_nm(files, tags, front_csv, N_common)
%B3_ANYTIME_MORAP_NM Anytime post-processing at a common budget (no reruns).
%
%   b3_anytime_morap_nm()
%   b3_anytime_morap_nm(files, tags, front_csv, N_common)
%
% Author's B3 closure requirement: the three runs terminated by
% alpha-tolerance at different costs (4696 / 6168 / 6611), so a
% common-budget checkpoint is needed to exclude the alternative
% explanation "CC-DNR finds more points only because it evaluated more".
%
% NO RERUN IS NEEDED. The runs start with an empty cache and
% State.CacheP/CacheF store every evaluated point in evaluation order;
% under the weak-dominance acceptance rule, the algorithm's archive
% after N evaluations equals the weakly-nondominated subset (first
% occurrence kept on ties) of the first N cached points. This function
% replays the cache incrementally, records recall / IGD / HV gap on an
% evaluation grid, prints the common-budget table at
% N_common = 4696 (the Fixed total), and writes the anytime curves to
% b3_anytime_curves.csv for the supplement figure.
%
% REV.8 REVIEW FIX (item 2). The HV gap at each checkpoint used to be
% computed variant-by-variant via metrics_objective(archF, Fex', 0.1),
% i.e. with a reference point built from union(archF_variant, Fex) --
% a DIFFERENT r for each variant at each checkpoint whenever the
% variants' archives are not identical subsets of Fex, which is the
% common case. This version instead does two passes: pass 1 replays
% every variant's cache and records its archive at every grid
% checkpoint (or its final archive, if the variant's run ended before
% that checkpoint); pass 2 then visits each checkpoint once, builds ONE
% reference point from the union of Fex and all three variants'
% archives AT THAT CHECKPOINT, and evaluates every variant's HV gap
% against that common r. The recall/IGD columns are unaffected (they do
% not depend on a reference point) and are computed as before.
%
% Defaults: files = pilot_fixed_run{1,2,3}.mat (fixed, cc_dnr, full),
% front_csv = 'morap_nm_exact_front.csv', N_common = 4696.
%
% Author: J. F. A. Madeira (2026). Phase B harness. Requires
% hypervolume_exact.m on the path.

    if nargin < 1 || isempty(files)
        files = {'pilot_fixed_run1.mat', 'pilot_fixed_run2.mat', ...
                 'pilot_fixed_run3.mat'};
    end
    if nargin < 2 || isempty(tags)
        tags = {'fixed', 'cc_dnr', 'full'};
    end
    if nargin < 3 || isempty(front_csv)
        front_csv = 'morap_nm_exact_front.csv';
    end
    if nargin < 4 || isempty(N_common)
        N_common = 4696;
    end

    T   = readmatrix(front_csv);
    Xex = T(:, 1:6);
    Fex = T(:, 7:9);
    delta_hv = 0.1;

    m_card = [5, 7, 4, 7, 5, 7];   % cardinality per coordinate, order (z1,n1,...)

    nV = numel(files);

    % --- pass 1: replay each variant's cache, snapshot at every grid point --
    Mv       = zeros(1, nV);
    gridAll  = zeros(1, 0);   % row vector by construction (see note below)
    archF_at = cell(1, nV);   % archF_at{v}{g} = objective archive at grid(g)
    archX_at = cell(1, nV);
    recall_at = cell(1, nV);
    gridV    = cell(1, nV);

    for v = 1:nV
        S = load(files{v});
        St = S.State;
        CacheP = St.CacheP;
        CacheF = St.CacheF;
        M = size(CacheF, 2);
        assert(size(CacheP, 2) == M, 'b3_anytime: cache size mismatch.');
        Mv(v) = M;

        Xall = zeros(M, 6);
        for i = 1:6
            Xall(:, i) = round(CacheP(i, :)' * (m_card(i) - 1)) + 1;
        end

        grid = unique([100:100:M, N_common, M]);
        grid = grid(grid <= M);
        gridV{v} = grid;
        gridAll  = union(gridAll, grid);   %#ok<AGROW>

        archF = zeros(3, 0);
        archX = zeros(0, 6);
        g = 1;
        archF_at{v} = cell(1, numel(grid));
        archX_at{v} = cell(1, numel(grid));
        recall_at{v} = zeros(1, numel(grid));
        for k = 1:M
            f = CacheF(:, k);
            if isempty(archF) || ~any(all(archF <= f, 1))
                dom = all(f <= archF, 1) & any(f < archF, 1);
                archF(:, dom) = [];
                archX(dom, :) = [];
                archF(:, end+1) = f;            %#ok<AGROW>
                archX(end+1, :) = Xall(k, :);   %#ok<AGROW>
            end
            while g <= numel(grid) && k == grid(g)
                archF_at{v}{g}  = archF;
                archX_at{v}{g}  = archX;
                recall_at{v}(g) = mean(ismember(Xex, archX, 'rows'));
                g = g + 1;
            end
        end
    end

    % --- pass 2: common reference point per checkpoint, across variants ----
    fid = fopen('b3_anytime_curves.csv', 'w');
    fprintf(fid, 'variant,N_eval,recall,igd,hv_gap\n');
    fprintf('\n=== B3 anytime post-processing (common budget N = %d) ===\n', ...
            N_common);
    fprintf('%-8s %-8s %-10s %-10s %-12s\n', ...
            'variant', 'N', 'recall', 'IGD', 'HV gap');

    % (:)' forces a row vector regardless of how gridAll was assembled:
    % MATLAB's for-loop iterates over COLUMNS, so looping directly over a
    % column vector runs the body once with k bound to the whole vector,
    % not once per checkpoint. union() can return a column vector even
    % when its inputs are logically "row-like" (e.g. the very first call
    % union(zeros(1,0), row_vector) is not guaranteed to stay a row), so
    % this guard is required even though gridAll is seeded as a row above.
    common = nan(nV, 3);
    for k = gridAll(:)'
        % For each variant, use its snapshot at checkpoint k if it has one
        % (i.e. k <= its own M and k is on its own grid); otherwise use its
        % FINAL archive (the variant's run ended before k).
        Fv = cell(1, nV);
        Xv = cell(1, nV);
        for v = 1:nV
            [tf, idx] = ismember(k, gridV{v});
            if tf
                Fv{v} = archF_at{v}{idx};
                Xv{v} = archX_at{v}{idx};
            else
                Fv{v} = archF_at{v}{end};
                Xv{v} = archX_at{v}{end};
            end
        end

        U = Fex';
        for v = 1:nV
            U = [U, Fv{v}];   %#ok<AGROW>
        end
        z_ideal = min(U, [], 2);
        z_nad   = max(U, [], 2);
        r       = z_nad + delta_hv * (z_nad - z_ideal);
        hv_ref  = hypervolume_exact(Fex', r);

        for v = 1:nV
            if k > Mv(v)
                continue;   % this variant never reaches this checkpoint
            end
            rec  = mean(ismember(Xex, Xv{v}, 'rows'));
            igd  = igd_value_local(Fex', Fv{v});
            hv   = hypervolume_exact(Fv{v}, r);
            if hv_ref > 0
                gap = (hv_ref - hv) / hv_ref;
            else
                gap = NaN;
            end
            fprintf(fid, '%s,%d,%.6f,%.8g,%.8g\n', tags{v}, k, rec, igd, gap);
            if k == min(N_common, Mv(v))
                common(v, :) = [rec, igd, gap];
            end
        end
    end
    fclose(fid);

    for v = 1:nV
        fprintf('%-8s %-8d %-10.4f %-10.4g %-12.4g\n', ...
                tags{v}, min(N_common, Mv(v)), ...
                common(v, 1), common(v, 2), common(v, 3));
    end
    fprintf(['NOTE: hv_gap values in b3_anytime_curves.csv now use ONE ' ...
             'common reference point per checkpoint (rev.8 review fix, ' ...
             'item 2). They will generally differ slightly from any ' ...
             'earlier version of this file computed per-variant; ' ...
             'regenerate any supplement figure/table from this file.\n']);
end


function v = igd_value_local(Fref, F)
% Local copy of metrics_objective.m's igd_value, since this function
% now computes HV separately via hypervolume_exact and no longer calls
% metrics_objective.m directly.
    if isempty(F)
        v = Inf;
        return;
    end
    m = size(Fref, 2);
    d = zeros(1, m);
    for k = 1:m
        diffs = F - Fref(:, k);
        d(k)  = sqrt(min(sum(diffs.^2, 1)));
    end
    v = mean(d);
end
