from flask import Flask, jsonify, request
from flask_cors import CORS
import json

import psycopg2
from psycopg2.extras import RealDictCursor

app = Flask(__name__)
CORS(app)

@app.route('/pubs', methods=["GET", "POST"])
def pubs():
    query = """ with healthsites as (select st_makepoint(longitude, latitude) as loc, "facility type" , "operational status" from health h2)
select "facility type" as name, st_y(loc) as latitude, st_x(loc) as longitude from healthsites
    """
    with psycopg2.connect(host="database", port=5432, dbname="gis_db", user="gis_user", password="gis_pass") as conn:
        with conn.cursor() as cursor:
            cursor.execute(query)
            results = cursor.fetchall()

    return jsonify([{'name': r[0], 'latitude': r[1], 'longitude': r[2]} for r in results]), 200

@app.route('/regions', methods=["GET", "POST"])
def regions():
    # query to find the number of bars per 1000 (rounded by 4) and pubs as well as number of people.
    # Note: Didn't have population data on 3 Communities, which I decided to exclude for now. Tough day...
    query = """select camp.npm_name as npm_name, area_sqm, ST_AsGeoJSON(shape) as geometry from camp"""

    # get results
    with psycopg2.connect(host="database", port=5432, dbname="gis_db", user="gis_user", password="gis_pass") as conn:
        with conn.cursor(cursor_factory=RealDictCursor) as cursor:
            cursor.execute(query)
            results = cursor.fetchall()


    # convert results to a GeoJSON
    geojsons = []
    for result in results:
        geojsons.append({
            "type": "Feature",
            "properties": {
                "name": result['npm_name'],
                "numbars": float(result['area_sqm'])
            },
            "geometry": json.loads(result['geometry'])
        })

    # return all results as a feature collection
    return jsonify({
        "type": "FeatureCollection", "features": geojsons
    }), 200

# Dropdowns
@app.route('/adminLevel', methods=['GET', "POST"])
def adminLevel():
    adminLevel = request.get_json()["adminLevel"]
    calculation = request.get_json()["calculation"]
    unitInterest = request.get_json()["unitInterest"]
    query = """select {2} as id, {1}::float as count, ST_AsGeoJSON(geom) as geometry
            from {0} 
            where {1} is not null 
            """.format("tbl_"+adminLevel + "_features", calculation+unitInterest, adminLevel+"_id")


    # get results
    with psycopg2.connect(host="database", port=5432, dbname="gis_db", user="gis_user", password="gis_pass") as conn:
        with conn.cursor(cursor_factory=RealDictCursor) as cursor:
            cursor.execute(query)
            results = cursor.fetchall()


    # convert results to a GeoJSON
    geojsons = []
    for result in results:
        geojsons.append({
            "type": "Feature",
            "properties": {
                "name": result['id'],
                "numbars": result['count']
            },
            "geometry": json.loads(result['geometry'])
        })

        # return all results as a feature collection
    return jsonify({"type": "FeatureCollection", "features": geojsons
        }), 200



@app.route('/health', methods=["GET", "POST"])
def health():
    healthsite = request.get_json()["healthLocation"]
    query = """ with healthsites as (select st_makepoint(longitude, latitude) as loc, "facility type" , "operational status" from health h2)
select "facility type" as name, st_y(loc) as latitude, st_x(loc) as longitude from healthsites where "facility type" = '{0}'
    """.format(healthsite)
    with psycopg2.connect(host="database", port=5432, dbname="gis_db", user="gis_user", password="gis_pass") as conn:
        with conn.cursor() as cursor:
            cursor.execute(query)
            results = cursor.fetchall()

    return jsonify([{'name': r[0], 'latitude': r[1], 'longitude': r[2]} for r in results]), 200


# Points in Polygons
@app.route('/pointpoly', methods=["GET", "POST"])
def pointpoly():
    adminLevel = request.get_json()["adminLevel"]
    points = request.get_json()["unitName"]
    unitInterest = request.get_json()["unitInterest"]

 #   if unitInterest == 'tube':
  #      pointUnit = 'tubewell'
   # elif unitInterest == 'latr':
    #    pointUnit = 'latrine'
    #elif unitInterest == 'bath':
      #  pointUnit == 'bathroom'
    #else:
     #   pointUnit = unitInterest
    


    query = """
with region as 
    (select ci.geom as geo
    from {0} ci 
    where {3} = '{2}'),
locations as 
    (select geom as geom, sanitary_inspection_score
    from geo_reach_infra t where t."type" like '{1}' or t."class" like '{1}') 
select sanitary_inspection_score as name, st_y(geom) as latitude, st_x(geom) as longitude 
    from locations l 
    join region r on ST_Within(l.geom, r.geo)""".format("tbl_"+adminLevel+"_features" ,"%"+unitInterest+"%", points, adminLevel+"_id")
    with psycopg2.connect(host="database", port=5432, dbname="gis_db", user="gis_user", password="gis_pass") as conn:
        with conn.cursor() as cursor:
            cursor.execute(query)
            results = cursor.fetchall()

    return jsonify([{'name': r[0], 'latitude': r[1], 'longitude': r[2]} for r in results]), 200

# Inserting into the DB and updating respective tables: working in separate python file so far but not with input from frontend
@app.route('/addPointInfo', methods=["GET", "POST"])
def addPointInfo():
    latitude = request.get_json()["latitude"]
    longitude = request.get_json()["longitude"]
    amenity = request.get_json()["amenity"]
    sanitationScore = request.get_json()["sanitationScore"]

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
    
    query = """ 
insert into geo_reach_infra (fid, class, contamination_risk_score, geom)
SELECT max(gri.fid)+1, '{0}', '{1}', st_SETsrid(st_point({2}::float, {3}::float), 4326) 
FROM geo_reach_infra gri""".format(class_mapping[amenity], sanitationScore, longitude, latitude)

    with psycopg2.connect(host="localhost", port=25432, dbname="gis_db", user="gis_user", password="gis_pass") as conn:
        with conn.cursor() as cursor:
            cursor.execute(query)
            conn.commit()
    
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
    
    pass
