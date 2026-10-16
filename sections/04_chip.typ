= Node microarchitecture <sec-chip>
Each node of the Isambard-AI phase 2 cluster brings together multiple NVIDIA GH200 superchips, each of which integrates its own Grace processor and H100 GPU, communicating via NVLink-C2C (Chip to Chip).
The main characteristics of these components are described throughout this section.

== Node composition
At the macro level, each node has $4$ GH200 superchips, which add up to $288$ ARM cores, $67584$ CUDA cores, $512$ GB of LPDDR5X memory and $384$ GB of HBM3 memory, distributed equally among the superchips @bristol_isambard_2025.
The tight integration allows each CPU or GPU to access any RAM or VRAM address of any other chip @nvidia_gh200_2024.

#figure(
  image("../figures/diagrama_blade.pdf", width: 100%),
  caption: [Diagram of an Isambard-AI phase 2 node: four GH200 superchips, each with its Grace CPU, H100 GPU, LPDDR5X and HBM3 memories, its Slingshot-11 network card and the intra-superchip NVLink-C2C links. Reference diagram based on @desensi2024.],
  kind: "Image",
	supplement: "Figure"
) <fig-node>

At the intra-node interconnect level, the GPUs are connected in an all-to-all mesh based on NVLink 4.0 technology, with 6 links per connection, offering a bandwidth of $150$ GB/s per direction @desensi2024.
For its part, CPU-GPU communication within the same superchip is carried out via NVLink-C2C, offering a total of $450$ GB/s per direction @nvidia_gh200_2024, far surpassing the 64 GB/s per direction offered by PCIe 5.0.
This reduces the minimum arithmetic intensity required for GPU execution to be worthwhile compared with the CPU.

Regarding latency, according to the analysis by Fusco et al. @fusco2024, this unified-memory NUMA architecture shows asymmetric behavior depending on where the data resides.

The Grace CPU accesses its local LPDDR5X memory with a latency of $170.0$ ns, while accessing the HBM3 of its paired GPU through C2C raises the cost to $798.8$ ns.
The Hopper GPU accesses its local HBM3 in $344.2$ ns and needs $817.8$ ns to access the CPU's LPDDR5X through the C2C link.

Peer-to-peer communications between superchips reflect routing overhead: a GPU accessing the HBM of another GPU incurs a latency of $1022.9$ ns, while a CPU accessing the LPDDR5X of another CPU waits $520$ ns.

== The CPU
#figure(
  image("../figures/neoverse_v2.drawio-1.jpg"),
  caption: [Microarchitectural pipeline of a processor based on the Neoverse V2 specification @bruce2023. It does not strictly correspond to the processor described in this section.],
  placement: top,
  scope: "parent",
  kind: "Image",
  supplement: "Figure"
) <fig-neoverse_diagram>

The Grace processor is a 72-core CPU with frequencies of up to $3.1$ GHz, based on the ARM Neoverse V2 microarchitecture (ARMv9-A), which was presented at the Hot Chips 2023 conference @bruce2023.
It is a superscalar core, with great capacity to exploit instruction-level parallelism (ILP) thanks to out-of-order execution and its width of 8 $mu$ops per cycle.
However, it does not implement simultaneous multithreading (SMT), so each core executes a single physical thread.
According to Flynn's taxonomy, it is a MIMD system whose cores can execute SIMD and SISD instructions.

As seen in @fig-neoverse_diagram, the processor's frontend can decode up to 6 instructions per cycle, as well as dispatch 8, relying on a $mu$op cache of $1536$ entries, 4-way set associative.
It also has a TAGE branch predictor @seznec2006.

The backend has $6$ scalar integer units (ALU), two of which perform `mul` operations and one of which also performs `fma`.
It also has $2$ branch units, $4$ 128-bit FP/SIMD ports, and $3$ address generation units (AGU).
Two of the AGUs handle loads and stores, while the third handles only loads, which theoretically allows up to $3$ memory operations of $16$ bytes per cycle.

Memory in this processor follows the hierarchy shown below:

