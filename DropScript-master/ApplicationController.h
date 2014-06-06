/**
 *  ApplicationController.h
 *  DropScript
 *
 *  Created by Wilfredo S‡nchez on Sun May 02 2004.
 *  Copyright (c) 2004 Wilfredo S‡nchez Vega. All rights reserved.
 **/

#import <Foundation/NSObject.h>
#import <AppKit/NSNibDeclarations.h>

@class NSString;
@class NSArray;
@class NSMutableArray;

@interface ApplicationController : NSObject

/* Instance variables */
{
@private
    BOOL            myAppIsLaunching;
    BOOL            myAppWasLaunchedWithDocument;
    BOOL            creatingDropScript;
    NSString*       myScriptFilename;
    NSMutableArray* myFilesToBatch;
}

/**
 * Actions
 **/

- (BOOL) createDropScript;
- (NSTask*) runScriptWithArguments: (NSArray*) theArguments;

/**
 * IB Targets
 **/

- (IBAction) doNew: (id) aSender;

- (IBAction) doOpen: (id) aSender;

- (void)handleURIEvent:(NSAppleEventDescriptor *)event withReplyEvent:(NSAppleEventDescriptor *)replyEvent;


@end
