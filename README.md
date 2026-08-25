# São Paulo Public Transport — interactive map

Interactive, poster-grade map of the public transport of **São Paulo**: the
whole SPTrans bus network, the ten trolleybus lines inside it, the Metrô and
the CPTM commuter rail — 1 325 lines / 34 966 km drawn along the real street
and track geometry. The largest sheet in this family.

## Live

**https://miqell24.github.io/sao-paulo-bus-map/** — GitHub Pages from `main:/docs`. Local build on port 8159 (`npm run serve`).

One feed, three worlds:

| category | source | lines | drawn |
|---|---|---|---|
| buses (navy) | SPTrans, `route_type` 3 | 1 300 | 33 973 km |
| **trolleybuses (green)** | the same, identified from OSM (see below) | 9 of 10 | 212 km |
| Metrô & CPTM | `route_type` 1 and 2, official colours from the feed | 16 | 781 km |

**The trolleybuses.** SPTrans ships them as ordinary buses, so the feed cannot
tell them apart — but two independent sources can, and they agree.
OpenStreetMap carries nine of them as `route=trolleybus` relations (operator
Ambiental Transportes Urbanos), and OSM's mapped overhead wire (1 506 ways,
167 km, against a system of about 137 km) puts each of those nine at 95–100 %
of its course under wire. The tenth, **4112-10**, has no route relation in OSM
but runs 100 % under wire, shares the Praça da República terminus with 4113-10
and is named as a current trolleybus line by the Portuguese Wikipedia, so it
joins them:

> 2002-10 · 2100-10 · 2100-21 · 2290-10 · 2290-21 · 3160-10 · 342M-10 ·
> 408A-10 · 4112-10 · 4113-10

Lines that share the wires without being trolleybus-operated stay navy: the
night services N401-11, N404-11 and N508-11 (the trolleybuses do not run
overnight) and the 390E-10 express, which OSM maps as `route=bus`.

Only nine of the ten are on the map: **2100-21 has no trips in this feed**, and
it is not alone — 36 of the 1 361 routes in `routes.txt` carry no trips at all
(mostly `-21`/`-23` variants), which is why 1 325 lines are drawn.

Line keys are SPTrans' own codes, verbatim, for every bus ("8000-10" style).
The rail lines arrive as `METRÔ L1`, `METRÔ 15`, `METRÔ17A`, `CPTM L07` — the
operator's name spelled out inside the line name, eight characters where two
will do on a badge beside a thousand bus codes. They keep the operator's
initial and the number: **M1–M6, M15, M17A, M17W** for the Metrô, **C7–C13**
for the CPTM. Lines 15 and 17 are monorails, so `railway=monorail` had to join
the rail graph.

## Where the data comes from

SPTrans publishes the feed behind a developer login
(`sptrans.com.br/…/BaixarGTFS?memberName=sptrans`), so this map takes the daily
mirror the **Mobility Database** keeps of that same file (feed `mdb-8`);
`files.mobilitydatabase.org/mdb-8/latest.zip` is the stable pointer. The build
here reads the 24.08.2026 file.

Matching: **1.57 m mean** across 2 271 line-directions, worst 55.6 m. The road
graph is 1.66 million nodes from 269 000 ways — 70 × 60 km of one of the
densest street grids on earth, fetched as a 5 × 5 grid of Overpass tiles,
because a box any bigger just answers 504.

Residue worth knowing: 33 poles dropped as farther than 200 m from every line
calling there, and **Metrô Linha 1 comes out in ten pieces** — five ~20 m gaps
per direction where OSM's tunnel ways do not meet and the engine bridges with a
raw chord. The line is drawn end to end; the strands break at those five spots.

## Two views

The panel's **Corridors / Lines** switch redraws the same data two ways.
*Corridors* is one stroke per roadway in the mode colours, with the trolleybus
green dashed over navy where the two share a street (566 runs do; 40 are
trolleybus-only). *Lines* draws every line on its own — up to four coloured
strands side by side, anything busier as one grey trunk with its numbers beside
it (`npm run lines`, checked by `npm run audit`). 61 % of the 21 851 roadway
runs carry four lines or fewer; the widest trunk gathers 62. No network diagram
for this city yet.

Being the biggest sheet in the family, it is also the slowest to open: the
browser pulls ~30 MB of GeoJSON before the first stroke appears.

## Pipeline

`npm run download` fetches the GTFS, the 25 road tiles and the rail extract
(Overpass) and MapLibre GL. `npm run build` map-matches every line (HMM/Viterbi
on the OSM graphs) and writes GeoJSON to `data/out/`; `npm run lines` adds the
line-by-line view, `npm run audit` checks it. Both want a large heap —
the scripts pass `--max-old-space-size=10240`. `npm run serve` hosts the map at
http://localhost:8159.

Data: GTFS SPTrans (via mobilitydatabase.org) · trolleybus identification from
OpenStreetMap · base map © OpenFreeMap / OpenMapTiles / OpenStreetMap
contributors.
