//
//  MyTableView.m
//  Notification Watcher
//
//  Created by Kevin Ballard on Tue Mar 16 2004.
//  Copyright (c) 2004 TildeSoft. All rights reserved.
//

#import "MyTableView.h"

@implementation MyTableView

- (NSDragOperation)draggingSourceOperationMaskForLocal:(BOOL)isLocal
{
    if (isLocal) {
        return NSDragOperationMove;
    } else {
        return NSDragOperationCopy;
    }
}

- (IBAction)copy:(id __unused)sender
{
    NSPasteboard *pb = [NSPasteboard generalPasteboard];
	[[self dataSource] tableView:self writeRowsWithIndexes:[self selectedRowIndexes] toPasteboard:pb];
}

- (BOOL)becomeFirstResponder
{
    NSNotification *pseudoNotification = [NSNotification
                    notificationWithName:NSTableViewSelectionDidChangeNotification
                                  object:self];
    [[NSNotificationCenter defaultCenter] postNotification:pseudoNotification];
    return [super becomeFirstResponder];
}

@end
