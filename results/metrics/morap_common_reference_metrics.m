function R = morap_common_reference_metrics(Flist_variants, Fex, delta_hv, tol_F)
%MORAP_COMMON_REFERENCE_METRICS Common-reference-point HV comparison for
% MORAP-NM across poll variants (Fixed / CC-DNR / Full).
%
%   R = morap_common_reference_metrics(Flist_variants, Fex, delta_hv)
%
% WHY THIS FILE EXISTS (rev.8 review, item 2). pilot_metrics_morap_nm.m
% calls metrics_objective(Flist, Fex', delta_hv) once per variant, and
% metrics_objective.m builds its reference point as
%   r = z_nad(union(F, Fref)) + delta*(z_nad - z_ideal)(union(F, Fref)).
% Called separately per variant this way, r is built from
% union(F_variant, Fex) -- a DIFFERENT set for each variant whenever a
% variant's archive contains points that are not on the exact front
% (Fixed/CC-DNR/Full all have precision < 1 on MORAP-NM, so this is not
% a corner case). The three reported HV gaps in
% Table~\ref{tab:morap-results} of the paper are therefore not
% guaranteed to share one reference point, and are not strictly
% comparable to each other as printed.
%
% This function fixes that: it builds ONE common reference point from
% the union of the exact front and ALL compared variants' archives, and
% evaluates every variant's HV (and the exact front's HV) at that same
% r, so the three resulting hv_gap values are directly comparable.
%
% Flist_variants  struct, one field per variant, each a q_obj x p
%                 matrix of objective column vectors (minimization),
%                 e.g. Flist_variants.fixed, Flist_variants.ccdnr,
%                 Flist_variants.full -- field names are free-form and
%                 carried through to the output struct.
% Fex             q_obj x m exact-front objective matrix (columns)
% delta_hv        HV margin (default 0.1, Protocol D4 / paper Section 5.1)
% tol_F           max-norm objective-space tolerance for the
%                 n_false_positive diagnostic only (default 1e-6; well
%                 above the ~1e-12 precision loss from a CSV round-trip
%                 of Fex, well below the resolution needed to separate
%                 distinct MORAP-NM front points -- see note below)
%
% Output struct R:
%   R.(variant).hv       HV of that variant's archive at the common r
%   R.(variant).hv_ref   HV of the exact front at the common r
%                        (IDENTICAL across variants by construction --
%                        assert this if it is not)
%   R.(variant).hv_gap   (hv_ref - hv) / hv_ref
%   R.refpoint            the single common reference point r
%   R.n_false_positive.(variant)  number of archive points whose
%                        objective vector does not match (within tol_F,
%                        max-norm) any exact-front objective vector, for
%                        context on why r can shift per variant when
%                        computed the old (non-common) way. Matching uses
%                        a numeric tolerance rather than exact equality
%                        because Fex is typically loaded from a CSV: the
%                        integer objectives (C, W) round-trip exactly,
%                        but the continuous objective (1-R) is written
%                        with about 12 significant digits, not full IEEE
%                        double precision, so bitwise ismember() on the
%                        raw floating-point rows spuriously flags almost
%                        every point as unmatched even when it is exactly
%                        on the front. This diagnostic never feeds into
%                        hv_gap (computed geometrically by
%                        hypervolume_exact, which is insensitive to this
%                        level of noise); it is context only, in the same
%                        identity-vs-tolerance spirit as front_matching.m.
%
% USAGE (against the saved Fixed/CC-DNR/Full .mat files for MORAP-NM,
% per B3_final_manifest.txt: pilot_fixed_run1/2/3.mat = Fixed/CC-DNR/Full):
%
%   Sfix = load('pilot_fixed_run1.mat');   % Fixed  (func_eval=4696)
%   Sccd = load('pilot_fixed_run2.mat');   % CC-DNR (func_eval=6168)
%   Sful = load('pilot_fixed_run3.mat');   % Full   (func_eval=6611)
%   T    = readmatrix('morap_nm_exact_front_decisions.csv');
%   Fex  = T(:, 7:9)';
%   V.fixed = Sfix.Flist;  V.ccdnr = Sccd.Flist;  V.full = Sful.Flist;
%   R = morap_common_reference_metrics(V, Fex, 0.1);
%   fprintf('Fixed  hv_gap = %.6g\n', R.fixed.hv_gap);
%   fprintf('CC-DNR hv_gap = %.6g\n', R.ccdnr.hv_gap);
%   fprintf('Full   hv_gap = %.6g\n', R.full.hv_gap);
%
% (Confirm the .mat variable holding the objective archive is indeed
% named Flist and is q_obj x p with objectives in rows -- transpose if
% your saved orientation is p x q_obj.)
%
% Then replace the HV-gap row of Table~\ref{tab:morap-results} with
% R.fixed.hv_gap / R.ccdnr.hv_gap / R.full.hv_gap, and update the table
% caption to state that r is now common (see the caption text already
% updated in the tex to describe this convention).
%
% Author: J. F. A. Madeira (2026). Phase B harness -- rev.8 review fix.
% Requires hypervolume_exact.m on the path.

    if nargin < 3 || isempty(delta_hv)
        delta_hv = 0.1;
    end
    if nargin < 4 || isempty(tol_F)
        tol_F = 1e-6;
    end

    names = fieldnames(Flist_variants);
    assert(~isempty(names), ...
        'morap_common_reference_metrics: Flist_variants has no fields.');

    U = Fex;
    for i = 1:numel(names)
        U = [U, Flist_variants.(names{i})];     %#ok<AGROW>
    end
    z_ideal = min(U, [], 2);
    z_nad   = max(U, [], 2);
    r       = z_nad + delta_hv * (z_nad - z_ideal);
    R.refpoint = r;

    hv_ref = hypervolume_exact(Fex, r);

    for i = 1:numel(names)
        v  = names{i};
        F  = Flist_variants.(v);
        hv = hypervolume_exact(F, r);
        R.(v).hv     = hv;
        R.(v).hv_ref = hv_ref;
        if hv_ref > 0
            R.(v).hv_gap = (hv_ref - hv) / hv_ref;
        else
            R.(v).hv_gap = NaN;
        end
        R.n_false_positive.(v) = size(F, 2) - n_tolerance_matches_local(F, Fex, tol_F);
    end

    fprintf('--- MORAP-NM common-reference-point HV comparison ---\n');
    fprintf('common r = [%s]\n', sprintf('%.6g  ', r));
    for i = 1:numel(names)
        v = names{i};
        fprintf(['%-8s hv_gap = %.6g   (objective-space non-matches vs ' ...
                 'exact front, tol=%.0e: %d)\n'], ...
                v, R.(v).hv_gap, tol_F, R.n_false_positive.(v));
    end
    fprintf(['NOTE: compare these hv_gap values against the ones already ' ...
             'in the paper (computed per-variant against Fex only, via ' ...
             'metrics_objective.m through pilot_metrics_morap_nm.m). If ' ...
             'they differ, Table~\\ref{tab:morap-results} must be ' ...
             'updated to the common-reference values before submission.\n']);
end


function n = n_tolerance_matches_local(F, Fex, tol_F)
% Number of columns of F that lie within tol_F (max-norm) of some column
% of Fex. Tolerance-based on purpose: see the n_false_positive doc-block
% above for why exact ismember() on floating-point objective rows is the
% wrong test here (CSV round-trip precision on Fex, not a real content
% mismatch). This is a diagnostic only; it is never used in the hv_gap
% computation.
    p = size(F, 2);
    matched = false(1, p);
    for a = 1:p
        d = max(abs(Fex - F(:, a)), [], 1);
        matched(a) = any(d <= tol_F);
    end
    n = sum(matched);
end
