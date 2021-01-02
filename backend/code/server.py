from flask import Flask, jsonify, request
from flask_cors import CORS
import json

import psycopg2
from psycopg2.extras import RealDictCursor

app = Flask(__name__)
CORS(app)

@app.route('/pubs', methods=["GET", "POST"])
def pubs():
    query = """ with amenity_poly as (
    	SELECT osm_id, name, amenity, ST_CENTROID(way) as centroid
    	from planet_osm_polygon
    	where amenity='refugee_site'
    	)
    select amenity_poly.name, ST_Y(amenity_poly.centroid) as latitude , ST_X(amenity_poly.centroid) as longitude
    from amenity_poly
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
    query = """select npm_name, area_sqm, ST_AsGeoJSON(shape) as geometry from outlines0"""

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
