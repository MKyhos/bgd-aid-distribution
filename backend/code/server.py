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


@app.route('/addPointInfo', methods=["GET","POST"])
def addPointInfo():
    latitude = request.get_json()["latitude"]
    longitude = request.get_json()["longitude"]
    amenity = request.get_json()["amenity"]
    sanitationScore = request.get_json()["sanitationScore"]

    query = """ insert into 
    geo_reach_infra("class", "type", sanitary_inspection_score, geom)
    values('someclass','somerealtype','somescore', st_setsrid(st_makepoint(90,21), 4326)) """

    with psycopg2.connect(host="database", port=5432, dbname="gis_db", user="gis_user", password="gis_pass") as conn:
        with conn.cursor() as cursor:
            cursor.execute(query)
            

    pass
