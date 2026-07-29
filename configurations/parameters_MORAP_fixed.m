%% parameters_MORAP_fixed.m
%%
%% FROZEN RUN CONFIGURATION -- MORAP-NM exact finite validation -- Fixed.
%% Derived from parameters_dms_si_mix.m with the poll_variant/dnr_mode
%% pair for this specific reported run fixed explicitly below, so this
%% file is self-contained and does not rely on dms_si_mix.m's
%% poll_variant-inference-from-dnr_mode fallback, nor on the mutable
%% development template being in any particular state.
%% Matches Table experimental-configurations of the paper: Halton
%% initialization (list=5), nPini=50, alfa_ini=0.1,
%% (beta_par,gamma_par)=(0.5,1), max_fevals=20000.
%% Fixed: one permanent identity cycle (dnr_mode = 0).
%%

% parameters_dms_si_mix.m
%
% Parameters for DMS_SI_MIX: multiobjective direct search extended to
% mixed-variable problems (C + D + K) in canonical [0,1] space.
%
% CANONICAL SPACE
%   All variables are stored in z in [0,1]^n:
%     C : continuous coordinates, dense in [0,1]
%     D : ordered-discrete identities on the grid
%         {0, 1/(N-1), ..., 1}
%     K : categorical identities on the grid
%         {0, 1/(m-1), ..., 1}
%
%   alpha is a shared dimensionless resolution parameter with
%   block-specific realizations: a continuous displacement, an
%   ordered-discrete rank, and a capped cyclic categorical rank.
%
%   DNR changes only the active categorical neighbourhood ordering.
%   Stored categorical identities and Pareto-list entries are not
%   re-encoded when the active permutation changes.
%
% THIS FILE IS A GENERIC/DEVELOPMENT TEMPLATE, edited by hand between
% runs; its current values are NOT a record of any specific reported
% experiment and should not be trusted as such (dnr_mode, list, and
% nPini below are commonly changed while testing). The archived,
% self-contained configuration actually used for each reported B2 and
% MORAP-NM run is frozen in the seven parameters_B2_*.m /
% parameters_MORAP_*.m files distributed alongside this one; those set
% poll_variant explicitly and do not rely on dms_si_mix.m's
% inference-from-dnr_mode fallback. Use this template only as a
% starting point for new, not-yet-reported runs.
%
% Copyright (C) 2026 J. F. A. Madeira

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Output
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
output = 2; % 0: final report only
            % 1: iteration log at screen + dms_report.txt
            %    (biobjective: Pareto front plot + dms_plot.jpg)
            % 2: as 1, plus Pareto front written to dms_paretofront.txt
            %    at each iteration

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Stopping criteria
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
stop_alfa  = 1;       % 1: halt when all alfa < tol_stop; 0: disabled
tol_stop   = 1e-8;    % Lowest value allowed for the step size parameter

stop_feval = 1;       % 1: halt at max_fevals; 0: disabled
max_fevals = 20000;   % Maximum number of function evaluations allowed

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Cache
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
cache      = 1;           % 1: maintain evaluation cache; 0: always evaluate
load_cache = 0;           % 1: warm-start from file_cache argument
save_cache = 0;           % 0: never | 1: at halt | 2: every iteration
tol_match  = tol_stop;    % Matching tolerance in [0,1]^n

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Initialization
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% list:
%   0 : single point (x_ini or midpoint of bounds)
%   1 : Latin hypercube
%   2 : random
%   3 : line/center construction (equally spaced between bounds)
%   4 : file-based (ONLY for C+D problems, no K variables)
%   5 : Halton sequences
%   6 : Sobol numbers
list = 5;

user_list_size = 1;   % 1: use nPini below; 0: nPini = n_vars
nPini          = 50;  % Number of initial points (when user_list_size = 1)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% List ordering (Pareto spread)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
spread_option = 1; % 0: no ordering
                   % 1: order by largest gap per objective dimension
                   % 2: order by largest Euclidean gap between consecutive
                   %    points in the Pareto front approximation

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Directions and step size
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
dir_dense = 0;    % 1: dense random poll directions (QR-based); 0: +-e_i only
                  % Note: for mixed problems (D or K variables), dir_dense
                  % is ignored -- mixed_poll_trial always uses +-e_i moves.

