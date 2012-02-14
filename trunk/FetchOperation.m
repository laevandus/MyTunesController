//
//  FetchOperation.m
//  MyTunesController
//
//  Created by Toomas Vahter on 13.02.12.
//  Copyright (c) 2012 Toomas Vahter. All rights reserved.
//

#import "FetchOperation.h"
#import "iTunes.h"
#import "PlugInManager.h"
#import "iTunesController.h"
#import "LyricsFetching.h"


@interface FetchOperation()
- (iTunesTrack *)_searchTrackWithDatabaseID:(NSInteger)trackDatabaseID;
- (NSString *)_fetchLyricsForTrack:(iTunesTrack *)track;
@end


@implementation FetchOperation

@synthesize delegate = _delegate;
@synthesize tracks = _tracks;


- (id)initWithTracks:(NSArray *)tracks
{
	if ((self = [super init])) 
	{
		_tracks = tracks;
	}
	
	return self;
}


- (void)main
{
	// Run as part of a operation
	@autoreleasepool 
	{
		BOOL isCurrentTrack = NO;
		CFAbsoluteTime startTime;
		CGFloat minimumOperationTimeInSeconds = 0.250;
		iTunesTrack *track = nil;
		
		for (track in self.tracks) 
		{
			// Get new reference which does not depend on currentTrack. currentTrack reference changes in the lifetime of the application and therefore I might get invalid object I am setting lyrics to in the delegate.
			startTime = CFAbsoluteTimeGetCurrent();
			
			isCurrentTrack = ([track databaseID] == [[[iTunesController sharedInstance] currentTrack] databaseID]);
			track = isCurrentTrack ? nil : track;
			
			if (track == nil) 
			{
				track = [self _searchTrackWithDatabaseID:[track databaseID]];
			}
			
			if (track)
			{
				NSString *lyrics = [self _fetchLyricsForTrack:track];
				
				if ([self isCancelled]) 
				{
					break;
				}
				
				// Tell delegate about the result on the main thread
				NSArray *modes = [NSArray arrayWithObject:NSRunLoopCommonModes];
				NSDictionary *fetchInfo = [NSDictionary dictionaryWithObjectsAndKeys:lyrics, @"lyrics", track, @"track", nil];
				[self performSelectorOnMainThread:@selector(finalizeFetchingWithInfo:) withObject:fetchInfo waitUntilDone:YES modes:modes];
				
				// Reduce the interval of querying websites
				CFAbsoluteTime spentTimeInSeconds = CFAbsoluteTimeGetCurrent() - startTime;
				
				if (spentTimeInSeconds < minimumOperationTimeInSeconds) 
				{
					usleep((minimumOperationTimeInSeconds - spentTimeInSeconds) * 1000000.0);
				}
			}
			else
			{
				NSLog(@"Failed to find track for database ID %ld", [track databaseID]);
			}
			
			if ([self isCancelled]) 
			{
				break;
			}
		}
	}
}


- (void)finalizeFetchingWithInfo:(NSDictionary *)fetchInfo
{
	if ([[self delegate] respondsToSelector:@selector(fetchOperation:didFetchLyrics:forTrack:)]) 
	{
		[[self delegate] fetchOperation:self didFetchLyrics:[fetchInfo objectForKey:@"lyrics"] forTrack:[fetchInfo objectForKey:@"track"]];
	}
}


- (iTunesTrack *)_searchTrackWithDatabaseID:(NSInteger)trackDatabaseID
{
	__block iTunesTrack *track = nil;
	iTunesPlaylist *musicPlaylist = [[iTunesController sharedInstance] playlistWithName:@"Music"];
	
	[[musicPlaylist tracks] enumerateObjectsUsingBlock:^(id object, NSUInteger index, BOOL *stop)
	 {
		 if ([object databaseID] == trackDatabaseID) 
		 {
			 track = (iTunesTrack *)object;
			 *stop = YES;
		 }
	 }];
	
	return track;
}


- (NSString *)_fetchLyricsForTrack:(iTunesTrack *)track
{
	// Track must have name and artist for fetching
	NSString *fetchedLyrics = nil;
	NSArray *plugIns = [[PlugInManager defaultManager] plugIns];
	
	if ([track.name length] && [track.artist length]) 
	{
		// Randomize plugins for distributing the load
		NSUInteger offset = rand() % ([plugIns count] + 1);
		id bundleInstance = nil;
		
		for (NSUInteger i = 0; i < [plugIns count]; i++) 
		{
			NSUInteger j = i + offset;
			
			if (j >= [plugIns count]) 
			{
				j = j - [plugIns count];
			}
			
			bundleInstance = [plugIns objectAtIndex:j];
			
			fetchedLyrics = [(id<LyricsFetching>)bundleInstance lyricsForTrackName:[track name] artist:[track artist] album:[track album]];
			
			if ([fetchedLyrics length] > 0 || [self isCancelled]) 
			{
				break;
			}
		}
	}
	
	return fetchedLyrics ? fetchedLyrics : @"";
}

@end
