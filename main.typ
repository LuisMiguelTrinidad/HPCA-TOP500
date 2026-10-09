#import "@preview/barcala:0.3.0": apendice, informe, nomenclatura
#import "@preview/zero:0.5.0"

#show: informe.with(
  asignatura: "HPA -- High Performance Architectures",
  trabajo: "TOP 500 SUPERCOMPUTERS REPORT",

  autores: (
    (
      nombre: "Trinidad Salvador, Luis Miguel",
      email: "lmtrinidadsalvador@gmail.com",
    ),
  ),

  titulo: [TOP 13: Isambard-AI phase 2],
  resumen: [*_Abstract_ --- El presente proyecto toma como fin la descripción a distintos niveles del clúster Isambard-AI phase 2. Se aborda de forma jerárquica *],
  unidad-academica: image("figures/logo_usc.svg", width: 60pt),
  institucion: image("figures/logo_udc.png", width: 60pt),
)

// Enlaces de colores
#show cite: set text(blue)
#show link: set text(blue)
#show ref: set text(blue)

#show: rest => columns(2, rest)
#set par(spacing: 1.2em, justify: true, first-line-indent: 1.3em)
#set text(size: 11pt)

= Introduction /* Revisar si es verdaderamente el primero */
Desde la invención del primer microprocesador comercial, el intel 4004 en 1971, hasta la actualidad, la capacidad computacional ha experimentado un crecimiento exponencial.
Sin embargo, este crecimiento converge hoy hacia su asíntota debido a los límites físicos y termodinámicos que rigen la industria de los semiconductores.
Históricamente, durante las últimas décadas siglo XX y principios del XXI, el aumento de rendimiento se fundamentó en dos pilares teóricos: el escalado de Dennard @dennard1974 y la ley de Moore @moore2006_1.

El escalado de Dennard, formalizado por Robert H. Dennard @dennard1974, establecía que al reducir las dimensiones físicas de los transistores, el voltaje y la corriente debían escalar de forma proporcional.
Esto permitía incrementar de forma lineal la frecuencia de reloj con la miniaturización litográfica, manteniendo constante la densidad de potencia por área.
No obstante, este paradigma colapsó @bohr2007 a principios de la década de los 2000, cuando los avances en litografía hicieron que comenzasen a manifestarse de forma significativa los efectos de la mecánica cuántica.
Específicamente, la aparición del efecto túnel electrónico impidió seguir reduciendo el voltaje umbral, desatando corrientes de fuga insostenibles y cristalizando la barrera de potencia (power wall).

Paralelamente, la ley de Moore @moore2006_1, que inicialmente predecía la duplicación de la densidad de transistores anualmente, y posteriormente de forma bianual @moore2006_2, ha sufrido una severa ralentización atribuida tanto al incremento exponencial del coste del equipamiento necesario para las nuevas litografías EUV @Waldrop2016TheCA/*No me cuadra esta cita*/, como a la aproximación a los límites atómicos del silicio. /*Tal vez una cita aquí */
La desaceleración de este modelo ha llevado recientemente al planteamiento de nuevos paradigmas de escalado basados en la minimización de los retrasos de la propagación de señales mediante el paso de arquitecturas 2D a integración vertical @he2026.

Ante el estancamiento del escalado vertical basado en frecuencia, la respuesta de la industria consistió en la explotación sistemática del escalado horizontal y el paralelismo a nivel de hilos (TLP) @peng2007memory.
AMD fue pionera en la transición hacia procesadores multinúcleo x86 en 2005, con la introducción del Athlon 64 X2 de diseño monolítico nativo@amd2007athlon.
Dos décadas después, la explotación del TLP en sistemas de memoria compartida ha alcanzado métricas sin precedentes, como demuestra la sexta generación de procesadores AMD EPYC, capaces de integrar hasta $256$ núcleos por _socket_ @amd2026epyc9006.

Pese a este drástico escalado, los procesadores de propósito general exhiben ineficiencias arquitectónicas frente a cargas de trabajo altamente paralelizables.
Estos problemas requieren del uso de aceleradores especializados, como las unidades de procesamiento gráfico (GPU), que rescinden del control de flujo monohilo en favor del paradigma paralelo SIMT.
No obstante, los requerimientos contemporáneos no solo exceden la capacidad computacional de un único circuito integrado, sino también la capacidad de transferencia de datos de las unidades de memoria a las de cómputo.
El desequilibrio histórico entre el rápido aumento de la capacidad de cómputo y el mas lento aumento del ancho de banda de memoria da lugar a un cuello de memoria sistémico, que fue por primera vez presentado en 1995 @wulf1995, y que cobra cada vez mas relevancia en el ámbito del entrenamiento de grandes modelos de lenguaje tal como refleja Gholami et Al @gholami2024.

