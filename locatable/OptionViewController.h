#import <UIKit/UIKit.h>
#import "LocatableAppDelegate.h"

@interface OptionViewController : UITableViewController <UITableViewDelegate, UITableViewDataSource> {
  NSArray *options;
  LocatableAppDelegate *owner;
  NSInteger selected;
}

-(id)initWithOwner:(LocatableAppDelegate*)owner options:(NSArray*)options selected:(NSInteger)selected;

@end
