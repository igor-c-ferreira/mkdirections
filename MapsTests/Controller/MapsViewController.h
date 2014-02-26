//
//  MapsViewController.h
//  MapsTests
//
//  Created by Igor Monteiro on 2/26/14.
//  Copyright (c) 2014 Igor Monteiro. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import <CoreLocation/CoreLocation.h>

@interface MapsViewController : UIViewController <UISearchBarDelegate, MKMapViewDelegate, CLLocationManagerDelegate>

@end
