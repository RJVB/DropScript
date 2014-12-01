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
#import <crt_externs.h>
#include <stdio.h>
#include <unistd.h>

int PostMessageBox( NSString *title, const char *message )
{ NSAlert* alert = [[[NSAlert alloc] init] autorelease];
    NSString *msg;
	@synchronized([NSAlert class]){
		[alert setAlertStyle:NSInformationalAlertStyle];
		[alert setMessageText:@"" ];
		if( !(msg = [NSString stringWithCString:message encoding:NSUTF8StringEncoding]) ){
			msg = [NSString stringWithCString:message encoding:NSASCIIStringEncoding];
		}
		if( msg ){
			[alert setInformativeText:msg];
		}
		else{
			NSLog( @"msg=%@ title=%@", msg, title );
		}
		[[alert window] setTitle:title];
		return NSAlertDefaultReturn == [alert runModal];
	}
	return 0;
}

int PostSelectionBox( NSString *title, const char *message )
{ NSAlert* alert = [NSAlert
			alertWithMessageText:title
			defaultButton:@"OK" alternateButton:@"New script" otherButton:@"Open existing"
			informativeTextWithFormat:[NSString stringWithCString:message encoding:NSUTF8StringEncoding]
		];
	@synchronized([NSAlert class]){
      int ret;
        [alert setAlertStyle:NSInformationalAlertStyle];
        ret = [alert runModal];
        switch( ret ){
            default:
            case NSAlertDefaultReturn:
                return 1;
                break;
            case NSAlertAlternateReturn:
                return 2;
                break;
            case NSAlertOtherReturn:
                return 3;
                break;
        }
	}
	return 0;
}

BOOL isAlias( NSString *thePath )
{ NSError *err;
  NSNumber *val = nil;
    if( [[NSURL fileURLWithPath:thePath] getResourceValue:&val forKey:NSURLIsAliasFileKey error:&err] ){
        return( [val boolValue] );
    }
    else{
        return NO;
    }
}

BOOL createAliasFromTo( NSString *target, NSString *alias, NSError **err )
{ BOOL ret = NO;
  NSData *bookmarkData = [[NSURL fileURLWithPath:target] bookmarkDataWithOptions:NSURLBookmarkCreationSuitableForBookmarkFile
                                                  includingResourceValuesForKeys:nil relativeToURL:nil error:err];
    if( bookmarkData ){
        err = NULL;
        ret = [NSURL writeBookmarkData:bookmarkData toURL:[NSURL fileURLWithPath:alias]
                         options:NSURLBookmarkCreationSuitableForBookmarkFile error:err];
    }
    return ret;
}

NSURL *resolveIfAlias( NSString *thePath )
{ NSError *err = nil;
  BOOL isStale = NO;
  NSURL *origURL = nil;
    if( isAlias(thePath) ){
        NSData* bookmark = [NSURL bookmarkDataWithContentsOfURL:[NSURL fileURLWithPath:thePath] error:nil];
        err = nil;
        // first try without attempting to mount anything:
        origURL = [NSURL URLByResolvingBookmarkData:bookmark
                                            options:NSURLBookmarkResolutionWithoutUI|NSURLBookmarkResolutionWithoutMounting
                                            relativeToURL:nil
                                            bookmarkDataIsStale:&isStale
                                            error:&err];
        if( !origURL ){
            // no luck, let's try again. This will probably cause a Finder window to be opened if the target is on
            // a volume that gets mounted
            err = nil;
            origURL = [NSURL URLByResolvingBookmarkData:bookmark
                                                options:0
                                                relativeToURL:nil
                                                bookmarkDataIsStale:&isStale
                                                error:&err];
            if( isStale || err ){
                NSLog( @"alias resolution: isStale=%d, err=%@", isStale, err );
                NSLog( @"%@ points to %@; using the destination", thePath, origURL );
            }
            else{
              NSArray *path = [[origURL path] pathComponents];
                // Tell the Finder to close the window corresponding to a volume just mounted
                if( ([(NSString*)[path objectAtIndex:0] compare:@"/"] == NSOrderedSame)
                   && ([(NSString*)[path objectAtIndex:1] compare:@"Volumes"] == NSOrderedSame)
                ){
                  NSString *osa = [NSString stringWithFormat:@"osascript -e 'tell application \"Finder\" to close window \"/%@/%@\"'",
                                   [path objectAtIndex:1], [path objectAtIndex:2]];
                    system( [osa fileSystemRepresentation] );
                }
            }
        }
    }
    return origURL;
}

