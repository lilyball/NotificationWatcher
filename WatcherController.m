#import "WatcherController.h"
#import "Globals.h"
#import "Extensions.h"
#import <mach-o/dyld.h>

static NSDictionary *italicAttributesForFont(NSFont *aFont)
{
	NSFont *newFont = [[NSFontManager sharedFontManager] convertFont:aFont
														 toHaveTrait:NSItalicFontMask];
	NSDictionary *attrDict;
	if (![newFont isEqual:aFont]) {
		attrDict = [NSDictionary dictionaryWithObject:newFont
											   forKey:NSFontAttributeName];
	} else {
		// NSObliquenessAttributeName isn't available on Jaguar
		if (NSIsSymbolNameDefined("_NSObliquenessAttributeName")) {
			NSSymbol attrSymbol = NSLookupAndBindSymbol("_NSObliquenessAttributeName");
			NSString *attr = *(NSString **)NSAddressOfSymbol(attrSymbol);
			attrDict = [NSDictionary dictionaryWithObject:[NSNumber numberWithFloat:0.16]
												   forKey:attr];
		} else {
			attrDict = [NSDictionary dictionary];
		}
	}
	return attrDict;
}

@implementation WatcherController

- (id)init
{
	if (self = [super init]) {
		distNotifications = [[NSMutableArray alloc] init];
		wsNotifications = [[NSMutableArray alloc] init];
		[[NSDistributedNotificationCenter defaultCenter] addObserver:self
															selector:@selector(distNotificationHook:)
																name:nil object:nil];
		[[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self
															   selector:@selector(wsNotificationHook:)
																   name:nil object:nil];
		NSMutableDictionary *defaults = [NSMutableDictionary dictionary];
		[defaults setObject:@"NO" forKey:kHideProcessSwitchNotificationPref];
		[[NSUserDefaults standardUserDefaults] registerDefaults:defaults];
	}
	return self;
}

- (void)awakeFromNib
{
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	[nc addObserver:self selector:@selector(selectNotification:)
			   name:NSTableViewSelectionDidChangeNotification object:distNotificationList];
	[nc addObserver:self selector:@selector(selectNotification:)
			   name:NSTableViewSelectionDidChangeNotification object:wsNotificationList];
}

- (void)dealloc
{
	[[NSDistributedNotificationCenter defaultCenter] removeObserver:self];
	[[[NSWorkspace sharedWorkspace] notificationCenter] removeObserver:self];
	[selectedDistNotification release];
	[selectedWSNotification release];
	[distNotifications release];
	[wsNotifications release];
	[super dealloc];
}

- (IBAction)showPrefs:(id)sender {
	[prefsWindow makeKeyAndOrderFront:sender];
}

- (void)distNotificationHook:(NSNotification*)aNotification
{
	if ([[NSUserDefaults standardUserDefaults] boolForKey:kHideProcessSwitchNotificationPref]) {
		if ([[aNotification name] isEqualToString:@"com.apple.HIToolbox.menuBarShownNotification"] ||
			[[aNotification name] isEqualToString:@"AppleSystemUIModeChanged"])
			return;
	}
	NSRect visibleRect = [distNotificationList visibleRect];
	NSRect bounds = [distNotificationList bounds];
	BOOL atBottom = ((visibleRect.origin.y + visibleRect.size.height) ==
						(bounds.origin.y + bounds.size.height));
	[distNotifications addObject:[[aNotification copy] autorelease]];
	[distNotificationList noteNumberOfRowsChanged];
	if (atBottom) {
		[distNotificationList scrollRowToVisible:[distNotificationList numberOfRows] - 1];
	}
}

- (void)wsNotificationHook:(NSNotification*)aNotification
{
	NSRect visibleRect = [wsNotificationList visibleRect];
	NSRect bounds = [wsNotificationList bounds];
	BOOL atBottom = ((visibleRect.origin.y + visibleRect.size.height) ==
					 (bounds.origin.y + bounds.size.height));
	[wsNotifications addObject:[[aNotification copy] autorelease]];
	[wsNotificationList noteNumberOfRowsChanged];
	if (atBottom) {
		[wsNotificationList scrollRowToVisible:[wsNotificationList numberOfRows] - 1];
	}
}

- (void)selectNotification:(NSNotification*)aNotification
{
	id sender = [aNotification object];
	[selectedDistNotification release];
	selectedDistNotification = nil;
	[selectedWSNotification release];
	selectedWSNotification = nil;
	NSNotification **targetVar;
	NSArray **targetList;
	if (sender == distNotificationList) {
		targetVar = &selectedDistNotification;
		targetList = &distNotifications;
	} else {
		targetVar = &selectedWSNotification;
		targetList = &wsNotifications;
	}
	if ([sender selectedRow] != -1) {
		[[*targetList objectAtIndex:[sender selectedRow]] retain];
		[*targetVar release];
		*targetVar = [*targetList objectAtIndex:[sender selectedRow]];
	}
	if (*targetVar == nil) {
		[objectText setStringValue:@""];
	} else {
		id obj = [*targetVar object];
		NSMutableAttributedString *objStr = nil;
		if (obj == nil) {
			NSFont *aFont = [objectText font];
			NSDictionary *attrDict = italicAttributesForFont(aFont);
			objStr = [[NSMutableAttributedString alloc] initWithString:@"(null)"
															attributes:attrDict];
		} else {
			objStr = [[NSMutableAttributedString alloc] initWithString:
						[NSString stringWithFormat:@" (%@)", [obj className]]];
			[objStr addAttributes:italicAttributesForFont([objectText font])
							range:NSMakeRange(1,[[obj className] length]+2)];
			if ([obj isKindOfClass:[NSString class]]) {
				[objStr replaceCharactersInRange:NSMakeRange(0,0) withString:obj];
			} else if ([obj respondsToSelector:@selector(stringValue)]) {
				[objStr replaceCharactersInRange:NSMakeRange(0,0)
									  withString:[obj performSelector:@selector(stringValue)]];
			} else {
				// Remove the space since we have no value to display
				[objStr replaceCharactersInRange:NSMakeRange(0,1) withString:@""];
			}
		}
		[objectText setObjectValue:objStr];
		[objStr release];
	}
	[userInfoList reloadData];
}

- (IBAction)clearNotifications:(id)sender
{
	[selectedDistNotification release];
	selectedDistNotification = nil;
	[selectedWSNotification release];
	selectedWSNotification = nil;
	[distNotifications removeAllObjects];
	[wsNotifications removeAllObjects];
	[distNotificationList reloadData];
	[wsNotificationList reloadData];
	[objectText setStringValue:@""];
	[userInfoList reloadData];
}

- (int)numberOfRowsInTableView:(NSTableView *)aTableView
{
	if (aTableView == distNotificationList) {
		return [distNotifications count];
	} else if (aTableView == wsNotificationList) {
		return [wsNotifications count];
	} else {
		if (selectedDistNotification == nil && selectedWSNotification == nil) {
			return 0;
		} else if (selectedDistNotification == nil) {
			return [[selectedWSNotification userInfo] count];
		} else {
			return [[selectedDistNotification userInfo] count];
		}
	}
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn
			row:(int)rowIndex
{
	if (aTableView == distNotificationList) {
		return [[distNotifications objectAtIndex:rowIndex] name];
	} else if (aTableView == wsNotificationList) {
		return [[wsNotifications objectAtIndex:rowIndex] name];
	} else {
		if (selectedDistNotification == nil && selectedWSNotification == nil) {
			return @"";
		} else {
			NSNotification **targetVar;
			if (selectedDistNotification == nil) {
				targetVar = &selectedWSNotification;
			} else {
				targetVar = &selectedDistNotification;
			}
			if ([[aTableColumn identifier] isEqualToString:@"key"]) {
				return [[[*targetVar userInfo] allKeys] objectAtIndex:rowIndex];
			} else {
				return [[[*targetVar userInfo] allValues] objectAtIndex:rowIndex];
			}
		}
	}
}

- (BOOL)tableView:(NSTableView *)tableView writeRows:(NSArray *)rows
	 toPasteboard:(NSPasteboard *)pboard
{
	NSMutableArray *rowStrings = [NSMutableArray array];
	NSEnumerator *e = [rows objectEnumerator];
	id aRow;
	while (aRow = [e nextObject]) {
		NSMutableArray *columnStrings = [NSMutableArray array];
		NSArray *columns = [tableView tableColumns];
		NSEnumerator *colEnum = [columns objectEnumerator];
		NSTableColumn *aColumn;
		while (aColumn = [colEnum nextObject]) {
			[columnStrings addObject:[self tableView:tableView
						   objectValueForTableColumn:aColumn
												 row:[aRow intValue]]];
		}
		[rowStrings addObject:[columnStrings joinWithSeparator:@"\t"]];
	}
	[pboard declareTypes:[NSArray arrayWithObject:NSStringPboardType] owner:nil];
	[pboard setString:[rowStrings joinWithSeparator:@"\r"] forType:NSStringPboardType];
	return YES;
}

@end