Para poder sortear este cuello de botella y abordar el cómputo a exaescala, resulta imperativo el despliegue de clústeres heterogéneos interconectados mediante topologías de red de alto ancho de banda y baja latencia.
En el contexto geopolítico, esta infraestructura masiva resulta crítica para el entrenamiento y desarrollo de grandes modelos de lenguaje con el fin de garantizar la soberanía tecnológica nacional.

En este marco de _IA soberana_ se fundamenta el proyecto estratégico AI Research Resource (AIRR) @ukgov_airr_2025 del gobierno Británico, junto al Bristol Centre for SuperComputing @bristol_isambard_2025, ambos responsables de Isambard-AI phase 2, la infraestructura de supercomputación orientada a IA mas avanzada de Reino Unido.

El presente informe desglosará de manera analítica y sistemática el clúster Isambard-AI phase 2, actual decimotercer puesto en la lista TOP500 @top500_isambard2_2025.
/* Aqui hay que usar referencia a las distintas secciones, como en el paper de sarteco. */
Para ello, se adopta una aproximación arquitectónica jerárquica: partiendo de la infraestructura física subyacente y las instalaciones (Facility Level), seguida del análisis estructural de los bastidores y la topología de la interconexión de red, la evaluación de la jerarquía de memoria del sistema y, finalmente, la caracterización microarquitectónica de los nodos computacionales, concluyendo con una validación empírica y teórica mediante benchmarks de rendimiento.

= Facility level system overview
A alto nivel, el cluster Isambard-AI está formado por un total de $5448$ superchips _NVIDIA GH200_ (Grace Hopper) @nvidia_gh200_2024 distribuidos a lo largo de 13 racks de alta densidad.
El primer rack, un HPE Cray EX2500 pertenece al supercomputador Isambard-AI phase 1, mientras que los otros 12 racks, HPE Cray EX4000, pertenecen al superordenadoer Isambard-AI phase 2 @mcintosh2025, el que se desglosa en el presente documento.

El superordenador opera bajo un consumo energético de $5$ MW, proporcionando una potencia computacional máxima de $216.50$ Pflops en `FP64` en el benchmark Linpack @top500_isambard2_2025.
Por otro lado, gracias a la arquitectura tensorial proporcionada por las GPU Nvidia, es capaz de alcanzar de forma teórica $21$ EFlops/s en formato FP8 @mcintosh2025.

== Brief history of the project
La concepción del sistema responde de forma directa a políticas de soberanía de datos y seguridad nacional.
A diferencia de infraestructuras paneuropeas desarrolladas bajo el consorcio EuroHPC, el gobierno británico desarrolló su propia estrategia bajo el programa _AI Research Resource_ (AIRR) @ukgov_airr_2025.
Esta iniciativa gubernamental supuso la inyección inicial de 225 millones de libras esterlinas en otoño de 2023. @HPE2023IsambardAI

La ejecución del proyecto recayó en la universidad de Bristol debido a su experiencia probada con el proyecto GW4 @mcintosh2019.
Concretamente, el clúster está bajo la supervisión del Prof. Simon McIntosh-Smith, director del _Bristol Centre for Supercomputing_ (BriCS), y la Dra. Sadaf Alam, directora de tecnología (CTO) de la misma institución/*citas a algun lado que diga que son los jefazos y cita a sus perfiles de la universidad*/.
El sistema fue ensamblado colaborativamente por Hewlett Packard Enterprise (HPE) y NVIDIA, y a pesar de la complejidad logística del mismo, la fase 1 fue completada en tiempo récord, pasando de la firma del contrato a un estado operacional en menos de 4 meses./*citas aqui*/

#image("figures/vista_aerea.png")

== Facilities
El sistema físico se aloja en el _National Composites Centre_ (NCC), ubicado en el _Bristol and Bath Science Park_ /*CIta*/. Comparte recinto con la fase 1 del proyecto Isambard-AI, así como con el cluster Isambard 3, basado exclusivamente en CPU Nvidia Grace /*cita*/.
Debido a las estrictas limitaciones espaciales, con tan solo ~550 metros cuadrados disponibles ($15.6 times 35 m$)/*cita*/, el sistema no podía ser desplegado en una sala blanca convencional/*CItar la iso de salas blancas*/.
En su lugar, se implementó una solución autocontenida que encapsula nodos, transformación eléctrica, y estaciones de bombeo dentro del propio habitáculo. Para ello se empleó una arquitectura de centro de datos modular, lo que permitió reducir un 72% de las emisiones derivadas de su construcción en comparación con los centros de datos convencionales/*cita del paper*/.

#image("figures/cluster_borrar.png") /*redescargar la imagen con la resolución total.*/

