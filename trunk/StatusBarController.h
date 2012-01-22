//
//  StatusBarController.h
//  MyTunesController
//
//  Created by Toomas Vahter on 21.01.12.
//  Copyright (c) 2012 Toomas Vahter. All rights reserved.
//

#import <Foundation/Foundation.h>

@class StatusView;

@interface StatusBarController : NSObject
{
	NSStatusItem *mainItem, *controllerItem;
}

@property (nonatomic, weak) IBOutlet NSButton *playButton;
@property (nonatomic, weak) IBOutlet id sparkleController;
@property (nonatomic, weak) IBOutlet StatusView *statusView;

- (IBAction)playPrevious:(id)sender;
- (IBAction)playPause:(id)sender;
- (IBAction)playNext:(id)sender;

- (void)addStatusItems;
- (void)updatePlayButtonState;

@end
