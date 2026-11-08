# MATLAB Audio QPSK Transceiver

A MATLAB implementation of a QPSK transmitter and receiver that sends a fixed-length bit packet through an audio channel. The receiver performs preamble detection, downconversion, matched filtering, synchronization, phase correction, symbol decisions, and bit recovery.

## Files

- `transmitter.m` — maps bits to QPSK symbols, applies pulse shaping and upconversion, and plays the waveform.
- `receiver.m` — records audio and processes incoming frames in a timer callback.
- `rtrcpuls.m` — square-root raised-cosine pulse helper used by both signal paths.

## Requirements

- MATLAB
- Audio input and output devices
- Signal Processing Toolbox and Communications Toolbox functions used by the scripts

## Usage

Add this directory to the MATLAB path. Start the receiver with a carrier frequency in hertz:

```matlab
recorder = receiver(3000);
```

Transmit a 432-bit row vector with the same carrier frequency:

```matlab
transmitter(packet, 3000);
```

The implementation was designed for a course GUI that provides the bit packet and reads the receiver's `UserData` fields. Hardware, acoustic conditions, and timing affect performance.

## Project note

This is a curated version of a team course project. It is presented as collaborative work and does not imply sole authorship. The pulse helper is a modified course/textbook utility, as noted in its source comments.

