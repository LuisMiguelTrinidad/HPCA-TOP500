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
  unidad-academica: image("figures/logo_usc.svg"),
  institucion: image("figures/logo_udc.png", width: 12%),
)

// Enlaces de colores
#show cite: set text(blue)
#show link: set text(blue)
#show ref: set text(blue)

// Bloques de matemática con números para citar
#set math.equation(numbering: "1")
#show ref: it => {
  if it.element != none and it.element.func() == math.equation {
    // Sobreescribir las referencias a ecuaciones
    link(it.element.location(), numbering(
      it.element.numbering,
      ..counter(math.equation).at(it.element.location()),
    ))
  } else {
    // Otras referencias quedan igual
    it
  }
}

// Configuración de `zero`
#import zero: num, zi
#zero.set-num(
  decimal-separator: ",",
)
#zero.set-group(
  size: 3,
  separator: ".",
  threshold: (integer: 5, fractional: calc.inf),
)
#zero.set-unit(
  fraction: "inline",
)

// Unidades
#let Vm = zi.declare("V/m")

// #nomenclatura(
//   ($q$, [Carga [#zi.coulomb()]]),
//   ($I$, [Corriente [#zi.ampere()]]),
//   ($U$, [Potencial eléctrico [#zi.volt()]]),
//   ($va(E)$, [Campo eléctrico [#Vm()]]),
//   ($va(B)$, [Campo magnético [#zi.tesla()]]),
// )

#set text(size: 12pt)

= Introducción
Desde la invención del primer microprocesador comercial, el intel 4004 en 1971, hasta la actualidad, la capacidad computacional ha experimentado un crecimiento exponencial.
Sin embargo, este crecimiento converge hoy hacia su asíntota debido a los límites físicos y termodinámicos que rigen la industria de los semiconductores.
Históricamente, durante las últimas décadas siglo XX y principios del XXI, el aumento de rendimiento se fundamentó en dos pilares teóricos: el escalado de Dennard @dennard1974 y la ley de Moore @moore2006_1.

El escalado de Dennard, formalizado por Robert H. Dennard @dennard1974, establecía que al reducir las dimensiones físicas de los transistores, el voltaje y la corriente debían escalar de forma proporcional.
Esto permitía incrementar de forma lineal la frecuencia de reloj con la miniaturización litográfica, manteniendo constante la densidad de potencia por área.
No obstante, este paradigma colapsó @bohr2007 a principios de la década de los 2000, cuando los avances en litografía hicieron que comenzasen a manifestarse de forma significativa los efectos de la mecánica cuántica.
Específicamente, la aparición del efecto túnel electrónico impidió seguir reduciendo el voltaje umbral, desatando corrientes de fuga insostenibles y cristalizando la barrera de potencia (power wall).

Paralelamente, la ley de Moore @moore2006_1, que inicialmente predecía la duplicación de la densidad de transistores anualmente, y posteriormente de forma bianual @moore2006_2, ha sufrido una severa ralentización atribuida tanto al incremento exponencial del coste del equipamiento necesario para las nuevas litografías EUV @Waldrop2016TheCA, como a la aproximación a los límites atómicos del silicio /*Otra cita aquí que desglose la evolución histórica de los procesos litográficos y sus densidades*/.
La desaceleración de este modelo ha llevado recientemente al planteamiento de nuevos paradigmas de escalado basados en la minimización de los retrasos de la propagación de señales mediante el paso de arquitecturas 2D a integración vertical @he2026.

Ante el estancamiento del escalado vertical basado en frecuencia, la respuesta de la industria consistió en la explotación sistemática del escalado horizontal y el paralelismo a nivel de hilo (TLP). AMD fue pionera en la transición hacia procesadores multnúcleo en 2005, con la introducción del Athlon 64 X2 /*cita aqui */.
Dos décadas después, la explotación del TLP en sistemas de memoria compartida ha alcanzado métricas sin precedentes, como demuestra la sexta generación de procesadores AMD EPYC, capaces de integrar hasta 256 núcleos por _socket_ /*cita aqui */.

La respuesta microarquitectónica fue el pivotaje del escalado vertical (frecuencia) hacia el escalado horizontal, con el desarrollo de multiprocesadores, del que fue pionero AMD con el lanzamiento de su AMD Athlon X2 en 2005.
Dos décadas después, la explotación del paralelismo a nivel de hilo (TLP) ha escalado hasta alcanzar los 256 núcleos en la sexta generación de procesadores AMD Epyc. /*cita*/ /* 256 nucleos - https://newsroom.amd.com/news/aai-2026-6th-gen-epyc/ */

