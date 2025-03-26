CREATE OR REPLACE TEMP VIEW node AS
SELECT
  osm_id AS id,
  /* CAST(tags->'osm_version AS integer)' */ NULL::integer AS version,
  /* CAST(tags->'osm_timestamp' AS timestamp without time zone) */ NULL::timestamp without time zone AS created,
  /* CAST(tags->'osm_changeset' AS bigint) */ NULL::bigint AS changeset,
  /* CAST(tags->'osm_uid' AS integer) */ NULL::integer AS uid,
  /* CAST(tags->'osm_user' AS text) */ NULL::text AS user,
  to_jsonb(tags) AS tags,
  NULL::bigint[] AS nodes,
  NULL::jsonb AS members,
  way AS geom,
  'n' AS osm_type
FROM planet_osm_point;

CREATE OR REPLACE TEMP VIEW way AS
SELECT
  l.osm_id AS id,
  /* CAST(l.tags->'osm_version AS integer)' */ NULL::integer AS version,
  /* CAST(l.tags->'osm_timestamp' AS timestamp without time zone) */ NULL::timestamp without time zone AS created,
  /* CAST(l.tags->'osm_changeset' AS bigint) */ NULL::bigint AS changeset,
  /* CAST(l.tags->'osm_uid' AS integer) */ NULL::integer AS uid,
  /* CAST(l.tags->'osm_user' AS text) */ NULL::text AS user,
  to_jsonb(l.tags) AS tags,
  w.nodes AS nodes, /* get nodes from table planet_osm_ways, using JOIN */
  NULL::jsonb AS members,
  l.way AS geom,
  'w' AS osm_type
FROM planet_osm_line AS l
LEFT JOIN planet_osm_ways AS w ON osm_id=id
UNION ALL
SELECT
  p.osm_id AS id,
  /* CAST(p.tags->'osm_version AS integer)' */ NULL::integer AS version,
  /* CAST(p.tags->'osm_timestamp' AS timestamp without time zone) */ NULL::timestamp without time zone AS created,
  /* CAST(p.tags->'osm_changeset' AS bigint) */ NULL::bigint AS changeset,
  /* CAST(p.tags->'osm_uid' AS integer) */ NULL::integer AS uid,
  /* CAST(p.tags->'osm_user' AS text) */ NULL::text AS user,
  to_jsonb(p.tags) as tags,
  w.nodes AS nodes, /* get nodes from table planet_osm_ways, using JOIN */
  NULL::jsonb AS members,
  p.way AS geom,
  'w' AS osm_type
FROM planet_osm_polygon AS p
LEFT JOIN planet_osm_ways AS w ON osm_id=id
WHERE id > 0; /* keep ways and exclude (multipolygon) relations */

CREATE OR REPLACE TEMP VIEW relation AS
SELECT
  r.id,
  /* CAST(hstore(r.tags)->'osm_version AS integer)' */ NULL::integer AS version,
  /* CAST(hstore(r.tags)->'osm_timestamp' AS timestamp without time zone) */ NULL::timestamp without time zone AS created,
  /* CAST(hstore(r.tags)->'osm_changeset' AS bigint) */ NULL::bigint AS changeset,
  /* CAST(hstore(r.tags)->'osm_uid' AS integer) */ NULL::integer AS uid,
  /* CAST(hstore(r.tags)->'osm_user' AS text) */ NULL::text AS user,
  r.tags as tags,
  NULL::bigint[] AS nodes,
  r.members AS members,
  p.way AS geom, /* get geom from table planet_osm_polygon with negative osm_id values, using JOIN */
  'r' AS osm_type
FROM planet_osm_rels AS r
LEFT JOIN planet_osm_polygon AS p ON id=-osm_id
;

CREATE OR REPLACE TEMP VIEW nwr AS
SELECT * FROM node
UNION ALL
SELECT * FROM way
UNION ALL
SELECT * FROM relation
;

CREATE OR REPLACE TEMP VIEW area AS
SELECT
  CASE
    WHEN p.osm_id<0 THEN 3600000000-p.osm_id /* transform the negative values used here for relations to the id format used for areas in overpass */
    ELSE p.osm_id
  END AS id,
  /* CAST(p.tags->'osm_version AS integer)' */ NULL::integer AS version,
  /* CAST(p.tags->'osm_timestamp' AS timestamp without time zone) */ NULL::timestamp without time zone AS created,
  /* CAST(p.tags->'osm_changeset' AS bigint) */ NULL::bigint AS changeset,
  /* CAST(p.tags->'osm_uid' AS integer) */ NULL::integer AS uid,
  /* CAST(p.tags->'osm_user' AS text) */ NULL::text AS user,
  to_jsonb(p.tags) as tags,
  w.nodes AS nodes, /* For ways only : get nodes from table planet_osm_ways, using JOIN */
  r.members AS members, /* For relations only : get members from table planet_osm_rels, using JOIN */
  p.way AS geom,
  'a' AS osm_type
FROM planet_osm_polygon AS p
LEFT JOIN planet_osm_ways AS w ON osm_id=w.id
LEFT JOIN planet_osm_rels AS r ON osm_id=-r.id
/* I don't know if JOIN to get nodes and members are useful for areas. Maybe geom is enough */
;
