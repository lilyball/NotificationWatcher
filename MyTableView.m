//
//  MyTableView.m
//  Notification Watcher
//
//  Created by Kevin Ballard on Tue Mar 16 2004.
//  Copyright (c) 2004 TildeSoft. All rights reserved.
//

#import "MyTableView.h"

@implementation MyTableView

- (unsigned int)draggingSourceOperationMaskForLocal:(BOOL)isLocal
{
    if (isLocal) {
        return NSDragOperationMove;
    } else {
        return NSDragOperationCopy;
    }
}

- (IBAction)copy:(id)sender
{
    NSMutableArray *rows = [NSMutableArray array];
    NSEnumerator *e = [self selectedRowEnumerator];
    id aRow;
    while (aRow = [e nextObject]) {
        [rows addObject:aRow];
    }
    NSPasteboard *pb = [NSPasteboard generalPasteboard];
    [[self dataSource] tableView:self writeRows:rows toPasteboard:pb];
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
