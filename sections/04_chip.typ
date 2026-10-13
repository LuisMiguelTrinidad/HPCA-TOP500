= Node microarchitecture
Cada nodo del clúster Isambard-AI phase 2 congrega múltiples superchips NVIDIA GH200, integrando cada uno de estos su propio procesador Grace y su GPU H100, que se comunican mediante NVLink-C2C (Chip to Chip).
Se describe a a lo largo de esta sección las principales características de los mismos.

== Node composition
A nivel macro, cada nodo cuenta con $4$ superchips GH200, que suman $288$ núcleos ARM, $67584$ núcleos cuda, $512$ GB de memoria LPDDR5X y $384$ GB de memoria HBM3 distribuidos de forma equitativa entre los superchips @bristol_isambard_2025.
La fuerte integración empleada permite que cada CPU o GPU acceda a cualquier dirección de memoria RAM o VRAM de cualquier otro chip @nvidia_gh200_2024.

#figure(
  image("../figures/diagrama_borrar.png"),
  caption: [Esquema de un nodo de Isambard-AI phase 2: cuatro superchips GH200, cada uno con su CPU Grace, su GPU H100, sus memorias LPDDR5X y HBM3, su tarjeta de red Slingshot-11 y los enlaces NVLink-C2C intra-superchip.],
  kind: "Image",
	supplement: "Figure"
) <fig-node>

A nivel de inteconexión intra-nodo, cada uno de las GPUs está interconectada con el resto en un enmallado _all-to-all_ basado en la tecnología NVLink 4.0, con 6 líneas de la misma en cada conexión, lo que ofrece un ancho de banda de $150$ GB/s por dirección.
Asímismo, la comunicación CPU-GPU dentro de un mismo chip cuenta con un ancho de banda muy superior al que dispondría con una conexión PCIe 5.0, ofreciendo un total de $450$ GB/s por dirección, lo que contribuye a reducir la intensidad aritmética mínima para hacer viable la ejecución de código en GPU frente a su ejecución en CPU.

En términos de latencia, y de acuerdo con el análisis de Fusco et Al. @fusco2024 esta arquitectura NUMA de memoria unificada presenta un comportamiento asimétrico según la ubicación de los datos.
La CPU Grace accede a su memoria local LPDDR5X (DDR) con una latencia de $170.0$ ns, mientras que acceder a la memoria HBM3 de su GPU emparejada a través de C2C incrementa el coste a $798.8$ ns.
Por su parte, la GPU Hopper accede a su memoria HBM3 local en $344.2$ ns, y requiere $817.8$ ns para acceder a la memoria LPDDR5X de la CPU a través del enlace C2C.
Las comunicaciones peer-to-peer (P2P) cruzadas entre distintos superchips reflejan la sobrecarga del enrutamiento: una GPU que accede a la memoria HBM de otra GPU incurre en una latencia de $1022.9$ ns, mientras que una CPU que accede a la memoria LPDDR5X de otra CPU ha de esperar $520$ ns.

== The CPU
#figure(
	image("../figures/neoverse_v2.drawio-1.jpg"),
	caption: [Pipeline microarquitectónico de un procesador basado en la especificación NeoVerse V2 @bruce2023. No se corresponde de forma estricta con el procesador descrito em esta sección.],
	placement: top,
	scope: "parent",
 	kind: "Image",
  supplement: "Figure"
) <fig-neoverse_diagram>

El procesador Grace es una CPU de 72 núcleos con frecuencias de hasta $3.1$ GHz, que toma como base la arquitectura ARM Neoverse V2 (ARMv9-A).
Esta CPU fue presentada en la conferencia hot chips de 2023 @bruce2023, y se trata de un núcleo superescalar con ejeución fuera de orden y un ancho de 8 $mu$ops por ciclo.

Tal como se observa en la @fig-neoverse_diagram, el frontend del procesador es capaz de decodificar hasta 6 instrucciones por ciclo, así como despachar 8 apoyándose en la caché de $mu$ops.
Asímismo, cuenta con un predictor de saltos TAGE @seznec2006.

El backend por su parte dispone de 6 unidades escalares enteras (ALU), de las cuales dos son capaces de realizar operaciones `mul` y una de ellas `fma` también.
Asímismo, cuenta con 2 unidades de salto, 4 puertos FP/SIMD de 128 bits, y 3 unidades de generación de direccioones (AGU).
Dos de estas AGU atienden cargas y almacenamientos, y la tercera solo cargas, lo que teóricamente permite hasta 3 operaciones de memoria de 16 bytes por ciclo.

Por su parte, la memoria en este procesador sigue la siguiente jerarquía de memorias:

