# Postgres/PostGIS, Osm2pgsql schema

Prepare Docker
```sh
docker compose --profile '*' build
```

## Prepare the data

Create you database using osm2pgsql.
If you do not use the `-s (--slim)` option, you will have to modify `view.sql` (see comments)

If your database was created "outside" docker, you will have to modify `docker-compose.yaml` to:
  - delete services `osm2pgsql` and `postgress`
  - in service api : delete reference `depends on: -postgres` and set your `DATABASE_URL: postgres://user:pw@host:5432/database`

## Run the server

Run the HTTP server
```
docker compose up
```
