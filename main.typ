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
#set par(spacing: 1em, justify: true, first-line-indent: 1em)
#set text(size: 11pt, lang: "en", region: "us")

#include "sections/01_introduction.typ"
#include "sections/02_facility.typ"
#include "sections/03_topology.typ"
#include "sections/04_chip.typ"

/* en algun lado tengo que meter esto */
= Storage

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
