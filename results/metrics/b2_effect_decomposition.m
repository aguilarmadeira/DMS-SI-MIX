function T = b2_effect_decomposition(out_dir, delta_hv)
%B2_EFFECT_DECOMPOSITION Split the Fixed-vs-CC-DNR contrast in B2.
%
%   T = b2_effect_decomposition()   % reads b2_<pair>_<variant>.mat from '.'
%
% Motivated by b2_rotation_diagnostics: in the B2 budget-limited runs the
% rotation counters advanced marginally (DTLZ2: not at all), so 'cc_dnr'
% operated mostly at epoch 0 — i.e. with the STATIC first covering cycle
% pi^(0), which is a zig-zag permutation, NOT the identity used by
% 'fixed'. The observed contrast therefore mixes two causes. The control
% variant 'cc_static' (cc_dnr trials, rho frozen at 0) separates them:
%
%   geometry effect  =  HV(cc_static) - HV(fixed)     (pi^(0) vs identity,
%                                                      no rotation at all)
%   rotation effect  =  HV(cc_dnr)   - HV(cc_static)  (counter advance only)
%   total            =  HV(cc_dnr)   - HV(fixed)      (= geometry + rotation)
%
% IMPORTANT: the HV reference here is rebuilt on the union of ALL loaded
% variant fronts (including cc_static, and full when present), so the HV
% values are NOT numerically comparable to b2_summary.csv (whose union
% had three fronts). Differences WITHIN this table are what matters.
%
% Sanity checks per pair:
%   * State.poll_variant matches the file tag;
%   * cc_static has rho identically zero on the final list;
%   * cc_static generated the same mean trials/poll as fixed and cc_dnr.
%
% Writes b2_decomposition.csv.
%
% Author: J. F. A. Madeira (2026). Phase B harness.

    if nargin < 1 || isempty(out_dir), out_dir = '.'; end
    if nargin < 2 || isempty(delta_hv), delta_hv = 0.1; end

    pair_names = {'DPAM1_mix', 'FES1_mix', 'QV1_mix', 'DTLZ2_mix', ...
                  'ZDT3_mix', 'ZDT1_mix'};
    tags = {'fixed', 'cc_static', 'cc_dnr', 'full'};   % full optional

    fid = fopen(fullfile(out_dir, 'b2_decomposition.csv'), 'w');
    fprintf(fid, ['pair,hv_fixed,hv_cc_static,hv_cc_dnr,hv_full,' ...
                  'geometry_effect,rotation_effect,total_effect\n']);

    T = struct([]);
    for p = 1:numel(pair_names)
        name = pair_names{p};

        S = struct();
        have = false(1, numel(tags));
        for v = 1:numel(tags)
            f = fullfile(out_dir, sprintf('b2_%s_%s.mat', name, tags{v}));
            if exist(f, 'file')
                S.(tags{v}) = load(f);
                have(v) = true;
                assert(strcmp(S.(tags{v}).State.poll_variant, tags{v}), ...
                    'b2_effect_decomposition: %s holds variant ''%s''.', ...
                    f, S.(tags{v}).State.poll_variant);
            end
        end
        if ~all(have(1:3))
            fprintf(['\n=== %s ===\n  missing one of ' ...
                     '{fixed, cc_static, cc_dnr} — pair skipped.\n'], name);
            continue;
        end

        % sanity: cc_static must never have advanced a counter
        Rst = S.cc_static.State.rhoK;
        assert(all(Rst(:) == 0), ...
            'b2_effect_decomposition: %s cc_static has rho > 0 (?!).', name);

        % union reference over all loaded fronts of this pair
        U = [];
        for v = 1:numel(tags)
            if have(v), U = [U, S.(tags{v}).Flist]; end   %#ok<AGROW>
        end

        hv = nan(1, numel(tags));
        tpp = nan(1, numel(tags));
        for v = 1:numel(tags)
            if ~have(v), continue; end
            R = metrics_objective(S.(tags{v}).Flist, U, delta_hv);
            hv(v)  = R.hv;
            tpp(v) = mean(S.(tags{v}).State.PollLog.trials_generated);
        end

        if abs(tpp(1) - tpp(2)) > 1e-12 || abs(tpp(2) - tpp(3)) > 1e-12
            warning(['b2_effect_decomposition: %s trials/poll differ ' ...
                     'across fixed/cc_static/cc_dnr: %s'], name, ...
                    mat2str(tpp(1:3), 6));
        end

        geo = hv(2) - hv(1);
        rot = hv(3) - hv(2);
        tot = hv(3) - hv(1);

        % rotation activity of the cc_dnr run, for context
        Rcd = S.cc_dnr.State.rhoK;

        fprintf('\n=== %s ===  (trials/poll %.0f)\n', name, tpp(1));
        fprintf('  HV: fixed %.6g | cc_static %.6g | cc_dnr %.6g', ...
                hv(1), hv(2), hv(3));
        if have(4), fprintf(' | full %.6g', hv(4)); end
        fprintf('\n');
        fprintf(['  geometry (cc_static - fixed)   : %+.6g\n' ...
                 '  rotation (cc_dnr - cc_static)  : %+.6g\n' ...
                 '  total    (cc_dnr - fixed)      : %+.6g\n'], ...
                geo, rot, tot);
        fprintf(['  cc_dnr rotation activity: entries with rho>0 ' ...
                 '%.1f%%, max rho %d\n'], ...
                100 * mean(any(Rcd > 0, 1)), max(Rcd(:)));

        row = struct('pair', name, 'hv_fixed', hv(1), ...
                     'hv_cc_static', hv(2), 'hv_cc_dnr', hv(3), ...
                     'hv_full', hv(4), 'geometry_effect', geo, ...
                     'rotation_effect', rot, 'total_effect', tot);
        if isempty(T), T = row; else, T(end+1) = row; end   %#ok<AGROW>
        fprintf(fid, '%s,%.10g,%.10g,%.10g,%.10g,%.6g,%.6g,%.6g\n', ...
                name, hv(1), hv(2), hv(3), hv(4), geo, rot, tot);
    end
    fclose(fid);
    fprintf('\nWritten: b2_decomposition.csv\n');
end
