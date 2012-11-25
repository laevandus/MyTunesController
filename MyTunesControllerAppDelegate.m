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
#import "PreferencesWindowController.h"
#import "StatusView.h"
#import "StatusBarController.h"
#import "LyricsWindowController.h"
#import "NetworkReachability.h"

@interface MyTunesControllerAppDelegate()
@property (nonatomic, strong) LyricsFetcher *mainLyricsFetcher;
- (void)_createDirectories;
@end

@implementation MyTunesControllerAppDelegate

+ (void)initialize
{
	if (self == [MyTunesControllerAppDelegate class]) 
	{
		[[NSUserDefaults standardUserDefaults] registerDefaults:@{CONotificationCorner: @3U}];
	}
}


#pragma mark Application Delegate

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender 
{
	return NSTerminateNow;
}


- (void)applicationDidFinishLaunching:(NSNotification *)aNotification 
{
	srand((unsigned int)time(NULL));
	
	[self _createDirectories];
	
	[[NSUserDefaultsController sharedUserDefaultsController] addObserver:self forKeyPath:@"values.NotificationCorner" options:NSKeyValueObservingOptionInitial context:nil];
	
	[[iTunesController sharedInstance] setDelegate:self];
	
	[self.statusBarController addStatusItems];
}


- (void)_createDirectories
{
	NSError *error = nil;
	NSFileManager *fileManager = [[NSFileManager alloc] init];
	NSURL *plugInsURL = [fileManager URLForDirectory:NSApplicationSupportDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:YES error:&error];
	
	if (plugInsURL == nil) 
	{
		NSLog(@"%s error = (%@)", __func__, [error localizedDescription]);
		return;
	}
	
	NSString *pluginsSubpath = @"MyTunesController/PlugIns/";
	plugInsURL = [plugInsURL URLByAppendingPathComponent:pluginsSubpath];
	error = nil;
	
	if (![plugInsURL checkResourceIsReachableAndReturnError:&error]) 
	{
		if (![fileManager createDirectoryAtURL:plugInsURL withIntermediateDirectories:YES attributes:nil error:&error])
		{
			NSLog(@"%s %@", __func__, [error localizedDescription]);
		}
	}
}


- (void)applicationWillTerminate:(NSNotification *)notification
{
	[[NSDistributedNotificationCenter defaultCenter] removeObserver:self];
	[[NSUserDefaultsController sharedUserDefaultsController] removeObserver:self forKeyPath:@"values.NotificationCorner"];
}


#pragma mark iTunesController Delegate

- (void)iTunesController:(iTunesController *)tunesController trackDidChange:(iTunesTrack *)newTrack
{
	[self.statusBarController updatePlayButtonState];
	
	if ([lyricsWindowController.window isVisible])
	{
		lyricsWindowController.track = newTrack;
		
		if ([[lyricsWindowController.track lyrics] length] == 0 && [NetworkReachability hasInternetConnection]) 
		{
			// Start fetching
            if (!self.mainLyricsFetcher)
            {
                self.mainLyricsFetcher = [[LyricsFetcher alloc] init];
                [self.mainLyricsFetcher setDelegate:self];
            }
            
			[self.mainLyricsFetcher fetchLyricsForTrack:[lyricsWindowController track]];
		}
	}
		
	if (newTrack == nil) 
		return;
	
	if ([[iTunesController sharedInstance] isPlaying]) 
	{
		// if I reused the window then text got blurred
		if (notificationWindowController) 
		{
			[notificationWindowController setDelegate:nil];
			[notificationWindowController close];
			notificationWindowController = nil;
		}
		
		if ([[newTrack name] length]) 
		{
			notificationWindowController = [[NotificationWindowController alloc] init];
			[notificationWindowController setDelegate:self];
			[notificationWindowController.window setAlphaValue:0.0];
			[notificationWindowController setTrack:newTrack];
			[notificationWindowController resize];
			[notificationWindowController setPositionCorner:notificationCorner];
			[notificationWindowController showWindow:self];
            [NSApp activateIgnoringOtherApps:YES];
		}
	}
	else 
	{
		[notificationWindowController disappear];
	}
}


#pragma mark LyricsFetcher Delegate

- (void)lyricsFetcher:(LyricsFetcher *)fetcher didFetchLyrics:(NSString *)lyrics forTrack:(iTunesTrack *)track
{
	if ([fetcher isEqual:self.mainLyricsFetcher])
	{
		// Handles main fetcher's requests		
		if ([lyricsWindowController.track databaseID] == [track databaseID]) 
		{
			// References represent the same object. SBObject is a references to the real object.
			[lyricsWindowController.track willChangeValueForKey:@"lyrics"];
			track.lyrics = lyrics;
			[lyricsWindowController.track didChangeValueForKey:@"lyrics"];
		}
		else
		{
			track.lyrics = lyrics;
		}
        
        if (!self.mainLyricsFetcher.isFetching)
        {
            self.mainLyricsFetcher = nil;
        }
	}
	else
	{
		NSLog(@"%s ignored LyricsFetcher (%@) in AppDelegate", __func__, fetcher);
	}
}


#pragma mark NotificationWindowController Delegate

- (void)notificationCanBeRemoved 
{
	[notificationWindowController close];
	[notificationWindowController setDelegate:nil];
	notificationWindowController = nil;
}


#pragma mark NSWindow Delegate

- (void)windowWillClose:(NSNotification *)notification
{
	NSWindow *window = [notification object];
	
	if ([window isEqualTo:[preferencesWindowController window]]) 
	{
		[preferencesWindowController.window setDelegate:nil];
		preferencesWindowController = nil;
	}
	else if ([window isEqualTo:[lyricsWindowController window]])
	{
		[lyricsWindowController.window setDelegate:nil];
		lyricsWindowController = nil;
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


- (void)showLyricsWindow
{
	if (lyricsWindowController == nil) 
	{
		lyricsWindowController = [[LyricsWindowController alloc] init];
		[lyricsWindowController.window setDelegate:self];
        [lyricsWindowController.window center];
	}
	
	lyricsWindowController.track = [[iTunesController sharedInstance] currentTrack];
	
	if ([[lyricsWindowController.track lyrics] length] == 0) 
	{
		// Start fetching
        if (!self.mainLyricsFetcher)
        {
            self.mainLyricsFetcher = [[LyricsFetcher alloc] init];
            [self.mainLyricsFetcher setDelegate:self];
        }
        
		[self.mainLyricsFetcher fetchLyricsForTrack:[lyricsWindowController track]];
	}
	
	[lyricsWindowController showWindow:self];
    [NSApp activateIgnoringOtherApps:YES];
}


- (void)showPreferencesWindow
{
	if (preferencesWindowController == nil) 
	{
		preferencesWindowController = [[PreferencesWindowController alloc] init];
		[preferencesWindowController.window setDelegate:self];
	}
	
	[preferencesWindowController showWindow:self];
	[NSApp activateIgnoringOtherApps:YES];
}

@end

NSString *CONotificationCorner = @"NotificationCorner";
