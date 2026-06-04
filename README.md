# MSIC Test Pattern Generator (TPG) — Verilog Implementation

A hardware implementation of a **Mixed-Signal IC (MSIC) Test Pattern Generator** in Verilog HDL, based on the paper:

> *"Design and Verification of MSIC Test Pattern Generator"*
> — Parvathy Chandra, Vishnu V.S., IJournals, 2015

---

## Overview

This project implements a complete TPG system for generating high-quality test vectors for digital circuits. It uses a combination of an **LFSR-based seed generator** and a **Reconfigurable Johnson Counter**, whose outputs are XOR-combined to produce diverse test patterns. The design operates in a **test-per-clock** configuration, with dual-clock support and built-in output verification using two different tools.Original files are to be run on vivado while modified files are to be run on EDA playground.

---

## Architecture

```
          CLK1                    CLK2
           │                       │
           ▼                       ▼
   ┌──────────────┐      ┌──────────────────────┐
   │  LFSR Seed   │      │  Reconfigurable      │
   │  Generator   │      │  Johnson Counter     │
   │  (8-bit)     │      │  (8-bit, 3 modes)    │
   └──────┬───────┘      └───────────┬──────────┘
          │  seed_out                │  jc_out
          └──────────┬───────────────┘
                     ▼
            ┌─────────────────┐
            │   XOR Network   │  tpg_out = seed XOR jc_out
            └────────┬────────┘
                     │  tpg_out
                     ▼
            ┌─────────────────┐
            │  Circuit Under  │
            │  Test (CUT)     │
            └────────┬────────┘
                     │  comb_out
          ┌──────────┴──────────┐
          ▼                     ▼
  ┌──────────────┐    ┌──────────────────┐
  │  Reversible  │    │   LUT Verifier   │
  │  Verifier    │    │                  │
  └──────────────┘    └──────────────────┘
     rev_pass              lut_pass
```

---

## Modules

| Module | Description |
|---|---|
| `lfsr_seed_gen` | 8-bit LFSR using primitive polynomial x⁸+x⁶+x⁵+x⁴+1, clocked by CLK1 |
| `reconfig_johnson` | 8-bit Johnson counter with 3 configurable modes, clocked by CLK2 |
| `xor_network` | Bitwise XOR of LFSR seed and Johnson output to produce test patterns |
| `circuit_under_test` | Sample CUT: 4-bit adder (lower nibble) + 4-bit XOR (upper nibble) |
| `reversible_verify` | Verifies CUT output by re-computing expected response from inputs |
| `lut_verify` | Verifies CUT output against a pre-computed golden LUT response |
| `msic_tpg_top` | Top-level module integrating all above blocks |

### Johnson Counter Modes

| `init` | `rj_mode` | Mode |
|--------|-----------|------|
| 0 | 1 | Initialization (shift zeros in) |
| 1 | 1 | Circular shift register |
| x | 0 | Normal Johnson counter (2l unique vectors) |

---

## Project Structure

```
msic-test-pattern-generator/
├── src/
│   └── msic_tpg_top.v          ← All design modules
├── testbench/
│   ├── tb_msic_tpg_original.v  ← Basic testbench
│   └── tb_msic_tpg_modified.v  ← Modified TB with VCD waveform dump
├── simulation/
│   └── (generated outputs go here)
├── docs/
│   └── (reference material)
├── run_sim.sh                   ← One-command simulation script
├── .gitignore
└── README.md
```

---

## Testbench Coverage

The testbench (`tb_msic_tpg_modified.v`) verifies:

- ✅ **Reset behaviour** — JC initializes to zero, LFSR seeds to `0x01`
- ✅ **Normal Johnson mode** — XOR output correctness across 8 clock cycles
- ✅ **Reversible verifier** — passes for all valid CUT outputs
- ✅ **LUT verifier** — passes for all valid CUT outputs
- ✅ **Circular shift mode** — waveform observation
- ✅ **Test-per-clock** — dual-clock interaction verified
- ✅ **Fault injection** — single-bit fault detected and flagged

The modified testbench also generates a **VCD waveform file** (`dump.vcd`) viewable in GTKWave.

---

## How to Run (Icarus Verilog)

### Prerequisites
```bash
#Install Xilinx Vivado
#Create a EDA Playground Account
```

### Run Simulation

```bash
# Clone the repo
git clone https://github.com/yourusername/msic-test-pattern-generator.git
cd msic-test-pattern-generator

# Give execute permission
chmod +x run_sim.sh

# Run with modified testbench (VCD output enabled)
./run_sim.sh

# Run with original testbench
./run_sim.sh original

# View waveform
gtkwave simulation/dump.vcd
```

### Manual Compile (if not using the script)

```bash
iverilog -o simulation/sim_out src/msic_tpg_top.v testbench/tb_msic_tpg_modified.v
vvp simulation/sim_out
```

---

## Expected Output

```
===== MSIC TEST =====

--- NORMAL JOHNSON ---
T=13 | SEED=01 | JC=00000001 | TPG=00000000 | OUT=00000000 | REV=1 | LUT=1
[PASS] XOR correct
[PASS] Reversible pass
[PASS] LUT pass
...

--- FAULT CHECK ---
[PASS] Fault injected correctly

==============================
PASS = 27
FAIL = 0
FINAL RESULT: ALL TESTS PASSED
==============================
```

---

## Tools Used

- **Language:** Verilog HDL (IEEE 1364-2001)
- **Simulator:** Icarus Verilog (iverilog) (EDA Playground)/ Xilinx Vivado
- **Waveform Viewer:** GTKWave

---

## Reference

> Parvathy Chandra, Vishnu V.S.,
> *"Design and Verification of MSIC Test Pattern Generator"*,
> International Journal of Innovative Research in Computer and Communication Engineering (IJournals), 2015.

---

## Team / Contributors

| Name | GitHub |
|------|--------|
| Asmitha Sathya Niranjan| [@asmith-sathya-niranjan]([https://github.com/asmith-sathya-niranjan]) | 
| Rishmita Achudan | [@username](https://github.com/username) |
| Anumolu Harika | [@username](https://github.com/username) |
| Tommundrula Harsha Veena | [@username](https://github.com/username) |
---

## License

This project is for academic purposes. See [LICENSE](LICENSE) for details.
