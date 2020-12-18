import { Injectable } from '@angular/core';
import { HttpClient, HttpHeaders } from '@angular/common/http';
import { Observable } from 'rxjs';

const httpOptions = {
  headers: new HttpHeaders({
    'Content-Type': 'application/json',
  }),
};

const httpOptionsAm = {
  headers: new HttpHeaders({
    'Content-Type': 'application/json'
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
}
