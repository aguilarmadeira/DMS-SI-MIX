% parameters_dms.m script file
%
% Purpose:
%
% File parameters_dms sets the algorithmic strategies, parameters,
% constants, and tolerances values to be used by the function dms, 
% which can be user modified.
%
% DMS Version 0.2.
%
% Copyright (C) 2011 A. L. Custódio, J. F. A. Madeira, A. I. F. Vaz, 
% and L. N. Vicente.
%
% http://www.mat.uc.pt/dms
%
% This library is free software; you can redistribute it and/or
% modify it under the terms of the GNU Lesser General Public
% License as published by the Free Software Foundation; either
% version 2.1 of the License, or (at your option) any later version.
%
% This library is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
% Lesser General Public License for more details.
%
% You should have received a copy of the GNU Lesser General Public
% License along with this library; if not, write to the Free Software
% Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307, USA.
%
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Output Options.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
output = 0; % 0-2 variable: 0 if only a final report is displayed at the 
            % screen; 1 if at each iteration output is displayed at the
            % screen and recorded in a text file stored at the current directory. 
            % If solving a biobjective problem, a plot of the approximated 
            % Pareto frontier computed will also be displayed and stored in 
            % a jpg format in the current directory; 2 level of output similar
            % to 1, but additionally at each iteration the current approximation
            % to the Pareto front is recorded in a file;
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Stopping Criteria.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
stop_alfa = 1;     % 0-1 variable: 1 if the stopping criterion is based
                   % on the step size parameter; 0 otherwise.
tol_stop  = 10^-8; % Lowest value allowed for the step size parameter.
%
stop_feval = 1;     % 0-1 variable: 1 if the stopping criterion is based
                    % on a maximum number of function evaluations; 0
                    % otherwise.
max_fevals = 20000; % Maximum number of function evaluations allowed.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Algorithmic Options.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Initialization.
%
list = 3;   % 0-4 variable: 0 if the algorithm initializes the iterate
            % list with a single point; 1 if a latin hypercube sampling
            % strategy is considered for initialization; 2 if 
            % random sampling is used; 3 if points are considered 
            % equally spaced in the line segment, joining the 
            % variable upper and lower bounds; 4 if the algorithm is
            % initialized with a list provided by the optimizer;
            % 5 if Halton sequences; 6 if Sobol numbers.
%
user_list_size = 0;  % 0-1 variable: 1 if the user sets below the iterate 
                     % list initial size; 0 if the iterate list initial size
                     % equals the problem dimension.
%                     
nPini = 50; % Number of points to consider in the iterate
            % list initialization, when its size is defined 
            % by the user.            
%
% Cache Use.
%
load_cache = 0; % 0-1 variable: 1 if a previous saved cache should be loaded
                % for use; 1 otherwise.
%
cache = 1; % 0-1 variable: 0 if point evaluation is always done;
           % 1 if a cache is maintained.
%
tol_match = tol_stop; % Tolerance used in point comparisons, when 
                      % considering a cache.
%
save_cache = 0; % 0-2 variable: 1 if at the end of all iterations,
                % the current cache is saved on a file for posterior use;
                % 2 if cache is saved at the end of each iteration;
                % 0 otherwise. 
%
% List ordering.
%
spread_option = 1; % 0-2 variable: 1 if for each point in the current approximation
                   % to the Pareto frontier, each component of the objective 
                   % function is projected in the corresponding dimension and 
                   % points are ordered according to the largest gap between 
                   % consecutive points, just before polling; 2 if points are 
                   % ordered according to the largest gap between consecutive 
                   % points in the current approximation to the Pareto frontier,
                   % measured using Euclidean distance. Each point has only one 
                   % consecutive point lying in the approximation to the Pareto 
                   % frontier (the closest one); 0 if no ordering strategy is 
                   % considered.
%
% Directions and step size.
%
dir_dense  = 0;   % 0-1 variable: 1 if a dense set of directions should be 
                  % considered for polling; 0 otherwise.
%
alfa_ini  = 0.1;    % Initial step size. 
%
beta_par  = 0.5;  % Coefficient for step size contraction.
%
gamma_par = 2.0;    % Coefficient for step size expansion.
%
% End of parameters_dms.