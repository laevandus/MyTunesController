//
//  FetchOperation.h
//  MyTunesController
//
//  Created by Toomas Vahter on 13.02.12.
//  Copyright (c) 2012 Toomas Vahter. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "iTunes.h"


@protocol FetchOperationDelegate;

@interface FetchOperation : NSOperation

// Designated initializer
- (id)initWithTracks:(NSArray *)tracks;

@property (weak) id delegate;
@property (readonly, strong) NSArray *tracks;

@end


@protocol FetchOperationDelegate <NSObject>
- (void)fetchOperation:(FetchOperation *)operation didFetchLyrics:(NSString *)lyrics forTrack:(iTunesTrack *)track;
@end
