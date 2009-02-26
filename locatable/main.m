#import <UIKit/UIKit.h>
#import "LocatableAppDelegate.h"

int main(int argc, char *argv[]) {
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
    int retVal = UIApplicationMain(argc, argv, nil, @"LocatableAppDelegate");
    [pool release];
    return retVal;
}
