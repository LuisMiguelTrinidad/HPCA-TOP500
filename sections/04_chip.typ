= Node microarchitecture <sec-chip>
Cada nodo del clúster Isambard-AI phase 2 congrega múltiples superchips NVIDIA GH200, integrando cada uno de estos su propio procesador Grace y su GPU H100, que se comunican mediante NVLink-C2C (Chip to Chip).
Se describen a lo largo de esta sección las principales características de los mismos.

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
Por su parte, la comunicación CPU-GPU dentro de un mismo superchip se realiza mediante NVLink-C2C, ofreciendo un total de $450$ GB/s por dirección @nvidia_gh200_2024, superando ampliamente los 64GB/s por dirección que ofrece PCIe 5.0, lo que reduce la intensidad aritmética mínima necesaria para que la ejecución en GPU sea rentable frente a la CPU.

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

El procesador Grace es una CPU de $72$ núcleos con frecuencias de hasta $3.1$ GHz, basada en la microarquitectura ARM Neoverse V2 (ARMv9-A), que fue presentada en la conferencia Hot Chips de 2023 @bruce2023.
Se trata de un núcleo superescalar, con gran capacidad de explotar paralelismo a nivel de instrucciones (ILP) gracias a la ejecución fuera de orden y su ancho de 8 $mu$ops por ciclo.
Sin embargo, no implementa multihilo simultáneo (SMT), por lo que cada núcleo ejecuta un único hilo físico.
De acuerdo con la taxonomía de Flynn se trata de un sistema MIMD, cuyos núcleos pueden ejecutar instrucciones SIMD.

Como se observa en la @fig-neoverse_diagram, el frontend del procesador puede decodificar hasta 6 instrucciones por ciclo, así como despachar 8 apoyándose en una caché de $mu$ops de $1536$ entradas, asociativa a 4 vías.
Cuenta además con un predictor de saltos TAGE @seznec2006.

El _backend_ dispone de $6$ unidades escalares enteras (ALU), de las cuales dos realizan operaciones `mul` y una de ellas también `fma`.
Cuenta asímismo con $2$ unidades de salto, $4$ puertos FP/SIMD de $128$ bits, y $3$ unidades de generación de direcciones (AGU).
Dos de las AGU atienden cargas y almacenamientos, mientras que la tercera solo cargas, lo que teóricamente permite hasta $3$ operaciones de memoria de $16$ bytes por ciclo.

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
        align([*Type*], center), align([*Size*], center), align([*Associativity*], center), align([*Bytes/cycle*], center), align([*Bandwidth*], center)
      ),
      table.hline(stroke: 0.5pt),

      [Registros], 	[No publicado], 	[---], 			[---], 	[---],
      [L1d], 				[$64$ KB/nucleo], [$4$ vías], [$48$], [$144$ GB/s/c],
      [L2], 				[$1$ MB/nucleo], 	[$8$ vías], [$64$], [$192$ GB/s/c],
      [L3], 				[$114$ MB], 			[---], 			[---], 	[>2TB/s @chipsandcheese_gh200],
      [LPDDR5X], 		[$128$ GB], 			[---], 			[---], 	[$512$ GB/s],
      table.hline(stroke: 1pt),
    )
  ],
  caption: [Jerarquía de memoria del procesador Grace (CPU) del superchip GH200.],
  supplement: "Table",
  kind: "Table",
) <tab-mem>

La comunicación entre hilos, explotada en el paralelismo a nivel de hilo (TLP), se realiza a través de una malla de coherencia basada en una grid $6 times 7$, representada en la @fig-grace. Con distancia Manhattan, el número máximo de saltos entre nodos es $6+7 = 13$.

#figure(
  image("../figures/grace_cpu_and_scalable_coherency_fabric.png", width: 100%),
  caption: [Diagrama de bloques del procesador Grace (CPU) del GH200: 72 núcleos Neoverse V2 y 114 MB de caché L3 distribuida sobre la malla de coherencia @nvidia_grace_cpu.],
  kind: "Image",
  supplement: "Figure"
) <fig-grace>

