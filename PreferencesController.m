#import "PreferencesController.h"
#import "Globals.h"

@implementation PreferencesController

- (IBAction)changeProcessActivation:(id)sender
{
    [[NSUserDefaults standardUserDefaults] setBool:[sender state]
                                            forKey:kHideProcessSwitchNotificationPref];
}

- (void)awakeFromNib
{
    [processActivationCheck setState:
        [[NSUserDefaults standardUserDefaults] boolForKey:kHideProcessSwitchNotificationPref]];
}

@end
