#import "OptionViewController.h"

@implementation OptionViewController

- (id) initWithOwner:(LocatableAppDelegate *) anOwner options:(NSArray *) anOptions selected:(NSInteger) aSelected {
  id retval = [super initWithStyle:UITableViewStyleGrouped];
  owner = anOwner;
  options = anOptions;
  selected = aSelected;
  return retval;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
  return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  return [options count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  static NSString *MyIdentifier = @"OptionViewController";
	
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:MyIdentifier];
  if (cell == nil) {
    cell = [[[UITableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:MyIdentifier] autorelease];
  } else {
    // Clear checkmark
    cell.accessoryType = UITableViewCellAccessoryNone;
  }

  cell.text = [options objectAtIndex:indexPath.row];
  if (indexPath.row == selected) {
    cell.accessoryType = UITableViewCellAccessoryCheckmark;
  }

  return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  selected = indexPath.row;
  [tableView reloadData];
  [owner selectedOption:indexPath.row forTag:tableView.tag];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return @"";
}

@end
