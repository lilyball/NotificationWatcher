//
//  ArrayExtensions.m
//  Notification Watcher
//
//  Created by Kevin Ballard on Tue Mar 16 2004.
//  Copyright (c) 2004 TildeSoft. All rights reserved.
//

#import "Extensions.h"

@implementation NSArray (ArrayExtensions)
- (NSString*)joinWithSeparator:(NSString*)sep
{
    NSMutableString *result = [NSMutableString string];
    BOOL isFirst = YES;
    NSEnumerator *e = [self objectEnumerator];
    id anObj;
    if (sep == nil) {
        sep = @",";
    }
    while (anObj = [e nextObject]) {
        if (isFirst) {
            isFirst = NO;
        } else {
            [result appendString:sep];
        }
        [result appendFormat:@"%@", anObj];
        /*if ([anObj isKindOfClass:[NSString class]]) {
            [result appendString:anObj];
        } else if ([anObj respondsToSelector:@selector(stringValue)]) {
            [result appendString:<#(NSString *)aString#>]*/
    }
    return result;
}
@end