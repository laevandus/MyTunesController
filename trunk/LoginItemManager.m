//
//  LoginItemManager.m
//  LoginItemManager
//
//  Created by Toomas Vahter on 05.02.12.
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

#import "LoginItemManager.h"


@implementation LoginItemManager


- (BOOL)addItemAtURL:(NSURL *)bundleURL
{
	BOOL result = NO;
	LSSharedFileListRef loginListRef = LSSharedFileListCreate(NULL, kLSSharedFileListSessionLoginItems, NULL);
	
	if (loginListRef) 
	{
		LSSharedFileListItemRef loginItemRef = LSSharedFileListInsertItemURL(loginListRef, kLSSharedFileListItemLast, NULL, NULL, (__bridge CFURLRef)bundleURL, NULL, NULL);             
		
		if (loginItemRef) 
		{
			result = YES;
			CFRelease(loginItemRef);
		}
		
		CFRelease(loginListRef);
	}
	
	return result;
}


- (BOOL)removeItemAtURL:(NSURL *)bundleURL
{
	BOOL result = NO;
	LSSharedFileListRef loginListRef = LSSharedFileListCreate(NULL, kLSSharedFileListSessionLoginItems, NULL);
	
	if (loginListRef) 
	{
		CFArrayRef loginItemsArrayRef = LSSharedFileListCopySnapshot(loginListRef, NULL);
		NSArray *loginItemsArray = [[NSArray alloc] initWithArray:(__bridge NSArray *)loginItemsArrayRef];
		
		for (id itemRef in loginItemsArray) 
		{		
			CFURLRef itemURLRef = NULL;
			
			if (LSSharedFileListItemResolve((__bridge LSSharedFileListItemRef)itemRef, 0, &itemURLRef, NULL) == noErr) 
			{
				if ([(__bridge NSURL *)itemURLRef isEqual:bundleURL])
				{
					result = (LSSharedFileListItemRemove(loginListRef, (__bridge LSSharedFileListItemRef)itemRef) == noErr);
				}
			}
			
			if (itemURLRef) 
			{
				CFRelease(itemURLRef);
			}
		}
		
		CFRelease(loginItemsArrayRef);
		CFRelease(loginListRef);
	}
	
	return result;
}


- (BOOL)itemExistsAtURL:(NSURL *)bundleURL
{
	BOOL result = NO;
	LSSharedFileListRef loginListRef = LSSharedFileListCreate(NULL, kLSSharedFileListSessionLoginItems, NULL);
	
	if (loginListRef) 
	{
		CFArrayRef loginItemsArrayRef = LSSharedFileListCopySnapshot(loginListRef, NULL);
		NSArray *loginItemsArray = [[NSArray alloc] initWithArray:(__bridge NSArray *)loginItemsArrayRef];
		
		for (id itemRef in loginItemsArray) 
		{
			CFURLRef itemURLRef = NULL;
			
			if (LSSharedFileListItemResolve((__bridge LSSharedFileListItemRef)itemRef, 0,&itemURLRef, NULL) == noErr) 
			{
				if ([(__bridge NSURL *)itemURLRef isEqual:bundleURL])
				{
					result = YES;
				}
			}
			
			if (itemURLRef) 
			{
				CFRelease(itemURLRef);
			}
			
			if (result) 
			{
				break;
			}
		}
		
		CFRelease(loginItemsArrayRef);
		CFRelease(loginListRef);
	}
	
	return result;
}


@end
