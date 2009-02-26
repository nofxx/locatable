#include "Relocatable.h"
#include <UIKit/UIKit.h>

void usage() {
  printf("Usage: Relocatable [-v] [-t SECONDS] [-d SECONDS] [-e CMD]\n");
  printf("  -d SECONDS      run as a daemon, delay specified seconds between fixes\n");
  printf("  -e CMD          execute given program (with args) after each location fix,\n");
  printf("                    can include @lat@, @long@, and @hacc@ tokens\n");
  printf("  -t SECONDS      spend specified seconds waiting for a fix, default 30\n");
  printf("  -v              turn on verbose logging\n");
  exit(1);
}

int main(int argc, char *argv[]) {
  NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
  
  int ch, secsPerFix = 30, secsBetweenFixes = -1;
  BOOL verbose = NO;
  char* command = (char*)0;

  while ((ch = getopt(argc, argv, "t:d:e:hv")) != -1) {
    switch (ch) {
    case 't':
      secsPerFix = atoi(optarg);
      break;
    case 'd':
      secsBetweenFixes = atoi(optarg);
      break;
    case 'e':
      command = optarg;
      break;
    case 'v':
      verbose = YES;
      break;
    case 'h':
    case '?':
    default:
      usage();
    }
  }
  
  Relocatable * r = [[Relocatable alloc] init];
  r.secsPerFix = secsPerFix;
  r.secsBetweenFixes = secsBetweenFixes;
  r.command = command;
  r.verbose = verbose;
  [r startUpdates];
  
  int retVal = UIApplicationMain(argc, argv, nil, nil);
  [pool release];
  return retVal;
}

