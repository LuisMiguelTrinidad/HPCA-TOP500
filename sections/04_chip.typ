= Node microarchitecture
Cada nodo del clúster Isambard-AI phase 2 congrega múltiples superchips NVIDIA GH200, integrando cada uno de estos su propio procesador Grace y su GPU H100, que se comunican mediante NVLink-C2C (Chip to Chip).
Se describe a a lo largo de esta sección las principales características de los mismos.

== Node composition
A nivel macro, cada nodo cuenta con $4$ superchips GH200, que suman $288$ núcleos ARM, $67584$ núcleos CUDA, $512$ GB de memoria LPDDR5X y $384$ GB de memoria HBM3, distribuidos de forma equitativa entre los superchips @bristol_isambard_2025.
La fuerte integración permite que cada CPU o GPU acceda a cualquier dirección de memoria RAM o VRAM de cualquier otro chip @nvidia_gh200_2024.

#figure(
  image("../figures/diagrama_blade.pdf", width: 100%),
  caption: [Esquema de un nodo de Isambard-AI phase 2: cuatro superchips GH200, cada uno con su CPU Grace, su GPU H100, sus memorias LPDDR5X y HBM3, su tarjeta de red Slingshot-11 y los enlaces NVLink-C2C intra-superchip. Diagrama de referencia basado en @desensi2024.],
  kind: "Image",
	supplement: "Figure"
) <fig-node>

A nivel de interconexión intra-nodo, las GPU están interconectadas en un enmallado _all-to-all_ basado en la tecnología NVLink 4.0, con 6 enlaces por conexión, lo que ofrece un ancho de banda de $150$ GB/s por dirección @desensi2024.
Por su parte, la comunicación CPU-GPU dentro de un mismo superchip se realiza mediante NVlink-C2C, ofreciendo un total de $450$ GB/s por dirección @nvidia_gh200_2024, superando ampliamente los 64GB/s por dirección que ofrece PCIe 5.0, lo que reduce la intensidad aritmética mínima necesaria para que la ejecución en GPU sea rentable frente a la CPU.

En materia de latencia, según el análisis de Fusco et al. @fusco2024, esta arquitectura NUMA de memoria unificada presenta un comportamiento asimétrico según la ubicación de los datos.

La CPU Grace accede a su memoria local LPDDR5X con una latencia de $170.0$ ns, mientras que acceder a la HBM3 de su GPU emparejada a través de C2C eleva el coste a $798.8$ ns.
Por su parte, la GPU Hopper accede a su HBM3 local en $344.2$ ns y necesita $817.8$ ns para acceder a la LPDDR5X de la CPU a través del enlace C2C.

Las comunicaciones _peer-to-peer_ entre superchips reflejan el overhead del enrutamiento: una GPU que accede a la HBM de otra GPU incurre en una latencia de $1022.9$ ns, mientras que una CPU que accede a la LPDDR5X de otra CPU espera $520$ ns.

== The CPU
#figure(
  image("../figures/neoverse_v2.drawio-1.jpg"),
  caption: [Pipeline microarquitectónico de un procesador basado en la especificación Neoverse V2 @bruce2023. No se corresponde de forma estricta con el procesador descrito en esta sección.],
  placement: top,
  scope: "parent",
  kind: "Image",
  supplement: "Figure"
) <fig-neoverse_diagram>

El procesador Grace es una CPU de 72 núcleos con frecuencias de hasta $3.1$ GHz, basada en la microarquitectura ARM Neoverse V2 (ARMv9-A), que fue presentada en la conferencia hot chips de 2023 @bruce2023.
Se trata de un núcleo superescalar, con gran capacidad de explotar paralelismo a nivel de instrucciones (ILP) gracias a la ejecución fuera de orden y su ancho de 8 $mu$ops por ciclo.
Sin embargo, no implementa multihilo simultáneo (SMT), por lo que cada núcleo ejecuta un único hilo físico.

Como se observa en la @fig-neoverse_diagram, el frontend del procesador puede decodificar hasta 6 instrucciones por ciclo, así como despachar 8 apoyándose en una caché de $mu$ops de 1536 entradas, asociativa a 4 vías.
Cuenta además con un predictor de saltos TAGE @seznec2006.

El _backend_ dispone de $6$ unidades escalares enteras (ALU), de las cuales dos realizan operaciones `mul` y una de ellas también `fma`.
Cuenta símismo con 2 unidades de salto, 4 puertos FP/SIMD de 128 bits, y 3 unidades de generación de direccioones (AGU).
Dos de las AGU atienden cargas y almacenamientos, mientras que la tercera solo cargas, lo que teóricamente permite hasta 3 operaciones de memoria de 16 bytes por ciclo.

