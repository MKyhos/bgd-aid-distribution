import { Injectable } from '@angular/core';
import { HttpClient, HttpHeaders } from '@angular/common/http';
import { Observable } from 'rxjs';
import { FeatureCollection } from 'geojson';

const httpOptions = {
  headers: new HttpHeaders({
    'Content-Type': 'application/json',
    'Access-Control-Allow-Origin': '*'
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

  public getHealthLocation(adminLevel: string, unitName: string): Observable<
    { name: string; latitude: number; longitude: number }[]
    > {
      const url = 'http://localhost:5000/pointpoly';
    
    
    
      return this.http.post<
        { name: string; latitude: number; longitude: number }[]
      >(url, {adminLevel, unitName}, httpOptions);
    
    }

  public getAmenities(amenity: string): Observable<
  { name: string; latitude: number; longitude: number }[]
> {
  const url = 'http://localhost:5000/amenity';



  return this.http.post<
    { name: string; latitude: number; longitude: number }[]
  >(url, {amenity}, httpOptions);

}

  public getAdminLevel(adminLevel: string, unitInterest: string): Observable<FeatureCollection> {
    const url = 'http://localhost:5000/adminLevel';
    return this.http.post<FeatureCollection>(url, {adminLevel, unitInterest}, httpOptions);

  }
  public getRegions(): Observable<FeatureCollection> {
    const url = 'http://localhost:5000/regions';
    return this.http.post<FeatureCollection>(url, {}, httpOptions);
  }

  public getLocations(adminLevel: string, unitName: string): Observable<
  { name: string; latitude: number; longitude: number }[]
> {
  const url = 'http://localhost:5000/pointpoly';



  return this.http.post<
    { name: string; latitude: number; longitude: number }[]
  >(url, {adminLevel, unitName}, httpOptions);

}

}
