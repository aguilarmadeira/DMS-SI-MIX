function T = b2_metrics(out_dir, delta_hv)
%B2_METRICS Combine the B2 runs into the ablation table.
%
%   T = b2_metrics()             % reads b2_<pair>_<variant>.mat from '.'
%
% For each pair, the HV reference is built by metrics_objective on the
% UNION of the three variant fronts (frozen formula, delta = 0.1), so
% hv_gap measures the gap to the combined-best front of the pair. IGD is
% additionally reported against a sampled analytical reference front
% where one exists (DTLZ2, ZDT3, ZDT1) — as in the paper, this measures
% proximity to the CONTINUOUS analytical front (the mixed formulation
% has a different attainable front, so it is a proximity diagnostic, not
% an optimality gap). Cost columns come from State.PollLog.
%
% Output struct array T(pair, variant) with all fields; also prints the
% table and writes b2_summary.csv.
%
% Author: J. F. A. Madeira (2026). Phase B harness.

    if nargin < 1 || isempty(out_dir), out_dir = '.'; end
    if nargin < 2 || isempty(delta_hv), delta_hv = 0.1; end

    pair_names = {'DPAM1_mix', 'FES1_mix', 'QV1_mix', 'DTLZ2_mix', ...
                  'ZDT3_mix', 'ZDT1_mix'};
    an_ref = containers.Map( ...
        {'DTLZ2_mix', 'ZDT3_mix', 'ZDT1_mix'}, ...
        {'DTLZ2', 'ZDT3', 'ZDT1'});
    tags = {'fixed', 'cc_dnr', 'full'};

    fid = fopen(fullfile(out_dir, 'b2_summary.csv'), 'w');
    fprintf(fid, ['pair,variant,hv,hv_gap_union,igd_analytical,' ...
                  'n_eval,polls,trials_per_poll,new_per_poll,' ...
                  'cache_hits_per_poll,coverage,list_size\n']);

    T = struct([]);
    for p = 1:numel(pair_names)
        name = pair_names{p};
        S = cell(1, 3);
        ok = true;
        for v = 1:3
            f = fullfile(out_dir, sprintf('b2_%s_%s.mat', name, tags{v}));
            if ~exist(f, 'file')
                warning('b2_metrics: missing %s — pair skipped.', f);
                ok = false; break;
            end
            S{v} = load(f);
        end
        if ~ok, continue; end

        U = [S{1}.Flist, S{2}.Flist, S{3}.Flist];   % union of the 3 fronts

        if isKey(an_ref, name)
            Fan = ref_front_analytical(an_ref(name));
        else
            Fan = [];
        end

        fprintf('\n=== %s ===\n', name);
        fprintf('%-8s %-12s %-12s %-12s %-8s %-8s %-8s %-8s\n', ...
                'variant', 'HV', 'gap(union)', 'IGD(an)', 'N_eval', ...
                'polls', 'tr/poll', 'cover');
        for v = 1:3
            R  = metrics_objective(S{v}.Flist, U, delta_hv);
            if ~isempty(Fan)
                Ra  = metrics_objective(S{v}.Flist, Fan, delta_hv);
                igd_an = Ra.igd;
            else
                igd_an = NaN;
            end
            L  = S{v}.State.PollLog;
            row = struct('pair', name, 'variant', tags{v}, ...
                'hv', R.hv, 'hv_gap_union', R.hv_gap, ...
                'igd_analytical', igd_an, ...
                'n_eval', S{v}.State.func_eval, ...
                'polls', numel(L.iter), ...
                'trials_per_poll', mean(L.trials_generated), ...
                'new_per_poll', mean(L.new_evals), ...
                'cache_hits_per_poll', mean(L.cache_hits), ...
                'coverage', L.coverage(end), ...
                'list_size', size(S{v}.Flist, 2));
            if isempty(T), T = row; else, T(end+1) = row; end  %#ok<AGROW>
            fprintf('%-8s %-12.6g %-12.4g %-12.4g %-8d %-8d %-8.1f %-8.3f\n', ...
                tags{v}, R.hv, R.hv_gap, igd_an, row.n_eval, ...
                row.polls, row.trials_per_poll, row.coverage);
            fprintf(fid, '%s,%s,%.10g,%.6g,%.6g,%d,%d,%.2f,%.3f,%.3f,%.4f,%d\n', ...
                name, tags{v}, R.hv, R.hv_gap, igd_an, row.n_eval, ...
                row.polls, row.trials_per_poll, row.new_per_poll, ...
                row.cache_hits_per_poll, row.coverage, row.list_size);
        end
    end
    fclose(fid);
    fprintf('\nSummary written to b2_summary.csv\n');
end
