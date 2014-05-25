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

- (void) runScriptWithArguments: (NSArray*) anArguments;

/**
 * IB Targets
 **/

- (IBAction) open: (id) aSender;

- (void)handleURIEvent:(NSAppleEventDescriptor *)event withReplyEvent:(NSAppleEventDescriptor *)replyEvent;


@end
