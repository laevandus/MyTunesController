//
//  MyTunesControllerAppDelegate.m
//  MyTunesController
//
//  Created by Toomas Vahter on 26.12.09.
//  Copyright (c) 2010 Toomas Vahter
//
//  This content is released under the MIT License (http://www.opensource.org/licenses/mit-license.php).
//  
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//  
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//  
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.



#import "MyTunesControllerAppDelegate.h"
#import "NotificationWindowController.h"
#import "PreferencesController.h"
#import "iTunesController.h"
#import "StatusView.h"
#import "StatusBarController.h"


@implementation MyTunesControllerAppDelegate

@synthesize statusBarController = _statusBarController;

+ (void)initialize
{
	if (self == [MyTunesControllerAppDelegate class]) 
	{
		[[NSUserDefaults standardUserDefaults] registerDefaults:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithUnsignedInteger:3], CONotificationCorner, nil]];
	}
}


#pragma mark Application Delegate

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender 
{
	return NSTerminateNow;
}


- (void)applicationDidFinishLaunching:(NSNotification *)aNotification 
{
	[[NSUserDefaultsController sharedUserDefaultsController] addObserver:self forKeyPath:@"values.NotificationCorner" options:NSKeyValueObservingOptionInitial context:nil];
	
	[[iTunesController sharedInstance] setDelegate:self];
	
	[self.statusBarController addStatusItems];
}


- (void)applicationWillTerminate:(NSNotification *)notification
{
	[[NSDistributedNotificationCenter defaultCenter] removeObserver:self];
	[[NSUserDefaultsController sharedUserDefaultsController] removeObserver:self forKeyPath:@"values.NotificationCorner"];
}


#pragma mark iTunesController Delegate

- (void)iTunesTrackDidChange:(iTunesTrack *)newTrack
{
	[self.statusBarController updatePlayButtonState];
		
	if (newTrack == nil) 
		return;
	
	if ([[iTunesController sharedInstance] isPlaying] == NO) 
	{
		[notificationWindowController disappear];
		return;
	}
	
	// if I reused the window then text got blurred
	if (notificationWindowController) 
	{
		[notificationWindowController setDelegate:nil];
		[notificationWindowController close];
		notificationWindowController = nil;
	}
	
	notificationWindowController = [[NotificationWindowController alloc] init];
	[notificationWindowController setDelegate:self];
	[notificationWindowController.window setAlphaValue:0.0];
	[notificationWindowController setTrack:newTrack];
	[notificationWindowController resize];
	[notificationWindowController setPositionCorner:notificationCorner];
	[notificationWindowController showWindow:self];
}


#pragma mark NotificationWindowController Delegate

- (void)notificationCanBeRemoved 
{
	[notificationWindowController close];
	notificationWindowController = nil;
}


#pragma mark NSWindow Delegate

- (void)windowWillClose:(NSNotification *)notification
{
	NSWindow *window = [notification object];
	
	if ([window isEqualTo:[preferencesWindowController window]]) 
	{
		preferencesWindowController = nil;
	}	
}


#pragma mark KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context 
{
	if ([keyPath isEqualToString:@"values.NotificationCorner"]) 
	{
		notificationCorner = [[[NSUserDefaults standardUserDefaults] objectForKey:CONotificationCorner] unsignedIntValue];
		
		if (notificationWindowController)
			[notificationWindowController setPositionCorner:notificationCorner];
	} 
	else 
	{
		[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];	
	}
}


#pragma mark Managing Windows

- (void)showAboutPanel
{
	[NSApp orderFrontStandardAboutPanel:self];
	[NSApp activateIgnoringOtherApps:YES];
}


- (void)showPreferencesWindow
{
	if (preferencesWindowController == nil) 
	{
		preferencesWindowController = [[PreferencesController alloc] init];
	}
	
	[preferencesWindowController showWindow:self];
	[NSApp activateIgnoringOtherApps:YES];
}

@end

NSString *CONotificationCorner = @"NotificationCorner";
