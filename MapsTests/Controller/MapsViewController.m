//
//  MapsViewController.m
//  MapsTests
//
//  Created by Igor Monteiro on 2/26/14.
//  Copyright (c) 2014 Igor Monteiro. All rights reserved.
//

#import "MapsViewController.h"
#import "RoutesViewController.h"

#define altitude_factor 3.0f

@interface MapsViewController ()
@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property (weak, nonatomic) IBOutlet UISearchBar *searchBar;

@property (strong, nonatomic) NSString *destination;
@property (strong, nonatomic) CLGeocoder *geocoder;
@property (strong, nonatomic) CLLocation *userLocation;
@property (strong, nonatomic) CLLocationManager *manager;

@property (strong, nonatomic) NSArray *routes;

@end

@implementation MapsViewController

#define ToRadian(x) ((x) * M_PI/180)
#define ToDegrees(x) ((x) * 180/M_PI)

+ (CLLocationCoordinate2D)midpointBetweenCoordinate:(CLLocationCoordinate2D)c1 andCoordinate:(CLLocationCoordinate2D)c2
{
	c1.latitude = ToRadian(c1.latitude);
	c2.latitude = ToRadian(c2.latitude);
	CLLocationDegrees dLon = ToRadian(c2.longitude - c1.longitude);
	CLLocationDegrees bx = cos(c2.latitude) * cos(dLon);
	CLLocationDegrees by = cos(c2.latitude) * sin(dLon);
	CLLocationDegrees latitude = atan2(sin(c1.latitude) + sin(c2.latitude), sqrt((cos(c1.latitude) + bx) * (cos(c1.latitude) + bx) + by*by));
	CLLocationDegrees longitude = ToRadian(c1.longitude) + atan2(by, cos(c1.latitude) + bx);
	
	CLLocationCoordinate2D midpointCoordinate;
	midpointCoordinate.longitude = ToDegrees(longitude);
	midpointCoordinate.latitude = ToDegrees(latitude);
	
	return midpointCoordinate;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
	{
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	[self.navigationController setNavigationBarHidden:NO animated:NO];
	if([self respondsToSelector:@selector(setEdgesForExtendedLayout:)])
	{
		[self setEdgesForExtendedLayout:UIRectEdgeNone];
	}
	self.searchBar.delegate = self;
	self.mapView.delegate = self;
	
	self.title = @"Mapa";
	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Rotas"
																			  style:UIBarButtonItemStylePlain
																			 target:self
																			 action:@selector(showRoute:)];
	
	self.manager = [[CLLocationManager alloc] init];
	self.manager.delegate = self;
	self.manager.distanceFilter = kCLDistanceFilterNone;
	self.manager.desiredAccuracy = kCLLocationAccuracyBestForNavigation;
	[self.manager startUpdatingLocation];
	
}

-(void)showRoute:(id)sender
{
	RoutesViewController* controller = [[RoutesViewController alloc] init];
	[controller setRoutes:self.routes];
	[self.navigationController pushViewController:controller animated:YES];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark -
#pragma mark Tratamento do keyboard
#pragma mark -

-(void)viewWillAppear:(BOOL)animated
{
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(keyboardWillShow:)
												 name:UIKeyboardWillShowNotification
											   object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(keyboardWillHide:)
												 name:UIKeyboardWillHideNotification
											   object:nil];
}

-(void)viewWillDisappear:(BOOL)animated
{
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}

