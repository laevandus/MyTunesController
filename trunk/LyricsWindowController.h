//
//  LyricsWindowController.h
//  MyTunesController
//
//  Created by Toomas Vahter on 21.01.12.
//  Copyright (c) 2012 Toomas Vahter. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "iTunes.h"

@interface LyricsWindowController : NSWindowController

@property (nonatomic, strong) iTunesTrack *track;

@property (nonatomic, readonly) NSAttributedString *attributedLyrics;
@property (nonatomic, readonly) NSString *trackDescription;

- (IBAction)clear:(id)sender;
- (IBAction)fetch:(id)sender;

@end
