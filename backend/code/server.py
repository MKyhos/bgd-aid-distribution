from flask import Flask, jsonify, request
from flask_cors import CORS

import psycopg2

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
