/* PreferencesController */

#import <Cocoa/Cocoa.h>

@interface PreferencesController : NSObject
{
    IBOutlet NSButton *processActivationCheck;
}
- (IBAction)changeProcessActivation:(id)sender;
@end