Pese a este drástico escalado, los procesadores de propósito general exhiben ineficiencias arquitectónicas frente a cargas de trabajo altamente paralelizables.
Estos problemas requieren del uso de aceleradores especializados, como las unidades de procesamiento gráfico (GPU), que rescinden del control de flujo monohilo en favor del paradigma paralelo SIMT.
No obstante, los requerimientos contemporáneos no solo exceden la capacidad térmica y geométrica de un único circuito integrado, sino también por las necesidades de transferencia de datos de la memoria a las unidades de cómputo.
El desequilibrio histórico entre el rápido aumento de la capacidad de cómputo y el mas lento aumento del ancho de banda de memoria da lugar a un cuello de memoria sistémico, que fue por primera vez presentado en /*año, cita de memory wall original del articulo de wulf*/, y que cobra cada vez mas relevancia en el ámbito del entrenamiento de grandes modelos de lenguaje tal como refleja Gholami et Al /*cita*/.

Para poder sortear este cuello de botella y abordar el cómputo a exaescala, resulta imperativo el despliegue de clústeres heterogéneos interconectados mediante topologías de red de alto ancho de banda y baja latencia.
En el contexto geopolítico, esta infraestructura masiva resulta crítica para el entrenamiento y desarrollo de modelos fundacionales /* Fundacionales? */ con el fin de garantizar la soberanía tecnológica nacional.
En este marco de "IA soberana" se fundamenta el proyecto estratégico AI Research Resource (AIRR) /*cita */ del gobierno Británico, junto al Bristol Centre for SuperComputing /*cita*/, ambos responsables de Isambard-AI phase 2 /* cita*/, la infraestructura de supercomputación orientada a IA mas avanzada de Reino Unido.

El presente informe desglosará de manera analítica y sistemática el clúster Isambard-AI phase 2, actual decimotercer puesto en la lista TOP500.
Para ello, se adopta una aproximación arquitectónica jerárquica: partiendo de la infraestructura física subyacente y las instalaciones (Facility Level), seguida del análisis estructural de los bastidores y la topología de la interconexión de red, la evaluación de la jerarquía de memoria del sistema y, finalmente, la caracterización microarquitectónica de los nodos computacionales, concluyendo con una validación empírica y teórica mediante benchmarks de rendimiento.

= System Overview & Facility Level
A alto nivel, el cluster Isambard-AI está formado por un total de 5448 superchips NVIDIA GH200 (Grace Hopper) /*cita aqui */. Estos componentes están distribuidos a lo largo de 13 racks de alta densidad. El primer rack, un HPE Cray EX2500 pertenece al supercomputador Isambard-AI phase 1, mientras que los otros 12 racks, HPE Cray EX4000, pertenecen al superordenadoer Isambard-AI phase 2/*cita para lo del phase 1 y 2*/, el que se desglosa en el presente documento. El superordenador opera bajo un consumo energético de 5MW, proporcionando una potencia computacional máxima de 216,50 en FP64 /*CITA*/. Por otro lado, gracias a la arquitectura tensorial proporcionada por las GPU Nvidia, es capaz de alcanzar 21EFlops/s en formato FP8 /*Cita*/.


== Breve historia del proyecto
La concepción del sistema responde de forma directa a políticas de soberanía de datos y seguridad nacional. A diferencia de infraestructuras paneuropeas desarrolladas bajo el consorcio EuroHPC, el gobierno británico desarrolló su propia estrategia bajo el programa _AI Research Resource_ (AIRR) /*cita*/. Esta iniciativa gubernamental supuso la inyección inicial de 225 millones de libras esterlinas en otoño de 2023. /*CIta a nota de prensa*/

La ejecución del proyecto recayó en la universidad de Bristol debido a su experiencia probada con los clústeres Isambard 1 y 2 /* https://gw4.ac.uk/case-studies/gw4-supercomputer-isambard/ */ . Concretamente, el clúster está bajo la supervisión del Prof. Simon McIntosh-Smith, director del _Bristol Centre for Supercomputing_ (BriCS), y la Dra. Sadaf Alam, directora de tecnología (CTO) de la misma institución/*citas a algun lado que diga que son los jefazos y cita a sus perfiles de la universidad*/. El sistema fue ensamblado colaborativamente por Hewlett Packard Enterprise (HPE) y NVIDIA, y a pesar de la complejidad logística del mismo, la fase 1 fue completada en tiempo récord, pasando de la firma del contrato a un estado operacional en menos de 4 meses./*citas aqui*/

