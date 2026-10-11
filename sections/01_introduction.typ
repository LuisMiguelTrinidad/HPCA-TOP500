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
