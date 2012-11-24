//
//  FetchOperation.m
//  MyTunesController
//
//  Created by Toomas Vahter on 13.02.12.
//  Copyright (c) 2012 Toomas Vahter. All rights reserved.
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

#import "FetchOperation.h"
#import "iTunes.h"
#import "PlugInManager.h"
#import "iTunesController.h"
#import "LyricsFetching.h"
#import "NetworkReachability.h"

@interface FetchOperation()
@property (readwrite, strong) NSArray *tracks;
- (iTunesTrack *)_searchTrackWithDatabaseID:(NSInteger)trackDatabaseID;
- (NSString *)_fetchLyricsForTrack:(iTunesTrack *)track;
@end

@implementation FetchOperation

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
		CGFloat minimumOperationTimeInSeconds = 0.5;
		NSInteger currentTrackDatabaseID = 0;
		NSUInteger trackCounter = 0;
		iTunesTrack *track = nil;
		
		NSArray *modes = @[NSRunLoopCommonModes];
		NSDictionary *fetchInfo = nil;
		
		for (track in self.tracks)
		{
			if ([NetworkReachability hasInternetConnection])
			{
                // Get new reference which does not depend on currentTrack. currentTrack reference changes in the lifetime of the application and therefore I might get invalid object I am setting lyrics to in the delegate.
                startTime = CFAbsoluteTimeGetCurrent();
				
                currentTrackDatabaseID = [[[iTunesController sharedInstance] currentTrack] databaseID];
                isCurrentTrack = ([track databaseID] == currentTrackDatabaseID);
                track = isCurrentTrack ? nil : track;
				
                if (track == nil)
                {
                    track = [self _searchTrackWithDatabaseID:currentTrackDatabaseID];
                }
				
                if (track)
                {
                    NSString *lyrics = [self _fetchLyricsForTrack:track];
					
                    if ([self isCancelled])
                    {
                        break;
                    }
					
                    // Tell delegate about the result on the main thread
                    fetchInfo = @{@"lyrics": lyrics, @"track": track};
                    [self performSelectorOnMainThread:@selector(finalizeFetchingWithInfo:) withObject:fetchInfo waitUntilDone:YES modes:modes];
					
                    // Reduce the interval of querying websites
                    CFAbsoluteTime spentTimeInSeconds = CFAbsoluteTimeGetCurrent() - startTime;
					
                    if (spentTimeInSeconds < minimumOperationTimeInSeconds)
                    {
                        useconds_t time = (useconds_t)((minimumOperationTimeInSeconds - spentTimeInSeconds) * 1000000.0);
                        usleep(time);
                    }
                }
                else
                {
                    NSLog(@"Failed to find track for database ID %ld", [track databaseID]);
                }
            }
            else
            {
                // Internet connection is down, tell delegate we did not get any lyrics
                fetchInfo = @{@"lyrics": @"", @"track": track};
                [self performSelectorOnMainThread:@selector(finalizeFetchingWithInfo:) withObject:fetchInfo waitUntilDone:YES modes:modes];
				
                // Wait a little bit before checking internet connection again
                usleep(20000);
            }
			
            if ([self isCancelled])
            {
                break;
            }
			
            trackCounter++;
        }
	}
}


- (void)finalizeFetchingWithInfo:(NSDictionary *)fetchInfo
{
	if ([[self delegate] respondsToSelector:@selector(fetchOperation:didFetchLyrics:forTrack:)])
	{
		[[self delegate] fetchOperation:self didFetchLyrics:fetchInfo[@"lyrics"] forTrack:fetchInfo[@"track"]];
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
			
			bundleInstance = plugIns[j];
			
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