BOOL isAppBundle(NSString *thePath)
{ NSBundle *bndl = [NSBundle bundleWithPath:thePath];
  BOOL ret = NO;
  NSDictionary *infoDct;
    if( bndl && (infoDct = [bndl infoDictionary]) ){
      id val = [infoDct objectForKey:@"CFBundlePackageType"];
        if( [val isKindOfClass:[NSString class]] && [((NSString*)val) compare:@"APPL"] == NSOrderedSame ){
            ret = YES;
        }
    }
    return ret;
}

// updateDropletIcon copies the icon used by the file at <thePath> to the specified <appBndl>
// appBndl will be a bundle created by us, so it already has a bundle icon specified in the Info.plist
// The call to setIcon: below will override that setting ... until the user deletes the icon, in which
// case our internal icon will be shown again.
BOOL updateDropletIcon( NSString *thePath, NSString *appBndl )
{ NSURL *origURL = resolveIfAlias(thePath);
  // get the icon for the original if thePath is an alias, for otherwise the result would have the alias arrow embedded
  // and we're not creating a Finder alias or symlink, but an application bundle.
  NSImage *icon = [[NSWorkspace sharedWorkspace] iconForFile:((origURL)?[origURL path] : thePath) ];
    if( icon ){
        if( !appBndl ){
            appBndl = [NSString stringWithFormat:@"%@.app", thePath];
        }
        NSLog(@"Icon for %@: %@", thePath, icon );
        return [[NSWorkspace sharedWorkspace] setIcon:icon forFile:appBndl options:0];
    }
    return NO;
}

@implementation ApplicationController

/**
 * Inits
 **/

