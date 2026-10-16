= Facility level system overview <sec-overview>
At a high level, the Isambard-AI cluster consists of a total of $5448$ _NVIDIA GH200_ (Grace Hopper) superchips @nvidia_gh200_2024 distributed across 13 high-density racks, which, according to Flynn's taxonomy, makes it a MIMD system.
The first rack, an HPE Cray EX2500, belongs to the Isambard-AI phase 1 supercomputer, while the other 12 racks, HPE Cray EX4000, belong to the Isambard-AI phase 2 supercomputer @mcintosh2025, which is broken down in this document.

The supercomputer operates at a power consumption of $5$ MW, providing a maximum computing power of $216.50$ PFlops in `fp64` on the Linpack benchmark @top500_isambard2_2025.
Moreover, thanks to the tensor architecture provided by the NVIDIA GPUs, it is theoretically capable of reaching $21$ EFlops/s in `fp8` format @mcintosh2025.

== Brief history of the project
The conception of the system responds directly to data sovereignty and national security policies.
Unlike pan-European infrastructures developed under the EuroHPC consortium, the British government developed its own strategy under the _AI Research Resource_ (AIRR) program @ukgov_airr_2025.
This government initiative involved an initial injection of 225 million pounds in autumn of 2023 @HPE2023IsambardAI.

Execution of the project was handed off to the University of Bristol, due to its proven experience with the GW4 project @mcintosh2019.
Specifically, the cluster is overseen by Prof. Simon McIntosh-Smith, director of the _Bristol Centre for Supercomputing_ (BriCS), and Dr. Sadaf Alam, Chief Technology Officer (CTO) of the same institution.
The system was assembled collaboratively by Hewlett Packard Enterprise (HPE) and NVIDIA, and despite the logistical complexity of the project, phase 1 was completed in record time, going from contract signing to operational status in less than 4 months.

#figure(
	image("../figures/vista_aerea.png"),
	caption: [Aerial view of the center during construction of the data center],
	kind: "Image",
	supplement: "Figure"
)

== Facilities
The physical system is housed in the _National Composites Centre_ (NCC), located in the _Bristol and Bath Science Park_.
It shares the site with phase 1 of Isambard-AI, as well as with the Isambard 3 cluster, based exclusively on NVIDIA Grace CPUs.
Due to strict space limitations, with only ~550 square meters available ($15.6 times 35 m$) @mcintosh2025, the system could not be deployed in a conventional clean room.
Instead, a self-contained solution was implemented that encloses the nodes, electrical transformation, and pumping stations within the enclosure itself.
To achieve this, a modular data center architecture was used, which made it possible to reduce by 72% the emissions derived from its construction compared with conventional data centers @mcintosh2025.

#figure(
	image("../figures/facilities_diagram.png"),
	caption: [Diagram of the system layout @mcintosh2025],
	kind: "Image",
	supplement: "Figure"
)

To dissipate the high density of thermal energy generated, which exceeds $400$ kW per rack, conventional air cooling is not feasible.
Instead, Direct Liquid Cooling is used, a solution standardized in the HPE Cray EX chassis @hpe_cray_ex_quickspecs.
This approach not only prevents overheating of the components, but its efficiency also makes the system a referent of the Green AI paradigm: its twin supercomputer, Isambard AI-phase 1, ranks 4th in the June 2026 Green AI ranking @green500_june2026.
This sustainability milestone is especially notable for having been achieved with accelerators from the Hopper generation, which exhibit higher nominal energy consumption per flop than more lithographically advanced architectures, such as Blackwell or Vera Rubin.
The system has a nominal Power Usage Effectiveness (PUE) of $1.08$, meaning that only $8%$ of the energy consumed goes to peripheral cooling, markedly better than the figure common for air-cooled systems, which hovers around 1.54–1.56 @UptimeInstitute2025Survey.

The environmental impact of the machine's consumption is minimized through its electricity procurement policy.
Although its high consumption of 5 MW required a high-capacity direct connection to the British national grid, 100% of the energy supplied to the system comes from renewable sources in the UK, covering not only wind, solar and hydroelectric systems but also battery storage systems @bristol_isambard_sustainability_2026.
