/************** ABOUT TABLES *****************/
/*
- without the --slim option, only tables _point _line and _polygon are created, with filtered data. These tables also contain the geometry.
- with --slim, 3 other tables containing the raw OSM elements are created : _nodes, _ways, _rels
*/

/************** ABOUT TAGS COLUMNS *****************/
/*
- tags in tables _nodes, _ways, _rels are identical to the ones in OSM (they are "raw data" tables)
- but tags in tables _point _line and _polygon are always (slightly) different depending on the hstore options:
  # With --hstore any tags without a column will be added to the hstore column.
  # With --hstore-all all tags are added to the hstore column unless they appear in the style file with a delete flag
*/

/************** ABOUT METADATA *****************/
/* adding metadata to the DB requires -x option */
/* without it, all the CAST(tags->...) will return NULL */


/************** NODES *****************/
/* read data only in table planet_osm_point since planet_osm_nodes may be absent if you used flat nodes mode or did not use --slim */
CREATE OR REPLACE TEMP VIEW node AS
SELECT
  osm_id AS id,
  CAST(tags->'osm_version' AS integer) AS version,
  CAST(tags->'osm_timestamp' AS timestamp without time zone) AS created,
  CAST(tags->'osm_changeset' AS bigint) AS changeset,
  CAST(tags->'osm_uid' AS integer) AS uid,
  CAST(tags->'osm_user' AS text) AS user,
  to_jsonb(tags) AS tags,
  NULL::bigint[] AS nodes,
  NULL::jsonb AS members,
  way AS geom,
  'n' AS osm_type
FROM planet_osm_point;

/************** WAYS *****************/
/* ways are in tables _line and _polygon (excluding id<0 which are relations) */
CREATE OR REPLACE TEMP VIEW way AS
SELECT
  l.osm_id AS id,
  CAST(l.tags->'osm_version' AS integer) AS version,
  CAST(l.tags->'osm_timestamp' AS timestamp without time zone) AS created,
  CAST(l.tags->'osm_changeset' AS bigint) AS changeset,
  CAST(l.tags->'osm_uid' AS integer) AS uid,
  CAST(l.tags->'osm_user' AS text) AS user,
  to_jsonb(l.tags) AS tags,
  w.nodes AS nodes, /* replace by `NULL::bigint[] AS nodes` if did not use --slim */
  NULL::jsonb AS members,
  l.way AS geom,
  'w' AS osm_type
FROM planet_osm_line AS l
LEFT JOIN planet_osm_ways AS w ON osm_id = id /* remove if you did not use --slim */
UNION ALL
SELECT
  p.osm_id AS id,
  CAST(p.tags->'osm_version' AS integer) AS version,
  CAST(p.tags->'osm_timestamp' AS timestamp without time zone) AS created,
  CAST(p.tags->'osm_changeset' AS bigint) AS changeset,
  CAST(p.tags->'osm_uid' AS integer) AS uid,
  CAST(p.tags->'osm_user' AS text) AS user,
  to_jsonb(p.tags) as tags,
  w.nodes AS nodes, /* replace by `NULL::bigint[] AS nodes` if did not use --slim */
  NULL::jsonb AS members,
  p.way AS geom,
  'w' AS osm_type
FROM planet_osm_polygon AS p
LEFT JOIN planet_osm_ways AS w ON osm_id = id /* remove if you did not use --slim */
WHERE p.osm_id > 0
;

/************** RELATIONS *****************/
/* complete version if you used --slim */
CREATE OR REPLACE TEMP VIEW relation AS
SELECT
  r.id AS id,
  CAST(r.tags->>'osm_version' AS integer) AS version,
  CAST(r.tags->>'osm_timestamp' AS timestamp without time zone) AS created,
  CAST(r.tags->>'osm_changeset' AS bigint) AS changeset,
  CAST(r.tags->>'osm_uid' AS integer) AS uid,
  CAST(r.tags->>'osm_user' AS text) AS user,
  r.tags as tags,
  NULL::bigint[] AS nodes,
  r.members AS members,
  p.way AS geom,
  'r' AS osm_type
FROM planet_osm_rels AS r
LEFT JOIN planet_osm_polygon AS p ON id = -osm_id;

/* simple version if you did not used --slim */
/* returns only some relations : multipolygon, boundary, routes */
/*
CREATE OR REPLACE TEMP VIEW relation AS
SELECT
  -osm_id as id, /* relation ids are stored as negative values in planet_osm_polygon */
  CAST(tags->'osm_version' AS integer) AS version,
  CAST(tags->'osm_timestamp' AS timestamp without time zone) AS created,
  CAST(tags->'osm_changeset' AS bigint) AS changeset,
  CAST(tags->'osm_uid' AS integer) AS uid,
  CAST(tags->'osm_user' AS text) AS user,
  to_jsonb(tags) as tags,
  NULL::bigint[] AS nodes,
  NULL::jsonb AS members,
  ST_Transform(way,4326) AS geom,
  'r' AS osm_type
FROM planet_osm_polygon;
*/

/************** NWR *****************/
CREATE OR REPLACE TEMP VIEW nwr AS
SELECT * FROM node
UNION ALL
SELECT * FROM way
UNION ALL
SELECT * FROM relation
;

/************** AREA *****************/
/* complete version if you used --slim */
CREATE OR REPLACE TEMP VIEW area AS
SELECT
  CASE
    WHEN p.osm_id<0 THEN 3600000000-p.osm_id /* transform the negative values used for relations in _polygon table to the id format used for areas in overpass */
    ELSE p.osm_id
  END AS id,
  CAST(p.tags->'osm_version' AS integer) AS version,
  CAST(p.tags->'osm_timestamp' AS timestamp without time zone) AS created,
  CAST(p.tags->'osm_changeset' AS bigint) AS changeset,
  CAST(p.tags->'osm_uid' AS integer) AS uid,
  CAST(p.tags->'osm_user' AS text) AS user,
  to_jsonb(p.tags) as tags,
  w.nodes AS nodes, /* For ways only : get nodes from table planet_osm_ways */
  r.members AS members, /* For relations only : get members from table planet_osm_rels */
  p.way AS geom,
  'a' AS osm_type
FROM planet_osm_polygon AS p
LEFT JOIN planet_osm_ways AS w ON osm_id=w.id
LEFT JOIN planet_osm_rels AS r ON osm_id=-r.id
/* I don't know if JOIN to get nodes and members are useful for areas. Maybe geom is enough? */
;

/* simple version if you did not used --slim */
/*
CREATE OR REPLACE TEMP VIEW area AS
SELECT
  CASE
    WHEN p.osm_id<0 THEN 3600000000-p.osm_id /* transform the negative values used here for relations to the id format used for areas in overpass */
    ELSE p.osm_id
  END AS id,
  CAST(p.tags->'osm_version' AS integer) AS version,
  CAST(p.tags->'osm_timestamp' AS timestamp without time zone) AS created,
  CAST(p.tags->'osm_changeset' AS bigint) AS changeset,
  CAST(p.tags->'osm_uid' AS integer) AS uid,
  CAST(p.tags->'osm_user' AS text) AS user,
  to_jsonb(p.tags) as tags,
  NULL::bigint[] AS nodes,
  NULL::jsonb AS members,
  ST_Transform(p.way,4326) AS geom,
  'a' AS osm_type
FROM planet_osm_polygon AS p
;
*/