<!---

This file is used to generate your project datasheet. Please fill in the information below and delete any unused
sections.

You can also include images in this folder and reference them in the markdown. Each image must be less than
512 kb in size, and the combined size of all images must be less than 1 MB.
-->

## How it works

This project implements a lightweight Hardware Anomaly Detector for Vehicle-to-Everything (V2X) communication systems on the Tiny Tapeout platform.

The design receives a 64-bit packet serially through the input interface. After all 64 bits are received, the packet is stored and analyzed. Selected packet fields are extracted as features and processed by a lightweight neural-inspired Multiply-Accumulate (MAC) engine.

The MAC engine calculates a threat score using predefined weights. The generated score is compared against a threshold value to determine whether the packet is safe or potentially malicious.

If the score exceeds the threshold, the design raises an interrupt signal (`irq`) indicating an anomaly. Otherwise, the packet is considered safe. The final threat score is presented on the output pins, and a completion pulse (`done`) indicates the end of processing.

### Processing Flow

1. Serial Packet Reception
2. Packet Parsing
3. Feature Extraction
4. Neural MAC Computation
5. Threat Score Generation
6. Threshold Comparison
7. Alert Generation
8. Output Score Transmission

---

## How to test

The design can be tested using the supplied Cocotb testbench.

### Input Pins

* `ui[0]` : Serial packet bit input
* `ui[1]` : Bit valid
* `ui[2]` : Mode select
* `ui[3]` : Start
* `ui[4]` to `ui[7]` : Unused

### Output Pins

* `uo[7:0]` : Anomaly score

### Bidirectional Pins

* `uio[0]` : Done pulse
* `uio[1]` : IRQ output
* `uio[2]` : Telemetry TX
* `uio[3]` to `uio[7]` : Unused

### Test Case 1 – Safe Packet

Inject the following 64-bit packet serially:

0xAA00123400001122

Expected Result:

* IRQ = 0
* Score = 0x00

The packet is classified as safe.

### Test Case 2 – Suspicious Packet

Inject the following 64-bit packet serially:

0x00000000FEFE0000

Expected Result:

* IRQ = 1
* Score = 0xFF

The packet is classified as anomalous and an interrupt is generated.

---

## External hardware

No external hardware is required.

The design can be fully tested through simulation and can operate directly on the Tiny Tapeout demo board using the onboard RP2040 microcontroller for packet injection and output monitoring.

