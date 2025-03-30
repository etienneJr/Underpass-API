# Postgres/PostGIS, Osm2pgsql schema

Prepare Docker
```sh
docker compose --profile '*' build
```

## Prepare the data

Create you database using osm2pgsql.
If you do not use the `-s (--slim)` option, you will have to modify view.sql (see comments)

## Run the server

Run the HTTP server
```
docker compose up
```
