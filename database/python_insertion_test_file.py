#python file to test insertion and updates for the db 

import psycopg2
FROM psycopg2.extras import RealDictCursor

class_mapping = {
      'tube': 'new_tubewell',
      'heal': 'new_health_service',
      'wpro': 'new_women_protection',
      'nutr': 'new_nutrition_service',
      'bath': 'new_bathing', 
      'latr': 'new_latrine'
    }

where_mapping = {
      'heal': "gri.class = 'health_service' or gri.class = 'new_health_service'",
      'wpro': "gri.class = 'women_protection' or gri.class = 'new_women_protection'",
      'nutr': "gri.class = 'nutrition_service' or gri.class = 'new_nutrition_service'",
      'bath': "(gri.class = 'sanitation' AND gri.type != 'latrine') or gri.class = 'new_bathing'", 
      'latr': "(gri.class = 'sanitation' AND gri.type != 'bathing') or class = 'new_latrine'"
    }

# example: should eventually be replaced with values from request.get_json()
amenity = 'heal'
sanitationScore = ''
latitude = '20.989767'
longitude = '92.248002'

#working: 
query = """ 
insert into geo_reach_infra (fid, class, contamination_risk_score, geom)
SELECT max(gri.fid)+1, '{0}', '{1}', st_SETsrid(st_point({2}::float, {3}::float), 4326) 
FROM geo_reach_infra gri""".format(class_mapping[amenity], sanitationScore, longitude, latitude)

with psycopg2.connect(host="localhost", port=25432, dbname="gis_db", user="gis_user", password="gis_pass") as conn:
    with conn.cursor() as cursor:
        cursor.execute(query)
        conn.commit()

#working: 
if amenity == 'tube': 
    query2 = """
    UPDATE buildings AS b1
    SET dist_tube = v.distance
    FROM (SELECT b1.id, ST_Distance(st_transform(b1.geom, 3857), st_transform(v.point,3857)) AS distance FROM voronoi_tube v join buildings b1 ON st_intersects(b1.geom, v.geom)) AS v
    WHERE b1.id = v.id;

    UPDATE tbl_sblock_features f
    SET dist_tube = b.dist, n_tube = n.tube, n_tube_risk = n.tube_risk, 
      perc_tube_risk = (100 / nullif(n.tube, 0)) * (n.tube_risk),
      pop_pertube = v.pop, n_pop_endangered_tubewell = v.pop_endangered
    FROM (SELECT sblock_id, avg(dist_tube) AS dist FROM buildings GROUP BY 1) AS b,
      (SELECT sblock_id,
      Count(gri.fid) FILTER (WHERE gri.class = 'tubewell' or gri.class = 'new_tubewell') AS tube,
      Count(gri.fid) FILTER (WHERE gri.class = 'tubewell' or gri.class = 'new_tubewell' AND gri.contamination_risk_score IN ('high', 'very high', 'intermediate')) AS tube_risk
      FROM geo_reach_infra AS gri JOIN geo_admin AS ga ON ST_Within(gri.geom, ga.geom)
      WHERE gri.class = 'tubewell' or gri.class = 'new_tubewell'
      GROUP BY 1) AS n,
      (SELECT t.sblock_id, avg(v.pop_pertube) AS pop, sum(v.pop_pertube) filter (WHERE v.contamination_risk_score IN ('high', 'very high', 'intermediate')) AS pop_endangered
      FROM tbl_sblock_features t LEFT JOIN voronoi_tube_pop v ON st_intersects(t.geom, v.point)
      GROUP BY 1) AS v
    WHERE f.sblock_id = b.sblock_id AND f.sblock_id = n.sblock_id AND f.sblock_id = v.sblock_id;
      
    UPDATE tbl_block_features f
    SET dist_tube = t.dist, n_tube = t.tube, n_tube_risk = t.tube_risk,  
      perc_tube_risk = (100 / nullif(t.tube, 0)) * (t.tube_risk), 
      pop_pertube = t.pop, n_pop_endangered_tubewell = t.pop_endangered 
    FROM (SELECT block_id, avg(dist_tube) AS dist, sum(n_tube) AS tube, 
      sum(n_tube_risk) AS tube_risk, avg(pop_pertube) AS pop, sum(n_pop_endangered_tubewell) AS pop_endangered       
      FROM tbl_sblock_features t 
      GROUP BY 1) AS t
    WHERE f.block_id = t.block_id;

    UPDATE tbl_camp_features f
    SET dist_tube = t.dist, n_tube = t.tube, n_tube_risk = t.tube_risk, 
      perc_tube_risk = (100 / nullif(t.tube, 0)) * (t.tube_risk), 
      pop_pertube = t.pop, n_pop_endangered_tubewell = t.pop_endangered 
    FROM (SELECT camp_id, avg(dist_tube) AS dist, sum(n_tube) AS tube, sum(n_tube_risk) AS tube_risk, avg(pop_pertube) AS pop, sum(n_pop_endangered_tubewell) AS pop_endangered       
      FROM tbl_block_features t 
      GROUP BY 1) AS t
    WHERE f.camp_id = t.camp_id"""

else: query2 = """
    UPDATE buildings AS b1
    SET dist_{0} = v.distance
    FROM (SELECT b1.id, ST_Distance(st_transform(b1.geom, 3857), st_transform(v.point,3857)) AS distance FROM voronoi_{0} v join buildings b1 ON st_intersects(b1.geom, v.geom)) AS v
    WHERE b1.id = v.id;
 
    UPDATE tbl_sblock_features f
    SET dist_{0} = b.dist, n_{0} = n.count, pop_per{0} = v.pop
    FROM (SELECT sblock_id, avg(dist_{0}) AS dist FROM buildings GROUP BY 1) AS b,
         (SELECT sblock_id, count(gri.fid) AS count FROM geo_reach_infra AS gri JOIN geo_admin AS ga ON ST_Within(gri.geom, ga.geom) WHERE {1} GROUP BY 1) AS n,
         (SELECT t.sblock_id, avg(v.pop_per{0}) AS pop FROM tbl_sblock_features t LEFT JOIN voronoi_{0}_pop v ON st_intersects(t.geom, v.point) GROUP BY 1) AS v
    WHERE f.sblock_id = b.sblock_id AND f.sblock_id = n.sblock_id AND f.sblock_id = v.sblock_id;
  
    UPDATE tbl_block_features f
    SET dist_{0} = t.dist, n_{0} = t.count, pop_per{0} = t.pop
    FROM (SELECT block_id, avg(dist_{0}) AS dist, sum(n_{0}) AS count, avg(pop_per{0}) AS pop FROM tbl_sblock_features t GROUP BY 1) AS t
    WHERE f.block_id = t.block_id

    UPDATE tbl_camp_features f
    SET dist_{0} = t.dist, n_{0} = t.count, pop_per{0} = t.pop
    FROM (SELECT camp_id, avg(dist_{0}) AS dist, sum(n_{0}) AS count, avg(pop_per{0}) AS pop FROM tbl_block_features t GROUP BY 1) AS t
    WHERE f.camp_id = t.camp_id""".format(amenity, where_mapping[amenity])

with psycopg2.connect(host="localhost", port=25432, dbname="gis_db", user="gis_user", password="gis_pass") as conn:
    with conn.cursor() as cursor:
        cursor.execute(query2)
        conn.commit()