#figure(
  align(center)[
    #set text(size: 6pt)
    #table(
      columns: (auto, auto, auto, auto, auto),
      align: (left, right, right, right, right),
      stroke: none,
      inset: (x: 5pt, y: 3pt),

      table.hline(stroke: 1pt),
      table.header(
        align([*Type*], center), align([*Size*], center), align([*Associativity*], center), align([*Bytes/cycle*], center), align([*Bandwidth*], center)
      ),
      table.hline(stroke: 0.5pt),

      [Registers], 	[Not published], 	[---], 			[---], 	[---],
      [L1d], 				[$64$ KB/core], [$4$-way], [$48$], [$144$ GB/s/core],
      [L2], 				[$1$ MB/core], 	[$8$-way], [$64$], [$192$ GB/s/core],
      [L3], 				[$114$ MB], 			[---], 			[---], 	[>2 TB/s @chipsandcheese_gh200],
      [LPDDR5X], 		[$128$ GB], 			[---], 			[---], 	[$512$ GB/s],
      table.hline(stroke: 1pt),
    )
  ],
  caption: [Memory hierarchy of the Grace (CPU) processor of the GH200 superchip.],
  supplement: "Table",
  kind: "Table",
) <tab-mem>

Communication between threads, exploited through thread-level parallelism (TLP), is carried out through a coherency mesh based on a $6 times 7$ grid, shown in @fig-grace. With Manhattan distance, the maximum number of hops between nodes is $6+7 = 13$.

#figure(
  image("../figures/grace_cpu_and_scalable_coherency_fabric.png", width: 100%),
  caption: [Block diagram of the Grace (CPU) processor of the GH200: 72 Neoverse V2 cores and 114 MB of distributed L3 cache over the coherency mesh @nvidia_grace_cpu.],
  kind: "Image",
  supplement: "Figure"
) <fig-grace>

The 72-core processor operates at 3.0 GHz using 4 128-bit SIMD pipelines per core, belonging to the ARMv9-A family (SVE2/NEON). Its computational capabilities are broken down below.

- *`fp64`:* Each pipeline includes 2 lanes performing one `FMA` (2 operations). This yields 16 FLOP/cycle per core. The total peak is $72 times 16 times 3.0 "GHz" = 3.456$ TFLOPS.
- *`fp32`:* Each pipeline includes 4 lanes performing one `FMA` (2 operations). This yields 32 FLOP/cycle per core. The total peak is $72 times 32 times 3.0 "GHz" = 6.912$ TFLOPS.
- *`bf16`:* The `BFDOT` instruction accumulates 2 products per 32-bit lane, equivalent to 8 `mac` (16 FLOP) per instruction. This results in 64 FLOP/cycle per core. The total peak is $72 times 64 times 3.0 "GHz" approx 13.8$ TFLOPS.
- *`int8`:* The `SDOT` instruction accumulates 4 products per 32-bit lane, equivalent to 16 `mac` (32 operations) per instruction. This results in 128 OPS/cycle per core. The total peak is $72 times 128 times 3.0 "GHz" approx 27.6$ TOPS.

== The GPU
Each superchip incorporates an H100 GPU with $132$ enabled streaming multiprocessors (SM), out of a total of $144$ on the die @chipsandcheese_gh200.
According to Flynn's taxonomy, the GPU, since it has several SMs, generally behaves as a MIMD model, while within each SM it is a degenerate case of SIMD, namely SIMT.
Bewlo, a description in two parts is provided: first the memory hierarchy, then its computational capabilities.

=== Memory hierachy
#figure(
  align(center)[
    #set text(size: 7pt)
    #table(
      columns: (auto, auto, auto, auto, auto),
      align: (left, right, right, right, right),
      stroke: none,
      inset: (x: 4pt, y: 3pt),

      table.hline(stroke: 1pt),
      table.header(
        align([*Type*], center), align([*Size*], center), align([*Bytes/cycle*], center), align([*Bandwidth*], center), align([*Latency*], center),
      ),
      table.hline(stroke: 0.5pt),
      [Registers],	[$256$ KB/SM], 			[---], 	[---], 	[$1$ cycle],
      [L1], 				[$256$ KB/SM], 			[$128$/SM], 	[$approx 33$ TB/s], 	[$approx 23$--$41$ cycles],
      [L2], 				[$2 times 25$ MB],	[---], [$approx 5.5$ TB/s], 	[$approx 200$--$263$ cycles],
      [HBM3], 			[$96$ GB], 					[---], 				[$approx 4$ TB/s],	 	[$approx 290$--$480$ cycles],
      table.hline(stroke: 1pt),
    )
  ],
  caption: [Memory hierarchy of the H100 (Hopper) GPU of the GH200 superchip. Latency data from @spheron_hierarchy],
  supplement: "Table",
  kind: "Table",
) <tab-gpu-mem>

