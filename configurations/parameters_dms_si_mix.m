% parameters_dms_si_mix.m
%
% Parameters for DMS_SI_MIX: multiobjective direct search extended to
% mixed-variable problems (C + D + K) in canonical [0,1] space.
%
% CANONICAL SPACE
%   All variables live in z ∈ [0,1]^n:
%     C : continuous, dense in [0,1]
%     D : discrete grid  {0, 1/(N-1), ..., 1}
%     K : categorical grid {0, 1/(m-1), ..., 1}  (under current perm_K)
%
%   alpha has a uniform geometric meaning across all variable types.
%   DNR rotation re-encodes K variables in perm_K; Pareto list invariant.
%
% Copyright (C) 2026 J. F. A. Madeira

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Output
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
output = 0; % 0: final report only
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
list = 6;

user_list_size = 1;   % 1: use nPini below; 0: nPini = n_vars
nPini          = 100;  % Number of initial points (when user_list_size = 1)

% init_extremes:
%   0 : off -- the initial list is exactly the nPini points of the
%       generator selected by 'list' above (legacy behaviour);
%   4 : continuous-anchor design. The list keeps EXACTLY nPini
%       canonically distinct points: the centre of the canonical
%       continuous box and the two axial bound points of each continuous
%       coordinate are written over the continuous coordinates of the
%       first 1 + 2*n_C rows of the low-discrepancy sample; the
%       ordered-discrete and categorical coordinates of those rows are
%       retained from the sample. A discarded duplicate is replaced by
%       continuing the same stream. Requires list = 5 or 6 and
%       nPini >= 1 + 2*n_C (9 for DPAM1/FES1/QV1/DTLZ2, 21 for
%       ZDT1/ZDT3). No effect when n_C = 0 (e.g. MORAP-NM).
%
% This is a MODIFIER of the generator chosen in 'list', not a generator:
% it composes with Halton (list = 5) and with Sobol (list = 6), so a
% sensitivity run varies exactly one factor at a time.
init_extremes = 0;   % 0 = off | 4 = continuous anchors

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
dnr_mode    = 3;   % 0=identity | 1=covering_cycles | 2=sobol_rank | 3=affine
poll_variant = 'cc_dnr';   % Phase B ablation: fixed | cc_static | cc_dnr | full
% Parameters used only when dnr_mode = 2 (sobol_rank)
dnr_s0    = 1;       % Sobol base index
dnr_omega = 1000;    % Per-variable Sobol offset (decorrelates categorical variables)

% End of parameters_dms_si_mix.