alfa_ini  = 0.1;  % Initial step size (dimensionless, lives in [0,1]^n)
beta_par  = 0.5;  % Step size contraction coefficient
gamma_par = 1;  % Step size expansion coefficient.
                  % The per-center DNR scheme stores an explicit rotation
                  % counter rho_{i,j} per categorical variable and list
                  % entry (see dms_si_mix.m), advanced after a failed poll
                  % for the variables in their rank-one regime. Because
                  % the categorical epoch is read from that stored counter
                  % and is NOT reconstructed from the step size, the DNR
                  % mechanism no longer constrains gamma: any gamma >= 1 is
                  % admissible as far as the categorical scheme is
                  % concerned. The default is kept at 1.0 to match the
                  % non-expansive step-size assumption of the base
                  % convergence analysis (Theorem, gamma = 1); set it to a
                  % value > 1 only if a success-expansion variant is
                  % explicitly intended.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% DNR for categorical variables
%
% dnr_mode selects the deterministic permutation schedule:
%
%   0  identity  (no rotation)
%        Permutation stays fixed at (1,2,...,m) throughout.
%        Equivalent to a fixed numerical encoding of categories.
%        Use as a baseline to assess the benefit of DNR rotation.
%
%   1  covering_cycles  [default]
%        Minimal covering cyclic orderings (Walecki / round-robin).
%        For m levels generates M = ceil((m-1)/2) orderings whose
%        adjacency pairs cover all C(m,2) unordered pairs.
%        After M epochs the family repeats cyclically.
%        Strongest theoretical guarantee; no external toolbox required.
%
%   2  sobol_rank
%        Sobol-rank permutations (DNR paper, Madeira 2026).
%        At epoch e for variable i:  s_i = dnr_s0 + e + dnr_omega*i
%        and p_i = argsort(Sobol_point(s_i, m)).
%        Requires Statistics / Global Optimisation Toolbox.
%        Provides a rich infinite deterministic sequence.
%        Cost: O(m log m) per epoch transition.
%
%   3  affine
%        Affine permutations: p(j) = 1 + mod(a*(j-1)+b, m), gcd(a,m)=1.
%        O(m) construction, no sorting required.
%        Recommended when m is very large (m >> 100).
%
% PER-CENTER DNR (rho-counter scheme): the categorical permutation is not
% rotated on a global iteration epoch. Each list entry carries an explicit
% rotation counter rho_{i,j} for every categorical variable i: rhoK is an
% (nK x |Plist|) matrix, one column per list entry, that travels with the
% list through every sort, filter, insertion and rotation. After a
% complete unsuccessful poll of a center, the counter of each of its
% categorical variables is advanced by one IF that variable is in its
% rank-one regime (categorical step radius equal to 1); variables not yet
% in the rank-one regime are left unchanged, so two categorical variables
% of the same entry -- possibly of different cardinalities -- may rotate
% at different times. A new list entry enters with rho = 0. There is no
% rotation-rate parameter and no hold-length knob. Because the counter is
% stored, the scheme is independent of gamma. See mixed_poll_trial and
% categorical_step_radius in dms_si_mix.m.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
dnr_mode    = 0;   % 0=identity | 1=covering_cycles | 2=sobol_rank | 3=affine
poll_variant = 'fixed';   % explicit for this frozen run config;
                                   % overrides the inference-from-dnr_mode
                                   % fallback in dms_si_mix.m

% Parameters used only when dnr_mode = 2 (sobol_rank)
dnr_s0    = 1;       % Sobol base index
dnr_omega = 1000;    % Per-variable Sobol offset (decorrelates categorical variables)

% End of parameters_dms_si_mix.
