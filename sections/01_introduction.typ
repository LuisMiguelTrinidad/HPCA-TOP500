= Introduction <sec-introduction>
Since the invention of the first commercial microprocessor, the Intel 4004 in 1971, up to the present day, computing capacity has grown exponentially.
However, this growth is now converging toward its asymptote due to the physical and thermodynamic limits that govern the semiconductor industry.
Historically, during the last decades of the 20th century and the early 21st, the increase in performance rested on two theoretical pillars: Dennard scaling @dennard1974 and Moore's law @moore2006_1.

Dennard scaling, formalized by Robert H. Dennard @dennard1974, established that when the physical dimensions of transistors are reduced, voltage and current must scale proportionally.
This allowed the clock frequency to increase linearly with lithographic miniaturization, keeping power density per unit area constant.
Nevertheless, this paradigm collapsed @bohr2007 in the early 2000s, when advances in lithography made the effects of quantum mechanics significantly apparent.
Specifically, the appearance of electron tunneling prevented further reduction of the threshold voltage, unleashing unsustainable leakage currents and crushing the power wall.

In parallel, Moore's law @moore2006_1, which initially predicted the doubling of transistor density every year, and later every two years @moore2006_2, has suffered a severe slowdown, attributed both to the exponential increase in the cost of the equipment needed for new EUV lithographies @Waldrop2016TheCA and to the approach of the atomic limits of silicon.
The deceleration of this model has recently led to proposals for new scaling paradigms based on minimizing signal propagation delays by moving from 2D architectures to vertical integration @he2026.

Faced with the stagnation of frequency-based vertical scaling, the industry's response was the systematic exploitation of horizontal scaling and thread-level parallelism (TLP) @peng2007memory.
AMD pioneered the transition to multicore x86 processors in 2005, with the introduction of the Athlon 64 X2, with a native monolithic design @amd2007athlon.
Two decades later, the exploitation of TLP in shared-memory systems has reached unprecedented figures, as demonstrated by the sixth generation of AMD EPYC processors, capable of integrating up to $256$ cores per _socket_ @amd2026epyc9006.

Despite this drastic scaling, general-purpose processors exhibit architectural inefficiencies when faced with highly parallelizable workloads.
These problems call for specialized accelerators, such as graphics processing units (GPUs), which sacrifice single-thread flow control in favor of the parallel SIMT paradigm.
However, contemporary requirements exceed not only the computing capacity of a single integrated circuit, but also the capacity to transfer data from memory units to compute units.
The historical imbalance between the rapid growth of computing capacity and the slower growth of memory bandwidth gives rise to a systemic memory bottleneck, first presented in 1995 @wulf1995, which is becoming increasingly relevant in the training of large language models, as Gholami et al. @gholami2024 show.

To overcome this bottleneck and approach exascale computing, it is imperative to deploy heterogeneous clusters interconnected by network topologies with high bandwidth and low latency.
In the geopolitical context, this massive infrastructure is critical for the training and development of large language models, in order to guarantee national technological sovereignty.

This framework of sovereign AI underpins the British government's strategic AI Research Resource (AIRR) initiative @ukgov_airr_2025.
In partnership with the Bristol Centre for Supercomputing @bristol_isambard_2025, it spearheads Phase 2 of Isambard-AI, the United Kingdom's most advanced AI-centric supercomputing infrastructure

This report will analytically and systematically break down the Isambard-AI phase 2 cluster, currently ranked 13th on the TOP500 list @top500_isambard2_2025.

To do so, a hierarchical architectural approach is adopted: @sec-overview starts from the underlying physical infrastructure and facilities (Facility Level).
Next, @sec-topology addresses the structural analysis of the racks, the network interconnection topology and the storage system.
Finally, @sec-chip provides the microarchitectural characterization of the compute nodes, concluding with an empirical and theoretical validation through the exploration and interpretation of their results on performance benchmarks
