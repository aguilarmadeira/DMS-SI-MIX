function hv = hypervolume_exact(F, r)
%HYPERVOLUME_EXACT Exact hypervolume for minimization, 2 or 3 objectives.
%
%   hv = hypervolume_exact(F, r)
%
% F  q_obj x p objective vectors (columns), minimization in every
%    component
% r  q_obj x 1 reference point
%
% Extracted from metrics_objective.m (rev.8 review, item 2) so that the
% same exact-HV routine can be shared by metrics_objective.m (per-pair
% reference point) and morap_common_reference_metrics.m (common
% reference point across several archives). Do not reimplement this
% logic a second time elsewhere; call this function instead.
%
% Author: J. F. A. Madeira (2026). Phase B harness.

    keep = all(F <= r, 1);          % only points dominating the reference
    F    = F(:, keep);
    if isempty(F)
        hv = 0;
        return;
    end
    F = nondominated_columns_local(F);
    switch size(F, 1)
        case 2
            hv = hv2d_local(F, r);
        case 3
            hv = hv3d_local(F, r);
        otherwise
            error('hypervolume_exact: q = %d not supported (2 or 3).', ...
                  size(F, 1));
    end
end


function hv = hv2d_local(F, r)
% Clean 2-D hypervolume sweep (F nondominated, all <= r, minimization).
    [~, ord] = sort(F(1, :), 'ascend');   % f1 ascending => f2 descending
    F  = F(:, ord);
    hv = 0;
    f2_prev = r(2);
    for k = 1:size(F, 2)
        hv = hv + (r(1) - F(1, k)) * (f2_prev - F(2, k));
        f2_prev = F(2, k);
    end
end


function hv = hv3d_local(F, r)
% Exact 3-D hypervolume by slicing along f3 (F nondominated, <= r).
    [f3s, ord] = sort(F(3, :), 'ascend');
    F  = F(:, ord);
    hv = 0;
    levels = [f3s, r(3)];
    for k = 1:size(F, 2)
        % Slab [f3(k), next level): points 1..k are active in this slab.
        height = levels(k + 1) - levels(k);
        if height <= 0
            continue;
        end
        A2 = nondominated_columns_local(F(1:2, 1:k));
        hv = hv + height * hv2d_local(A2, r(1:2));
    end
end


function G = nondominated_columns_local(F)
% Keep the weakly-nondominated columns of F (minimization), first
% occurrence kept on ties -- consistent with the algorithm's archive.
    p    = size(F, 2);
    keep = true(1, p);
    for a = 1:p
        for b = 1:p
            if a ~= b && keep(b) && all(F(:, b) <= F(:, a)) ...
                    && (any(F(:, b) < F(:, a)) || b < a)
                keep(a) = false;
                break;
            end
        end
    end
    G = F(:, keep);
end
