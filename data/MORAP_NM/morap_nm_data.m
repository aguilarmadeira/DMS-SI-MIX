function data = morap_nm_data()
%MORAP_NM_DATA Component data of the MORAP-NM benchmark (frozen).
%
% PROVENANCE (Protocol v2.1, Section 4.2 — data freeze, 2026-07-26):
%   Values transcribed VERBATIM from Table 2 of:
%     D. Cao, A. Murat, R. B. Chinnam, "Efficient exact optimization of
%     multi-objective redundancy allocation problems in series-parallel
%     systems", Reliability Engineering & System Safety 111 (2013)
%     154-163, DOI 10.1016/j.ress.2012.09.013.
%   The instance originates from Taboada & Coit (2012), Int. J. Applied
%   Evolutionary Computation 3(2):1-18 (ref. [30] in Cao et al.).
%   Structure: s = 3 subsystems, m = (5, 4, 5) component types,
%   n_max,i = 7 for every subsystem.
%
% MORAP-NM is a NO-MIXING variant defined on these data: each subsystem
% selects ONE component type z_i and a redundancy level n_i in {1..7}.
% It is NOT the formulation solved by Cao et al. (whose decision
% variables x_ij count components with type mixing; their exact front
% has 6112 points and is NOT reusable here). The MORAP-NM exact front
% is enumerated independently (enumerate_morap_nm.m): 578 Pareto-optimal
% decisions, all with distinct objective vectors.
%
% FROZEN CONVENTIONS (author-approved):
%   * objective F1 = 1 - R_sys (affine strictly decreasing transform of
%     R: preserves the Pareto order of reliability maximization and
%     keeps all objectives nonnegative); F2 = C_sys; F3 = W_sys;
%   * variable order (z1, n1, z2, n2, z3, n3), i.e. (K,D,K,D,K,D);
%   * category labels 'Si_Tj'.
%
% NOMINALITY CHECK (Protocol v2.1, Section 4.3), verified on these data:
%   in every subsystem, reliability and cost are (weakly) decreasing in
%   the published type index, but WEIGHT is non-monotone in all three
%   subsystems (S1: 9,6,4,7,8; S2: 5,7,3,4; S3: 6,8,2,4,4). Hence no
%   single total order of the types is simultaneously consistent with
%   reliability, cost, and weight (e.g. S1: T2 (.91,6,6) vs T3
%   (.89,6,4); S2: T1 (.97,12,5) vs T3 (.70,2,3); S3: T2 (.89,6,8) vs
%   T3 (.72,4,2)). Note: S2 type 4 is dominated by S2 type 3
%   (r .66<.70, c 2=2, w 4>3); consistently, it never appears on the
%   enumerated exact front. One dominated type does not invalidate the
%   (moderate) nominality claim.
%
% Author: J. F. A. Madeira (2026). Phase B harness.

    % --- Subsystem 1 (5 types) ---
    data.r{1} = [0.94, 0.91, 0.89, 0.75, 0.72];
    data.c{1} = [   9,    6,    6,    3,    2];
    data.w{1} = [   9,    6,    4,    7,    8];

    % --- Subsystem 2 (4 types) ---
    data.r{2} = [0.97, 0.86, 0.70, 0.66];
    data.c{2} = [  12,    3,    2,    2];
    data.w{2} = [   5,    7,    3,    4];

    % --- Subsystem 3 (5 types) ---
    data.r{3} = [0.96, 0.89, 0.72, 0.71, 0.67];
    data.c{3} = [  10,    6,    4,    3,    2];
    data.w{3} = [   6,    8,    2,    4,    4];

    data.s    = 3;
    data.m    = [5, 4, 5];
    data.nmax = [7, 7, 7];

    % Category labels 'Si_Tj'. Objectives are looked up BY LABEL, not by
    % list position, so the indexing-sensitivity test (Protocol B3b) can
    % reorder the label lists in ProblemData without touching the
    % objective definition; the physical meaning travels with the label.
    for i = 1:3
        data.labels{i} = cell(1, data.m(i));
        for j = 1:data.m(i)
            data.labels{i}{j} = sprintf('S%d_T%d', i, j);
        end
    end
end
