//
//  MyTableView.h
//  Notification Watcher
//
//  Created by Kevin Ballard on Tue Mar 16 2004.
//  Copyright (c) 2004 TildeSoft. All rights reserved.
//

#import <AppKit/AppKit.h>

@interface MyTableView : NSTableView {
    
}
- (unsigned int)draggingSourceOperationMaskForLocal:(BOOL)isLocal;
- (IBAction)copy:(id)sender;
- (BOOL)becomeFirstResponder;

@end