-(void)keyboardWillShow:(NSNotification*)sender
{
	NSDictionary *userInfo = [sender userInfo];
	NSTimeInterval animationDuration;
	UIViewAnimationCurve animationCurve;
	CGRect keyboardRect;
	
	[[userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] getValue:&animationCurve];
	animationDuration = [[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
	keyboardRect = [[userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
	keyboardRect = [self.view convertRect:keyboardRect fromView:nil];
	
	CGFloat keyboardTop = keyboardRect.origin.y;
	CGRect frame = self.searchBar.frame;
	frame.origin.y = keyboardTop - self.searchBar.frame.size.height;
	
	[UIView beginAnimations:@"ResizeForKeyboard" context:nil];
	[UIView setAnimationDuration:animationDuration];
	[UIView setAnimationCurve:animationCurve];
	self.searchBar.frame = frame;
	[UIView commitAnimations];
}

-(void)keyboardWillHide:(NSNotification*)sender
{
	NSDictionary *userInfo = [sender userInfo];
	NSTimeInterval animationDuration;
	UIViewAnimationCurve animationCurve;
	
	[[userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] getValue:&animationCurve];
	animationDuration = [[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
	
	CGRect frame = self.searchBar.frame;
	frame.origin.y = self.view.frame.size.height - self.searchBar.frame.size.height;
	
	[UIView beginAnimations:@"ResizeForKeyboard" context:nil];
	[UIView setAnimationDuration:animationDuration];
	[UIView setAnimationCurve:animationCurve];
	self.searchBar.frame = frame;
	[UIView commitAnimations];
}

#pragma mark -
#pragma mark Rota
#pragma mark -
-(void)showRouteFromLocation:(CLLocation*)from withName:(NSString*)name toUserLocationBy:(MKDirectionsTransportType)transType
{
	MKPlacemark* fromPlaceMark = [[MKPlacemark alloc] initWithCoordinate:from.coordinate
												   addressDictionary:[NSDictionary dictionaryWithObjectsAndKeys:@"",@"", nil]];
	MKMapItem* fromItem = [[MKMapItem alloc] initWithPlacemark:fromPlaceMark];
	[fromItem setName:name];
	
	MKPlacemark* toPlaceMark = [[MKPlacemark alloc] initWithCoordinate:self.userLocation.coordinate
													   addressDictionary:[NSDictionary dictionaryWithObjectsAndKeys:@"",@"", nil]];
	MKMapItem* toItem = [[MKMapItem alloc] initWithPlacemark:toPlaceMark];
	[toItem setName:@"User location"];
	
	MKDirectionsRequest *request = [[MKDirectionsRequest alloc] init];
	[request setSource:fromItem];
	[request setDestination:toItem];
	[request setDepartureDate:[NSDate date]];
	[request setTransportType:transType];
	
	MKDirections *directions = [[MKDirections alloc] initWithRequest:request];
	[directions calculateDirectionsWithCompletionHandler:^(MKDirectionsResponse *response, NSError *error) {
		NSLog(@"response = %@",response);
        NSArray *arrRoutes = [response routes];
		self.routes = [response routes];
		
		if(self.mapView.overlays && self.mapView.overlays.count > 0)
		{
			[self.mapView removeOverlays:self.mapView.overlays];
		}
		
        [arrRoutes enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
			
            MKRoute *route = obj;
			
            [self.mapView addOverlay:route.polyline];
			
            NSLog(@"Rout Name : %@",route.name);
            NSLog(@"Total Distance (in Meters) :%f",route.distance);
			
            NSArray *steps = [route steps];
			route = nil;
			
            NSLog(@"Total Steps : %d",[steps count]);
			
            [steps enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                NSLog(@"Rout Instruction : %@",[obj instructions]);
                NSLog(@"Rout Distance : %f",[obj distance]);
            }];
			steps = nil;
        }];
		arrRoutes = nil;
	}];
	
}

- (MKOverlayView *)mapView:(MKMapView *)mapView viewForOverlay:(id)overlay {
	
	if ([overlay isKindOfClass:[MKPolyline class]]) {
		MKPolylineView* aView = [[MKPolylineView alloc]initWithPolyline:(MKPolyline*)overlay] ;
		aView.strokeColor = [[UIColor blueColor] colorWithAlphaComponent:0.5];
		aView.lineWidth = 10;
		return aView;
	}
	return nil;
}

#pragma mark -
#pragma mark Operações de geolocalização
#pragma mark -
-(void)convertString:(NSString*)location ToLocationWithCompletion:(void(^)(NSError* error, CLLocation *location))completion
{
	if(!self.geocoder)
	{
		self.geocoder = [[CLGeocoder alloc] init];
	}
	
	[self.geocoder geocodeAddressString:location completionHandler:^(NSArray *placemarks, NSError *error) {
		if(error)
		{
			if(completion)
			{
				completion(error,nil);
			}
		}else if(placemarks.count == 0)
		{
			if(completion)
			{
				completion([NSError errorWithDomain:@"Empty response" code:0 userInfo:nil],nil);
			}
		}else
		{
			CLPlacemark* placemark = [placemarks objectAtIndex:0];
			if(placemarks && completion)
			{
				completion(nil, placemark.location);
			}
		}
	}];
}

#pragma mark -
#pragma mark Search bar delegates
#pragma mark -

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
	[searchBar resignFirstResponder];
	[self convertString:searchBar.text ToLocationWithCompletion:^(NSError *error, CLLocation *location) {
		if(error)
		{
			[[[UIAlertView alloc]
			  initWithTitle:@"Response"
			  message:error.debugDescription
			  delegate:nil
			  cancelButtonTitle:@"Ok"
			  otherButtonTitles:nil]
			 show];
		}else
		{
			if(self.mapView.annotations && self.mapView.annotations.count > 0)
				[self.mapView removeAnnotations:self.mapView.annotations];
			
			MKPointAnnotation* annotation = [[MKPointAnnotation alloc] init];
			annotation.coordinate = location.coordinate;
			annotation.title = [searchBar text];
			[self.mapView addAnnotation:annotation];
			
			CGFloat radius = [self.userLocation distanceFromLocation:location];
			
			CLLocationCoordinate2D medium = [MapsViewController midpointBetweenCoordinate:location.coordinate
																			andCoordinate:self.userLocation.coordinate];
			
			MKMapCamera* camera = [MKMapCamera
								   cameraLookingAtCenterCoordinate:medium
								   fromEyeCoordinate:medium
								   eyeAltitude:location.altitude + (radius * altitude_factor)];
			
			[self.mapView setCamera:camera animated:YES];
			[self showRouteFromLocation:location withName:searchBar.text toUserLocationBy:MKDirectionsTransportTypeAutomobile];
		}
	}];
}
- (void)searchBarCancelButtonClicked:(UISearchBar *) searchBar {
	[searchBar resignFirstResponder];
}
- (BOOL)searchBarShouldEndEditing:(UISearchBar *)searchBar {
	[self searchBarSearchButtonClicked:searchBar];
	return YES;
}

#pragma mark -
#pragma mark Location manager delegates
#pragma mark -
-(void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
	if(locations.count > 0)
	{
		id temp = [locations lastObject];
		if([temp isKindOfClass:[CLLocation class]])
		{
			self.userLocation = (CLLocation*)temp;
			[self.manager stopUpdatingLocation];
			MKMapCamera* camera = [MKMapCamera cameraLookingAtCenterCoordinate:self.userLocation.coordinate
															 fromEyeCoordinate:self.userLocation.coordinate
																   eyeAltitude:self.userLocation.altitude + (10 * altitude_factor)];
			[self.mapView setCamera:camera animated:YES];
		}
	}
}

-(void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
	[[[UIAlertView alloc]
	  initWithTitle:@"Location"
	  message:error.debugDescription
	  delegate:nil
	  cancelButtonTitle:@"Ok"
	  otherButtonTitles:nil]
	 show];
}

@end
