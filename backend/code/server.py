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


@app.route('/pointpoly', methods=["GET", "POST"])
def pointpoly():
    adminLevel = request.get_json()["adminLevel"]
    unitName = request.get_json()["unitName"]
    unitInterest = request.get_json()["unitInterest"]
    
    if unitInterest == 'tube':
        points = 'tubewell'
        addinfo = 'contamination_risk_score'
    elif unitInterest == 'latrine':
        points = 'latrines'
        addinfo = 'type_of_structure'

    query = """
with region as 
    (select st_geomfromtext(ci.geometry, 4326)as geo, id, individuals, families 
    from {0} ci 
    where ci.id = '{1}'),
locations as 
    (select st_geomfromtext(st_astext(st_makepoint("gps longitude"::float, "gps latitude"::float)), 4326)as loc, {3}
    from {2} t)
    select {3} as name, st_y(loc) as latitude, st_x(loc) as longitude 
    from locations l 
    join region r on ST_Within(l.loc, r.geo)""".format(adminLevel + "_info", unitName, points, addinfo)
    with psycopg2.connect(host="database", port=5432, dbname="gis_db", user="gis_user", password="gis_pass") as conn:
        with conn.cursor() as cursor:
            cursor.execute(query)
            results = cursor.fetchall()

    return jsonify([{'name': r[0], 'latitude': r[1], 'longitude': r[2]} for r in results]), 200