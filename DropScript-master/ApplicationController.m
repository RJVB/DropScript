/**
 *  ApplicationController.m
 *  DropScript
 *
 *  Created by Wilfredo S�nchez on Sun May 02 2004.
 *  Copyright (c) 2004 Wilfredo S�nchez Vega. All rights reserved.
 *  Extended by Ren� J.V. Bertin, (C) Tue May 20nd 2014
 **/

#import <Cocoa/Cocoa.h>

#import "ApplicationController.h"
#include <unistd.h>

int PostMessageBox( const char *title, const char *message )
{ NSAlert* alert = [[[NSAlert alloc] init] autorelease];
    NSString *msg, *tit;
	@synchronized([NSAlert class]){
		[alert setAlertStyle:NSInformationalAlertStyle];
		[alert setMessageText:@"" ];
		if( !(msg = [NSString stringWithCString:message encoding:NSUTF8StringEncoding]) ){
			msg = [NSString stringWithCString:message encoding:NSASCIIStringEncoding];
		}
		if( !(tit = [NSString stringWithCString:title encoding:NSUTF8StringEncoding]) ){
			tit = [NSString stringWithCString:title encoding:NSASCIIStringEncoding];
		}
		if( msg ){
			[alert setInformativeText:msg];
		}
		else{
			NSLog( @"msg=%@ tit=%@", msg, tit );
		}
		[[alert window] setTitle:tit];
		return NSAlertDefaultReturn == [alert runModal];
	}
	return 0;
}

int PostSelectionBox( const char *title, const char *message )
{ NSAlert* alert = [NSAlert
			alertWithMessageText:[NSString stringWithCString:title encoding:NSUTF8StringEncoding]
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
{ NSError *err;
  BOOL isStale = NO;
  NSURL *origURL = nil;
    if( isAlias(thePath) ){
        NSData* bookmark = [NSURL bookmarkDataWithContentsOfURL:[NSURL fileURLWithPath:thePath] error:nil];
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

BOOL updateDropletIcon( NSString *thePath, NSString *appBndl )
{ NSImage *icon = [[NSWorkspace sharedWorkspace] iconForFile:thePath];
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
                NSRunAlertPanel(@"Error", @"Missing drop_script.py script.", @"Bummer", nil, nil);
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

- (NSTask*) runScriptWithArguments: (NSArray*) theArguments
{ NSString *scriptFile = myScriptFilename;
  BOOL isAppBndle = NO;
  NSURL *origURL;
    if( (origURL = resolveIfAlias(myScriptFilename)) ){
        scriptFile = [origURL path];
    }
    isAppBndle = isAppBundle(scriptFile);
    if( theArguments == nil ){
        if( isAppBndle ){
            [[NSWorkspace sharedWorkspace] launchApplication:scriptFile];
        }
        else{
            // RJVB 20140520
            NSTask *aTask = [[NSTask alloc] init];
            [aTask setLaunchPath:scriptFile];
            [aTask launch];
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
            return [NSTask launchedTaskWithLaunchPath:scriptFile
                                     arguments:theArguments];
        }
    }
    // we return nil when launching an app bundle - for now. There's no reason
    // to be able to wait for it anyway (= not a foreseen situation).
    return nil;
}

- (int) runScriptWithArguments: (NSArray*) theArguments wait:(BOOL)wait
{ NSTask *script = [self runScriptWithArguments:theArguments];
  int ret = 0;
    if( wait ){
        [script waitUntilExit];
        ret = [script terminationStatus];
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

- (BOOL) createDropScriptWithFile:(NSString*) thePath
{ NSString *dirName = [thePath stringByDeletingLastPathComponent], *alias = NULL;
  NSError *err = nil;
  int ret = 1;
  BOOL success = NO;
    if( [[NSURL fileURLWithPath:thePath] checkResourceIsReachableAndReturnError:&err] ){
        if( access( [dirName fileSystemRepresentation], W_OK ) == 0 ){
            // check here if thePath is an appbundle, and if so, create an alias to it in dirName and update thePath accordingly.
            if( isAppBundle(thePath) ){
                alias = [NSString stringWithFormat:@"%@-DropLet", [thePath stringByDeletingPathExtension]];
                if( createAliasFromTo( thePath, alias, &err ) ){
                    ret = [self runScriptWithArguments:[NSArray arrayWithObject:alias] wait:YES];
                    thePath = alias;
                }
                else{
                    NSLog( @"%@ is an AppBundle and cannot make alias \"%@\" to it (%@)", thePath, alias, err );
                    PostMessageBox( "DropScript", "Source script is an AppBundle and cannot make an alias to it" );
                }
            }
            else{
                ret = [self runScriptWithArguments:[NSArray arrayWithObject:thePath] wait:YES];
            }
        }
        else{
            NSOpenPanel *destPanel = [NSOpenPanel openPanel];
            [destPanel setCanChooseFiles: NO];
            [destPanel setCanChooseDirectories: YES];
            [destPanel setMessage:@"Choose a destination to save the new DropLet"];
            if( [destPanel runModal] == NSFileHandlingPanelOKButton ){
                dirName = [[destPanel URL] path];
                // check here if thePath is an appbundle, and if so, create an alias to it in dirName and update thePath accordingly.
                if( isAppBundle(thePath) ){
                    alias = [NSString stringWithFormat:@"%@/%@", dirName,
                             [[thePath stringByDeletingPathExtension] lastPathComponent]];
                    if( createAliasFromTo( thePath, alias, &err ) ){
                        // we can just call runScriptWithArguments with a single argument, as the droplet
                        // is to be created in the same directory as the alias we just made.
                        ret = [self runScriptWithArguments:[NSArray arrayWithObject:alias] wait:YES];
                        thePath = alias;
                    }
                    else{
                        NSLog( @"%@ is an AppBundle and cannot make alias \"%@\" to it (%@)", thePath, alias, err );
                        PostMessageBox( "DropScript", "Source script is an AppBundle and cannot make an alias to it" );
                    }
                }
                else{
                    ret = [self runScriptWithArguments:[NSArray arrayWithObjects:thePath, dirName, nil] wait:YES];
                }
            }
        }
        if( ret == 0 ){
            if( isAlias(thePath) ){
                // we just received a Finder alias (bookmark). The python script that created our DropLet
                // doesn't handle those correctly (on all OS X versions), so we take corrective action here.
                NSString *scriptFile = [NSString stringWithFormat:@"%@/%@.app/Contents/Resources/drop_script",
                                        dirName, [thePath lastPathComponent]];
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
                        PostMessageBox( "DropScript", [errMsg fileSystemRepresentation] );
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
        [self runScriptWithArguments: myFilesToBatch];
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
        PostMessageBox( [[scriptFile lastPathComponent] fileSystemRepresentation], "Editing of AppBundles is not supported" );
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
            switch( PostSelectionBox( "DropScript", "Use the File menu either to create a New script or else to Open an existing executable" ) ){
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
                [self runScriptWithArguments:nil];
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
