= Node microarchitecture
Cada nodo del clúster Isambard-AI phase 2 congrega múltiples superchips NVIDIA GH200, integrando cada uno de estos su propio procesador Grace y su GPU H100, unidos mediante NVLink-C2C (Chip to Chip).
Se describe a a lo largo de esa sección las principales características de los mismos.

== Node composition
A nivel macro, cada nodo cuenta con $4$ superchips GH200, sumando en total $288$ núcleos, $67584$ núcleos cuda, $512$ GB de memoria RAM LPDDR5X y $384$ GB de memoria HBM3 distribuidos de forma equitativa por superchip @bristol_isambard_2025.
La fuerte integración empleada permite que cada CPU o GPU pueda acceder a cualquier dirección de memoria RAM o VRAM de cualquiera de los otros chips @nvidia_gh200_2024.

A nivel de inteconexión intra-nodo, cada uno de las GPUs está interconectada con el resto en un enmallado _all-to-all_ basado en la tecnología NVLink 4.0, con 6 líneas de la misma en cada conexión, lo que ofrece un ancho de banda de $150$ GB/s por dirección.
Asímismo, la comunicación CPU-GPU dentro de un mismo chip cuenta con un ancho de banda muy superior al que dispondría con una conexión PCIe 5.0, ofreciendo un total de $450$ GB/s por dirección, lo que contribuye a reducir la intensidad aritmética mínima para hacer viable la ejecución de código en GPU frente a su ejecución en CPU.

En términos de latencia, y de acuerdo con el análisis de Fusco et Al. @fusco2024 esta arquitectura de memoria unificada presenta un comportamiento asimétrico dependiente de la ubicación física de los datos.
La CPU Grace accede a su memoria local LPDDR5X (DDR) con una latencia de $170.0$ ns, mientras que acceder a la memoria HBM3 de su GPU emparejada a través de C2C incrementa el coste a $798.8$ ns.
Por su parte, la GPU Hopper accede a su memoria HBM3 local en $344.2$ ns, y requiere $817.8$ ns para acceder a la memoria LPDDR5X de la CPU a través del enlace C2C.
Las comunicaciones peer-to-peer (P2P) cruzadas entre distintos superchips del mismo nodo reflejan la sobrecarga del enrutamiento: una GPU que accede a la memoria HBM de otra GPU incurre en una latencia de $1022.9$ ns, mientras que si una CPU accede a la memoria LPDDR5X de otra CPU la penalización es de $520$ ms.

#figure(
  image("../figures/diagrama_borrar.png"),
  caption: [Esquema de un nodo de Isambard-AI phase 2: cuatro superchips GH200, cada uno con su CPU Grace, su GPU H100, sus memorias LPDDR5X y HBM3, su tarjeta de red Slingshot-11 y los enlaces NVLink-C2C intra-superchip.],
) <fig-node>

== The CPU
El procesador Grace es una CPU ARM de 72 núcleos Neoverse V2 implementada con la arquitectura ARMv9-A presentada en la conferencia hot chips 2023 /*citar hot chips*/, a una frecuencia de $3-3.1$ GHz según el uso hecho de instrucciones SIMD @nvidia_gh200_2024.
La Tabla @tab-cpu resume sus características principales.

/* revisar el dato de 4 unidades que multiplican, puede que esté mal */
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

      [Microarquitectura], [Neoverse V2 (ARMv9-A)],
      [Núcleos], [72],
      [Frecuencia], [3,1 GHz],

      table.hline(stroke: 0.5pt),
      table.cell(colspan: 2)[*Unidades de cómputo*],

      [Pipelines SIMD por núcleo], [$4 times 128$ bits],
      [Unidades enteras por núcleo], [6 ALU (2 con multiplicación)],

      table.hline(stroke: 0.5pt),
      table.cell(colspan: 2)[*Jerarquía de caché*],

      [L1 (I/D)], [$64$ KB / $64$ KB por núcleo],
      [L2], [$1$ MB por núcleo],
      [L3], [$114$ MB compartida],

      table.hline(stroke: 0.5pt),
      table.cell(colspan: 2)[*Memoria*],

      [Capacidad], [$128$ GB LPDDR5X],
      [Ancho de banda], [$512$ GB/s],

      table.hline(stroke: 0.5pt),
      table.cell(colspan: 2)[*Rendimiento pico teórico*],

      [FP64], [$approx 3.5$ TFLOPS],
      [FP32], [$approx 7.1$ TFLOPS],
      [Intensidad de equilibrio (FP64)], [$approx 6.8$ FLOP/byte],
      table.hline(stroke: 1pt),
    )
  ],
  caption: [Características microarquitectónicas del procesador Grace (CPU) del superchip GH200 @nvidia_gh200_2024.],
  kind: "table",
) <tab-cpu>

/*El dato está mal, serían 3GHz si eso, mañana lo reviso */
El número de operaciones de coma flotante por ciclo se obtiene de cuatro pipelines SIMD de $128$ bits, cada una con $2$ carriles `fp64` que realizan una FMA ($2$ operaciones), lo que da $16$ FLOP/ciclo por núcleo, es decir, $72 times 16 times 3.1"GHz" approx 3.5 "TFLOPS"$.

== The GPU
La GPU H100 de cada superchip tiene $132$ multiprocesadores (SM), con $128$ núcleos `fp32` y `fp64` por SM, y $4$ núcleos tensoriales de cuarta generación por SM.
Su memoria HBM3 ofrece hasta $4$ TB/s y se comunica con la CPU mediante NVLink-C2C a $900$ GB/s bidireccionales. La @tab-gpu recoge sus características y los picos teóricos por precisión.

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
      [FP8 denso / disperso], [$approx 1979 / 3958$ TFLOPS],
      [IA de equilibrio (FP64 CUDA/tens)], [$approx 8.5 / 17$ FLOP/byte],
      table.hline(stroke: 1pt),
    )
  ],
  caption: [Características microarquitectónicas de la GPU H100 (Hopper) del superchip GH200.],
  kind: "table"
) <tab-gpu>

A escala del sistema completo ($5448$ superchips), el pico `fp8` disperso de $3958$ TFLOPS por GPU da el orden de $21$ EFLOPS.

/* Pendiente: añadir figura del pipeline de ejecución de Neoverse V2 y de la jerarquía de cachés del H100 si se desea. */

/* Añadir: ancho de banda de la caché L1 y L2 y L3 de la GPU y la CPU */
