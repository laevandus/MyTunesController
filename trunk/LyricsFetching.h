//
//  LyricsFetching.h
//  LyricsFetcher
//
//  Created by Toomas Vahter on 22.12.11.
//  Copyright (c) 2011 Toomas Vahter. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol LyricsFetching <NSObject>

// TODO: versioning

- (NSString *)name;

// Return nil if nothing found.
- (NSString *)lyricsForTrackName:(NSString *)name artist:(NSString *)artist album:(NSString *)album;

@end
