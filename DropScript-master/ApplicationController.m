/**
 *  ApplicationController.m
 *  DropScript
 *
 *  Created by Wilfredo Sánchez on Sun May 02 2004.
 *  Copyright (c) 2004 Wilfredo Sánchez Vega. All rights reserved.
 *  Extended by René J.V. Bertin, (C) Tue May 20nd 2014
 **/

#import <Cocoa/Cocoa.h>

#import "ApplicationController.h"

@implementation ApplicationController

/**
 * Inits
 **/

- (id) init
{
    if ((self = [super init]))
    {
        myAppIsLaunching             = YES;
        myAppWasLaunchedWithDocument = NO;
        myScriptFilename             = [[[NSBundle mainBundle] pathForResource:@"drop_script" ofType:nil] retain];

        if( !myScriptFilename ){
            if( (myScriptFilename = [[[NSBundle mainBundle] pathForResource:@"drop_script.py" ofType:nil] retain]) ){
                creatingDropScript = YES;
            }
            else{
                NSRunAlertPanel(@"Error", @"Missing script.", @"Bummer", nil, nil);
                [NSApp terminate: self];
            }
        }
        else{
            creatingDropScript = NO;
        }

        // Provide application services
        // From http://stackoverflow.com/questions/49510/how-do-you-set-your-cocoa-application-as-the-default-web-browser
        [NSApp setServicesProvider: self];
        NSAppleEventManager *em = [NSAppleEventManager sharedAppleEventManager];
        [em
         setEventHandler:self
         andSelector:@selector(handleURIEvent:withReplyEvent:)
         forEventClass:kInternetEventClass
         andEventID:kAEGetURL];
    }
    return self;
}

- (void) dealloc
{
    [myScriptFilename release];

    [super dealloc];
}

/**
 * Actions
 **/

- (void) runScriptWithArguments: (NSArray*) anArguments
{
    if( anArguments == nil ){
        // RJVB 20140520
        NSTask *aTask = [[NSTask alloc] init];
        [aTask setLaunchPath:myScriptFilename];
        [aTask launch];
    }
    else{
        [NSTask launchedTaskWithLaunchPath: myScriptFilename
                                 arguments: anArguments];
    }
}

- (void) runScriptWithArguments: (NSArray*) anArguments wait:(BOOL)wait
{
    if( anArguments == nil ){
        // RJVB 20140520
        NSTask *aTask = [[NSTask alloc] init];
        [aTask setLaunchPath:myScriptFilename];
        [aTask launch];
        if( wait ){
            [aTask waitUntilExit];
        }
    }
    else{
        if( wait ){
            [[NSTask launchedTaskWithLaunchPath: myScriptFilename
                                     arguments: anArguments] waitUntilExit];
        }
        else{
            [NSTask launchedTaskWithLaunchPath: myScriptFilename
                                     arguments: anArguments];
        }
    }
}

/**
 * IB Targets
 **/

- (IBAction) open: (id) aSender
{
    NSOpenPanel* anOpenPanel = [NSOpenPanel openPanel];

    [anOpenPanel setCanChooseFiles         : YES];
    [anOpenPanel setCanChooseDirectories   : YES];
    [anOpenPanel setAllowsMultipleSelection: YES];

    if ([anOpenPanel runModal] == NSOKButton)
    {
        [self runScriptWithArguments: [anOpenPanel URLs]];
    }
}

/**
 * Application delegate
 **/

- (BOOL) application: (NSApplication*) anApplication
            openFile: (NSString*     ) aFileName
{
    if (myAppIsLaunching) myAppWasLaunchedWithDocument = YES;

    if (myFilesToBatch == nil)
    {
        myFilesToBatch = [[NSMutableArray alloc] init];
        [self performSelector: @selector(_delayedOpenFile:) withObject: nil afterDelay: 0];
    }

    [myFilesToBatch addObject: aFileName];

    return YES;
}

