#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import <CoreLocation/CLLocationManagerDelegate.h>

@interface LocatableAppDelegate : NSObject <UIApplicationDelegate, UIAlertViewDelegate, UIWebViewDelegate, CLLocationManagerDelegate, UITableViewDelegate, UITableViewDataSource> {
  UIWindow *window;
  UIWebView *webView;
  UIActivityIndicatorView *activityView;
  UIAlertView *aboutAlertView;
  UIView * subview;
  NSString * returnURL;
  NSString * jsArgs;
  CLLocationManager* locationManager;
  UISwitch *enabledSwitch;
  UINavigationController *navControl;
  UITableViewController *tableControl; // main prefs panel
  CLLocation * mostRecentLocation;

  NSArray* accuracyOptions;
  NSInteger accuracyIndex;

  NSArray* frequencyOptions;
  NSInteger frequencyIndex;

  NSArray* askOptions;
  NSInteger askIndex;

  // Persistent preferences
  BOOL enabled;
  BOOL initialized;
  NSInteger accuracy;
  NSInteger frequency;
  NSInteger ask;
}

@property (nonatomic, retain) UIWindow *window;
@property (nonatomic, retain) UIAlertView *aboutAlertView;

-(void)showAboutAlertDialog;
-(void)startLocationUpdate;
-(void)quickRefresh;
-(void)checkReady;
-(void)selectedOption:(NSInteger)option forTag:(NSInteger)tag;
-(void)stopUpdates;
@end

