import { Component, EventEmitter, Output, ViewEncapsulation} from '@angular/core';
import { FormBuilder, FormGroup,  Validators } from '@angular/forms';

@Component({
  selector: 'app-settings',
  templateUrl: './settings.component.html',
  styleUrls: ['./settings.component.scss']
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

  // adminlevel
  @Output()
  adminLevelAdded: EventEmitter<{
    adminLevel: string;
    calculation: string;
    unitInterest: string;
  }> = new EventEmitter<{ adminLevel: string; calculation: string; unitInterest: string }>();


  // amenity type listenable in parent
  @Output()
  amenityAdded: EventEmitter<{
    amenity: string;
  }> = new EventEmitter<{ amenity: string }>();

  @Output()
  healthLocationAdded: EventEmitter<{
    healthLocation: string;
  }> = new EventEmitter<{ healthLocation: string }>();


  // location form stores and validates the inputs from our forms defined in the html document
  locationForm: FormGroup;
  // amenity form
  //amenityForm: FormGroup;

  // admin form
  adminForm: FormGroup;

  healthsiteForm: FormGroup;

  constructor(private fb: FormBuilder) {
    this.locationForm = fb.group({
      latitude: fb.control(21.072, [
        Validators.required,
        Validators.min(-90),
        Validators.max(90),
      ]),
      longitude: fb.control(92.29, [
        Validators.required,
        Validators.min(-180),
        Validators.max(180),
      ]),
    });
  //  this.amenityForm = fb.group({
  //    amenity: fb.control('shelter', [
  //      Validators.required,
  //    ]),
  //  });


    
    this.adminForm = fb.group({
      adminLevel: fb.control('camp', [
        Validators.required      ]),
      calculation: fb.control('n_', [
          Validators.required      ]),
      unitInterest: fb.control('tube', [
        Validators.required
      ])

    });

    this.healthsiteForm = fb.group({
      healthLocation: fb.control('none', [
        Validators.required      
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
    //this.pubsAdded.emit(true);
    console.log('hi');
    
  }

  onAdSubmit(adminLevel: { adminLevel: string; calculation: string; unitInterest: string}): void {
    if(adminLevel.unitInterest == 'population'|| adminLevel.unitInterest == 'pop_female'){
      adminLevel.calculation='n_';
      this.adminForm.controls.calculation.disable()}

    else if(adminLevel.unitInterest == 'wpro'||adminLevel.unitInterest == 'heal'||adminLevel.unitInterest == 'nutr'){
      adminLevel.calculation = 'dist_'
      this.adminForm.controls.calculation.disable(); 
    }
    else if (this.adminForm.controls.calculation._pendingValue!== 'undefined'){
      console.log(adminLevel.calculation);
      
      this.adminForm.controls.calculation.enable();
      adminLevel.calculation = this.adminForm.controls.calculation._pendingValue;
    }
    else{
      adminLevel.calculation = adminLevel.calculation;
    }
    
    
    this.adminLevelAdded.emit(adminLevel);
    
    //console.log(adminLevel);
  }

  onHtSubmit(healthLocation: { healthLocation: string}): void {
    this.healthLocationAdded.emit(healthLocation);
    console.log(healthLocation);
  }


    //console.log(adminLevel);
  }
