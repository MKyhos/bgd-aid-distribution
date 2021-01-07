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
    unitInterest = request.get_json()["unitInterest"]
    query = """with subblockdat as(select sblock_id as id, coalesce (pop_n_individuals, 0) as individuals, coalesce(pop_n_family, 0) as families from dta_sblock ds),
blockdat as(select block_id as id, coalesce(sum(pop_n_individuals), 0) as individuals, coalesce(sum(pop_n_family), 0) as families from dta_sblock ds group by (block_id)),
campdat as(select camp_id as id, coalesce(sum(pop_n_individuals), 0) as individuals, coalesce(sum(pop_n_family), 0) as families from dta_sblock ds group by (camp_id)),
camp as (select ssid as ssid, shape, area_sqm from camp),
block as (select block_ssid as ssid, shape, area_sqm from block),
subblock as (select subblock_1 as ssid, shape, area_sqm from subblock)
select id, {2} as count, ST_AsGeoJSON(shape) as geometry from {1} bd join {0} bl on bd.id=bl.ssid  """.format(adminLevel, adminLevel+"dat", unitInterest)


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
                "numbars": float(result['count'])
            },
            "geometry": json.loads(result['geometry'])
        })

        # return all results as a feature collection
    return jsonify({"type": "FeatureCollection", "features": geojsons
        }), 200
