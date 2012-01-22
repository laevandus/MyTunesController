//
//  TrackDurationValueTransformer.m
//  MyTunesController
//
//  Created by Toomas Vahter on 05.11.10.
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

#import "iTunesTrackDurationValueTransformer.h"


@implementation iTunesTrackDurationValueTransformer

+ (Class)transformedValueClass 
{ 
	return [NSString class]; 
}


+ (BOOL)allowsReverseTransformation 
{ 
	return NO; 
}


- (id)transformedValue:(id)value 
{
	if ([value isKindOfClass:[NSNumber class]]) 
	{
		CGFloat floatValue = [value floatValue];
		
		if (floatValue > 0.0) 
		{
			NSUInteger duration = floatValue + 0.5;
			NSUInteger minutes = 0;
			
			while (duration >= 60) 
			{
				duration -= 60;
				minutes++;
			}
			
			if (duration < 10) 
				value = [NSString stringWithFormat:@"%d:0%d", minutes, duration];
			else 
				value = [NSString stringWithFormat:@"%d:%d", minutes, duration];
		}
		else 
		{
			value = nil;
		}
	}
	
	return value;
}

@end