The SM registers occupy $256$ KB, shared among the resident warps: each thread can use up to $255$ 32-bit registers (about $1$ KB), which amounts to up to $32$ KB per warp of 32 threads @choquette2022.

The L1 has $256$ KB per SM, offering a bandwidth of $128$ B/cycle per SM @hopper_tuning, which allows it to reach about $33$ TB/s aggregated over the $132$ SMs.

The $50$ MB L2 cache is shared by all SMs and is divided into two partitions of $25$ MB each.
Accesses to the far partition cost roughly twice as much as accesses to the near one.
Chips and Cheese measured @chipsandcheese_gh200 more than $5.5$ TB/s of read bandwidth on the near partition, but on an H100 PCIe with $114$ SMs, so for the SXM variant this is an estimate.

La HBM3 del GH200 ofrece $96$ GB y $4$ TB/s, a través de un bus de $6144$ bits.

Finally, Hopper's thread block clusters allow co-scheduling up to $16$ blocks on adjacent SMs.
A block can access the shared memory of another through an SM-to-SM network @choquette2022, which according to NVIDIA reduces exchange latency by about $7$ times.

=== Compute per SM
Each SM contains $128$ `fp32` cores, $64$ `fp64` cores and $4$ fourth-generation tensor cores.
@fig-sm shows the organization of an SM of the H100 GPU.

#figure(
  image("../figures/h100_sm.svg"),
  caption: [Diagram of the SM of the Hopper (H100) architecture. Taken from @modal_tensor_core],
  kind: "Image",
  supplement: "Figure"
) <fig-sm>

The compute of each SM depends on the data type.
In the CUDA cores, each `fp32` core executes one `fma` per cycle, which gives $128$ `fma`, or $256$ FLOP, per SM and cycle.
In `fp64`, the CUDA cores perform $64$ FMA per cycle, that is, $128$ FLOP.

The tensor cores are the ones that stand out most in lower-precision formats.
@tab-compute summarizes these values together with the arithmetic intensity, which is studied in the final table.

#figure(
  align(center)[
    #set text(size: 7pt)
    #table(
      columns: (auto, auto, auto, auto, auto, auto),
      align: (left, center, right, right, right, right),
      stroke: none,
      inset: (x: 3pt, y: 3pt),

      table.hline(stroke: 1pt),
      table.header(
        [*Type*], [*Unit*],[*FLOP/c/SM*], [*TFLOPS*], [*AI/L1*], [*AI/HBM3*],
      ),
      table.hline(stroke: 0.5pt),
      [`fp64`],        [CUDA],      [$128$],  [$approx 34$],   [$1$],  [$approx 8.5$],
      [`fp32`],        [CUDA],      [$256$],  [$approx 67$],   [$1$],  [$approx 16.75$],
      [`fp64`],        [Tensor], [$256$],  [$approx 67$],   [$2$],  [$approx 16.75$],
      [`tf32`],        [Tensor], [$2048$], [$approx 494$],  [$16$], [$approx 123.5$],
      [`FP16/BF16`],   [Tensor], [$4096$], [$approx 990$],  [$32$], [$approx 247.5$],
      [`FP8/INT8`],    [Tensor], [$8192$], [$approx 1979$], [$64$], [$approx 494.75$],
      table.hline(stroke: 1pt),
    )
  ],
  caption: [Operations per cycle and per SM, peak of the 132-SM system, and minimum arithmetic intensity for compute-bound workloads.],
  supplement: "Table",
  kind: "Table",
) <tab-compute>

