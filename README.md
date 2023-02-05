# An optimized RISC-V processor
A pipelined RISC-V processor with realistic memory system built in Minispec hardware description language and Assembly, with quicksort algorithm optimized for performance on it. Completed as a final project in MIT 6.191 (6.004) Fall 2022. 

Features:
* Processor has a real memory system with specialized instruction and data caches. Instruction cache uses a direct mapped cache while data cache uses a two-way cache. 
* Processor uses a 4-stage pipeline with data bypassing following the state-transition diagram below:
![State-transition diagram of pipelined processor](./img/pipeline_diagram.png)
* Quicksort algorithm written in Assembly includes Hoare partitioning, tail call elimination, loop-invariant code motion, and strategically ordered code to minimize stalling in the processor's pipeline. Results in >50% faster performance
* Implementation of carry-select adder for faster ALU add operations
* In total, the optimizations lead to a >40% faster runtime and CPI (cycles per instruction) for the processor compared to a single cycle version of it

Notes:
1. Minispec is a custom verson of Bluespec System Verilog
2. All relevant files are in `/src`. Key files for processor functionality are `Processor.ms`, `Decode.ms`, `Execute.ms`, `ALU.ms`, `CacheHelpers.ms`, `DirectMappedCache.ms`, `TwoWayCache.ms`. Sorting code in is in `/src/sw/sort/sort.S`.
