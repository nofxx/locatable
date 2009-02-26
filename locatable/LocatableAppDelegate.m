#import "LocatableAppDelegate.h"
#import "OptionViewController.h"

@implementation LocatableAppDelegate

@synthesize window;
@synthesize aboutAlertView;

const NSInteger kTagTableView_Prefs = 1;
const NSInteger kTagTableView_Accuracy = 2;
const NSInteger kTagTableView_Frequency = 3;
const NSInteger kTagTableView_Ask = 4;
const NSInteger kTagTableViewCell_Choice = 5;

const int accuracyLevel[] = { 0, 10, 100, 1000, 3000 };
const int frequencyLevel[] = { 0, 300, 600, 1800, 3600, 86400 };
const int askLevel[] = { 1, -1, -2, 0 };

const NSString * kDefaultsInitialized = @"initialized";
const NSString * kDefaultsEnabled = @"enabled";
const NSString * kDefaultsAccuracy = @"accuracy";
const NSString * kDefaultsFrequency = @"frequency";
const NSString * kDefaultsAsk = @"ask";

const NSString * kURLSchemeLocatable = @"locatable://";
const NSString * kURLSchemeHTTP = @"http://";
const NSString * kLocatableDomain = @"lbs.tralfamadore.com";
const NSString * kVersionNumber = @"0.4-pre";

const NSInteger secsPerFix = 20; // Maximum time to wait for GPS

- (void)dealloc {
  [window release];
  [super dealloc];
}

- (void)applicationWillTerminate:(UIApplication *)application
{
  NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
  [defaults setBool:initialized forKey:(NSString*)kDefaultsInitialized];
  [defaults setBool:enabled forKey:(NSString*)kDefaultsEnabled];
  [defaults setInteger:accuracy forKey:(NSString*)kDefaultsAccuracy];
  [defaults setInteger:frequency forKey:(NSString*)kDefaultsFrequency];
  [defaults setInteger:ask forKey:(NSString*)kDefaultsAsk];
}

- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url
{   
  if (!url) {
    // The URL is nil. There's nothing more to do.
    return NO;
  }
    
  NSString *URLString = [url absoluteString];
  NSString *tmp = [NSString stringWithString:[URLString substringFromIndex:kURLSchemeLocatable.length]];
  [tmp retain];
  returnURL = [kURLSchemeHTTP stringByAppendingString:tmp];
  [returnURL retain];

  return YES;
}

- (void)applicationDidFinishLaunching:(UIApplication *)application {
  window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
  [window makeKeyAndVisible];
  window.backgroundColor = [UIColor blackColor];
  
  // Give the URL handler a chance to run
  [self performSelector:@selector(startup) withObject:nil afterDelay:0.0];
}

