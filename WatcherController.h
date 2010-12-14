/* WatcherController */

#import <Cocoa/Cocoa.h>

@interface WatcherController : NSObject {
	IBOutlet NSWindow *prefsWindow;
    IBOutlet NSTextField *objectText;
    IBOutlet NSTableView *distNotificationList;
    IBOutlet NSTableView *wsNotificationList;
    IBOutlet NSTableView *userInfoList;
    NSMutableArray *distNotifications;
    NSMutableArray *wsNotifications;
    NSNotification *selectedDistNotification;
    NSNotification *selectedWSNotification;
	NSMutableArray *savedRowHeights;
}
- (IBAction)clearNotifications:(id)sender;
- (IBAction)showPrefs:(id)sender;
- (void)selectNotification:(NSNotification*)aNotification;
- (void)distNotificationHook:(NSNotification*)aNotification;
- (void)wsNotificationHook:(NSNotification*)aNotification;
@end
