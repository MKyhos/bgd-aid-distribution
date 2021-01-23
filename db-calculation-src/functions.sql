
-- Overall place to store and create functions.

-- For security reasons, by default pg_featureserv will only publish
-- functions on the following schema:
CREATE SCHEMA IF NOT EXISTS postgisftw;
CREATE SCHEMA IF NOT EXISTS internal;


CREATE OR REPLACE FUNCTION postgisftw.get_dta(level int = 1)
RETURNS TABLE (
  camp_id varchar,
  block_id varchar,
  sblock_id varchar,
  population numeric,
  dist_heal numeric,
  dist_bath numeric,
  dist_latr numeric,
  dist_nutr numeric,
  dist_wpro numeric,
  dist_tube numeric,
  count_buildings bigint,
  n_latr bigint,
  n_heal bigint,
  n_nutr bigint,
  n_wpro bigint,
  n_tube bigint,
  n_bath bigint,
  geom geometry
) AS
$$
  BEGIN
    IF level = 1 THEN -- Camp level
      RETURN QUERY
        SELECT d.*, g.geom,
          'none' AS block_id,
          'none' AS sblock_id
        FROM dta_camp_features AS d,
          (
            SELECT ga.camp_id, ST_Union(ga.geom) AS geom
            FROM geo_admin AS ga
            GROUP BY 1
          ) AS g
        WHERE d.camp_id = g.camp_id;
    ELSIF level = 2 THEN -- Block level
      RETURN QUERY
        SELECT d.*, g.geom,
          'none' AS sblock_id
        FROM dta_block_features AS d,
          (
            SELECT ga.block_id, ST_Union(ga.geom) AS geom
            FROM geo_admin AS ga
            GROUP BY 1
          ) AS g
        WHERE d.block_id = g.block_id;
    ELSIF level = 3 THEN -- SBlock level
      RETURN QUERY
        SELECT d.*, g.geom
        FROM dta_sblock_features AS d
        JOIN geo_admin AS g ON d.sblock_id = g.sblock_id; 
    ELSE
      RETURN QUERY
        SELECT 'NULL' AS id, 'NULL' AS geom;
    END IF;
  END;
$$
LANGUAGE 'plpgsql' STABLE PARALLEL SAFE;

COMMENT ON FUNCTION postgisftw.get_dta IS 'Function exposing the three admin 
level polygons plus properties.';