Por su parte, la memoria en este procesador sigue la siguiente jerarquía de memorias:

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
        align([*Type*], center), align([*Size*], center), align([*Associativity*], center), align([*Bytes/cycle*], center), align([*Bandwith*], center)
      ),
      table.hline(stroke: 0.5pt),

      [Registros], [No publicado], [---], [---], [---],
      [L1d], [$64$ KB/nucleo], [$4$ vías], [$48$], [$144$ GB/s/c],
      [L2], [$1$ MB/nucleo], [$8$ vías], [$64$], [$192$ GB/s/c],
      [L3], [$114$ MB], [---], [---], [---],
      [LPDDR5X], [$128$ GB], [---], [---], [$512$ GB/s],
      table.hline(stroke: 1pt),
    )
  ],
  caption: [Jerarquía de memoria del procesador Grace (CPU) del superchip GH200.],
  supplement: "Table",
  kind: "Table",
) <tab-mem>

La comunicación entre hilos, explotada en el paralelismo a nivel de hilo (TLP), se realiza a través de una malla de coherencia basada en una grid $6 times 7$, representada en la figura @fig-grace. Con distancia Manhattan, el número máximo de saltos entre nodos es $6+7 = 13$.

#figure(
  image("../figures/grace_cpu_and_scalable_coherency_fabric.png"),
  caption: [Diagrama de bloques del procesador Grace (CPU) del GH200: 72 núcleos Neoverse V2 y 114 MB de caché L3 distribuida sobre la malla de coherencia @nvidia_grace_cpu.],
  kind: "Image",
  supplement: "Figure"
) <fig-grace>

El número de operaciones de coma flotante por ciclo se obtiene de $4$ pipelines SIMD de $128$ bits, cada uno con $2$ carriles `fp64` que realizan una `FMA` ($2$ operaciones), lo que da $16$ FLOP/ciclo por núcleo.
Tomando como referencia la frecuencia de reloj $3.0$ Ghz, máxima alcanzable al usar un pipeline completo de operaciones SIMD @nvidia_gh200_2024.
El pico `fp64` del procesador completo es $72 times 16 times 3 "GHz" = 3.456$ TFLOPS.

Por otro lado, el procesador, dispone de instrucciones de multiplicación-acumulación de matrices, disponibles desde ARM 8.6 /*cita*/, lo que permite realizar esta operación con enteros de 8 bit, `int8`, o de coma flotante de 16 bits `bf16`.
Cada una de ellas realiza $32$ multiplicaciones-acumulaciones sobre enteros de $8$ bits (`int8`), es decir, $64$ operaciones contando cada MAC como dos, o $16$ MAC sobre datos de $16$ bits en coma flotante (`bf16`), es decir, $32$ operaciones /*cita a algun manual de ARM*/.

Suponiendo que los $4$ pipelines emiten una de estas instrucciones por ciclo, el pico teórico por núcleo es $4 times 64 = 256$ OPS `int8` y $4 times 32 = 128$ FLOP `fp16` por ciclo.
Para el procesador completo a $3.0$ GHz, esto supone unos $55$ TOPS `int8` y $27.6$ TFLOPS `bf16`.

== The GPU
Cada superchip incorpora una GPU H100 con $132$ multiprocesadores (SM). Cada uno de ellos cuenta con $128$ núcleos `fp32` y $64$ núcleos `fp64` y $4$ núcleos tensoriales de cuarta generación.
Su memoria HBM3 ofrece hasta $4$ TB/s y se comunica con la CPU mediante NVLink-C2C a $900$ GB/s bidireccionales.
La jerarquía de memoria de la GPU se resume en la @tab-gpu-mem.

/* revisar todos los datos de la tabla e incluir cita */
#figure(
  align(center)[
    #set text(size: 6pt)
    #table(
      columns: (auto, auto, auto, auto, auto, auto),
      align: (left, center, center, center, center, center),
      stroke: none,
      inset: (x: 4pt, y: 3pt),

      table.hline(stroke: 1pt),
      table.header(
        [*Tipo*], [*Tamaño*], [*Asociatividad*], [*Bytes/ciclo*], [*Ancho de banda*], [*Latencia*],
      ),
      table.hline(stroke: 0.5pt),
      [L1], [$256$ KB/SM], [No publicado], [$128$ por SM], [$approx 33$ TB/s], [$approx 33$c],
      [L2], [$50$ MB], [No publicado], [No publicado], [$>5.5$ TB/s], [$200$--$263$c],
      [HBM3], [$96$ GB], [---], [---], [$4$ TB/s], [$344.2$ ns (local, @fusco2024)],
      table.hline(stroke: 1pt),
    )
  ],
  caption: [Jerarquía de memoria de la GPU H100 (Hopper) del superchip GH200. Los anchos de banda agregados se calculan a la frecuencia de boost de $1.98$ GHz.],
  supplement: "Table",
  kind: "Table",
) <tab-gpu-mem>

A escala del sistema completo ($5448$ superchips), el pico `fp8` disperso de $3958$ TFLOPS por GPU da el orden de $21$ EFLOPS.

/* Pendiente: añadir figura del pipeline de ejecución de Neoverse V2 y de la jerarquía de cachés del H100 si se desea. */

/* Añadir: ancho de banda de la caché L1 y L2 y L3 de la GPU y la CPU, así como el número de vías en el caso de la CPU */