El número de operaciones de coma flotante por ciclo se obtiene de $4$ pipelines SIMD de $128$ bits, cada uno con $2$ carriles `fp64` que realizan una `FMA` ($2$ operaciones), lo que da $16$ FLOP/ciclo por núcleo.
Con la frecuencia de reloj de $3.0$ GHz, el pico `fp64` del procesador completo es $72 times 16 times 3.0 "GHz" = 3.456$ TFLOPS.

Los pipelines SIMD pertenecen a la familia de instrucciones vectoriales de ARMv9 (SVE2, con compatibilidad NEON de $128$ bits). Esta familia no incluye una unidad matricial dedicada como SME, de modo que la aceleración de cargas de baja precisión se realiza con instrucciones de producto escalar. Por ejemplo, `SDOT` (`int8`) acumula en cada carril de $32$ bits cuatro productos, es decir, $16$ `mac` por instrucción sobre registros de $128$ bits, o $32$ operaciones contando cada `mac` como dos. Con $4$ pipelines, el pico por núcleo es $4 times 32 = 128$ OPS `int8` por ciclo, y para el procesador completo a $3.0$ GHz, $72 times 128 times 3.0 "GHz" approx 27.6$ TOPS `int8`.

En coma flotante de $16$ bits, `BFDOT` (`bf16`) acumula dos productos en cada carril, es decir, $8$ `mac` o $16$ FLOP por instrucción. Con $4$ pipelines, el pico por núcleo es $4 times 16 = 64$ FLOP `bf16` por ciclo, lo que da $72 times 64 times 3.0 "GHz" approx 13.8$ TFLOPS `bf16` para el procesador completo.

Estas cifras suponen que los $4$ pipelines ejecutan una instrucción de este tipo por ciclo.

Suponiendo que los $4$ pipelines emiten una de estas instrucciones por ciclo, el pico teórico por núcleo es $4 times 64 = 256$ OPS `int8` y $4 times 32 = 128$ FLOP `fp16` por ciclo.
Para el procesador completo a $3.0$ GHz, esto supone unos $55$ TOPS `int8` y $27.6$ TFLOPS `bf16`.

== The GPU
Cada superchip incorpora una GPU H100 con $132$ multiprocesadores (SM) habilitados, de un total de $144$ en el die @chipsandcheese_gh200.
De acuerdo con la taxonomía de Flynn, la GPU, al contar con distintos SMs, se comporta de forma general de acuerdo al modelo SIMD, mientras que dentro de cada SM, se trata de un caso degenerado de SIMD, SIMT.
Se describe a continuación la misma en dos partes: primero la jerarquía de memoria y después sus capacidades computacionales.

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
      [Registros],	[$256$ KB/SM], 			[---], 	[---], 	[$1$c],
      [L1], 				[$256$ KB/SM], 			[$128$/SM], 	[$approx 33$ TB/s], 	[$approx 23$--$41$c],
      [L2], 				[$2 times 25$ MB],	[---], [$approx 5.5$ TB/s], 	[$approx 200$--$263$c],
      [HBM3], 			[$96$ GB], 					[---], 				[$approx 4$ TB/s],	 	[$approx 290$--$480$c],
      table.hline(stroke: 1pt),
    )
  ], /* Los datos de 256/SM y 32/slice parecen estar mal */
  caption: [Jerarquía de memoria de la GPU H100 (Hopper) del superchip GH200. Datos de latencias de @spheron_hierarchy],
  supplement: "Table",
  kind: "Table",
) <tab-gpu-mem>

Los registros del SM ocupan $256$ KB, repartidos entre los warps residentes: cada hilo puede usar hasta $255$ registros de 32 bits (unos $1$ KB), lo que supone hasta $32$ KB por warp de 32 hilos @choquette2022.

La L1 cuenta con $256$ KB por SM, ofreciendo un ancho de banda de $128$ B/ciclo por SM @hopper_tuning, lo que le permite alcanzar unos $33$ TB/s agregados sobre los $132$ SM.

