= Rack, Interconnection & Storage <sec-topology>
The rack-level and interconnection architecture is designed hierarchically to maximize compute density and minimize latency, responding to the operational demands of contemporary artificial intelligence workloads.

At the rack level, each of the $12$ HPE Cray EX4000 @mcintosh2025 cabinets available contains a total of $110$ compute nodes, which provides a total of $440$ NVIDIA GH200 superchips per cabinet.

Within each rack, the basic unit is the HPE Cray EX254n _blade_ accelerator.
It houses two independent compute nodes, each of which has $4$ NVIDIA Grace processors of $72$ cores (ARM Neoverse V2 architecture), as well as $4$ NVIDIA H100 GPUs (Hopper architecture).
Consequently, each node has 288 ARM v9 cores and 4 H100 GPUs.

#figure(
	image("../figures/borrar_y_mejorar_resolucion.png"),
	caption: [HPE Cray EX254n blade chassis],
	kind: "Image",
	supplement: "Figure"
)

At the cluster interconnect level, network orchestration is delegated to the HPE Slingshot 11 architecture @hpe_slingshot_2026
The HPE Cray EX system uses an orthogonal cableless coupling @hpe_cray_ex_quickspecs: compute blades are inserted from the front of the chassis, while switch blades are inserted from the rear, intersecting at a midplane.
This design fundamentally serves $3$ goals:

- *Improve signal integrity:* allowing greater bandwidth.
- *Minimize interconnect latencies:* the short trace layout minimizes propagation delays.
- *Minimize energy expenditure:* reducing the amount of energy needed per transmitted byte.

Each node uses $4$ network cards, offering a total bandwidth of $800$ Gb/s of simultaneous input and output @bristol_isambard_2025 per node toward the main network.
For inter-node connections, 64-port switches are used, offering a total of $25.6$ Tb/s.

At the macroscopic level, the network topology used is of the _Dragonfly_ type @kim2008.
This design is based on all-to-all meshes of small groups of nodes, which are subsequently interconnected with each other; this makes it possible to guarantee a diameter of 3 hops @hpe_slingshot_2026 for $lt.eq 37120$ endpoints.

#figure(
	image("../figures/dragonfly.pdf"),
	caption: [Example of a dragonfly topology],
	kind: "Image",
	supplement: "Figure"
)

Although the exact implementation of this topology in the Isambard-AI phase 2 cluster is unknown, it is possible to infer it using other systems as a reference, such as the _Alps_ system, belonging to the _Swiss National Supercomputing Centre_ @desensi2024.
A possible implementation of this architecture for each switch is shown in @fig-switches.

#figure(
	image("../figures/Switch-diagrama.pdf"),
	caption: [Distribution of the switches in the _Alps_ supercomputer],
	kind: "Image",
	supplement: "Figure"
) <fig-switches>

== Storage
Storage responds to requirements that differ from those of classical HPC simulation.
Training requires high-speed reads of datasets and periodic writes of checkpoints, while inference demands a large number of small, parallel reads.
For this reason, a traditional parallel file system alone is not enough @mcintosh2025.
To cover this, Isambard-AI phase 2 combines three tiers.

The first is an all-flash HPE ClusterStor E1000 storage with Lustre, made up of 1056 NVMe SSDs of 30.72 TB each, with about 20.3 PiB usable.
The expected aggregate performance reaches up to 2500 GB/s for reads and 1980 GB/s for writes, with 35 million random 4 KB read IOPS.
The second is a multiprotocol, multi-tenant SDS platform based on VAST Data, with about 3.56 PB usable, designed for AI workloads and for isolating sensitive data between projects.
The third is local 3.84 TB SSDs on a subset of nodes, intended for small or sensitive data.
