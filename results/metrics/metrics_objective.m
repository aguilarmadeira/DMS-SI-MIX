function R = metrics_objective(F, Fref, delta_hv)
%METRICS_OBJECTIVE Objective-space quality metrics (Protocol v1, S4.2).
%
%   R = metrics_objective(F, Fref, delta_hv)
%
% F        q_obj x p  objective vectors of the approximation (columns),
%                     minimization in every component
% Fref     q_obj x m  reference front (exact front in B3; union front in
%                     B1/B2 pairwise comparisons)
% delta_hv HV reference-point margin (protocol decision D4, default 0.1):
%          r = z_nad + delta_hv * (z_nad - z_ideal), computed on the
%          UNION of F and Fref -- the formula frozen in Section 5.1 of
%          the paper.
%
% Output struct R:
%   .hv        hypervolume of F w.r.t. r (exact; q_obj = 2 or 3)
%   .hv_ref    hypervolume of Fref w.r.t. the same r
%   .hv_gap    relative gap: (hv_ref - hv) / hv_ref (0 = matches ref)
%   .igd       inverse generational distance from Fref to F
%   .refpoint  the reference point r used
%
% Phase B harness. Author: J. F. A. Madeira (2026).

    if nargin < 3 || isempty(delta_hv)
        delta_hv = 0.1;
    end

    U       = [F, Fref];
    z_ideal = min(U, [], 2);
    z_nad   = max(U, [], 2);
    r       = z_nad + delta_hv * (z_nad - z_ideal);

    R.refpoint = r;
    R.hv       = hypervolume_exact(F,    r);
    R.hv_ref   = hypervolume_exact(Fref, r);
    if R.hv_ref > 0
        R.hv_gap = (R.hv_ref - R.hv) / R.hv_ref;
    else
        R.hv_gap = NaN;
    end
    R.igd = igd_value(Fref, F);
end

% hypervolume_exact.m (top-level file, on the same path) provides the
% exact-HV routine shared with morap_common_reference_metrics.m -- see
% that file for the common-reference-point MORAP-NM comparison added in
% the rev.8 review (item 2): this function alone, called once per
% variant with Fref = the exact front, gives each variant its OWN
% reference point r = f(union(F, Fref)), which need not coincide across
% variants when F is not a subset of Fref. Use
% morap_common_reference_metrics.m instead of this function when the
% reported HV gaps of several variants must share one r.


function v = igd_value(Fref, F)
% Inverse generational distance: mean over Fref of the Euclidean
% distance to the closest point of F.
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