La caché L2 de $50$ MB es compartida por todos los SM y se divide en dos particiones de $25$ MB.
Los accesos a la partición lejana cuestan aproximadamente el doble que a la cercana.
Chips and Cheese midió @chipsandcheese_gh200 más de $5.5$ TB/s de lectura en la partición cercana, pero sobre una H100 PCIe con $114$ SM, así que para la variante SXM es una estimación.

La HBM3 del GH200 ofrece $96$ GB y $4$ TB/s, a través de un bus de $6144$ bits.

Por último, los clústeres de bloques de Hopper permiten co-planificar hasta $16$ bloques en SM adyacentes.
Un bloque puede acceder a la memoria compartida de otro a través de una red SM a SM @choquette2022, lo que según NVIDIA reduce la latencia de intercambio unas $7$ veces.

=== Cómputo por SM
Cada SM contiene $128$ núcleos FP32, $64$ núcleos FP64 y $4$ núcleos tensoriales de cuarta generación.
La @fig-sm muestra la organización de un SM de la GPU H100.

#figure(
  image("../figures/h100_sm.svg"),
  caption: [Diagrama del SM de la arquitectura Hopper (H100). Extraído de @modal_tensor_core],
  kind: "Image",
  supplement: "Figure"
) <fig-sm>

El cómputo de cada SM depende del tipo de dato.
En los núcleos CUDA, cada núcleo FP32 ejecuta una FMA por ciclo, lo que da $128$ FMA, o $256$ FLOP, por SM y ciclo.
En FP64, los núcleos CUDA realizan $64$ FMA por ciclo, es decir, $128$ FLOP.

Los núcleos tensoriales son los que más destacan en formatos de menor precisión.
La @tab-compute resume estos valores junto con la intensidad aritmética, que se estudia en la tabla final.

=== Tabla resumen
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
        [*Type*], [*Unidad*],[*FLOP/c/SM*], [*TFLOPS*], [*IA/L1*], [*IA/HBM3*],
      ),
      table.hline(stroke: 0.5pt),
      [`fp64`],        [CUDA],      [$128$],  [$approx 34$],   [$1$],  [$approx 8.5$],
      [`fp32`],        [CUDA],      [$256$],  [$approx 67$],   [$1$],  [$approx 16.75$],
      [`fp64`],        [Tensorial], [$256$],  [$approx 67$],   [$2$],  [$approx 16.75$],
      [`tf32`],        [Tensorial], [$2048$], [$approx 494$],  [$16$], [$approx 123.5$],
      [`FP16/BF16`],   [Tensorial], [$4096$], [$approx 990$],  [$32$], [$approx 247.5$],
      [`FP8/INT8`],    [Tensorial], [$8192$], [$approx 1979$], [$64$], [$approx 494.75$],
      table.hline(stroke: 1pt),
    )
  ],
  caption: [Operaciones por ciclo y por SM, pico del sistema de $132$ SM e intensidad aritmética mínima para compute-bound.],
  supplement: "Table",
  kind: "Table",
) <tab-compute>

Las intensidades explican dónde está el cuello de botella.
Un kernel FP64 CUDA ya necesita unos $8.5$ FLOP por byte de HBM3 para saturar el cómputo, mientras que el FP16 tensorial necesita unos $247$.
Las cargas de entrenamiento de modelos de lenguaje reutilizan mucho cada dato y pueden alcanzar esa intensidad, pero los kernels de baja intensidad quedan limitados por la memoria.

Por último, la GPU H100 se corresponde con la categoría SIMD de Flynn en su modelo SIMT.
Un mismo _warp_ de $32$ hilos emite una única instrucción por ciclo sobre datos distintos, mientras que los $132$ multiprocesadores operan de forma independiente, lo que aporta un nivel MIMD.
Dentro de cada SM, la planificación de hasta $64$ _warps_ residentes oculta las latencias de memoria mediante el cambio de contexto entre _warps_, en lugar de la ejecución fuera de orden.
