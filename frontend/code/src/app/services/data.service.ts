import { Injectable } from '@angular/core';
import { HttpClient, HttpHeaders } from '@angular/common/http';
import { Observable } from 'rxjs';
import { FeatureCollection } from 'geojson';

const httpOptions = {
  headers: new HttpHeaders({
    'Content-Type': 'application/json',
  }),
};

@Injectable({
  providedIn: 'root',
})
export class DataService {
  constructor(private http: HttpClient) {}

  /**
   * Get Pubs from Backend
   */
  public getPubs(): Observable<
    { name: string; latitude: number; longitude: number }[]
  > {
    const url = 'http://localhost:5000/pubs';
    return this.http.post<
      { name: string; latitude: number; longitude: number }[]
    >(url, {}, httpOptions);
  }

  public getAmenities(amenity: string): Observable<
    { name: string; latitude: number; longitude: number }[]
  > {
    const url = 'http://localhost:5000/amenity';



    return this.http.post<
      { name: string; latitude: number; longitude: number }[]
    >(url, {amenity}, httpOptions);

  }

  public getAdminLevel(adminLevel: string): Observable<FeatureCollection> {
    const url = 'http://localhost:5000/adminLevel';
    return this.http.post<FeatureCollection>(url, {adminLevel}, httpOptions);

  }
  public getRegions(): Observable<FeatureCollection> {
    const url = 'http://localhost:5000/regions';
    return this.http.post<FeatureCollection>(url, {}, httpOptions);
}
}
