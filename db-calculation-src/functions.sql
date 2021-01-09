
-- Overall place to store and create functions.

-- For security reasons, by default pg_featureserv will only publish
-- functions on the following schema:
CREATE SCHEMA IF NOT EXISTS postgisftw;
CREATE SCHEMA IF NOT EXISTS internal;


CREATE OR REPLACE FUNCTION postgisftw.get_dta(level int = 1)
RETURNS TABLE (id VARCHAR, geom GEOMETRY) AS
$$
  BEGIN
    IF level = 1 THEN
      RETURN QUERY
        SELECT g.camp_id AS id, ST_Union(g.geom) AS geom
        FROM public.geo_admin AS g
        GROUP BY g.camp_id;
    ELSIF level = 2 THEN
      RETURN QUERY
        SELECT g.block_id AS id, ST_Union(g.geom) AS geom
        FROM public.geo_admin AS g
        GROUP BY g.block_id;
    ELSIF level = 3 THEN
      RETURN QUERY
        SELECT g.sblock_id as id, g.geom
        FROM public.geo_admin AS g;
    ELSE
      RETURN QUERY
        SELECT 'NULL' AS id, 'NULL' AS geom;
    END IF;
  END;
$$
LANGUAGE 'plpgsql' STABLE PARALLEL SAFE;

COMMENT ON FUNCTION postgisftw.get_dta IS 'Function exposing the three admin 
level polygons plus properties.';

