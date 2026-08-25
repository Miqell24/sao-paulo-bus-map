#!/usr/bin/env bash
# Downloads input data: the SPTrans GTFS, OSM networks (Overpass), MapLibre GL.
# Everything is cached — re-running only fetches what is missing.
#
# São Paulo: ONE feed from SPTrans — buses (route_type 3), the Metrô (1) and
# the CPTM commuter rail (2) in one bundle, with the operators' official line
# colours. SPTrans publishes it behind a developer login
# (sptrans.com.br/…/BaixarGTFS?memberName=sptrans), so this script takes the
# daily mirror the Mobility Database keeps of that same file (feed mdb-8);
# files.mobilitydatabase.org/mdb-8/latest.zip is the stable pointer to it.
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p data/gtfs data/osm web/vendor

ok_json () { # $1=file  $2=minimum element count
  python3 - "$1" "$2" <<'PYEOF' 2>/dev/null
import json, sys
try:
    sys.exit(0 if len(json.load(open(sys.argv[1])).get("elements", [])) >= int(sys.argv[2]) else 1)
except Exception:
    sys.exit(1)
PYEOF
}

# Overpass with patience: the public mirrors answer 504 ("server too busy") for
# minutes at a time. Rounds with growing back-off, mirrors rotated inside each.
overpass () { # $1=outfile  $2=query  $3=minimum element count
  local out="$1" q="$2" floor="$3" round wait
  for round in 1 2 3 4 5 6 7 8; do
    for EP in "https://overpass-api.de/api/interpreter" \
              "https://maps.mail.ru/osm/tools/overpass/api/interpreter" \
              "https://overpass.kumi.systems/api/interpreter" \
              "https://overpass.private.coffee/api/interpreter"; do
      echo "-- round $round: $EP"
      if curl -fsS --max-time 1800 -o "$out" --data-urlencode "data=$q" "$EP" && ok_json "$out" "$floor"; then
        return 0
      fi
      rm -f "$out"
    done
    wait=$((round * 45))
    echo "-- all mirrors busy, waiting ${wait}s"
    sleep "$wait"
  done
  echo "Overpass: all mirrors failed for $out" >&2
  return 1
}

# 1) GTFS — SPTrans through the Mobility Database mirror
if [ ! -f data/gtfs/routes.txt ]; then
  echo "== GTFS → data/gtfs =="
  curl -fL --retry 3 --max-time 900 -o data/gtfs.zip "https://files.mobilitydatabase.org/mdb-8/latest.zip"
  unzip -o data/gtfs.zip -d data/gtfs
fi

# 2) OSM — roadways, as a 5 × 5 grid of tiles over the bus network's extent
#    (stops 23.91–23.37 S, 46.82–46.37 W plus margin). Small tiles are not an
#    optimisation but a requirement: this is one of the densest street grids on
#    earth, and Overpass answers 504 on a box big enough to hold a quarter of
#    it — the same lesson Buenos Aires taught the family. build.mjs merges the
#    tiles at load (cfg.osmFiles, ways deduped by id).
HW='["highway"~"^(motorway|trunk|primary|secondary|tertiary|unclassified|residential|living_street|service|busway|construction|motorway_link|trunk_link|primary_link|secondary_link|tertiary_link)$"]'
mkdir -p data/osm/tiles
LAT0=-24.00; LON0=-46.95; DLAT=0.140; DLON=0.134
i=0
for r in 0 1 2 3 4; do
  for c in 0 1 2 3 4; do
    i=$((i + 1))
    f="data/osm/tiles/t$i.json"
    [ -f "$f" ] && continue
    S=$(python3 -c "print(f'{$LAT0 + $r*$DLAT:.4f},{$LON0 + $c*$DLON:.4f},{$LAT0 + ($r+1)*$DLAT:.4f},{$LON0 + ($c+1)*$DLON:.4f}')")
    echo "== Overpass (roads, tile $i/25: $S) =="
    overpass "$f" "[out:json][timeout:600][maxsize:1000000000];way($S)$HW;out geom;" 20
  done
done

# 2b) OSM — rails for the Metrô and the CPTM. Lines 15 and 17 are monorails, so
#     railway=monorail belongs in the extract; the CPTM reaches Jundiaí and Mogi
#     das Cruzes, hence the wider box.
if [ ! -f data/osm/sp-rail.json ]; then
  echo "== Overpass (rails) =="
  overpass data/osm/sp-rail.json \
    '[out:json][timeout:900][maxsize:1000000000];way(-23.90,-47.10,-23.10,-46.10)["railway"~"^(subway|light_rail|rail|monorail|tram|construction)$"];out geom;' 200
fi

# 3) MapLibre GL (vendored, no CDN at runtime)
if [ ! -f web/vendor/maplibre-gl.js ]; then
  echo "== MapLibre GL =="
  curl -fL --retry 3 -o web/vendor/maplibre-gl.js  https://unpkg.com/maplibre-gl@5.6.1/dist/maplibre-gl.js
  curl -fL --retry 3 -o web/vendor/maplibre-gl.css https://unpkg.com/maplibre-gl@5.6.1/dist/maplibre-gl.css
fi

echo "OK — data ready:"
du -sh data/gtfs data/osm/*.json 2>/dev/null || true
