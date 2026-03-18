/*
-----------------------------------------------
  APPTRAP LICENSE

  "Do what you want to do,
  and go where you're going to
  Think for yourself,
  'cause I won't be there with you"

  You are completely free to do anything with
  this source code, but if you try to make
  money on it you will be beaten up with a
  large stick. I take no responsibility for
  anything, and this license text must
  always be included.

  Markus Amalthea Magnuson <markus.magnuson@gmail.com>
-----------------------------------------------
*/

#import "ATPreferencePane.h"
#import "ATNotifications.h"
#import "ATVariables.h"
#import <ServiceManagement/ServiceManagement.h>

static NSString *AppTrapBackgroundBundleIdentifier = @"com.KumaranVijayan.AppTrap";

@interface ATPreferencePane () <SUUpdaterDelegate>
@end

@implementation ATPreferencePane

- (void)mainViewDidLoad
{
	[[ATSUUpdater sharedUpdater] resetUpdateCycle];
	[[ATSUUpdater sharedUpdater] setDelegate:self];
		
    // Setup the application path
    appPath = [[self bundle] pathForResource:@"AppTrap" ofType:@"app"];
	NSLog(@"appPath: %@", appPath);
	
	[automaticallyCheckForUpdate setState:[[ATSUUpdater sharedUpdater] automaticallyChecksForUpdates]];

    // Check if application is in login items and update checkbox state
    if ([self inLoginItems]) {
		[startOnLoginButton setState:NSControlStateValueOn];
	} else {
		[startOnLoginButton setState:NSControlStateValueOff];
	}
    
    // Display read me file
    [aboutView readRTFDFromFile:[[self bundle] pathForResource:@"Read Me" ofType:@"rtf"]];
    // Replace the {APPTRAP_VERSION} symbol with the version number
    NSRange versionSymbolRange = [[aboutView string] rangeOfString:@"{APPTRAP_VERSION}"];
    if (versionSymbolRange.location != NSNotFound){
        [[aboutView textStorage] replaceCharactersInRange:versionSymbolRange withString:[[self bundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"]];
	}

    // Register for notifications from AppTrap
    NSDistributedNotificationCenter *nc = [NSDistributedNotificationCenter defaultCenter];
    
    [nc addObserver:self
           selector:@selector(updateStatus)
               name:ATApplicationFinishedLaunchingNotification
             object:nil
 suspensionBehavior:NSNotificationSuspensionBehaviorDeliverImmediately];
    
    [nc addObserver:self
           selector:@selector(updateStatus)
               name:ATApplicationTerminatedNotification
             object:nil
 suspensionBehavior:NSNotificationSuspensionBehaviorDeliverImmediately];
	
	[nc addObserver:self
		   selector:@selector(checkBackgroundProcessVersion:) 
			   name:ATApplicationGetVersionData 
			 object:nil 
 suspensionBehavior:NSNotificationSuspensionBehaviorDeliverImmediately];
	
	[nc postNotificationName:ATApplicationSendVersionData 
					  object:nil 
					userInfo:nil 
		  deliverImmediately:YES];	
}

- (void)checkBackgroundProcessVersion:(NSNotification*)notification {
	NSLog(@"checkBackgroundProcessVersion");
	NSLog(@"notification: %@", [notification description]);
	NSLog(@"notification userInfo: %@", [[notification userInfo] description]);
	
	NSString *backgroundProcessVersion = [notification userInfo][ATBackgroundProcessVersion];
	int backgroundProcessVersionInt = [backgroundProcessVersion intValue];
	NSString *prefpaneVersion = [[self bundle] objectForInfoDictionaryKey:@"CFBundleVersion"];
	int prefpaneVersionInt = [prefpaneVersion intValue];
	
	if (prefpaneVersionInt != backgroundProcessVersionInt) {
		NSAlert *alert = [[NSAlert alloc] init];
		alert.messageText = @"AppTrap";
		alert.informativeText = NSLocalizedStringFromTableInBundle(@"The background process is an older version. Would you like to restart it with the newer version?", nil, [self bundle], @"");
		[alert addButtonWithTitle:NSLocalizedStringFromTableInBundle(@"Restart AppTrap", nil, [self bundle], @"")];
		[alert addButtonWithTitle:NSLocalizedStringFromTableInBundle(@"Don't restart AppTrap", nil, [self bundle], @"")];
		[alert beginSheetModalForWindow:[startStopButton window]
					  completionHandler:^(NSModalResponse returnCode) {
			if (returnCode == NSAlertFirstButtonReturn) {
				[startStopButton setEnabled:NO];
				[restartingAppTrapIndicator startAnimation:nil];
				[restartingAppTrapTextField setHidden:NO];
				[self terminateAppTrap];
				[self performSelector:@selector(restartWithNewVersion) withObject:nil afterDelay:5];
			}
		}];
	}
}

- (void)checkBackgroundProcessVersion {
	NSDistributedNotificationCenter *nc = [NSDistributedNotificationCenter defaultCenter];
	
	[nc postNotificationName:ATApplicationSendVersionData
					  object:nil
					userInfo:nil
		  deliverImmediately:YES];
}

- (void)restartWithNewVersion {
	[self launchAppTrap];
	[restartingAppTrapIndicator stopAnimation:nil];
	[restartingAppTrapTextField setHidden:YES];
	[startStopButton setEnabled:YES];
}

- (void)didSelect
{
    if ([self inLoginItems]) {
		[startOnLoginButton setState:NSControlStateValueOn];
	} else {
		[startOnLoginButton setState:NSControlStateValueOff];
	}
	
    [self updateStatus];
	[self checkBackgroundProcessVersion];
}

- (void)updateStatus
{
    if ([self appTrapIsRunning]) {
        // Need to specify bundle because we're a prefpane
        [statusText setStringValue:NSLocalizedStringFromTableInBundle(@"Active", nil, [self bundle], @"")];
        [statusText setTextColor:[NSColor labelColor]];
        [startStopButton setTitle:NSLocalizedStringFromTableInBundle(@"Stop AppTrap", nil, [self bundle], @"")];
    }
    else {
        // Need to specify bundle because we're a prefpane
        [statusText setStringValue:NSLocalizedStringFromTableInBundle(@"Inactive", nil, [self bundle], @"")];
        [statusText setTextColor:[NSColor secondaryLabelColor]];
        [startStopButton setTitle:NSLocalizedStringFromTableInBundle(@"Start AppTrap", nil, [self bundle], @"")];
    }
    
    // Extra check after five seconds in case the launch/termination was delayed
    [self performSelector:@selector(updateStatus)
			   withObject:nil
			   afterDelay:5.0];
}

- (void)launchAppTrap
{
    NSLog(@"launching AppTrap");
    NSURL *appURL = [NSURL fileURLWithPath:appPath];
    NSWorkspaceOpenConfiguration *config = [NSWorkspaceOpenConfiguration configuration];
    config.addsToRecentItems = NO;
    config.activates = NO;
    [[NSWorkspace sharedWorkspace] openApplicationAtURL:appURL
                                          configuration:config
                                      completionHandler:^(NSRunningApplication *app, NSError *error) {
        if (error) {
            NSLog(@"Couldn't launch AppTrap: %@", error);
        }
    }];
}

- (void)terminateAppTrap
{
	NSLog(@"terminating AppTrap");
    NSDistributedNotificationCenter *nc = [NSDistributedNotificationCenter defaultCenter];
    [nc postNotificationName:ATApplicationShouldTerminateNotification
                      object:nil
                    userInfo:nil
          deliverImmediately:YES];
}

- (BOOL)appTrapIsRunning
{
	id <NSFastEnumeration> applications = [NSRunningApplication runningApplicationsWithBundleIdentifier:AppTrapBackgroundBundleIdentifier];
	for (NSRunningApplication *application in applications)
	{
		NSString *bundleIdentifier = application.bundleIdentifier;
		if ([bundleIdentifier isEqualToString:AppTrapBackgroundBundleIdentifier])
		{
			return YES;
		}
	}
	return NO;
}

#pragma mark -
#pragma mark Update check

- (SUUpdater*)updater {
	return [SUUpdater updaterForBundle:[NSBundle bundleForClass:[self class]]];
}

- (IBAction)automaticallyCheckForUpdate:(id)sender {
	[[ATSUUpdater sharedUpdater] setAutomaticallyChecksForUpdates:[sender state]];
}

- (IBAction)checkForUpdate:(id)sender {
	[[ATSUUpdater sharedUpdater] checkForUpdates:sender];
}

#pragma mark -
#pragma mark Login items

- (BOOL)inLoginItems
{
    SMAppService *service = [SMAppService loginItemServiceWithIdentifier:AppTrapBackgroundBundleIdentifier];
    return service.status == SMAppServiceStatusEnabled;
}

- (void)addToLoginItems
{
    SMAppService *service = [SMAppService loginItemServiceWithIdentifier:AppTrapBackgroundBundleIdentifier];
    NSError *error = nil;
    if (![service registerAndReturnError:&error]) {
        NSLog(@"Failed to add AppTrap to login items: %@", error);
    }
}

- (void)removeFromLoginItems
{
    SMAppService *service = [SMAppService loginItemServiceWithIdentifier:AppTrapBackgroundBundleIdentifier];
    NSError *error = nil;
    if (![service unregisterAndReturnError:&error]) {
        NSLog(@"Failed to remove AppTrap from login items: %@", error);
    }
}

#pragma mark -
#pragma mark Interface actions

- (IBAction)startStopAppTrap:(id)sender
{
    if ([self appTrapIsRunning]) {
        [self terminateAppTrap];
    } else {
        [self launchAppTrap];
	}
}

- (IBAction)startOnLogin:(id)sender
{
    if ([sender state] == NSControlStateValueOn) {
        [self addToLoginItems];
	} else {
        [self removeFromLoginItems];
	}
}

- (IBAction)visitWebsite:(id)sender
{
    NSURL *url = [NSURL URLWithString:@"http://onnati.net/apptrap/"];
    [[NSWorkspace sharedWorkspace] openURL:url];
}

@end
