//
//  ArrayExtensions.h
//  Notification Watcher
//
//  Created by Kevin Ballard on Tue Mar 16 2004.
//  Copyright (c) 2004 TildeSoft. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSArray (ArrayExtensions)
- (NSString*)joinWithSeparator:(NSString*)sep;
@end

@interface NSTableView (TableViewExtensions)
- (unsigned int)draggingSourceOperationMaskForLocal:(BOOL)isLocal;
- (IBAction)copy:(id)sender;
@end