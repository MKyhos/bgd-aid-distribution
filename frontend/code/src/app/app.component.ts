import { Component, ViewChild } from '@angular/core';
import { MapComponent } from './map/map.component';
import { DataService } from './services/data.service';
import { FeatureCollection } from 'geojson';

@Component({
  selector: 'app-root',
  templateUrl: './app.component.html',
  styleUrls: ['./app.component.scss'],
})
export class AppComponent {
  // There are two options to add markers to our map component
  // option 1: get the component and call add marker method directly
  @ViewChild(MapComponent) map!: MapComponent;

  // option 2: use @Input() in the child component
  amenities: { name: string; latitude: number; longitude: number }[] = [];

  /*
   * Services or other dependencies are often imported via dependency injection.
   * See https://angular.io/guide/dependency-injection for more details.
   */
  constructor(private dataservice: DataService) {}

  /**
   * @param $event add marker on the map at the specified latitude and longitude
   */
  onAddMarker($event: { latitude: number; longitude: number }) {
    this.map.addMarker($event.latitude, $event.longitude);
  }

  ngAfterViewInit(): void {
    this.dataservice.getRegions().subscribe((geojson: FeatureCollection) => {
      this.map.addGeoJSON(geojson);
    });
  }

  /*
   * Retrieve pubs from backend and override the member variable.
   */
  onPubsAdded() {
    this.dataservice.getPubs().subscribe((pubs) => {
      this.amenities = pubs;
    });
  }

  onAmenitiesAdded($event: { amenity: string }) {
    this.dataservice.getAmenities($event.amenity).subscribe((amenities) => {
    this.amenities = amenities;

  }
  )};
}
