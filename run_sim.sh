#!/bin/bash
# ============================================================
#  run_sim.sh - Simulate MSIC TPG using Icarus Verilog (iverilog)
#  Usage:
#    ./run_sim.sh              → runs with modified TB (VCD dump enabled)
#    ./run_sim.sh original     → runs with original TB (no VCD)
# ============================================================

SRC=src/msic_tpg_top.v

if [ "$1" == "original" ]; then
    TB=testbench/tb_msic_tpg_original.v
    OUT=simulation/sim_original
    echo "[INFO] Using original testbench (no VCD output)"
else
    TB=testbench/tb_msic_tpg_modified.v
    OUT=simulation/sim_modified
    echo "[INFO] Using modified testbench (VCD output: simulation/dump.vcd)"
fi

# Compile
iverilog -o $OUT $SRC $TB

if [ $? -ne 0 ]; then
    echo "[ERROR] Compilation failed."
    exit 1
fi

# Run simulation
cd simulation
vvp ../$OUT

echo ""
echo "[INFO] Simulation complete."
echo "[INFO] To view waveform: gtkwave dump.vcd"