The intensities explain where the bottleneck lies.
A CUDA `fp64` kernel already needs about $8.5$ FLOP per byte of HBM3 to saturate the compute, while tensor FP16 needs about $247$.
Language model training workloads reuse each value heavily and can reach that intensity, but low-intensity kernels remain limited by memory.

== Benchmarking
The results are divided into two blocks: the Grace CPU, measured by Phoronix @phoronix_gh200, and the H100 GPU, for which there is only manufacturer data and third-party data with different configurations.

=== CPU Grace
Phoronix compares the 72 cores of the GH200 with the AMD EPYC 9654 and the Intel Xeon 8592+, under Ubuntu 23.10, Linux 6.5 and GCC 13.
The tested system is a GPTshop.ai desktop with 480 GB of LPDDR5X, not the Isambard-AI cluster: since they share the CPU, the results characterize the processor and not the complete system.

#figure(
  align(center)[
    #set text(size: 7pt)
    #table(
      columns: (auto, auto, auto, auto, auto),
      align: (left, left, right, right, right),
      stroke: none,
      inset: (x: 4pt, y: 3pt),

      table.hline(stroke: 1pt),
      table.header(
        [*Benchmark*], [*Workload*], [*Grace (GH200)*], [*EPYC 9654*], [*Xeon 8592+*],
      ),
      table.hline(stroke: 0.5pt),
      [HPCG (GFLOP/s)], [memory-bound], [32.13], [43.97], [35.42],
      [Graph500 (TEPS)], [irregular access], [$1.24 times 10^9$], [$0.816 times 10^9$], [$1.199 times 10^9$],
      [LULESH z/s], [hydrodynamics], [23185], [23701], [39468],
      table.hline(stroke: 1pt),
    )
  ],
  caption: [Benchmark results of the Grace CPU against reference processors @phoronix_gh200],
  supplement: "Table",
  kind: "Table",
) <tab-phoronix>

In HPCG, Grace obtains 27% less than the EPYC 9654, despite its peak bandwidth of 512 GB/s.
In Graph500, with irregular accesses, it outperforms both x86 processors.
In LULESH it is on par with the EPYC, while the Xeon archiecves almost 1.7x that result.

=== GPU H100
For the GPU, NVIDIA publishes a comparison of the 144 GB GH200 variant against an x86 reference and an x86 system with H100 @nvidia_gh200_perf.
The chart does not detail the reference configuration, so these are manufacturer figures.

#figure(
  align(center)[
    #set text(size: 7pt)
    #table(
      columns: (auto, auto, auto, auto),
      align: (left, left, right, right),
      stroke: none,
      inset: (x: 4pt, y: 3pt),

      table.hline(stroke: 1pt),
      table.header(
        [*Workload*], [*Type*], [*x86 + H100*], [*GH200 (144 GB)*],
      ),
      table.hline(stroke: 0.5pt),
      [ICON], [HPC], [6×], [8×],
      [MILC], [HPC], [27×], [41×],
      [Quantum Fourier Transform], [HPC], [61×], [94×],
      [DLRM inference (100 GB)], [AI], [9×], [18×],
      [IVF-PQ vector search], [AI], [25×], [33×],
      [GNN training (500 GB)], [AI], [5×], [40×],
      table.hline(stroke: 1pt),
    )
  ],
  caption: [Speedup relative to an x86 reference (1.0×), according to NVIDIA @nvidia_gh200_perf],
  supplement: "Table",
  kind: "Table",
) <tab-gh200-nvidia>

As an independent contrast, Databricks measured on nodes of 8 H100 SXM 80 GB against A100 80 GB @databricks_h100.
BF16 training is 2.2× faster, and with FP8 it reaches up to 3.3×.
Matrix multiplications reach close to 5× against a theoretical maximum of 6.3×, while memory-bound operations improve by at most 1.6×, in line with the bandwidth advantage of the H100 over the A100.

These figures correspond to the GPU in another configuration and from another software generation, so they serve as a reference for the GPU's behavior, not as a measurement of the GH200 in the cluster.
