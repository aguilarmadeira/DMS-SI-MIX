function T = b2_init_sensitivity(dirs, labels, delta_hv)
%B2_INIT_SENSITIVITY Are the B2 conclusions robust to the initialization?
%
%   b2_init_sensitivity()   % compares '.', 'b2_sobol50', 'b2_halton200'
%
% Motivation: the frozen B2 configuration initializes with Halton
% (list = 5, nPini = 50). This script compares complete 4-variant sweeps
% {fixed, cc_static, cc_dnr, full} run under DIFFERENT initializations,
% each stored in its own directory as b2_<pair>_<variant>.mat.
%
% Prespecified questions (frozen before the sensitivity runs):
%   Q1  does the variant ordering hold (CC-DNR best on most pairs, Full
%       budget-limited degradation on the largest pairs)?
%   Q2  does the decomposition hold (static-geometry term dominates the
%       Fixed-vs-CC-DNR contrast; rotation term small and >= 0)?
%   Q3  is DPAM1's adverse zig-zag geometry a Halton artifact or does it
%       persist under other initializations?
%
% HV reference: for each pair, ONE union front across ALL loaded configs
% and variants of that pair — so HV values are comparable across both
% variants AND initializations (but NOT to b2_summary.csv nor to
% b2_decomposition.csv, whose unions were smaller).
%
% Per (pair, config): HV of the four variants, best of the three
% protocol variants {fixed, cc_dnr, full}, geometry term
% (cc_static - fixed), rotation term (cc_dnr - cc_static).
% Sanity: State.poll_variant matches tag; cc_static rho == 0;
% trials/poll equal across fixed/cc_static/cc_dnr; the init parameters
% recorded in State.parameters (fields list / nPini when present) are
% printed for verification.
%
% Writes b2_init_sensitivity.csv.
%
% Author: J. F. A. Madeira (2026). Phase B harness.

    if nargin < 1 || isempty(dirs)
        dirs   = {'.', 'b2_sobol50', 'b2_halton200'};
        labels = {'halton50', 'sobol50', 'halton200'};
    end
    if nargin < 2 || isempty(labels)
        labels = dirs;
    end
    if nargin < 3 || isempty(delta_hv), delta_hv = 0.1; end

    pair_names = {'DPAM1_mix', 'FES1_mix', 'QV1_mix', 'DTLZ2_mix', ...
                  'ZDT3_mix', 'ZDT1_mix'};
    tags  = {'fixed', 'cc_static', 'cc_dnr', 'full'};
    prot3 = [1 3 4];                 % the three protocol variants

    % keep only existing directories
    keep = cellfun(@(d) exist(d, 'dir') == 7, dirs);
    if ~all(keep)
        fprintf('Skipping missing directories: %s\n', ...
                strjoin(dirs(~keep), ', '));
    end
    dirs = dirs(keep);  labels = labels(keep);
    nc   = numel(dirs);
    if nc < 2
        error(['b2_init_sensitivity: need at least two config ' ...
               'directories to compare.']);
    end

    fid = fopen('b2_init_sensitivity.csv', 'w');
    fprintf(fid, ['pair,config,hv_fixed,hv_cc_static,hv_cc_dnr,hv_full,' ...
                  'best_of3,geometry_effect,rotation_effect,' ...
                  'neval_fixed,neval_cc_dnr,neval_full\n']);

    T = struct([]);
    for p = 1:numel(pair_names)
        name = pair_names{p};

        % ---- load everything for this pair, build the global union ----
        S = cell(nc, numel(tags));
        U = [];
        for c = 1:nc
            for v = 1:numel(tags)
                f = fullfile(dirs{c}, sprintf('b2_%s_%s.mat', name, tags{v}));
                if exist(f, 'file')
                    S{c, v} = load(f);
                    assert(strcmp(S{c, v}.State.poll_variant, tags{v}), ...
                        'b2_init_sensitivity: %s holds variant ''%s''.', ...
                        f, S{c, v}.State.poll_variant);
                    U = [U, S{c, v}.Flist];                    %#ok<AGROW>
                end
            end
        end

        fprintf('\n=== %s ===\n', name);
        fprintf('%-11s %-11s %-11s %-11s %-11s %-8s %-11s %-11s\n', ...
                'config', 'fixed', 'cc_static', 'cc_dnr', 'full', ...
                'best_3', 'geometry', 'rotation');

        for c = 1:nc
            hv  = nan(1, numel(tags));
            ne  = nan(1, numel(tags));
            tpp = nan(1, numel(tags));
            for v = 1:numel(tags)
                if isempty(S{c, v}), continue; end
                R      = metrics_objective(S{c, v}.Flist, U, delta_hv);
                hv(v)  = R.hv;
                ne(v)  = S{c, v}.State.func_eval;
                tpp(v) = mean(S{c, v}.State.PollLog.trials_generated);
                if strcmp(tags{v}, 'cc_static')
                    Rst = S{c, v}.State.rhoK;
                    assert(all(Rst(:) == 0), ...
                        'cc_static with rho > 0 in %s/%s (?!).', ...
                        dirs{c}, name);
                end
            end
            if all(~isnan(tpp([1 2 3]))) && ...
               (abs(tpp(1) - tpp(2)) > 1e-12 || abs(tpp(2) - tpp(3)) > 1e-12)
                warning('%s/%s: trials/poll differ across cheap variants: %s', ...
                        dirs{c}, name, mat2str(tpp(1:3), 6));
            end

            hv3 = hv(prot3);
            if all(isnan(hv3))
                best = 'n/a';
            else
                [~, ib] = max(hv3);
                best    = tags{prot3(ib)};
            end
            geo = hv(2) - hv(1);
            rot = hv(3) - hv(2);

            fprintf('%-11s %-11.6g %-11.6g %-11.6g %-11.6g %-8s %+-11.4g %+-11.4g\n', ...
                    labels{c}, hv(1), hv(2), hv(3), hv(4), best, geo, rot);
            fprintf(fid, '%s,%s,%.10g,%.10g,%.10g,%.10g,%s,%.6g,%.6g,%d,%d,%d\n', ...
                    name, labels{c}, hv(1), hv(2), hv(3), hv(4), best, ...
                    geo, rot, ne(1), ne(3), ne(4));

            row = struct('pair', name, 'config', labels{c}, ...
                         'hv', hv, 'best_of3', best, ...
                         'geometry_effect', geo, 'rotation_effect', rot);
            if isempty(T), T = row; else, T(end+1) = row; end  %#ok<AGROW>
        end

        % recorded init parameters, for verification
        for c = 1:nc
            v1 = find(~cellfun(@isempty, S(c, :)), 1);
            if isempty(v1), continue; end
            par = S{c, v1}.State.parameters;
            li  = 'n/a';  np = 'n/a';
            if isfield(par, 'list'),  li = num2str(par.list);  end
            if isfield(par, 'nPini'), np = num2str(par.nPini); end
            fprintf('  [%s] recorded init: list=%s nPini=%s\n', ...
                    labels{c}, li, np);
        end
    end
    fclose(fid);
    fprintf(['\nWritten: b2_init_sensitivity.csv\n' ...
             'NOTE: HV reference = union across all configs and variants ' ...
             'per pair;\nvalues are comparable across configs here, but ' ...
             'not to earlier CSVs.\n']);
end