Para disipar la alta densidad de energía térmica generada, que excede los $400$ kW por rack, el uso de refrigeración por aire convencional se presenta inviable.
En su lugar, se emplea Refrigeración Líquida Directa, solución estandarizada en los chasis HPE Cray Ex. /* otra cita por aquí*/
Esta aproximación no solo evita el sobrecalentamiento de los componentes, sino que su eficiencia convierte al sistema en un referente del paradigma Green AI, posicionandose su supercomputador gemelo, el Isambard AI-phase 1 en el puesto 4 del ranking Green AI de junio de 2026 @green500_june2026.
Este hito en sostenibilidad es especialmente reseñable al haber sido alcanzado mediante aceleradores de la generación Hopper, los cuales exhiben consumos nominales por flop superiores en comparación con arquitecturas litográficamente mas avanzadas, como Blackwell o Vera Rubin.
El sistema ostenta una Efectividad del Uso de la Energía (PUE) nominal de $1.08$, lo que implica que que solo el $8%$ de la energía se destina a refrigeración periférica.
//, ostensiblemente superior a la cifra común de sistemas refrigerados por aire, que ronda el 2.0. /*no logro verificar esto, molaria citarlo, y si podemos poner el del ft3 mejor que mejor*/

El impacto mediambiental derivado del consumo de la máquina se minimiza a través de su política de aprovisionamiento eléctrico.
Si bien su alto consumo de 5MW implicó la necesidad de una conexión de alta capacidad directa a la red eléctrica nacional británica, el 100% de la energía suministrada al sistema procede de fuentes renovables de Reino Unido, abarcando no solo sitemas eólicos, solares e hidroeléctricos, sino también sistemas de almacenamiento en baterías /*cita*/.


= Rack & System Interconnect Level
La arquitectura a nivel de rack e interconexión está diseñada de forma jerárquica para maximizar la densidad de cómputo y minimizar la latencia, respondiendo a las exigencias operacionales de las cargas de trabajo de inteligencia artifical contemporáneas.
A nivel de bastidor, cada uno de los 12 disponibles contiene un total de 110 nodos computacionales, lo que se traduce en un total de 440 superchips NVIDIA GH200 por armario. Cada uno se estos chips contiene un procesador con 72 núcleos, así como 72 gráficas Nvidia Tesla H100 de arquitectura Hopper.

/*Incluir una imagen de los racks*/

Dentro de cada chasis, la unidad básica es el _blade_ acelerador HPE Cray EX254n. Esta placa aloja dos nodos independientes, que a su vez, se componen de 4 superchips NVIDIA GH200, congregando un total de 8 GPUs y 8 CPUs por chasis.

#image("figures/borrar_y_mejorar_resolucion.png")

A nivel de interconexión inter-nodo, la orquestración de la red se delega en la tecnología HPE Slingshot 11 /*cita de su especificacion */. Cada nodo hace uso de 4 de estas tarjetas de red, ofreciendo un ancho de banda total de $800$ Gb/s de forma uni/direccional /*Chequear */ por nodo hacia la red principal.

ASímismo /* hablar de los switches, cuantos switches hay en total */

La topología de red empleada /*Hablar de Dragonfly high radix, con ilustraciones y citas al paper original */


= Memory Hierarchy Architecture
Detalle aquí las conclusiones de su trabajo.

/* A nivel de procesador, núm de registros, L1, L2, L3, RAM */
/* Lo mismo para la GPU, tal vez fusionar esto con lo siguiente */
/* Presentarlo en formato tabla, con los anchos de banda */

= Processor & Accelerator Microarchitecture

/* Número de unidades FP, número de Int, cuantas hacen mult, tabla como la del TFG, ancho de vector, número de cores, TFLOPS max, Intensidad aritmética... */

= Empirical Performance & Benchmarks

= Theoretical Correlations & Quantitative Analysis

// // Sección de apéndices. Si no se usa, se puede comentar o borrar
// #show: apendice

// = Apéndice
// Si corresponde, utilice uno o más apéndices para complementar la información del trabajo.

#bibliography("bibliografia.bib", title: "Bibliography")

/*
HECHO
	- A short description of the system
EN ELLO
	- A enumeration of the characteristics of the different memory hierarchies in the sytem (CPU and or GPUs): number of caches levels and characteristics of each one.
EN ELLO
	- A description of the relevant features of each processor, such as: number of cores, vector instructions family supported, characteristics of the pipeline, the architecture that implements the processor (Nehalem, Skylake,...), the support of multiple issue, the reported performance of the processor executing different benchmarks (such as SPEC CPU and others)
SER MAS EXPLICITO CON ESTO
	- Types of parallelism exploited by the different components of the system, according to Flynn's taxonomy.
BUSCAR ALGO SOBRE LA COMUNICACION ENTRE NUCLEOS...
	- Characteristics of the supported multithreading
REVISAR AL FINAL PARA VER QUE FALTA
	- Anyother correlation found between the theoretical concepts introduction in chapters 1 and 2 and the characteristics of the processor will be welcomed.

 */
