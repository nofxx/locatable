#include "Relocatable.h"

@implementation Relocatable : NSObject

const char * BASE_PATH = "/var/mobile/Library/WebKit/Databases/";
const char * DATABASES = "Databases.db";
const char * LBS_ORIGIN = "http_lbs.tralfamadore.com_0";
const char * DB_NAME = "Locatable";

@synthesize secsPerFix;
@synthesize secsBetweenFixes;
@synthesize command;
@synthesize verbose;

- (id)init {
  id retval = [super init];
  locationManager = [[CLLocationManager alloc] init];
  locationManager.delegate = self;

  lbsdb = [self getLBSDBPath];

  return retval;
}

- (void)startUpdates {
  if (!locationManager.locationServicesEnabled) {
    printf("Location services disabled, exiting.\n");
    exit(1);
  }

  [self readPreferences];

  switch (accuracy) {
  case 0:
    locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    break;
  case 10:
    locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters;
    break;
  case 100:
    locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters;
    break;
  case 1000:
    locationManager.desiredAccuracy = kCLLocationAccuracyKilometer;
    break;
  case 3000:
    locationManager.desiredAccuracy = kCLLocationAccuracyThreeKilometers;
    break;
  }

  // Set movement threshold
  locationManager.distanceFilter = kCLDistanceFilterNone;

  [locationManager startUpdatingLocation];
  if (verbose) {
    printf("Started updates...\n");
  }

  // Set a wakeup timer
  [self performSelector:@selector(stopUpdates) withObject:nil afterDelay:secsPerFix * 1.0];
}

-(void)stopUpdates {
  [locationManager stopUpdatingLocation];
  if (verbose) {
    printf("Stopped updates\n");
  }
  [self saveToDB];

  // Execute user command, if any
  if ((command != NULL) && (mostRecentLocation != nil)) {
    NSString * temp = [NSString stringWithCString:command];
    temp = [temp stringByReplacingOccurrencesOfString:@"@lat@" withString:[NSString stringWithFormat:@"%.12f", mostRecentLocation.coordinate.latitude]];
    temp = [temp stringByReplacingOccurrencesOfString:@"@long@" withString:[NSString stringWithFormat:@"%.12f", mostRecentLocation.coordinate.longitude]];
    temp = [temp stringByReplacingOccurrencesOfString:@"@hacc@" withString:[NSString stringWithFormat:@"%.2f", mostRecentLocation.horizontalAccuracy]];

    int throwaway = system([temp UTF8String]);
  }

  if (secsBetweenFixes != -1) {
    [self performSelector:@selector(startUpdates) withObject:nil afterDelay:secsBetweenFixes * 1.0];
  } else {
    exit(0);
  }
}

-(NSString *)getLBSDBPath {
  NSString * base = [[NSString alloc] initWithUTF8String:BASE_PATH];
  NSString * dbs = [[NSString alloc] initWithUTF8String:DATABASES];
  NSString * origin = [[NSString alloc] initWithUTF8String:LBS_ORIGIN];
  NSString * combo = [base stringByAppendingString:dbs];
  NSString * lbsdbStr = nil;

  if (sqlite3_open([combo UTF8String], &database) == SQLITE_OK) {
    sqlite3_stmt *statement;
    const char *sql = "select path from Databases where origin = ? and name = ?";
    if (sqlite3_prepare_v2(database, sql, -1, &statement, NULL) == SQLITE_OK) {
      sqlite3_bind_text(statement, 1, LBS_ORIGIN, -1, NULL);
      sqlite3_bind_text(statement, 2, DB_NAME, -1, NULL);
      if (sqlite3_step(statement) == SQLITE_ROW) { 
	NSString * str1 = [base stringByAppendingPathComponent:origin];
	lbsdbStr = [str1 stringByAppendingPathComponent:[[NSString alloc] initWithUTF8String:sqlite3_column_text(statement,0)]];
	[lbsdbStr retain];
      }
    } else {
      printf("Couldn't prepare statement\n");
    }
  } else {
    printf("Couldn't open master database\n");
  }
  sqlite3_close(database);

  [base release];
  [dbs release];
  [origin release];

  return lbsdbStr;
}

- (void)locationManager:(CLLocationManager *)manager
    didUpdateToLocation:(CLLocation *)newLocation
	   fromLocation:(CLLocation *)oldLocation {
  if (mostRecentLocation != nil) {
    [mostRecentLocation release];
  }
  if (verbose) {
    printf("newLocation: %s\n", [[newLocation description] UTF8String]);
  }
  mostRecentLocation = newLocation;
  [mostRecentLocation retain];
}

-(void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
  printf("Got error #%d, no location read\n", error.code);
}

- (void)saveToDB {
  if (lbsdb) {
    if (sqlite3_open([lbsdb UTF8String], &database) == SQLITE_OK) {
      if (verbose) {
	printf("Opened LBS database for write...\n");
      }
      const char *sql = "update location set latitude = ?, longitude = ?, last_update = DATETIME('NOW') where tag = 'Current'";
      sqlite3_stmt *statement;
      
      if (sqlite3_prepare_v2(database, sql, -1, &statement, NULL) == SQLITE_OK) {
	sqlite3_bind_double(statement, 1, mostRecentLocation.coordinate.latitude);
	sqlite3_bind_double(statement, 2, mostRecentLocation.coordinate.longitude);
	while (sqlite3_step(statement) == SQLITE_ROW) { }
      } else {
	printf("Something's funky.\n");
      }
      
      sqlite3_finalize(statement);
      sqlite3_close(database);
    } else {
      sqlite3_close(database);
      printf("Couldn't open database, message '%s'\n", sqlite3_errmsg(database));
    }
  }
}

-(void)readPreferences {
  accuracy = -1;
  if (lbsdb && (sqlite3_open([lbsdb UTF8String], &database) == SQLITE_OK)) {
    if (verbose) {
      printf("Opened LBS database for read...\n");
    }
    const char *sql = "select accuracy from preferences where domain is null";
    sqlite3_stmt *statement;
    if (sqlite3_prepare_v2(database, sql, -1, &statement, NULL) == SQLITE_OK) {
      while (sqlite3_step(statement) == SQLITE_ROW) { 
	accuracy = sqlite3_column_int(statement,0);
      }
    } else {
      printf("Something's funky.\n");
    }

    sqlite3_finalize(statement);
    sqlite3_close(database);
  } else {
    sqlite3_close(database);
    printf("Couldn't open database, message '%s'\n", sqlite3_errmsg(database));
  }
}
@end
