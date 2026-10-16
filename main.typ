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
  resumen: [
  *_Abstract_ --- This project aims to describe the Isambard-AI phase 2 cluster at several levels.
  It takes a hierarchical approach, from the physical infrastructure down to the microarchitecture of the nodes, and validates it with benchmarks and a theoretical analysis.*
  ],
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


#bibliography("bibliografia.bib", title: "Bibliography")
