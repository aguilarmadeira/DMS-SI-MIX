function Fref = ref_front_analytical(problem, npts)
%REF_FRONT_ANALYTICAL Sampled analytical Pareto fronts (ZDT1, ZDT3, DTLZ2).
%
%   Fref = ref_front_analytical('ZDT1')    % 2 x npts
%   Fref = ref_front_analytical('ZDT3')    % 2 x <=npts (disconnected)
%   Fref = ref_front_analytical('DTLZ2')   % 3 x ~npts (sphere octant)
%
% Used by b2_metrics.m as the IGD reference where an analytical front
% exists. Sampling is deterministic.
%
% Author: J. F. A. Madeira (2026). Phase B harness.

    if nargin < 2 || isempty(npts)
        npts = 1000;
    end

    switch upper(problem)

        case 'ZDT1'
            f1   = linspace(0, 1, npts);
            Fref = [f1; 1 - sqrt(f1)];

        case 'ZDT3'
            % Dense sample of the curve, then keep the lower envelope
            % (nondominated points): sort by f1 ascending and keep points
            % whose f2 is strictly below every previous f2.
            f1 = linspace(0, 1, 20 * npts);
            f2 = 1 - sqrt(f1) - f1 .* sin(10 * pi * f1);
            keep    = false(size(f1));
            best_f2 = Inf;
            for k = 1:numel(f1)
                if f2(k) < best_f2
                    keep(k) = true;
                    best_f2 = f2(k);
                end
            end
            Fref = [f1(keep); f2(keep)];
            % thin to about npts points, keeping endpoints
            idx  = unique(round(linspace(1, size(Fref, 2), npts)));
            Fref = Fref(:, idx);

        case 'DTLZ2'
            % Unit-sphere positive octant: (cos a cos b, cos a sin b, sin a)
            g = max(3, round(sqrt(npts)));
            [A, B] = meshgrid(linspace(0, pi/2, g), linspace(0, pi/2, g));
            Fref = [reshape(cos(A) .* cos(B), 1, []); ...
                    reshape(cos(A) .* sin(B), 1, []); ...
                    reshape(sin(A), 1, [])];

        otherwise
            error('ref_front_analytical: no analytical front for %s.', ...
                  problem);
    end
end
