% enumerate_pareto.m
%
% Exhaustive enumeration of the (finite) auxetic design space and exact
% Pareto front, used to validate the DMS_SI_MIX approximation. It reuses
% the SAME objective and domains as the optimisation wrapper, so the exact
% front is directly comparable to the DMS_SI_MIX result.
%
% It answers, with certainty:
%   - how many true Pareto points exist;
%   - which architectures appear on the exact front (is rotating dominated?);
%   - whether every L < max is dominated;
%   - whether the exact front collapses to single values of T / theta;
%   - the exact ranges of nu_eff, rho_total and SEA;
% and, if a DMS result file is present, how much of the exact front the
% DMS_SI_MIX run actually covered.
%
% Requirements on the path: the wrapper (auxetic_mix.m or
% auxetic_mix_fabricable.m). No DMS files are needed.
%
% NOTE: works only when every variable is discrete/categorical (a finite
% space). If a variable is continuous ([lb ub]) the script stops with a
% clear message. For the full auxetic_mix space (~1.44e6 points) expect a
% run of the order of a minute; the fabricable space is tiny and instant.
%
% % Author: J. F. A. Madeira (2026).

clear; clc;

%==========================================================================
% USER SETTINGS
%==========================================================================
PROBLEM_WRAPPER = 'auxetic_mix_fabricable_refined';   % or 'auxetic_mix_fabricable'
SAVE_RESULT     = true;            % write <wrapper>_exact_front.csv + .mat
COMPARE_DMS     = true;            % compare with <wrapper>_result.mat if present
TOL             = 1e-6;            % tolerance for objective-vector matching
%==========================================================================

fprintf('================================================================\n');
fprintf(' Exhaustive Pareto enumeration  --  wrapper: %s\n', PROBLEM_WRAPPER);
fprintf('================================================================\n');

if isempty(which(PROBLEM_WRAPPER)) && exist([PROBLEM_WRAPPER '.m'],'file') ~= 2
    error('Wrapper %s.m not found on the path.', PROBLEM_WRAPPER);
end

PB          = feval(PROBLEM_WRAPPER);
func_F      = PB.func_F;
ProblemData = PB.ProblemData;
nvar        = PB.n;
nobj        = PB.nobj;
vnames      = PB.var_names;
arch_names  = PB.arch_names;

%--------------------------------------------------------------------------
% 1. Build the value list for each variable (and detect continuous ones)
%--------------------------------------------------------------------------
vals  = cell(1, nvar);
iscat = false(1, nvar);
card  = zeros(1, nvar);
for i = 1:nvar
    d = ProblemData{i};
    if isnumeric(d) && numel(d) == 2
        error(['Variable x%d (%s) is continuous [lb ub]; exhaustive ' ...
               'enumeration requires a finite (discrete/categorical) ' ...
               'space. Replace its domain with a discrete grid.'], i, vnames{i});
    elseif iscell(d) && isnumeric(d{1})        % ordered discrete
        vals{i}  = d{1}(:);
        iscat(i) = false;
    else                                       % categorical (cell of strings)
        vals{i}  = d;
        iscat(i) = true;
    end
    card(i) = numel(vals{i});
end

N      = prod(card);
stride = [1, cumprod(card(1:end-1))];   % mixed-radix strides
fprintf('Variables : %d   cardinalities: [%s]\n', nvar, num2str(card));
fprintf('Total combinations: %s\n', addcommas(N));
if N > 5e6
    fprintf(['WARNING: large space (%s). This may take several minutes ' ...
             'and a lot of memory.\n'], addcommas(N));
end

%--------------------------------------------------------------------------
% 2. Enumerate and evaluate (reusing the wrapper objective)
%--------------------------------------------------------------------------
fprintf('\nEnumerating ...\n');
t0 = tic;

Ffeas = zeros(N, nobj);   % feasible objective rows (trimmed later)
Vfeas = zeros(N, nvar);   % feasible decision rows (col of P = arch index)
c     = 0;                % feasible counter
x     = cell(1, nvar);
report_every = max(1, floor(N/10));

for k = 1:N
    % mixed-radix decode of k into per-variable indices
    rem = k - 1;
    idx = zeros(1, nvar);
    for i = nvar:-1:1
        idx(i) = floor(rem / stride(i));
        rem    = rem - idx(i)*stride(i);
    end
    idx = idx + 1;

    % build decoded point x and a numeric decision row
    vrow = zeros(1, nvar);
    for i = 1:nvar
        if iscat(i)
            x{i}    = vals{i}{idx(i)};
            vrow(i) = idx(i);          % store category index
        else
            x{i}    = vals{i}(idx(i));
            vrow(i) = x{i};
        end
    end

    F = func_F(x);
    if all(isfinite(F))
        c = c + 1;
        Ffeas(c,:) = F(:).';
        Vfeas(c,:) = vrow;
    end

    if mod(k, report_every) == 0
        fprintf('  %3.0f%%  (%s / %s)\n', 100*k/N, addcommas(k), addcommas(N));
    end
end
Ffeas = Ffeas(1:c, :);
Vfeas = Vfeas(1:c, :);
fprintf('Feasible points: %s   (%.1f%% of the space)\n', addcommas(c), 100*c/N);

%--------------------------------------------------------------------------
% 3. Exact Pareto front (minimisation of [nu_eff, rho_total, -SEA])
%--------------------------------------------------------------------------
front = pareto_front_indices(Ffeas);   % indices into feasible arrays
Pf = Ffeas(front, :);
Pv = Vfeas(front, :);
np = size(Pf, 1);

% signed objectives for reporting (SEA = -f3)
nu  = Pf(:,1);
rho = Pf(:,2);
SEA = -Pf(:,3);

