# Underpass-API

An Overpass-API on SQL Database.

Underpass-API aim to be a [Overpass-API](https://github.com/drolbr/Overpass-API) compatible engine built upon [converter](https://github.com/teritorio/overpass_parser-rb) from Overpass Language to SQL.

## Prepare the data & Run the server

Folow the instruction of one of the backends:
* [Postgres+PostGIS / Osmosis](backends/postgres_osmosis/README.md), Osmosis schema
* [DuckDB+Spatial / QuackOSM](backends/duckdb_quackosm/README.md), Quackosm schema

## Query

The API as available at http://localhost:9292/interpreter

## Performance

Test with the [Gironde, France](http://download.openstreetmap.fr/extracts/europe/france/aquitaine/gironde-latest.osm.pbf) extract (94MB).
Test with generic index, running localy, 8 CPU, 8 GB RAM.

Test Query 1
```
[out:json][timeout:25];
(
  nwr[highway=bus_stop][name];
  nwr[public_transport=platform];
);
out center meta;
```

time curl 'http://localhost:9292/interpreter' -X POST -H 'Content-Type: application/x-www-form-urlencoded; charset=UTF-8' --data-raw 'data=%5Bout%3Ajson%5D%5Btimeout%3A25%5D%3B%0A(%0A++nwr%5Bhighway%3Dbus_stop%5D%5Bname%5D%3B%0A++nwr%5Bpublic_transport%3Dplatform%5D%3B%0A)%3B%0Aout+center+meta%3B'

| Backend                          | Setup  | Query 1 |
|----------------------------------|--------|---------|
| Postgres+PostGIS / Osmosis       | 10m11s |    5,7s |
| DuckDB+Spatial / QuackOSM (1)    |  2m00s |    2,4s |
| Overpass API (2)                 |  8m49s |    3,1s |
| Overpass API overpass-api.de (3) |      - |    5,9s |

(1) Without metadata.
(2) Required converion from PBF to XML included ().
(3) Query with polygon to limit the spatial extent.
