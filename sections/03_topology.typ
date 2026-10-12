= Rack & System Interconnect Level
La arquitectura a nivel de rack e interconexión está diseñada de forma jerárquica para maximizar la densidad de cómputo y minimizar la latencia, respondiendo a las exigencias operacionales de las cargas de trabajo de inteligencia artifical contemporáneas.

/*Incluir una imagen de los racks*/

A nivel de bastidor, cada uno de los $12$ HPE Cray EX4000 @mcintosh2025 disponibles contiene un total de $110$ nodos computacionales, lo que proporciona un total de $440$ superchips NVIDIA GH200 por armario.

Dentro de cada rack, la unidad básica es el _blade_ acelerador HPE Cray EX254n.
Esta placa aloja dos nodos computacionales independientes, cada uno de los cuales cuenta con $4$ procesadores NVIDIA Grace de $72$ núcleos (arquitectura ARM Neoverse V2), así como $4$ GPU NVIDIA H100 (arquitectura Hopper).
Consecuentemente, cada nodo dispone de 288 núcleos ARM v9 y 4 GPUS H100.

#image("../figures/borrar_y_mejorar_resolucion.png")

A nivel de interconexión del cluster, la orquestración de la red se delega en la arquitectura HPE Slingshot 11 @hpe_slingshot_2026.
El sistema HPE Cray EX utiliza un acoplamiento ortogonal sin cables /*cita*/: los chasis de cómputo se insertan por la parte frontal del chasis, mientras que los chásis de conmutación (switches) se insertan por la parte trasera, intersectando en un midplane.
Este diseño cumple fundamentalmente con 3 objetivos:

- *Mejorar la integridad de señal:* permitiendo mayor ancho de banda.
- *Minimizar las latencias de interconexión:* el reducido trazado permite minimizar los retrasos en tiempo de propagación.
- *Minimizar el gasto energético:* reduciendo la cantidad de energía necesaria por byte transmitido.

Cada nodo hace uso de 4 tarjetas de red, ofreciendo un ancho de banda total de $800$ Gb/s de entrada y salida simultánea @bristol_isambard_2025 por nodo hacia la red principal.
Para la interconexión entre nodos se hace uso de switches de 64 puertos, que ofrecen un total de 25.6Tb/s.

A nivel macroscópico, la topología de red empleada es de tipo _Dragonfly_ @kim2008.
Este diseño toma como base enmallados all-to-all de pequeños grupos de nodos, que se interconectan posteriormente entre sí, esto permite garantizar un diámetro de 3 saltos @hpe_slingshot_2026 para $lt.eq 37120$ endpoints.

#image("../figures/dragonfly.pdf")

Aunque se desconoce la implementación exacta de esta topología en el clúster Isambard-AI phase 2, es posible inferir, usando como referencia otros sistemas, como el sistema _Alps_, perteneciente al _Swiss National Supercomputing Centre_ @desensi2024. Una posible implementación de esta arquitectura para cada switch se ofrece en la figura /*numero*/.

#image("../figures/Switch-diagrama.pdf")
