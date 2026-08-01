#!/bin/bash
# Corrida definitiva MORAP-NM. Sequencial, progresso em definitive.log.
set -u
LOG=definitive.log
echo "=== INICIO $(date -u +%Y-%m-%dT%H:%M:%SZ) ===" >> $LOG
for cfg in "rand 100" "rand 200" "rand 600" "rand 50" "halton 50" "halton 100" "rand 20"; do
  set -- $cfg; TAG=$1; POP=$2
  echo "--- $TAG pop=$POP 30 sementes | inicio $(date -u +%H:%M:%SZ) ---" >> $LOG
  python3 -u nsga2_morap_v3.py $POP 30 $TAG >> $LOG 2>&1
  echo "--- $TAG pop=$POP concluido $(date -u +%H:%M:%SZ) ---" >> $LOG
done
echo "=== FIM $(date -u +%Y-%m-%dT%H:%M:%SZ) ===" >> $LOG
touch DEFINITIVE_DONE
