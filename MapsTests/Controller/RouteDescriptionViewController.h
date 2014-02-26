//
//  RouteDescriptionViewController.h
//  MapsTests
//
//  Created by Igor Monteiro on 2/26/14.
//  Copyright (c) 2014 Igor Monteiro. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>

@interface RouteDescriptionViewController : UITableViewController

@property (strong, nonatomic) MKRoute *route;

@end