- (id) init
{
    if( (self = [super init]) ){
      char **argv = *_NSGetArgv();
        myAppIsLaunching             = YES;
        myAppWasLaunchedWithDocument = NO;
//         NSLog( @"Application name is \"%@\"", [[NSString stringWithCString:argv[0] encoding:NSUTF8StringEncoding] lastPathComponent] );
//         myScriptFilename             = [[[NSBundle mainBundle] pathForResource:@"drop_script" ofType:nil] retain];
        myScriptFilename             = [[[NSBundle mainBundle]
                                         pathForResource:[[NSString stringWithCString:argv[0] encoding:NSUTF8StringEncoding] lastPathComponent]
                                         ofType:nil] retain];

        if( !myScriptFilename ){
            if( (myScriptFilename = [[[NSBundle mainBundle] pathForResource:@"drop_script.py" ofType:nil] retain]) ){
                creatingDropScript = YES;
            }
            else{
                NSRunAlertPanel(@"Error", @"Missing drop_script.py script.", @"Bummer", nil, nil);
                [NSApp terminate: self];
            }
        }
        else{
            creatingDropScript = NO;
        }

        id cfBundleName = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleName"];
        if( cfBundleName && [cfBundleName isKindOfClass:[NSString class]] ){
            appName = [(NSString*) cfBundleName retain];
//             NSLog( @"appName from CFBundleName=%@", appName );
        }
        else{
            appName = [[[NSString stringWithCString:argv[0] encoding:NSUTF8StringEncoding] lastPathComponent] retain];
//             NSLog( @"appName from argv=%@", appName );
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
    [appName release];

    [super dealloc];
}

/**
 * Actions
 **/

- (NSTask*) runScriptWithArguments: (NSArray*) theArguments
{ NSString *scriptFile = myScriptFilename;
  BOOL isAppBndle = NO;
  NSURL *origURL;
  id closeIO = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"WrapperClosesStdIO"];
  BOOL detach = false;
    if( (origURL = resolveIfAlias(myScriptFilename)) ){
        scriptFile = [origURL path];
    }
    isAppBndle = isAppBundle(scriptFile);
    if( closeIO && [closeIO isKindOfClass:[NSNumber class]] ){
        if( (detach = [((NSNumber*)closeIO) boolValue]) ){
            NSLog( @"Info.plist::WrapperClosesStdIO=%@ - will close stdin, stdout and stderr",
                  closeIO );
        }
    }
    if( theArguments == nil ){
        if( isAppBndle ){
            [[NSWorkspace sharedWorkspace] launchApplication:scriptFile];
        }
        else{
            // RJVB 20140520
            NSTask *aTask = [[NSTask alloc] init];
            [aTask setLaunchPath:scriptFile];
            if( detach ){
                fclose(stdin), fclose(stdout), fclose(stderr);
            }
            [aTask launch];
            [aTask release];
            return aTask;
        }
    }
    else{
        if( isAppBndle ){
            // not the most elegant solution, but there appears to be no single call to open
            // a number of files with a given application. (There's one to open an array
            // of NSURLs, but it takes a bundle identifier, not the path.)
            for( NSString *arg in theArguments ){
                [[NSWorkspace sharedWorkspace] openFile:arg withApplication:scriptFile];
            }
        }
        else{
            if( detach ){
                fclose(stdin), fclose(stdout), fclose(stderr);
            }
            return [NSTask launchedTaskWithLaunchPath:scriptFile
                                     arguments:theArguments];
        }
    }
    // we return nil when launching an app bundle - for now. There's no reason
    // to be able to wait for it anyway (= not a foreseen situation).
    return nil;
}

- (int) runScriptWithArguments: (NSArray*) theArguments wait:(BOOL)wait
{ NSTask *script = [[self runScriptWithArguments:theArguments] retain];
  int ret = 0;
    if( wait ){
        [script waitUntilExit];
        ret = [script terminationStatus];
        [script release];
    }
    else{
        [script autorelease];
    }
    return ret;
}

/**
 * IB Targets
 **/

- (IBAction) doNew: (id) aSender
{
    if( creatingDropScript ){
        if( [self createDropScript] ){
            [NSApp terminate: self];
        }
    }
}

NSArray *createArgList( NSString *fName, NSString *dirName )
{ NSMutableArray *array = [NSMutableArray arrayWithObject:fName];
    if( dirName ){
        [array addObject:dirName];
    }
#ifdef APPDROP2BUNDLE
    else{
        [array addObject:@""];
    }
    [array addObject:@"AppDrop2Bundle.icns"];
#endif
    return array;
}

- (NSString*) createDropScriptNow:(NSString*)thePath dirName:(NSString*)dirName retCode:(int*)ret
{ NSString *alias;
  NSError *err = nil;
    // check here if thePath is an appbundle, and if so, create an alias to it in dirName and update thePath accordingly.
    if( isAppBundle(thePath) ){
        if( dirName ){
            alias = [NSString stringWithFormat:@"%@/%@", dirName,
                     [[thePath stringByDeletingPathExtension] lastPathComponent]];
        }
        else{
            alias = [NSString stringWithFormat:@"%@-DropLet", [thePath stringByDeletingPathExtension]];
        }
        if( createAliasFromTo( thePath, alias, &err ) ){
            // we can just call runScriptWithArguments with a single argument, as the droplet
            // is to be created in the same directory as the alias we just made.
            *ret = [self runScriptWithArguments:[NSArray arrayWithObject:alias] wait:YES];
            thePath = alias;
        }
        else{
            NSLog( @"%@ is an AppBundle and cannot make alias \"%@\" to it (%@)", thePath, alias, err );
            PostMessageBox( appName, "Source script is an AppBundle and cannot make an alias to it" );
        }
    }
    else{
        *ret = [self runScriptWithArguments:createArgList(thePath, dirName) wait:YES];
    }
    return thePath;
}

- (BOOL) createDropScriptWithFile:(NSString*) thePath
{ NSString *dirName = [thePath stringByDeletingLastPathComponent], *alias = NULL;
  NSError *err = nil;
  int ret = 1;
  BOOL success = NO;
    if( [[NSURL fileURLWithPath:thePath] checkResourceIsReachableAndReturnError:&err] ){
        if( access( [dirName fileSystemRepresentation], W_OK ) == 0 ){
            thePath = [self createDropScriptNow:thePath dirName:NULL retCode:&ret];
//             // check here if thePath is an appbundle, and if so, create an alias to it in dirName and update thePath accordingly.
//             if( isAppBundle(thePath) ){
//                 alias = [NSString stringWithFormat:@"%@-DropLet", [thePath stringByDeletingPathExtension]];
//                 if( createAliasFromTo( thePath, alias, &err ) ){
//                     ret = [self runScriptWithArguments:createArgList(alias, NULL) wait:YES];
//                     thePath = alias;
//                 }
//                 else{
//                     NSLog( @"%@ is an AppBundle and cannot make alias \"%@\" to it (%@)", thePath, alias, err );
//                     PostMessageBox( appName, "Source script is an AppBundle and cannot make an alias to it" );
//                 }
//             }
//             else{
//                 ret = [self runScriptWithArguments:createArgList(thePath, NULL) wait:YES];
//             }
        }
        else{
            NSOpenPanel *destPanel = [NSOpenPanel openPanel];
            [destPanel setCanChooseFiles: NO];
            [destPanel setCanChooseDirectories: YES];
            [destPanel setMessage:@"Choose a destination to save the new DropLet"];
            if( [destPanel runModal] == NSFileHandlingPanelOKButton ){
                dirName = [[destPanel URL] path];
                thePath = [self createDropScriptNow:thePath dirName:dirName retCode:&ret];
            }
        }
        if( ret == 0 ){
            if( isAlias(thePath) ){
                // we just received a Finder alias (bookmark). The python script that created our DropLet
                // doesn't handle those correctly (on all OS X versions), so we take corrective action here.
//                 NSString *scriptFile = [NSString stringWithFormat:@"%@/%@.app/Contents/Resources/drop_script",
//                                         dirName, [thePath lastPathComponent]];
                NSString *scriptFile = [NSString stringWithFormat:@"%@/%@.app/Contents/Resources/%@",
                                        dirName, [thePath lastPathComponent], [thePath lastPathComponent]];
                BOOL ok;
                    unlink([scriptFile fileSystemRepresentation]);
                    if( alias ){
                        ok = [[NSFileManager defaultManager] moveItemAtPath:thePath toPath:scriptFile error:&err];
                        alias = nil;
                    }
                    else{
                        ok = [[NSFileManager defaultManager] copyItemAtPath:thePath toPath:scriptFile error:&err];
                    }
                    if( !ok ){
                        NSString *errMsg = [NSString stringWithFormat:@"An error occurred copying the alias %@ to %@ (%@)",
                                            thePath, scriptFile, err];
                        PostMessageBox( appName, [errMsg fileSystemRepresentation] );
                    }
                    else{
                        success = YES;
                        updateDropletIcon( scriptFile, [NSString stringWithFormat:@"%@/%@.app", dirName, [thePath lastPathComponent]] );
                    }
            }
            else{
                success = YES;
                updateDropletIcon( thePath, [NSString stringWithFormat:@"%@/%@.app", dirName, [thePath lastPathComponent]] );
            }
        }
        if( alias ){
            // clean up the temporary alias we created
            unlink([alias fileSystemRepresentation]);
        }
    }
    else{
        NSLog( @"File %@ is unreachable: %@", thePath, err );
    }
    return success;
}

- (IBAction) doOpen: (id) aSender
{
    NSOpenPanel* anOpenPanel = [NSOpenPanel openPanel];

    [anOpenPanel setCanChooseFiles: YES];
    [anOpenPanel setCanChooseDirectories: NO];
    [anOpenPanel setAllowsMultipleSelection: NO];
    [anOpenPanel setResolvesAliases: NO];

    if( [anOpenPanel runModal] == NSFileHandlingPanelOKButton ){
        if( [self createDropScriptWithFile:[[anOpenPanel URL] path]] ){
            [NSApp terminate: self];
        }
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
    if( creatingDropScript ){
        for( NSString *thePath in myFilesToBatch ){
            [self createDropScriptWithFile:thePath];
        }
    }
    else{
        [self runScriptWithArguments: myFilesToBatch wait:NO];
    }
    [myFilesToBatch release];
    myFilesToBatch = nil;

    if (myAppWasLaunchedWithDocument) [NSApp terminate: self];
}

// RJVB 20140520
- (BOOL) createDropScript
{ NSSavePanel *panel = [NSSavePanel savePanel];
  NSArray *dtPaths = NSSearchPathForDirectoriesInDomains( NSDesktopDirectory, NSUserDomainMask, YES );
    [panel setMessage:@"Select a name and location for a new script file\nNB: this is a temporary file!\n(Select replace to choose an existing file)"];
    [panel setTitle:@"new file"];
    [panel setDirectoryURL:[NSURL fileURLWithPath:[dtPaths objectAtIndex:0] isDirectory:YES]];
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
        err = nil;
        if( [[NSURL fileURLWithPath:thePath] checkResourceIsReachableAndReturnError:&err] ){
            [self runScriptWithArguments:[NSArray arrayWithObject:thePath] wait:YES];
            updateDropletIcon(thePath, nil);
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
{ NSString *command, *scriptFile;
  NSURL *origURL = resolveIfAlias(myScriptFilename);
  NSError *err = nil;
    if( origURL ){
        scriptFile = [origURL path];
    }
    else{
        scriptFile = myScriptFilename;
    }
    if( isAppBundle(scriptFile) ){
        PostMessageBox( [scriptFile lastPathComponent], "Editing of AppBundles is not supported" );
    }
    else{
        command = [NSString stringWithFormat:@"open -tW \"%@\"", scriptFile];
        system( [command fileSystemRepresentation] );
    }
    if( ![[NSURL fileURLWithPath:scriptFile] checkResourceIsReachableAndReturnError:&err] ){
        NSLog( @"Warning: droplet file %@ has become unreachable: %@", scriptFile, err );
    }
}

- (void) applicationDidFinishLaunching: (NSNotification*) aNotification
{
    myAppIsLaunching = NO;
    if( myScriptFilename && !myAppWasLaunchedWithDocument ){
        // RJVB 20140520
        if( creatingDropScript ){
            switch( PostSelectionBox( appName, "Use the File menu either to create a New script or else to Open an existing executable" ) ){
                case 2:
                    [self doNew:self];
                    break;
                case 3:
                    [self doOpen:self];
                    break;
            }
        }
        else{
          NSUInteger mods = [NSEvent modifierFlags];
            if( (mods & NSCommandKeyMask) && (mods & NSShiftKeyMask) ){
                [self editScriptFile];
            }
            else{
                [self runScriptWithArguments:nil wait:NO];
            }
            [NSApp terminate: self];
        }
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
        [self runScriptWithArguments: aData wait:NO];
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
    NSMutableArray *urls = [[[NSMutableArray alloc] init] autorelease];
    [urls addObject:urlStr];
    [self runScriptWithArguments: urls wait:NO];
}

@end
