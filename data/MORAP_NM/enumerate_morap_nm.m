function [Xdec, Fdec, Fobj] = enumerate_morap_nm(out_csv)
%ENUMERATE_MORAP_NM Exact Pareto front of MORAP-NM by full enumeration.
%
%   [Xdec, Fdec, Fobj] = enumerate_morap_nm()
%   [Xdec, Fdec, Fobj] = enumerate_morap_nm('morap_nm_exact_front.csv')
%
% Enumerates all 5*7*4*7*5*7 = 34 300 decisions of the MORAP-NM
% benchmark (morap_nm_data.m) and filters the Pareto-optimal set under
% strict Pareto dominance (Definition 2.2 of the paper: u dominates v
% iff u <= v componentwise and u ~= v; minimization).
%
% Two distinct objects are returned (Protocol v2.1, author's S8):
%   Xdec  |P*_dec| x 6  Pareto-optimal DECISIONS, columns
%                       (z1, n1, z2, n2, z3, n3) — used for
%                       configuration recovery, per-subsystem type/level
%                       analysis, first-hit statistics;
%   Fdec  |P*_dec| x 3  objective vectors (1-R, C, W) of those decisions;
%   Fobj  |F*_obj| x 3  DISTINCT nondominated objective vectors — used
%                       for HV, HV gap, IGD, objective recall/precision.
% Keeping both prevents losing distinct decisions that share an
% objective vector.
%
% Reference values from the frozen enumeration (2026-07-26, verified
% independently in Python): |P*_dec| = 578 and |F*_obj| = 578 — every
% Pareto-optimal decision has a DISTINCT objective vector, so
% identity-based front matching is unambiguous and 100% recall is in
% principle attainable by the algorithm's one-entry-per-vector list.
% S2 type 4 (dominated in the data table) never appears on the front.
% Front ranges: (1-R) in [2.99e-9, 0.6623], C in [6, 217], W in [9, 147].
%
% This front is NOT the published front of Cao et al. (2013): their
% formulation allows type mixing (6112 Pareto-optimal points); MORAP-NM
% is the no-mixing variant and its front is this independent object.
%
% Author: J. F. A. Madeira (2026). Phase B harness.

    data = morap_nm_data();
    m    = data.m;
    nmax = data.nmax;

    Ntot = prod(m) * prod(nmax);
    X    = zeros(Ntot, 6);
    F    = zeros(Ntot, 3);

    k = 0;
    for z1 = 1:m(1)
    for z2 = 1:m(2)
    for z3 = 1:m(3)
        z = [z1, z2, z3];
        for n1 = 1:nmax(1)
        for n2 = 1:nmax(2)
        for n3 = 1:nmax(3)
            n = [n1, n2, n3];
            R = 1.0; C = 0.0; W = 0.0;
            for i = 1:3
                R = R * (1 - (1 - data.r{i}(z(i)))^n(i));
                C = C + data.c{i}(z(i)) * n(i);
                W = W + data.w{i}(z(i)) * n(i);
            end
            k = k + 1;
            X(k, :) = [z1, n1, z2, n2, z3, n3];   % frozen interleaved order
            F(k, :) = [1 - R, C, W];              % frozen F1 = 1 - Rsys
        end
        end
        end
    end
    end
    end
    assert(k == Ntot);

    % Strict-dominance Pareto filter.
    nd = true(Ntot, 1);
    for a = 1:Ntot
        le  = all(F <= F(a, :), 2);
        neq = any(F ~= F(a, :), 2);
        if any(le & neq)
            nd(a) = false;
        end
    end

    Xdec = X(nd, :);
    Fdec = F(nd, :);
    Fobj = unique(Fdec, 'rows');

    fprintf('MORAP-NM enumeration: |Omega| = %d, |P*_dec| = %d, |F*_obj| = %d\n', ...
            Ntot, size(Xdec, 1), size(Fobj, 1));

    if nargin >= 1 && ~isempty(out_csv)
        T = [Xdec, Fdec];
        fid = fopen(out_csv, 'w');
        fprintf(fid, 'z1,n1,z2,n2,z3,n3,oneMinusR,C,W\n');
        fprintf(fid, '%d,%d,%d,%d,%d,%d,%.12g,%g,%g\n', T');
        fclose(fid);
        fprintf('Exact front (decisions) written to %s\n', out_csv);
    end
end
