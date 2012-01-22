//
//  PluginManager.h
//  LyricsFetcher
//
//  Created by Toomas Vahter on 26.12.11.
//  Copyright (c) 2011 Toomas Vahter. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PlugInManager : NSObject
@property (readonly, retain) NSArray *plugIns; // Array of loaded and validated NSBundle instances. Atomic!
@end
