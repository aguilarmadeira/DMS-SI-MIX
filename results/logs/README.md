# results/logs — per-poll records

**The per-poll logs are not separate files. They are embedded in every archive
in `results/archives/`, in `State.PollLog`.**

This folder exists to point at them.

## Fields

`State.PollLog` is a struct of parallel arrays, one entry per completed poll of
the run. For example, the Fixed run on DPAM1-Mix performed 1758 polls, so each
array has 1758 entries.

| Field | Meaning |
|---|---|
| `iter` | poll index |
| `alpha` | step size used to generate that poll |
| `trials_generated` | trial slots produced by the mixed poll |
| `trials_kept` | trials retained after removing boundary-degenerate and duplicate trials |
| `cache_hits` | trials answered from the cache |
| `new_evals` | new black-box evaluations charged to the budget |
| `accepted` | trials accepted into the nondominated list |
| `success` | whether the poll was successful |
| `coverage` | categorical coverage at that poll |

`trials_generated` minus `trials_kept` gives the boundary-degenerate and
duplicate trials discarded before evaluation; `new_evals` summed over all polls
equals `State.func_eval`.

## Extracting a log

```matlab
S = load('results/archives/b2_default/b2_DPAM1_mix_fixed.mat');
L = S.State.PollLog;
T = table(L.iter(:), L.alpha(:), L.trials_generated(:), L.trials_kept(:), ...
          L.cache_hits(:), L.new_evals(:), L.accepted(:), L.success(:), ...
          L.coverage(:), 'VariableNames', ...
          {'iter','alpha','trials_generated','trials_kept','cache_hits', ...
           'new_evals','accepted','success','coverage'});
writetable(T, 'DPAM1_fixed_polllog.csv');
```

The same works for any archive, including the MORAP-NM runs — but note the
filename caveat documented in `results/archives/README.md`.
