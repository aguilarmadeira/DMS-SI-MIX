# results/logs — per-poll logs

One log per reported run, recording the poll-by-poll trajectory: selected poll
center, poll step size, trials generated, acceptance outcomes, rotation-counter
state, and evaluation counts.

Expected contents: the `PollLog` records exported from each run, named so that
each log maps unambiguously to one parameter file in `configurations/` and one
archive in `results/archives/`.
