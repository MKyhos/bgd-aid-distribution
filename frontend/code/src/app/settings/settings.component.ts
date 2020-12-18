import { Component, EventEmitter, Output } from '@angular/core';
import { FormBuilder, FormGroup, Validators } from '@angular/forms';

@Component({
  selector: 'app-settings',
  templateUrl: './settings.component.html',
  styleUrls: ['./settings.component.scss'],
})
export class SettingsComponent {
  // this output can be listened to in the parent component
  @Output()
  markerAdded: EventEmitter<{
    latitude: number;
    longitude: number;
  }> = new EventEmitter<{ latitude: number; longitude: number }>();

  // this output can be listened to in the parent component
  @Output()
  pubsAdded: EventEmitter<boolean> = new EventEmitter<boolean>();

  // amenity type listenable in parent
  @Output()
  amenityAdded: EventEmitter<{
    amenity: string;
  }> = new EventEmitter<{ amenity: string }>();


  // location form stores and validates the inputs from our forms defined in the html document
  locationForm: FormGroup;
  // amenity form
  amenityForm: FormGroup;

  constructor(private fb: FormBuilder) {
    this.locationForm = fb.group({
      latitude: fb.control(21.24, [
        Validators.required,
        Validators.min(-90),
        Validators.max(90),
      ]),
      longitude: fb.control(92.09, [
        Validators.required,
        Validators.min(-180),
        Validators.max(180),
      ]),
    });
    this.amenityForm = fb.group({
      amenity: fb.control('shelter', [
        Validators.required,
      ]),
    });
  }

  /**
   * When the add marker button was clicked, emit the location where the marker should be added
   * @param marker Latitude and longitude of the marker
   */
  onSubmit(marker: { latitude: number; longitude: number }): void {
    this.markerAdded.emit(marker);
  }

    /**
   * When the add marker button was clicked, emit the location where the marker should be added
   * @param marker Latitude and longitude of the marker
   */
  addPubs(): void {
    this.pubsAdded.emit(true);
  }


  onAmSubmit(amenity: { amenity: string}): void {
    this.amenityAdded.emit(amenity);

  }
}
