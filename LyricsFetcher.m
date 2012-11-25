//
//  LyricsFetcher.m
//  LyricsFetcher
//
//  Created by Toomas Vahter on 22.12.11.
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

#import "LyricsFetcher.h"
#import "LyricsFetching.h"
#import "FetchOperation.h"

@interface LyricsFetcher ()
@property (nonatomic, readwrite, getter = isFetching) BOOL fetching;
@end

@implementation LyricsFetcher

- (id)init
{
	if ((self = [super init])) 
	{		
		// Create serial queue
		fetchingQueue = [[NSOperationQueue alloc] init];
		[fetchingQueue setMaxConcurrentOperationCount:1];
	}
	
	return self;
}


- (void)dealloc
{
	[self cancelAllFetches];
	[fetchingQueue waitUntilAllOperationsAreFinished];
}


- (void)cancelAllFetches
{	
	[fetchingQueue cancelAllOperations];
    self.fetching = NO;
}


- (void)fetchLyricsForTrack:(iTunesTrack *)track
{
	[self fetchLyricsForTracks:@[track]];
}


- (void)fetchLyricsForTracks:(NSArray *)tracks
{
	FetchOperation *operation = [[FetchOperation alloc] initWithTracks:tracks];
	[operation setDelegate:self];
	[fetchingQueue addOperation:operation];
}


- (void)fetchOperation:(FetchOperation *)operation didFetchLyrics:(NSString *)lyrics forTrack:(iTunesTrack *)track
{    
	if ([self.delegate respondsToSelector:@selector(lyricsFetcher:didFetchLyrics:forTrack:)])
	{
		[self.delegate lyricsFetcher:self didFetchLyrics:lyrics forTrack:track];
	}
}


- (void)fetchOperationDidFinishFetching:(FetchOperation *)operation
{
    self.fetching = [fetchingQueue operationCount] > 1;
}

@end