#figure(
  align(center)[
    #set text(size: 6pt)
    #table(
      columns: (auto, auto, auto, auto, auto),
      align: (left, left, center, center, center),
      stroke: none,
      inset: (x: 5pt, y: 3pt),

      table.hline(stroke: 1pt),
      table.header(
        [*Type*], [*Size*], [*Associativity*], [*Bytes/cycle*], [*Bandwith*],
      ),
      table.hline(stroke: 0.5pt),

      [Registros], [No publicado], [---], [---], [---],
      [L1 datos], [$64$ KB/nucleo], [$4$ vías], [$48$], [$144$ GB/s],
      [L2], [$1$ MB/nucleo], [$8$ vías], [$64$], [$192$ GB/s],
      [L3], [$114$ MB], [---], [---], [---],
      [LPDDR5X], [$128$ GB], [---], [---], [$512$ GB/s],
      table.hline(stroke: 1pt),
    )
  ],
  caption: [Jerarquía de memoria del procesador Grace (CPU) del superchip GH200. ],
  supplement: "Table",
  kind: "Table",
) <tab-mem>

La comunicación entre hilos, explotada en el paralelismo a nivel de hilo (TLP), se realiza a través de una malla de coherencia basada en una grid 6x7.

#figure(
  image("../figures/grace_cpu_and_scalable_coherency_fabric.png"),
  caption: [Diagrama de bloques del procesador Grace (CPU) del GH200: 72 núcleos Neoverse V2, 114 MB de caché L3 distribuida sobre la malla de coherencia @nvidia_grace_cpu.],
) <fig-grace>

El número de operaciones de coma flotante por ciclo se obtiene de $4$ pipelines SIMD de $128$ bits, cada cada uno con $2$ carriles `fp64` que realizan una `FMA` ($2$ operaciones), lo que da $16$ FLOP/ciclo por núcleo, asímismo, se toma como frecuencia de reloj $3.0$ Ghz, frecuencia máxima alcanzable al usar un pipeline completo de operaciones SIMD @nvidia_gh200_2024.
$72 times 16 times 3"GHz" eq 3.456 "TFLOPS"$.

/*Tiene instrucciones de mult de matrices, hay que añadirlo (bf16, int8) */

== The GPU
La GPU H100 de cada superchip tiene $132$ multiprocesadores (SM), con $128$ núcleos `fp32` y `fp64` por SM, y $4$ núcleos tensoriales de cuarta generación por SM.
Su memoria HBM3 ofrece hasta $4$ TB/s y se comunica con la CPU mediante NVLink-C2C a $900$ GB/s bidireccionales.
La @tab-gpu recoge sus características y los picos teóricos por precisión.

#figure(
  align(center)[
    #set text(size: 8pt)
    #table(
      columns: (auto, auto),
      align: (left, left),
      stroke: none,
      inset: (x: 5pt, y: 3pt),

      table.hline(stroke: 1pt),
      table.header(table.cell(colspan: 2, align: center)[*Especificaciones*]),
      table.hline(stroke: 1pt),

      table.cell(colspan: 2)[*Generales*],

      [Microarquitectura], [Hopper],
      [Frecuencia (boost)], [$approx 1.98$ GHz],

      table.hline(stroke: 0.5pt),
      table.cell(colspan: 2)[*Unidades de cómputo*],

      [Multiprocesadores (SM)], [$132$],
      [Núcleos CUDA (FP32/FP64)], [$16 896$ (128 por SM)],
      [Núcleos tensoriales], [528 ($4^"a"$ generación)],

      table.hline(stroke: 0.5pt),
      table.cell(colspan: 2)[*Jerarquía de caché*],

      [L1 / memoria compartida], [$256$ KB por SM],
      [L2], [$50$ MB],

      table.hline(stroke: 0.5pt),
      table.cell(colspan: 2)[*Memoria*],

      [Capacidad], [$96$ GB HBM3],
      [Ancho de banda], [$4$ TB/s],

      table.hline(stroke: 0.5pt),
      table.cell(colspan: 2)[*Rendimiento pico teórico*],

      [`fp64` (CUDA)], [$approx 34$ TFLOPS],
      [`fp64` (tensorial)], [$approx 67$ TFLOPS],
      [FP32], [$approx 67$ TFLOPS],
      [FP8 denso / disperso], [$approx 1979 "/" 3958$ TFLOPS],
      [IA de equilibrio (FP64 CUDA/tens)], [$approx 8.5 "/" 17$ FLOP/byte],
      table.hline(stroke: 1pt),
    )
  ],
  caption: [Características microarquitectónicas de la GPU H100 (Hopper) del superchip GH200.],
  supplement: "Table",
  kind: "Table"
) <tab-gpu>

A escala del sistema completo ($5448$ superchips), el pico `fp8` disperso de $3958$ TFLOPS por GPU da el orden de $21$ EFLOPS.

/* Pendiente: añadir figura del pipeline de ejecución de Neoverse V2 y de la jerarquía de cachés del H100 si se desea. */

/* Añadir: ancho de banda de la caché L1 y L2 y L3 de la GPU y la CPU, así como el número de vías en el caso de la CPU */
