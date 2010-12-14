#import "WatcherController.h"
#import "Globals.h"
#import "Extensions.h"
#import <mach-o/dyld.h>

static NSDictionary *italicAttributesForFont(NSFont *aFont) {
	NSFont *newFont = [[NSFontManager sharedFontManager] convertFont:aFont
														 toHaveTrait:NSItalicFontMask];
	NSDictionary *attrDict;
	if (![newFont isEqual:aFont]) {
		attrDict = [NSDictionary dictionaryWithObject:newFont
											   forKey:NSFontAttributeName];
	} else {
		attrDict = [NSDictionary dictionaryWithObject:[NSNumber numberWithFloat:0.16]
											   forKey:NSObliquenessAttributeName];
	}
	return attrDict;
}

@implementation WatcherController

- (id)init {
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

- (void)awakeFromNib {
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	[nc addObserver:self selector:@selector(selectNotification:)
			   name:NSTableViewSelectionDidChangeNotification object:distNotificationList];
	[nc addObserver:self selector:@selector(selectNotification:)
			   name:NSTableViewSelectionDidChangeNotification object:wsNotificationList];
}

- (void)dealloc {
	[[NSDistributedNotificationCenter defaultCenter] removeObserver:self];
	[[[NSWorkspace sharedWorkspace] notificationCenter] removeObserver:self];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[selectedDistNotification release];
	[selectedWSNotification release];
	[distNotifications release];
	[wsNotifications release];
	[super dealloc];
}

- (IBAction)showPrefs:(id)sender {
	[prefsWindow makeKeyAndOrderFront:sender];
}

- (void)distNotificationHook:(NSNotification*)aNotification {
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

- (void)wsNotificationHook:(NSNotification*)aNotification {
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

- (void)selectNotification:(NSNotification*)aNotification {
	id sender = [aNotification object];
	[selectedDistNotification release];
	selectedDistNotification = nil;
	[selectedWSNotification release];
	selectedWSNotification = nil;
	[savedRowHeights release];
	savedRowHeights = nil;
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
		[*targetVar autorelease];
		*targetVar = [[*targetList objectAtIndex:[sender selectedRow]] retain];
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

- (IBAction)clearNotifications:(id)sender {
	[selectedDistNotification release];
	selectedDistNotification = nil;
	[selectedWSNotification release];
	selectedWSNotification = nil;
	[savedRowHeights release];
	savedRowHeights = nil;
	[distNotifications removeAllObjects];
	[wsNotifications removeAllObjects];
	[distNotificationList reloadData];
	[wsNotificationList reloadData];
	[objectText setStringValue:@""];
	[userInfoList reloadData];
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView {
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

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex {
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
				return [[[[*targetVar userInfo] allValues] objectAtIndex:rowIndex] description];
			}
		}
	}
}

- (BOOL)tableView:(NSTableView *)tableView writeRowsWithIndexes:(NSIndexSet *)rowIndexes toPasteboard:(NSPasteboard *)pboard {
	NSMutableArray *rowStrings = [NSMutableArray array];
	NSUInteger rowIdx;
	for (rowIdx = [rowIndexes firstIndex]; rowIdx != NSNotFound; rowIdx = [rowIndexes indexGreaterThanIndex:rowIdx]) {
		NSMutableArray *columnStrings = [NSMutableArray array];
		NSArray *columns = [tableView tableColumns];
		NSEnumerator *colEnum = [columns objectEnumerator];
		NSTableColumn *aColumn;
		while (aColumn = [colEnum nextObject]) {
			[columnStrings addObject:[self tableView:tableView
						   objectValueForTableColumn:aColumn
												 row:rowIdx]];
		}
		[rowStrings addObject:[columnStrings componentsJoinedByString:@"\t"]];
	}
	[pboard declareTypes:[NSArray arrayWithObject:NSStringPboardType] owner:nil];
	[pboard setString:[rowStrings componentsJoinedByString:@"\r"] forType:NSStringPboardType];
	return YES;
}

- (CGFloat)tableView:(NSTableView *)aTableView heightOfRow:(NSInteger)row {
	if (aTableView != userInfoList || (selectedDistNotification == nil && selectedWSNotification == nil) ) {
		return 14;
	}

	NSNotification *targetVar;
	if (selectedDistNotification == nil) {
		targetVar = selectedWSNotification;
	} else {
		targetVar = selectedDistNotification;
	}
	
	if (savedRowHeights == nil) {
		savedRowHeights = [[NSMutableArray alloc] init];
	}
	if ([savedRowHeights count] < row + 1) {
		NSString *str = [[[[targetVar userInfo] allValues] objectAtIndex:row] description];
		
		NSSize size = [str sizeWithAttributes:[NSDictionary dictionaryWithObject:[NSFont fontWithName:@"Lucida Grande" size:11] forKey:NSFontAttributeName]];
		[savedRowHeights insertObject:[NSNumber numberWithFloat:size.height] atIndex:row];
	}
	return [[savedRowHeights objectAtIndex:row] floatValue];
}

@end