- (void) _delayedOpenFile: (id) anObject
{
    [self runScriptWithArguments: myFilesToBatch];
    [myFilesToBatch release];
    myFilesToBatch = nil;

    if (myAppWasLaunchedWithDocument) [NSApp terminate: self];
}

// RJVB 20140520
- (BOOL) createDropScript
{ NSSavePanel *panel = [NSSavePanel savePanel];
    [panel setMessage:@"Select a name and location for a new script file\nNB: this is a temporary file!\n(Select replace to choose an existing file)"];
    [panel setTitle:@"new file"];
    [panel setDirectoryURL:[NSURL fileURLWithPath:@"/tmp" isDirectory:YES]];
    if( [panel runModal] == NSFileHandlingPanelOKButton ){
        NSString *thePath = [[panel URL] path];
        NSError *err = nil;
        NSLog( @"Selected file: %@", thePath );
        if( ![[panel URL] checkResourceIsReachableAndReturnError:&err] ){
            FILE *fp = fopen( [thePath fileSystemRepresentation], "w" );
            if( fp ){
                fprintf( fp, "#!/bin/sh\n" );
                fprintf( fp, "#Edit this script; any files dropped on the droplet will be passed\n"
                        "# as regular shell arguments ($1, $2, etc)\n" );
                fprintf( fp, "\n\nexit 0\n" );
                fclose(fp);
            }
            else{
                return NO;
            }
        }
        { NSString *command = [NSString stringWithFormat:@"open -tW \"%@\" ; chmod 755 \"%@\"", thePath, thePath];
            system( [command fileSystemRepresentation] );
        }
        [err autorelease]; err = nil;
        if( [[NSURL fileURLWithPath:thePath] checkResourceIsReachableAndReturnError:&err] ){
            [self runScriptWithArguments:[NSArray arrayWithObject:thePath] wait:YES];
            unlink([thePath fileSystemRepresentation]);
            return YES;
        }
        else{
            NSLog( @"File %@ is unreachable: %@", thePath, err );
        }
    }
    return NO;
}

- (void) editScriptFile
{ NSString *command = [NSString stringWithFormat:@"open -tW \"%@\"", myScriptFilename];
  NSError *err = nil;
    system( [command fileSystemRepresentation] );
    if( ![[NSURL fileURLWithPath:myScriptFilename] checkResourceIsReachableAndReturnError:&err] ){
        NSLog( @"Warning: droplet file %@ has become unreachable: %@", myScriptFilename, err );
    }
}

- (void) applicationDidFinishLaunching: (NSNotification*) aNotification
{
    myAppIsLaunching = NO;
    if( myScriptFilename && !myAppWasLaunchedWithDocument ){
        // RJVB 20140520
        if( creatingDropScript ){
            [self createDropScript];
        }
        else{
          NSUInteger mods = [NSEvent modifierFlags];
            if( (mods & NSCommandKeyMask) ){
                [self editScriptFile];
            }
            else{
                [self runScriptWithArguments:nil];
            }
        }
        [NSApp terminate: self];
    }
}

/**
 * Services
 **/

- (void) dropService: (NSPasteboard*) aPasteBoard
            userData: (NSString*    ) aUserData
               error: (NSString**   ) anError
{
    NSArray* aTypes = [aPasteBoard types];

    id aData = nil;

    if ([aTypes containsObject: NSFilenamesPboardType] &&
        (aData = [aPasteBoard propertyListForType: NSFilenamesPboardType]))
    {
        [self runScriptWithArguments: aData];
    }
    else
    {
        *anError = @"Unknown data type in pasteboard.";
        NSLog(@"Service invoked with no valid pasteboard data.");
    }
}

- (void)handleURIEvent:(NSAppleEventDescriptor *)event
        withReplyEvent:(NSAppleEventDescriptor *)replyEvent
{
    NSString *urlStr = [[event paramDescriptorForKeyword:keyDirectObject]
                        stringValue];
    NSMutableArray *urls = [[NSMutableArray alloc] init];
    [urls addObject: urlStr];
    [self runScriptWithArguments: urls];
}

@end