fprintf('\n=== EXACT PARETO FRONT ===\n');
fprintf('Pareto points: %d\n', np);
fprintf('Elapsed: %.1f s\n', toc(t0));

%--------------------------------------------------------------------------
% 4. Architecture distribution on the exact front
%--------------------------------------------------------------------------
archIdx = Pv(:,6);
fprintf('\n--- Architecture distribution on the exact front ---\n');
for a = 1:numel(arch_names)
    m = (archIdx == a);
    if any(m)
        fprintf('%-12s: %4d (%4.1f%%)  nu[%.2f,%.2f] rho[%.2f,%.2f] SEA[%.2f,%.2f]\n', ...
            arch_names{a}, sum(m), 100*sum(m)/np, ...
            min(nu(m)),max(nu(m)), min(rho(m)),max(rho(m)), min(SEA(m)),max(SEA(m)));
    else
        fprintf('%-12s: %4d  (dominated -- absent from the exact front)\n', arch_names{a}, 0);
    end
end

%--------------------------------------------------------------------------
% 5. Key questions
%--------------------------------------------------------------------------
fprintf('\n--- Key questions ---\n');
rot = find(strcmp(arch_names,'rotating'),1);
fprintf('1) rotating on exact front?  %s\n', ternary(any(archIdx==rot),'YES','NO (dominated)'));
Lf = unique(Pv(:,4));
fprintf('2) L values on front: [%s]  -> any below max? %s\n', ...
        num2str(Lf.'), ternary(any(Lf < max(vals{4})),'YES','NO'));
fprintf('3) T values on front: [%s]   theta values: [%s]\n', ...
        num2str(unique(Pv(:,3)).'), num2str(unique(Pv(:,7)).'));
fprintf('4) alpha [%g,%g]  E_i [%g,%g]  n [%g,%g]\n', ...
        min(Pv(:,1)),max(Pv(:,1)), min(Pv(:,2)),max(Pv(:,2)), min(Pv(:,5)),max(Pv(:,5)));
fprintf('5) nu[%.3f,%.3f]  rho[%.2f,%.2f]  SEA[%.2f,%.2f]\n', ...
        min(nu),max(nu), min(rho),max(rho), min(SEA),max(SEA));

%--------------------------------------------------------------------------
% 6. Optional: how much of the exact front did DMS_SI_MIX cover?
%--------------------------------------------------------------------------
dmsfile = sprintf('%s_result.mat', PROBLEM_WRAPPER);
if COMPARE_DMS && exist(dmsfile, 'file') == 2
    S = load(dmsfile, 'Flist');
    if isfield(S,'Flist') && ~isempty(S.Flist)
        Fdms = S.Flist.';                 % np_dms x nobj, same [nu,rho,-SEA]
        on_front = 0; dominated = 0;
        for j = 1:size(Fdms,1)
            d = max(abs(Pf - Fdms(j,:)), [], 2);
            if any(d < TOL)
                on_front = on_front + 1;
            elseif any(all(Pf <= Fdms(j,:),2) & any(Pf < Fdms(j,:),2))
                dominated = dominated + 1;
            end
        end
        fprintf('\n--- DMS_SI_MIX coverage (from %s) ---\n', dmsfile);
        fprintf('DMS points: %d | on exact front: %d (%.1f%% of %d exact) | dominated: %d\n', ...
            size(Fdms,1), on_front, 100*on_front/np, np, dominated);
    end
elseif COMPARE_DMS
    fprintf('\n(No %s found; skipping DMS coverage comparison.)\n', dmsfile);
end

%--------------------------------------------------------------------------
% 7. Save the exact front (labelled CSV + .mat)
%--------------------------------------------------------------------------
if SAVE_RESULT
    csvfile = sprintf('%s_exact_front.csv', PROBLEM_WRAPPER);
    fid = fopen(csvfile,'w');
    fprintf(fid,'idx,alfa,E_i,T,L,n,P,theta,nu_eff,rho_total,SEA\n');
    for k = 1:np
        fprintf(fid,'%d,%g,%g,%g,%g,%g,%s,%g,%.6f,%.6f,%.6f\n', ...
            k, Pv(k,1), Pv(k,2), Pv(k,3), Pv(k,4), Pv(k,5), ...
            arch_names{Pv(k,6)}, Pv(k,7), nu(k), rho(k), SEA(k));
    end
    fclose(fid);
    fprintf('\nExact front written to: %s\n', csvfile);
    save(sprintf('%s_exact_front.mat', PROBLEM_WRAPPER), ...
         'Pf','Pv','front','nu','rho','SEA','arch_names','card','N','c');
    fprintf('Saved: %s_exact_front.mat\n', PROBLEM_WRAPPER);
end

fprintf('\nDone.\n');

%==========================================================================
% LOCAL FUNCTIONS
%==========================================================================
function origidx = pareto_front_indices(F)
% Indices of the non-dominated rows of F (minimisation, all objectives).
% Sorting by columns first makes a single forward sweep correct, because a
% point can then only be dominated by an earlier (smaller-or-equal) point.
    [Fs, ord] = sortrows(F);
    front = (1:size(Fs,1)).';
    i = 1;
    while i <= numel(front)
        fi  = Fs(front(i), :);
        Ff  = Fs(front, :);
        dom = all(Ff >= fi, 2) & any(Ff > fi, 2);   % strictly dominated by fi
        dom(i) = false;                              % never remove fi itself
        front(dom) = [];
        i = i + 1;
    end
    origidx = ord(front);
end

function s = ternary(cond, a, b)
    if cond, s = a; else, s = b; end
end

function s = addcommas(n)
% thousands separators for readability
    s = sprintf('%d', round(n));
    s = regexprep(s, '\d{1,3}(?=(\d{3})+$)', '$0,');
end
% End of enumerate_pareto.
