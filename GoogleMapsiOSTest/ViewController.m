//
//  ViewController.m
//  GoogleMapsiOSTest
//
//  Created by Alexander Stein on 11/20/18.
//  Copyright © 2018 Alexander Stein. All rights reserved.
//

#import "ViewController.h"
#import <GoogleMaps/GoogleMaps.h>
#import "ZipArchive.h"

#define CachesDirectory  [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0]

@interface TestTileLayer : GMSSyncTileLayer
@end

@implementation TestTileLayer
- (UIImage *)tileForX:(NSUInteger)x y:(NSUInteger)y zoom:(NSUInteger)zoom {
    // On every tile, render an image.
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *tilePath = [CachesDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"IndiaOSM/OSM_tiles/%lu/%lu/%lu.png",(unsigned long)zoom,(unsigned long)x,(unsigned long)y]];
    NSLog(@"Looking for %lu,%lu,%lu at location %@", (unsigned long)x, (unsigned long)y, (unsigned long)zoom, tilePath);
    
    if ([fileManager fileExistsAtPath: tilePath]) {
        NSLog(@"Image is there, fetching tile");
        NSData *imgData = [[NSData alloc] initWithContentsOfURL:[NSURL fileURLWithPath:tilePath]];
        UIImage *thumbNail = [[UIImage alloc] initWithData:imgData];
        return thumbNail;
    } else {
        NSLog(@"Image is not there");
        return kGMSTileLayerNoTile;
    }
}

@end

@implementation ViewController{
    GMSMapView *_mapView;
    NSInteger _mapSource;
    BOOL _firstLocationUpdate;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //Load Map
    GMSCameraPosition *camera = [GMSCameraPosition cameraWithLatitude:19.139417 longitude:72.868337 zoom:12];
    _mapView = [GMSMapView mapWithFrame:CGRectZero camera:camera];
    _mapView.settings.compassButton = YES;
    _mapView.settings.myLocationButton = YES;
    
    // Listen to the myLocation property of GMSMapView.
    [_mapView addObserver:self
               forKeyPath:@"myLocation"
                  options:NSKeyValueObservingOptionNew
                  context:NULL];
    self.view = _mapView;
    
    //Add offline tilemap Layer
    GMSTileLayer *layer = [[TestTileLayer alloc] init];
    layer.map = _mapView;
    
    BOOL success;
    NSError *error;
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    NSString *documentsDirectory = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"];
    NSString *filePath = [documentsDirectory stringByAppendingPathComponent:@"IndiaOSM.zip"];
    
    success = [fileManager fileExistsAtPath:filePath];
    if (!success) {
        NSString *path = [[NSBundle mainBundle] pathForResource:@"IndiaOSM" ofType:@"zip"];
        success = [fileManager copyItemAtPath:path toPath:filePath error:&error];
        [SSZipArchive unzipFileAtPath:filePath toDestination:documentsDirectory];
    }

    
    // Ask for My Location data after the map has already been added to the UI.
    dispatch_async(dispatch_get_main_queue(), ^{
        self->_mapView.myLocationEnabled = YES;
    });
    
}

- (void)mapView:(GMSMapView *)mapView didTapMyLocation:(CLLocationCoordinate2D)location {
    NSString *message = [NSString stringWithFormat:@"My Location Dot Tapped at: [lat: %f, lng: %f]",
                         location.latitude, location.longitude];
    UIAlertController *alertController =
    [UIAlertController alertControllerWithTitle:@"Location Tapped"
                                        message:message
                                 preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK"
                                                       style:UIAlertActionStyleDefault
                                                     handler:^(UIAlertAction *action){
                                                     }];
    [alertController addAction:okAction];
    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)dealloc {
    [_mapView removeObserver:self
                  forKeyPath:@"myLocation"
                     context:NULL];
}

#pragma mark - KVO updates

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {
    if (!_firstLocationUpdate) {
        // If the first location update has not yet been received, then jump to that
        // location.
        _firstLocationUpdate = YES;
        CLLocation *location = [change objectForKey:NSKeyValueChangeNewKey];
        _mapView.camera = [GMSCameraPosition cameraWithTarget:location.coordinate
                                                         zoom:14];
    }
}
@end


