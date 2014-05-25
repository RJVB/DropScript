/**
 * Causes the Services menu to update without having to log out and log in.
 * Doesn't affect running applications; requires app re-launch.
 **/

#include <stdlib.h>

#import <Foundation/NSAutoreleasePool.h>
#import <AppKit/NSApplication.h>

int main()
{
  NSAutoreleasePool* aPool = [[NSAutoreleasePool alloc] init];

  NSUpdateDynamicServices();

  [aPool release];

  exit(0);
}
