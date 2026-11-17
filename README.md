# AHB Protocol — Learning Project

Part of the AMBA Learning Series: APB → **AHB** → AXI

---

## Overview

This project implements a simple AHB (Advanced High-performance Bus) system from scratch in Verilog. It is designed as a learning exercise to understand the AHB protocol — pipelined transfers, wait states, multiple slave handling, and the decoder/mux architecture.

---

## System Architecture

```
                    ┌─────────────┐
                    │  AHB_MASTER │
                    └──────┬──────┘
                           │ HADDR, HTRANS, HWRITE, HWDATA, HBURST
                    ┌──────▼──────┐
                    │ AHB_DECODER │ → HSEL0, HSEL1, HSEL2
                    └──────┬──────┘
           ┌───────────────┼───────────────┐
    ┌──────▼──────┐ ┌──────▼──────┐ ┌──────▼──────┐
    │  AHB_SLAVE  │ │  AHB_SLAVE  │ │  AHB_SLAVE  │
    │  (Slave 0)  │ │  (Slave 1)  │ │  (Slave 2)  │
    │  0 wait st. │ │  1 wait st. │ │  2 wait st. │
    └──────┬──────┘ └──────┬──────┘ └──────┬──────┘
           └───────────────┼───────────────┘
                    ┌──────▼──────┐
                    │   AHB_MUX   │ → HRDATA, HREADY, HRESP
                    └──────┬──────┘
                           │
                    ┌──────▼──────┐
                    │  AHB_MASTER │ (response back)
                    └─────────────┘
```

---

## Address Map

| Slave   | Address Range               | Wait States |
|---------|-----------------------------|-------------|
| Slave 0 | `0x0000_0000 – 0x0000_00FF` | 0           |
| Slave 1 | `0x0000_0100 – 0x0000_01FF` | 1           |
| Slave 2 | `0x0000_0200 – 0x0000_02FF` | 2           |
| Unmapped| `0x0000_0300` and above     | —           |

---

## File List

### Design Sources

| File            | Module        | Description                                      |
|-----------------|---------------|--------------------------------------------------|
| `ahb_slave.v`   | `AHB_SLAVE`   | Parameterized 4×32-bit register file slave       |
| `ahb_decoder.v` | `AHB_DECODER` | Generates HSEL0/1/2 from HADDR                   |
| `ahb_mux.v`     | `AHB_MUX`     | Routes HRDATA/HREADYOUT/HRESP from active slave  |
| `ahb_master.v`  | `AHB_MASTER`  | FSM-based master, single and 4-beat INCR4 bursts |
| `ahb_top.v`     | `AHB_TOP`     | Wires all modules together                       |

### Simulation Sources

| File                | Top Module        | Tests                                          |
|---------------------|-------------------|------------------------------------------------|
| `tb_ahb_slave.sv`   | `TB_AHB_SLAVE`    | Write/read all 4 regs on all 3 slave instances |
| `tb_ahb_decoder.sv` | `TB_AHB_DECODER`  | HSEL generation, boundaries, random addresses  |
| `tb_ahb_mux.sv`     | `TB_AHB_MUX`      | Slave selection routing, back-to-back switches |
| `tb_ahb_master.sv`  | `TB_AHB_MASTER`   | Single/burst transfers, slave stub with waits  |
| `tb_ahb_top.sv`     | `TB_AHB_TOP`      | Full system: all slaves, single + burst        |

---

## Module Details

### AHB_SLAVE
- 4 × 32-bit registers at offsets `0x00`, `0x04`, `0x08`, `0x0C`
- `WAIT_STATES` parameter controls how many cycles HREADYOUT is held low
- Two-phase pipeline: address captured on cycle N, data processed on cycle N+1
- `HRESP` asserts on out-of-range address access within slave region
- `HSEL` driven externally by decoder — slave does not decode HADDR

### AHB_DECODER
- Purely combinational
- Asserts exactly one HSEL at a time based on HADDR
- All HSELs low for unmapped addresses

### AHB_MUX
- Purely combinational
- Routes active slave's HRDATA, HREADYOUT, HRESP to master
- Default output when no slave selected: `HRDATA=0`, `HREADY=1`, `HRESP=0`

### AHB_MASTER
- FSM states: `IDLE → ADDR → DATA → DONE` (single)
- FSM states: `IDLE → ADDR → BURST_DATA → DONE` (4-beat burst)
- `BURST_EN=0`: single transfer, `HBURST=SINGLE`, `HTRANS=NONSEQ`
- `BURST_EN=1`: 4-beat incrementing burst, `HBURST=INCR4`, `HTRANS=NONSEQ` then `SEQ×3`
- Stalls automatically when `HREADY` is low (wait states from slave)
- `RDATA_CAP`: holds last read data received
- `HRESP_CAP`: latches error response from slave

---

## Key AHB Concepts Demonstrated

| Concept               | Where to observe                                      |
|-----------------------|-------------------------------------------------------|
| Two-phase pipeline    | `HADDR` leads `HWDATA` by one cycle in waveform       |
| Wait states           | `HREADY` low for 1–2 cycles on Slave 1 and Slave 2   |
| HTRANS encoding       | NONSEQ on first beat, SEQ on burst beats 2–4          |
| Multiple slave select | Only one HSEL high at a time — decoder output         |
| Mux routing           | HRDATA switches cleanly as HSEL changes               |
| Error response        | HRESP goes high on out-of-range address access        |
| Burst transfer        | HADDR increments by 4 each beat, HBURST=INCR4         |

---

## Coding Style

- All signal names in `ALL_CAPS`
- Active-low asynchronous reset (`HRESETn`)
- `begin-end` blocks on all always statements
- No generate blocks, no packed arrays
- Parameters used only where necessary (`WAIT_STATES` in slave)
- Testbench inputs use `$random` — no hardcoded data values
- No self-checking in testbenches — waveform analysis in Vivado

---

## Simulation (Vivado)

1. Create a new RTL project in Vivado
2. Add all `.v` files as design sources
3. Add the relevant `.sv` file as simulation source
4. Set the corresponding `TB_*` module as top for simulation
5. Run behavioral simulation and add signals to waveform window

**Recommended waveform signals for `tb_ahb_top`:**
- `HADDR`, `HTRANS`, `HWRITE`, `HBURST`, `HWDATA`
- `HRDATA`, `HREADY`, `HRESP`
- `HSEL0`, `HSEL1`, `HSEL2`
- `DONE`, `RDATA_CAP`, `HRESP_CAP`
- `DUT/U_SLAVE0/REG_FILE`, `DUT/U_SLAVE1/REG_FILE`, `DUT/U_SLAVE2/REG_FILE`
