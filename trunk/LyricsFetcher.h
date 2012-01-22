//
//  LyricsFetcher.h
//  LyricsFetcher
//
//  Created by Toomas Vahter on 22.12.11.
//  Copyright (c) 2011 Toomas Vahter. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "iTunes.h"


@class PlugInManager;
@protocol LyricsFetcherDelegate;

@interface LyricsFetcher : NSObject
{
	NSOperationQueue *fetchingQueue;
}

+ (LyricsFetcher *)sharedFetcher;

@property (nonatomic, readonly, strong) PlugInManager *pluginManager;
@property (nonatomic, weak) id delegate;

- (void)fetchLyricsForTrack:(iTunesTrack *)track;

@end


@protocol LyricsFetcherDelegate <NSObject>
- (void)lyricsFetcher:(LyricsFetcher *)fetcher didFetchLyrics:(NSString *)lyrics forTrack:(iTunesTrack *)track;
@end
