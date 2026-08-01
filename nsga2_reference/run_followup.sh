#!/bin/bash
# Corre depois da fila principal: controlos emparelhados + repeticao do rand-100.
set -u
LOG=definitive.log
while [ ! -f DEFINITIVE_DONE ]; do sleep 30; done
echo "=== FOLLOWUP INICIO $(date -u +%H:%M:%SZ) ===" >> $LOG
for cfg in "paired 50" "paired 100" "rand 100"; do
  set -- $cfg; TAG=$1; POP=$2
  echo "--- $TAG pop=$POP 30 sementes | inicio $(date -u +%H:%M:%SZ) ---" >> $LOG
  python3 -u nsga2_morap_v3.py $POP 30 $TAG >> $LOG 2>&1
  echo "--- $TAG pop=$POP concluido $(date -u +%H:%M:%SZ) ---" >> $LOG
done
python3 verify_rerun_100.py >> $LOG 2>&1
echo "=== FOLLOWUP FIM $(date -u +%H:%M:%SZ) ===" >> $LOG
touch FOLLOWUP_DONE
