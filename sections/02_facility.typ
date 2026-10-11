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

#image("../figures/vista_aerea.png")

== Facilities
El sistema físico se aloja en el _National Composites Centre_ (NCC), ubicado en el _Bristol and Bath Science Park_ /*CIta*/. Comparte recinto con la fase 1 del proyecto Isambard-AI, así como con el cluster Isambard 3, basado exclusivamente en CPU Nvidia Grace /*cita*/.
Debido a las estrictas limitaciones espaciales, con tan solo ~550 metros cuadrados disponibles ($15.6 times 35 m$)/*cita*/, el sistema no podía ser desplegado en una sala blanca convencional/*CItar la iso de salas blancas*/.
En su lugar, se implementó una solución autocontenida que encapsula nodos, transformación eléctrica, y estaciones de bombeo dentro del propio habitáculo. Para ello se empleó una arquitectura de centro de datos modular, lo que permitió reducir un 72% de las emisiones derivadas de su construcción en comparación con los centros de datos convencionales/*cita del paper*/.

#image("../figures/cluster_borrar.png") /*redescargar la imagen con la resolución total.*/

Para disipar la alta densidad de energía térmica generada, que excede los $400$ kW por rack, el uso de refrigeración por aire convencional se presenta inviable.
En su lugar, se emplea Refrigeración Líquida Directa, solución estandarizada en los chasis HPE Cray Ex. /* otra cita por aquí*/
Esta aproximación no solo evita el sobrecalentamiento de los componentes, sino que su eficiencia convierte al sistema en un referente del paradigma Green AI, posicionandose su supercomputador gemelo, el Isambard AI-phase 1 en el puesto 4 del ranking Green AI de junio de 2026 @green500_june2026.
Este hito en sostenibilidad es especialmente reseñable al haber sido alcanzado mediante aceleradores de la generación Hopper, los cuales exhiben consumos nominales por flop superiores en comparación con arquitecturas litográficamente mas avanzadas, como Blackwell o Vera Rubin.
El sistema ostenta una Efectividad del Uso de la Energía (PUE) nominal de $1.08$, lo que implica que que solo el $8%$ de la energía se destina a refrigeración periférica.
//, ostensiblemente superior a la cifra común de sistemas refrigerados por aire, que ronda el 2.0. /*no logro verificar esto, molaria citarlo, y si podemos poner el del ft3 mejor que mejor*/

El impacto mediambiental derivado del consumo de la máquina se minimiza a través de su política de aprovisionamiento eléctrico.
Si bien su alto consumo de 5MW implicó la necesidad de una conexión de alta capacidad directa a la red eléctrica nacional británica, el 100% de la energía suministrada al sistema procede de fuentes renovables de Reino Unido, abarcando no solo sitemas eólicos, solares e hidroeléctricos, sino también sistemas de almacenamiento en baterías /*cita*/.
