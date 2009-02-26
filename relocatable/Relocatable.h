#import <CoreLocation/CoreLocation.h>
#import <CoreLocation/CLLocationManagerDelegate.h>
#import <sqlite3.h>
@interface Relocatable : NSObject <CLLocationManagerDelegate> {
  CLLocationManager* locationManager;	
  sqlite3 *database;
  NSString * lbsdb;

  int accuracy;
  int secsPerFix;
  int secsBetweenFixes;
  char * command;
  BOOL verbose;

  CLLocation * mostRecentLocation;
}
@property int secsPerFix;
@property int secsBetweenFixes;
@property char* command;
@property BOOL verbose;
- (void)startUpdates;
- (void)readPreferences;
- (NSString*)getLBSDBPath;
- (void)stopUpdates;
- (void)saveToDB;
- (void)locationManager:(CLLocationManager *)manager
    didUpdateToLocation:(CLLocation *)newLocation
    fromLocation:(CLLocation *)oldLocation;
-(void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error;

@end

