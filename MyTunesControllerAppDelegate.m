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
- (NSPoint)notificationWindowOriginForWindowSize:(NSSize)windowSize;

- (void)fetchLyricsForTrackIfNeeded:(iTunesTrack *)track;
- (void)cleanUpMainLyricsFetcher;
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
		[self fetchLyricsForTrackIfNeeded:newTrack];
	}
    
    // Do not show notification window
	if (newTrack == nil) 
		return;
	
	if ([[iTunesController sharedInstance] isPlaying]) 
	{
		if (notificationWindowController) 
		{
            [NSObject cancelPreviousPerformRequestsWithTarget:notificationWindowController];
			[notificationWindowController close];
            notificationWindowController.delegate = nil;
			notificationWindowController = nil;
		}
		
		if ([[newTrack name] length]) 
		{            
			notificationWindowController = [[NotificationWindowController alloc] init];
			[notificationWindowController setDelegate:self];
			[notificationWindowController setTrack:newTrack];
			[notificationWindowController fitToContent];
            
            NSRect windowFrame = notificationWindowController.window.frame;
            windowFrame.origin = [self notificationWindowOriginForWindowSize:windowFrame.size];
            [notificationWindowController.window setFrame:windowFrame display:NO];
            
			[notificationWindowController showWindow:self];
            [notificationWindowController performSelector:@selector(disappear) withObject:nil afterDelay:5.0];
		}
	}
	else 
	{
		[notificationWindowController disappear];
	}
}


- (NSPoint)notificationWindowOriginForWindowSize:(NSSize)windowSize
{
    NSRect visibleFrame = [[NSScreen mainScreen] visibleFrame];
	NSPoint origin = NSZeroPoint;
	
	switch (notificationCorner)
	{
		case 0:	// left up
			origin = NSMakePoint(NSMinX(visibleFrame) + 20.f, NSMaxY(visibleFrame) - windowSize.height - 20.f);
			break;
		case 1:	// left down
			origin = NSMakePoint(NSMinX(visibleFrame) + 20.f, NSMinY(visibleFrame) + 20.f);
			break;
		case 2: // right up
			origin = NSMakePoint(NSMaxX(visibleFrame) - windowSize.width - 20.f, NSMaxY(visibleFrame) - windowSize.height - 20.f);
			break;
		case 3: // right down
			origin = NSMakePoint(NSMaxX(visibleFrame) - windowSize.width - 20.f, NSMinY(visibleFrame) + 20.f);
			break;
		default:
			break;
	}
    
    return origin;
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
        
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(cleanUpMainLyricsFetcher) object:nil];
        [self performSelector:@selector(cleanUpMainLyricsFetcher) withObject:nil afterDelay:60.0];
	}
	else
	{
		NSLog(@"%s ignored LyricsFetcher (%@) in AppDelegate", __func__, fetcher);
	}
}


- (void)fetchLyricsForTrackIfNeeded:(iTunesTrack *)track
{
    if (track && [track.lyrics length] == 0)
    {
        if ([NetworkReachability hasInternetConnection])
        {
            // Start fetching
            if (!self.mainLyricsFetcher)
            {
                self.mainLyricsFetcher = [[LyricsFetcher alloc] init];
                [self.mainLyricsFetcher setDelegate:self];
            }
            
            [self.mainLyricsFetcher fetchLyricsForTrack:track];
        }
    }
}


- (void)cleanUpMainLyricsFetcher
{
    if (!self.mainLyricsFetcher.isFetching)
    {
        self.mainLyricsFetcher = nil;
    }
}


#pragma mark NotificationWindowController Delegate

- (void)notificationDidDisappear:(NotificationWindowController *)notification
{
    [NSObject cancelPreviousPerformRequestsWithTarget:notificationWindowController];
	[notificationWindowController close];
	notificationWindowController.delegate = nil;
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
	
    iTunesTrack *track = [[iTunesController sharedInstance] currentTrack];
    
	lyricsWindowController.track = track;
	[self fetchLyricsForTrackIfNeeded:track];
	
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
