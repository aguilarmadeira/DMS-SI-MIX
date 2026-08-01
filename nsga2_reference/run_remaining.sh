#!/bin/bash
# Retomavel: cada invocacao salta as sementes ja gravadas.
set -u
LOG=definitive.log
echo "=== RETOMA $(date -u +%Y-%m-%dT%H:%M:%SZ) ===" >> $LOG
for cfg in "paired 50" "paired 100" "rand 100" "rand 20"; do
  set -- $cfg; TAG=$1; POP=$2
  echo "--- $TAG pop=$POP | inicio $(date -u +%H:%M:%SZ) ---" >> $LOG
  python3 -u nsga2_morap_v3.py $POP 30 $TAG >> $LOG 2>&1
  echo "--- $TAG pop=$POP concluido $(date -u +%H:%M:%SZ) ---" >> $LOG
done
python3 verify_rerun_100.py >> $LOG 2>&1
touch DEFINITIVE_DONE FOLLOWUP_DONE
echo "=== FIM $(date -u +%H:%M:%SZ) ===" >> $LOG