- (void)invokeJavascript:(NSString *) args {
  jsArgs = args;
  [jsArgs retain];
  // TODO: Can I do this once and still have it work rather than reload each time?
  if (webView == nil) {
    // The UIWebView is meant to be invisible, but must be at least 1x1 to work
    webView = [[UIWebView alloc] initWithFrame:CGRectMake(0.0, 0.0, 1.0, 1.0)];
    [webView retain];
    webView.delegate = self;

    NSString* filePath = [[NSBundle mainBundle] pathForResource:@"functions" ofType:@"html"];
    NSData *myData = [NSData dataWithContentsOfFile:filePath];
    if (myData) {
      [webView loadData:myData MIMEType:@"text/html" textEncodingName:@"UTF-8" baseURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@%@/", kURLSchemeHTTP, kLocatableDomain]]];
    } else {
      NSLog(@"Can't find functions.html\n");
    }
    [window addSubview:webView];
  } else {
    [self checkReady];
  }
}

- (void)enabledStatusChanged {
  enabled = enabledSwitch.on;
  [self invokeJavascript:[NSString stringWithFormat:@"setDefaultPreferences(%d,%d,%d,%d)", enabled ? 1 : 0, accuracy, frequency, ask]];
}

- (void)startup {
  accuracyOptions = [NSArray arrayWithObjects:@"Best", @"10 m", @"100 m", @"1 km", @"3 km", nil];
  [accuracyOptions retain];
  frequencyOptions = [NSArray arrayWithObjects:@"Each request", @"5 min", @"10 min", @"30 min", @"One hour", @"One day", nil];
  [frequencyOptions retain];
  askOptions = [NSArray arrayWithObjects:@"Always", @"Once per site", @"Twice per site", @"Never", nil];
  [askOptions retain];

  NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
  initialized = [defaults boolForKey:(NSString*)kDefaultsInitialized];
  if (!initialized) {
    // First time run defaults
    enabled = YES;
    accuracy = 1000;
    frequency = 600;
    ask = 1;
  } else {
    enabled = [defaults boolForKey:(NSString*)kDefaultsEnabled];
    if ([defaults objectForKey:(NSString*)kDefaultsAccuracy]) {
      accuracy = [defaults integerForKey:(NSString*)kDefaultsAccuracy];
    } else {
      accuracy = 1000;
    }
    if ([defaults objectForKey:(NSString*)kDefaultsFrequency]) {
      frequency = [defaults integerForKey:(NSString*)kDefaultsFrequency];
    } else {
      frequency = 600;
    }
    if ([defaults objectForKey:(NSString*)kDefaultsAsk]) {
      ask = [defaults integerForKey:(NSString*)kDefaultsAsk];
    } else {
      ask = 1;
    }
  }
  
  // Set indices
  for (int i = 0; i < [accuracyOptions count]; i++) {
    if (accuracy == accuracyLevel[i]) {
      accuracyIndex = i;
      break;
    }
  }
  for (int i = 0; i < [frequencyOptions count]; i++) {
    if (frequency == frequencyLevel[i]) {
      frequencyIndex = i;
      break;
    }
  }
  for (int i = 0; i < [askOptions count]; i++) {
    if (ask == askLevel[i]) {
      askIndex = i;
      break;
    }
  }
  
  if (returnURL != nil) {
    [self quickRefresh];
  } else {
    tableControl = [[UITableViewController alloc] initWithStyle:UITableViewStyleGrouped];
    tableControl.title = @"Locatable";
    tableControl.tableView.tag = kTagTableView_Prefs;
    tableControl.tableView.delegate = self;
    tableControl.tableView.dataSource = self;

    enabledSwitch = [[UISwitch alloc] initWithFrame:CGRectMake(200.0,7.0,0,0)];
    [enabledSwitch addTarget:self action:@selector(enabledStatusChanged) forControlEvents:UIControlEventValueChanged];

    if (!initialized) {
      [self invokeJavascript:[NSString stringWithFormat:@"setDefaultPreferences(%d,%d,%d,%d)", enabled ? 1 : 0, accuracy, frequency, ask]];
    }

    enabledSwitch.on = enabled;
    
    UIBarButtonItem * aboutButton = [[UIBarButtonItem alloc] initWithTitle:@"About" style:UIBarButtonItemStylePlain target:self action:@selector(showAboutAlertDialog)];
    [tableControl.navigationItem setRightBarButtonItem:aboutButton animated:NO];

    navControl = [[UINavigationController alloc] initWithRootViewController:tableControl];
    [window addSubview:navControl.view];
  }
}

//////////////////////////////////////////////////////////////////////////

// App started from Safari -- update location and return
- (void)quickRefresh {
  subview = [[UIView alloc] initWithFrame:window.bounds];
  [window addSubview:subview];
  activityView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
  activityView.center = subview.center;
  [activityView startAnimating];
  [subview addSubview:activityView];
  
  UILabel * label = [[UILabel alloc] init];
  label.backgroundColor = [UIColor blackColor];
  label.textColor = [UIColor whiteColor];
  label.textAlignment = UITextAlignmentCenter;
  label.text = @"Updating Location...";
  [label sizeToFit];
  label.center = CGPointMake(subview.center.x, subview.center.y + activityView.bounds.size.height);
  [subview addSubview:label];

  [self startLocationUpdate];
}

// Called when the web view (for the set page) finishes loading
- (void)webViewDidFinishLoad:(UIWebView *)view {
  if (view == webView) {
    [self checkReady];
  }
}

// Poll the page every half second for completion (because we can't invoke app methods from Javascript)
- (void) checkReady {
  NSString * result;
  if (![result = [webView stringByEvaluatingJavaScriptFromString:@"isReady()"] isEqualToString:@"YES"]) {
    [self performSelector:@selector(checkReady) withObject:nil afterDelay:0.5];
  } else {
    // We're done loading.  Now call javascript and go again
    if (jsArgs != nil) {
      result = [webView stringByEvaluatingJavaScriptFromString:jsArgs];
      // Note: result is void
      [jsArgs release];
      jsArgs = nil;
      [self performSelector:@selector(checkReady) withObject:nil afterDelay:0.5];
    } else {
      // We're fully done, so kill off the webView that was doing the action if it's the quickRefresh case.
      if (activityView != nil) {
	[webView removeFromSuperview];
	[activityView stopAnimating];
	subview.hidden = YES;
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@%@/close.html", kURLSchemeHTTP, kLocatableDomain]]];	
      } else {
	// We've done a successful set.html (first time run, etc.)
	initialized = YES;
      }
    }
  }
}


//////////////////////////////////////////////////////////////////////////

- (void)startLocationUpdate {
    // Create the location manager if this object does not
    // already have one.
    if (nil == locationManager)
        locationManager = [[CLLocationManager alloc] init];

    if (!locationManager.locationServicesEnabled) {
      [self stopUpdates];
      return;
    }

    locationManager.delegate = self;

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

    // Set a movement threshold for new events
    locationManager.distanceFilter = kCLDistanceFilterNone;

    [locationManager startUpdatingLocation];

    // Set a wakeup timer
    [self performSelector:@selector(stopUpdates) withObject:nil afterDelay:secsPerFix * 1.0];
}

// Delegate method from the CLLocationManagerDelegate protocol.
- (void)locationManager:(CLLocationManager *)manager
    didUpdateToLocation:(CLLocation *)newLocation
	   fromLocation:(CLLocation *)oldLocation {
  if (mostRecentLocation != nil) {
    [mostRecentLocation release];
  }
  mostRecentLocation = newLocation;
  [mostRecentLocation retain];

  // Check if this one is recent enough
  NSDate* eventDate = newLocation.timestamp;
  NSTimeInterval howRecent = [eventDate timeIntervalSinceNow];

  if (abs(howRecent) < 5.0) {
    // If it's accurate enough, we're done
    if (mostRecentLocation.horizontalAccuracy < accuracy*1.0) {
      [self stopUpdates];
    }
  }
}

-(void)stopUpdates {
  if (locationManager == nil) { return; }
  [locationManager stopUpdatingLocation];
  locationManager = nil;

  if (mostRecentLocation != nil) {
    // Call set page.
    [self invokeJavascript:[NSString stringWithFormat:@"setPosition(%f,%f)", mostRecentLocation.coordinate.latitude, mostRecentLocation.coordinate.longitude]];
    // The webview didFinishLoad event will be called when it's done loading
    [mostRecentLocation release];
  } else {
    // No location read -- just exit (this needs some better UX)
    if (activityView != nil) {
      [activityView stopAnimating];
      subview.hidden = YES;
      [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@%@/close.html", kURLSchemeHTTP, kLocatableDomain]]];	
    }
  }
}

-(void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
  NSLog(@"Got error #%d, no location to update\n", error.code);
}

//////////////////////////////////////////////////////////////////////////
// "About" popup
- (void)showAboutAlertDialog
{
  NSString *message = [NSString stringWithFormat:@"Version %@\nCopyright (C) 2008 Wes Biggs\n%@%@\ninfo@tralfamadore.com", kVersionNumber, kURLSchemeHTTP, kLocatableDomain];
  aboutAlertView = [[UIAlertView alloc] initWithTitle:@"Locatable" message:message delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
  [aboutAlertView show];
}

- (void)dismissAboutAlert
{
  [self.aboutAlertView dismissWithClickedButtonIndex:-1 animated:YES];
}

- (void)modalViewCancel:(UIAlertView *)alertView
{
  [alertView release];
}

- (void)modalView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
  if (buttonIndex != -1) {
      // user action closed the alert
  }
  [alertView release];
}
//////////////////////////////////////////////////////////////////////////

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
  if (tableView.tag == kTagTableView_Prefs) {
    return 2;
  }
  return 0;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  if (tableView.tag == kTagTableView_Prefs) {
    switch (section) {
    case 0:
      return 4;
    case 1:
      return 2;
    }
  }
  return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  static NSString *MyIdentifier = @"MyIdentifier";
	
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:MyIdentifier];
  if (cell == nil) {
    cell = [[[UITableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:MyIdentifier] autorelease];
  } else {
    UIView *oldlabel = [cell.contentView viewWithTag:kTagTableViewCell_Choice];
    if (oldlabel != nil) {
      [oldlabel removeFromSuperview];
    }
  }

  if (tableView.tag == kTagTableView_Prefs) {
    // Set up the cell
    CGRect contentRect = CGRectMake(170.0, 0.0, 100, 40);
    UILabel * label;
    
    switch (indexPath.section) {
    case 0:
      switch (indexPath.row) {
      case 0:
	cell.text = [[NSString alloc] initWithCString:"Location Sharing"];
	cell.selectionStyle = UITableViewCellSelectionStyleNone;
	[cell.contentView addSubview:enabledSwitch];
	break;
      case 1:
	cell.text = [[NSString alloc] initWithCString:"Accurate to"];
	label = [[UILabel alloc] initWithFrame:contentRect];
	label.textAlignment = UITextAlignmentRight;
	label.tag = kTagTableViewCell_Choice;
	label.text = [accuracyOptions objectAtIndex:accuracyIndex];
	label.textColor = [UIColor colorWithRed:0.32 green:0.40 blue:0.55 alpha:1.0];
	[cell.contentView addSubview:label];
	cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	break;
      case 2:
	cell.text = [[NSString alloc] initWithCString:"Expire after"];
	label = [[UILabel alloc] initWithFrame:contentRect];
	label.textAlignment = UITextAlignmentRight;
	label.tag = kTagTableViewCell_Choice;
	label.text = [frequencyOptions objectAtIndex:frequencyIndex];
	label.textColor = [UIColor colorWithRed:0.32 green:0.40 blue:0.55 alpha:1.0];
	[cell.contentView addSubview:label];
	cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	break;
      case 3:
	cell.text = [[NSString alloc] initWithCString:"Ask permission"];
	label = [[UILabel alloc] initWithFrame:contentRect];
	label.textAlignment = UITextAlignmentRight;
	label.tag = kTagTableViewCell_Choice;
	label.text = [askOptions objectAtIndex:askIndex];
	label.textColor = [UIColor colorWithRed:0.32 green:0.40 blue:0.55 alpha:1.0];
	[cell.contentView addSubview:label];
	cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	break;
      }
      break;
    case 1:
      switch (indexPath.row) {
      case 0:
	cell.text = [[NSString alloc] initWithCString:"Featured Sites"];
	cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	break;
      case 1:
	cell.text = [[NSString alloc] initWithCString:"Learn More"];
	cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	break;
	/*
	  case 1:
	  cell.text = [[NSString alloc] initWithCString:"Locations"];
	  cell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
	  break;
	*/
      }					
      break;
    }
  }
  return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  OptionViewController * optionControl = nil;
  if (tableView.tag == kTagTableView_Prefs) {
    // Navigation logic
    switch (indexPath.section) {
    case 0:
      switch (indexPath.row) {
      case 1: // Accurate to
	optionControl = [[OptionViewController alloc] initWithOwner:self options:accuracyOptions selected:accuracyIndex];
	optionControl.title = @"Accuracy";
	optionControl.tableView.tag = kTagTableView_Accuracy;
	[navControl pushViewController:optionControl animated:YES];
	break;
      case 2: // Frequency
	optionControl = [[OptionViewController alloc] initWithOwner:self options:frequencyOptions selected:frequencyIndex];
	optionControl.title = @"Expire after";
	optionControl.tableView.tag = kTagTableView_Frequency;
	[navControl pushViewController:optionControl animated:YES];
	break;
      case 3: // Site policy
	optionControl = [[OptionViewController alloc] initWithOwner:self options:askOptions selected:askIndex];
	optionControl.title = @"Ask permission";
	optionControl.tableView.tag = kTagTableView_Ask;
	[navControl pushViewController:optionControl animated:YES];
	break;
      }
      break;
    case 1:
      switch (indexPath.row) {
      case 0: // Featured Sites
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://lbs.tralfamadore.com/featured.html"]];	
	break;
      case 1: // Learn More
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://lbs.tralfamadore.com/"]];	
	break;
      }
    }
  }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
  if (tableView.tag == kTagTableView_Prefs) {
    switch (section) {
    case 0:
      return @"Defaults";
    case 1:
      return @"Links";
    }
  }
  return @"";
}

//////////////////////////////////////////////////

- (void)selectedOption:(NSInteger) option forTag:(NSInteger) tag {
  if (tag == kTagTableView_Accuracy) {
    accuracyIndex = option;
    accuracy = accuracyLevel[option];
  } else if (tag == kTagTableView_Frequency) {
    frequencyIndex = option;
    frequency = frequencyLevel[option];
  } else if (tag == kTagTableView_Ask) {
    askIndex = option;
    ask = askLevel[option];
  }
  [self invokeJavascript:[NSString stringWithFormat:@"setDefaultPreferences(%d,%d,%d,%d)", enabled ? 1 : 0, accuracy, frequency, ask]];
  [navControl popToRootViewControllerAnimated: YES];
  [tableControl.tableView reloadData];
}
@end
