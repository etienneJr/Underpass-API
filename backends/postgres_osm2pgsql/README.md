# Postgres/PostGIS, Osm2pgsql schema

Prepare Docker
```sh
docker compose --profile '*' build
```

Or with bundle (requires to modify the `ENV[...]` in the .rb files ?)
```
bundle install
```

## Prepare the data

Create you database using osm2pgsql.
If you include metadata (using an .osm extract which includes them, and the --extra-attributes option), you will need to modify view.sql to include the commented syntax for version, tstamp, changeset, user, uid

## Run the server

Run the HTTP server
```
docker compose up
```

Or with bundle (requires to modify the `ENV[...]` in the .rb files ?)
```
bundle exec rackup
```
