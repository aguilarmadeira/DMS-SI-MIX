function M = front_matching(Zret, Zex, var_type, tol_match, Fret, Fex, tau_F)
%FRONT_MATCHING Exact-front matching rule (Experimental Protocol v1, S4.3).
%
%   M = front_matching(Zret, Zex, var_type, tol_match)
%   M = front_matching(Zret, Zex, var_type, tol_match, Fret, Fex, tau_F)
%
% Matching is by IDENTITY OF THE ENUMERATED SOLUTION first: a returned
% canonical point matches an exact-front point iff every finite (D/K)
% coordinate is identical on the canonical grid and every continuous
% coordinate agrees within tol_match (max-norm). The objective tolerance
% tau_F is used ONLY to flag near-duplicates in objective space; it never
% grants a match by itself (prevents ambiguity when two architectures
% have equal or near-equal objectives).
%
% Inputs:
%   Zret      n x p returned canonical points (columns)
%   Zex       n x q exact-front canonical points (columns)
%   var_type  1 x n cell of 'C' | 'D' | 'K' (as in meta.var_type)
%   tol_match continuous matching tolerance in canonical space
%   Fret,Fex  (optional) objective vectors for the near-duplicate flag
%   tau_F     (optional) objective-space flag tolerance
%
% Output struct M:
%   .match       p x q logical, identity matches
%   .recall      fraction of exact-front points matched by some return
%   .precision   fraction of returned points matching some exact point
%   .n_exact_hit number of exact-front points recovered
%   .unmatched_exact   indices of exact-front points never matched
%   .flag_near_F  p x q logical (only if F args given): objective vectors
%                 within tau_F but NOT identity-matched -- reported, never
%                 counted as matches
%
% Phase B harness. Author: J. F. A. Madeira (2026).

    n = size(Zret, 1);
    assert(size(Zex, 1) == n, 'front_matching: dimension mismatch.');
    p = size(Zret, 2);
    q = size(Zex, 2);

    is_finite_coord = false(n, 1);
    for i = 1:n
        is_finite_coord(i) = var_type{i} == 'D' | var_type{i} == 'K';
    end
    % Finite canonical coordinates are exact grid values; identity there
    % is equality up to representation noise, far below any grid gap.
    tol_finite = 1e-12;

    M.match = false(p, q);
    for a = 1:p
        for b = 1:q
            d = abs(Zret(:, a) - Zex(:, b));
            ok_fin = all(d(is_finite_coord)  <= tol_finite);
            ok_con = all(d(~is_finite_coord) <= tol_match);
            M.match(a, b) = ok_fin && ok_con;
        end
    end

    hit_exact        = any(M.match, 1);
    hit_ret          = any(M.match, 2);
    M.n_exact_hit    = sum(hit_exact);
    M.recall         = M.n_exact_hit / max(1, q);
    M.precision      = sum(hit_ret) / max(1, p);
    M.unmatched_exact = find(~hit_exact);

    if nargin >= 7 && ~isempty(Fret) && ~isempty(Fex)
        M.flag_near_F = false(p, q);
        for a = 1:p
            for b = 1:q
                if ~M.match(a, b) && ...
                        max(abs(Fret(:, a) - Fex(:, b))) <= tau_F
                    M.flag_near_F(a, b) = true;
                end
            end
        end
    end
end
