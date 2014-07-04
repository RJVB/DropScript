// a very simple utility to that allows to launch OS X applications (app bundles) from a command line
// and lets them appear in the foreground. Contrary to OS X's own open command, it does not treat all
// arguments like they're documents to be opened, and so doesn't impose to pass non-file arguments after
// a --args option. It also removes the need to specify full paths for the files to be opened for
// certain applications (KDE app bundles for instance).

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>
#import <sys/types.h>
#import <libgen.h>
#import <mach/clock_types.h>
#import <dispatch/semaphore.h>

// from http://stackoverflow.com/a/4933492

@interface NSWorkspace (MDAdditions)
- (pid_t) launchApplicationAtPath:(NSString *)path
				withArguments:(NSArray *)argv
				 waitFinished:(BOOL)wait
						psn:(ProcessSerialNumber*)psn
					   error:(NSError **)error;
- (void) appTerminated:(NSNotification*)note;
@end

#import <CoreServices/CoreServices.h>

@interface NSString (MDAdditions)
- (BOOL) getFSRef:(FSRef *)anFSRef error:(NSError **)anError;
@end

#import <sys/syslimits.h>

@implementation NSString (MDAdditions)

- (BOOL) getFSRef:(FSRef *)anFSRef error:(NSError **)anError
{
	if( anError ){
		*anError = nil;
	}
	OSStatus status = noErr;
	status = FSPathMakeRef( (const UInt8 *)[self UTF8String], anFSRef, NULL );
	if( status != noErr ){
		if( anError ){
			*anError = [NSError errorWithDomain:NSOSStatusErrorDomain code:status userInfo:nil];
		}
	}
	return (status == noErr);
}
@end

static dispatch_semaphore_t sema;
static pid_t waitPID;

@implementation NSWorkspace (MDAdditions)

- (void)appTerminated:(NSNotification *)note
{
// 	NSLog(@"terminated %@\n", [[note userInfo] objectForKey:@"NSApplicationProcessIdentifier"]);
	if( [[[note userInfo] objectForKey:@"NSApplicationProcessIdentifier"] unsignedLongLongValue] == (unsigned long long) waitPID ){
		dispatch_semaphore_signal(sema);
	}
}

- (pid_t) launchApplicationAtPath:(NSString *)path withArguments:(NSArray *)argv
				 waitFinished:(BOOL)wait
						psn:(ProcessSerialNumber*)psn
					   error:(NSError **)error
{ pid_t pid = 0;
	if( error ){
		*error = nil;
	}

	if( path ){
		FSRef itemRef;
		if( [path getFSRef:&itemRef error:error] ){
			LSApplicationParameters appParameters = { 0,
				kLSLaunchAndDisplayErrors|kLSLaunchDontAddToRecents, &itemRef, NULL, NULL,
				(argv ? (CFArrayRef)argv : NULL), NULL };
			ProcessSerialNumber PSN;

			OSStatus status = noErr;
			status = LSOpenApplication( &appParameters, &PSN );

			if( status != noErr ){
                    NSLog( @"[%@ %@] LSOpenApplication() returned %d for %@",
					 NSStringFromClass([self class]),
					 NSStringFromSelector(_cmd), (int) status, path );
                    if( error ){
					*error = [NSError errorWithDomain:NSOSStatusErrorDomain code:status userInfo:nil];
				}
			}
			else{
				if( psn ){
					*psn = PSN;
				}
				GetProcessPID( &PSN, &pid );
				if( wait ){
				  NSNotificationCenter *center = [self notificationCenter];
					sema = dispatch_semaphore_create(0);
					[center addObserver:self selector:@selector(appTerminated:)
								name:NSWorkspaceDidTerminateApplicationNotification
							   object:NSApp];
					waitPID = pid;
					if( kill( pid, 0 ) ){
						// catch the case where the app we launched exited before we could put the notification centre
						// in place
						dispatch_semaphore_signal(sema);
					}
				}
			}
		}
	}
	else{
		if( error ){
			*error = [NSError errorWithDomain:NSOSStatusErrorDomain code:paramErr userInfo:nil];
		}
	}
	return pid;
}
@end



int main( int argc, const char *argv[] )
{ NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  BOOL success = NO, waitApp = NO;
	if ( argc > 1 ){
		int i = 1;
		NSString *cwd = [[NSFileManager defaultManager] currentDirectoryPath];
		NSMutableArray *theArguments = [[NSMutableArray alloc] init];

		if( strcmp( argv[i], "--help" ) == 0 ){
			fprintf( stderr, "Usage: %s [-W|--wait-app] command [arguments]\n",
				   basename((char*)argv[0]) );
			exit(0);
		}

		if( strcmp( argv[i], "-W" ) == 0 || strcmp( argv[i], "--wait-apps" ) == 0 ){
			waitApp = YES;
			i += 1;
		}

		NSString *command = [NSString stringWithCString:argv[i] encoding:NSUTF8StringEncoding];

		for( ++i ; i < argc ; ++i ){
		  NSString *arg = [NSString stringWithCString:argv[i] encoding:NSUTF8StringEncoding];
			if( argv[i][0] != '/' && access( argv[i], R_OK ) == 0 ){
			  NSString *fullPath = [NSString stringWithFormat:@"%@/%s", cwd, argv[i]];
				if( fullPath ){
// 					NSLog( @"%s@%@ -> %@", argv[i], cwd, fullPath );
					arg = fullPath;
				}
			}
			[theArguments addObject:arg];
		}

		NSError *err = nil;
		ProcessSerialNumber psn;
		[[NSWorkspace sharedWorkspace] launchApplicationAtPath:command withArguments:theArguments
														   waitFinished:waitApp psn:&psn error:&err];
		if( err ){
			NSLog( @"%@", err );
			success = NO;
		}
		else{
			success = YES;
			if( waitApp ){
				// thanks to http://michiganlabs.com/unit-testing-objectivec-asychronous-blockbased-api/
				// and http://stackoverflow.com/questions/4326350/how-do-i-wait-for-an-asynchronously-dispatched-block-to-finish
			  NSTimeInterval TIMEOUT = 5.0;
				while( dispatch_semaphore_wait( sema, DISPATCH_TIME_NOW ) ){
					[[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
										beforeDate:[NSDate dateWithTimeIntervalSinceNow:TIMEOUT]];
				}
			}
		}
	}
	[pool release];
	exit( !success );
}
