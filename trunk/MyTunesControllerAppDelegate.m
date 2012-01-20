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
#import "LyricsWindowController.h"
#import "NotificationWindowController.h"
#import "PreferencesController.h"
#import "iTunesController.h"
#import "StatusView.h"
#import "UserDefaults.h"

#import "ImageScaler.h"

@interface MyTunesControllerAppDelegate()
- (void)_setupStatusItem;
- (void)_updateStatusItemButtons;
@end


@implementation MyTunesControllerAppDelegate

@synthesize window;

+ (void)initialize
{
	[[NSUserDefaults standardUserDefaults] registerDefaults:[NSDictionary dictionaryWithObjectsAndKeys:
															 [NSNumber numberWithUnsignedInteger:3], CONotificationCorner,    
															 nil]];
}

- (void)dealloc 
{
	[[NSDistributedNotificationCenter defaultCenter] removeObserver:self];
	[[NSUserDefaultsController sharedUserDefaultsController] removeObserver:self forKeyPath:@"values.NotificationCorner"];
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender 
{
	return NSTerminateNow;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification 
{
	[[NSUserDefaultsController sharedUserDefaultsController] addObserver:self
															  forKeyPath:@"values.NotificationCorner"
																 options:NSKeyValueObservingOptionInitial
																 context:nil];
	[[iTunesController sharedInstance] setDelegate:self];
	[self _setupStatusItem];
	[self _updateStatusItemButtons];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context 
{
	if ([keyPath isEqualToString:@"values.NotificationCorner"]) {
		positionCorner = [[[NSUserDefaults standardUserDefaults] objectForKey:CONotificationCorner] unsignedIntValue];
		
		if (notificationController)
			[notificationController setPositionCorner:positionCorner];
	} 
	else 
		[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}

#pragma mark Delegates

- (void)iTunesTrackDidChange:(iTunesTrack *)newTrack
{
	[self _updateStatusItemButtons];
	
	if (lyricsController) 
		lyricsController.track = newTrack;
		
	if (newTrack == nil) 
		return;
	
	if ([[iTunesController sharedInstance] isPlaying] == NO) {
		[notificationController disappear];
		return;
	}
	
	// if I reused the window then text got blurred
	if (notificationController) {
		[notificationController setDelegate:nil];
		[notificationController close];
		notificationController = nil;
	}
	notificationController = [[NotificationWindowController alloc] init];
	[notificationController setDelegate:self];
	[notificationController.window setAlphaValue:0.0];
	[notificationController setTrack:newTrack];
	[notificationController resize];
	[notificationController setPositionCorner:positionCorner];
	[notificationController showWindow:self];
}

- (void)notificationCanBeRemoved 
{
	[notificationController close];
	notificationController = nil;
}

- (void)windowWillClose:(NSNotification *)notification
{
	NSWindow *w = [notification object];
	
	if ([w isEqualTo:lyricsController.window]) {
		lyricsController = nil;
	}
	else if ([w isEqualTo:preferencesController.window]) {
		preferencesController = nil;
	}
		
}

#pragma mark Actions

- (IBAction)playPrevious:(id)sender 
{
	[[iTunesController sharedInstance] playPrevious];
}

- (IBAction)playPause:(id)sender 
{
	[[iTunesController sharedInstance] playPause];
}

- (IBAction)playNext:(id)sender 
{
	[[iTunesController sharedInstance] playNext];
}

#pragma mark Private

- (void)_aboutApp 
{
	[NSApp orderFrontStandardAboutPanel:self];
	[NSApp activateIgnoringOtherApps:YES];
}

- (void)_openLyrics
{
	if (lyricsController == nil) {
		lyricsController = [[LyricsWindowController alloc] init];
		lyricsController.window.delegate = self;
	}
	
	lyricsController.track = [[iTunesController sharedInstance] currentTrack];
	[lyricsController showWindow:self];
	[NSApp activateIgnoringOtherApps:YES];
}

- (void)_openPreferences 
{
	if (preferencesController == nil) {
		preferencesController = [[PreferencesController alloc] init];
		preferencesController.window.delegate = self;
	}
	
	[preferencesController showWindow:self];
	[NSApp activateIgnoringOtherApps:YES];
}

- (void)_quitApp 
{
	[NSApp terminate:self];
}

- (void)_setupStatusItem 
{	
	NSImage *statusIcon = [NSImage imageNamed:@"status_icon.png"];
	controllerItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
	[controllerItem setImage:statusIcon];
	[controllerItem setHighlightMode:YES];
	
	statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
	[statusItem setImage:[NSImage imageNamed:@"blank.png"]];
	[statusItem setView:statusView];
	
	NSMenu *mainMenu = [[NSMenu alloc] init];
	[mainMenu setAutoenablesItems:NO];
	
	NSMenuItem *theItem = [mainMenu addItemWithTitle:@"About"
								  action:@selector(_aboutApp)
						   keyEquivalent:@""];
	[theItem setTarget:self];
	
	theItem = [mainMenu addItemWithTitle:@"Check for Updates..."
								  action:@selector(checkForUpdates:)
						   keyEquivalent:@""];
	[theItem setTarget:sparkle];
	
	theItem = [mainMenu addItemWithTitle:@"Preferences..."
								  action:@selector(_openPreferences)
						   keyEquivalent:@""];
	[theItem setTarget:self];
	
	[mainMenu addItem:[NSMenuItem separatorItem]];
	
	theItem = [mainMenu addItemWithTitle:@"Lyrics..."
								  action:@selector(_openLyrics)
						   keyEquivalent:@""];
	[theItem setTarget:self];
	
	[mainMenu addItem:[NSMenuItem separatorItem]];
	
	
	theItem = [mainMenu addItemWithTitle:@"Quit"
								  action:@selector(_quitApp)
						   keyEquivalent:@"Q"];
	[theItem setTarget:self];
	
	[controllerItem setMenu:mainMenu];
}

- (void)_updateStatusItemButtons 
{
	if ([[iTunesController sharedInstance] isPlaying] == NO) {
		[playButton setImage:[NSImage imageNamed:@"play"]];
	}
	else {
		[playButton setImage:[NSImage imageNamed:@"pause"]];
	}
}

@end