#image("figures/vista_aerea.png")

== Instalaciones
El sistema físico se aloja en el _National Composites Centre_ (NCC), ubicado en el _Bristol and Bath Science Park_ /*CIta*/. Comparte recinto con la fase 1 del proyecto Isambard-AI, así como con el cluster Isambard 3, basado exclusivamente en CPU Nvidia Grace /*cita*/.
Debido a las estrictas limitaciones espaciales, con tan solo ~550 metros cuadrados disponibles ($15.6 times 35 m$)/*cita*/, el sistema no podía ser desplegado en una sala blanca convencional /*CItar la iso de salas blancas*/. En su lugar, se implementó una solución autocontenida que encapsula nodos, transformación eléctrica, y estaciones de bombeo dentro del propio habitáculo. Para ello se empleó una arquitectura de centro de datos modular, lo que permitió reducir un 72% de las emisiones derivadas de su construcción en comparación con los centros de datos convencionales/*cita del paper*/.


#image("figures/cluster_borrar.png") /*redescargar la imagen con la resolución total.*/

Para disipar la alta densidad de energía térmica generada, que excede los 400 kW por rack, el uso de refrigeración por aire convencional se presenta inviable.
En su lugar, se emplea Refrigeración Líquida Directa, solución estandarizada en los chasis HPE Cray Ex. /* otra cita por aquí*/
Esta aproximación no solo evita el sobrecalentamiento de los componentes, sino que convierte al sistema Isambard-AI, topológicamente idéntico al sistema Isambard-AI 2, en un referente del paradigma Green AI, posicionandose en el puesto 4 del ranking Green AI de junio de 2026 /*cita al top 500*/. Este hito en sostenibilidad es especialmente reseñable al haber sido alcanzado mediante aceleradores de la generación Hopper, los cuales exhiben consumos nominales por flop superiores en comparación con arquitecturas litográficamente mas avanzadas, como Blackwell o Vera Rubin. /* una cita tal vez por aquí*/
El sistema ostenta una Efectividad del Uso de la Energía (PUE) nominal de 1.08, lo que implica que que solo el 8% de la energía se destina a refrigeración periférica, ostensiblemente superior a la cifra común de sistemas refrigerados por aire, que ronda el 2.0. /*cita de esto, y si podemos poner el del ft3 mejor que mejor*/


El impacto mediambiental derivado del consumo de la máquina se minimiza a través de su política de aprovisionamiento eléctrico. Si bien su alto consumo de 5MW implicó la necesidad de una conexión de alta capacidad directa a la red eléctrica nacional británica, el 100% de la energía suministrada al sistema procede de fuentes renovables de Reino Unido, abarcando no solo sitemas eólicos, solares e hidroeléctricos, sino también sistemas de almacenamiento en baterías /*cita*/.


= Rack & System Interconnect Level
La arquitectura a nivel de rack e interconexión está diseñada de forma jerárquica para maximizar la densidad de cómputo y minimizar la latencia, respondiendo a las exigencias operacionales de las cargas de trabajo de inteligencia artifical contemporáneas.
A nivel de bastidor, cada uno de los 12 disponibles contiene un total de 110 nodos computacionales, lo que se traduce en un total de 440 superchips NVIDIA GH200 por armario. Cada uno se estos chips contiene un procesador con 72 núcleos, así como 72 gráficas Nvidia Tesla H100 de arquitectura Hopper.

/*Incluir una imagen de los racks*/

Dentro de cada chasis, la unidad básica es el _blade_ acelerador HPE Cray EX254n. Esta placa aloja dos nodos independientes, que a su vez, se componen de 4 superchips NVIDIA GH200, congregando un total de 8 GPUs y 8 CPUs por chasis.

#image("figures/borrar_y_mejorar_resolucion.png")

A nivel de interconexión inter-nodo, la orquestración de la red se delega en la tecnología HPE Slingshot 11


= Memory Hierarchy Architecture
Detalle aquí las conclusiones de su trabajo.

= Processor & Accelerator Microarchitecture

= Empirical Performance & Benchmarks

= Theoretical Correlations & Quantitative Analysis

// // Sección de apéndices. Si no se usa, se puede comentar o borrar
// #show: apendice

// = Apéndice
// Si corresponde, utilice uno o más apéndices para complementar la información del trabajo.

#bibliography("bibliografia.bib", title: "Bibliography")
