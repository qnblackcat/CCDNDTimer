#import <UIKit/UIKit.h>
#include "CCDNDTimer.h"
//#import <rootless.h>
//#define CCTOGGLE_ICON_PATH ROOT_PATH_NS(@"/var/jb/Library/ControlCenter/Bundles/CCDNDTimer.bundle/");
#pragma clang diagnostic ignored "-Wdeprecated-declarations"

@interface UIWindow ()
- (void)_setSecure:(BOOL)arg1;
@end

@implementation CCDNDTimer
BOOL gotDeselected;
NSDate* DNDFireDate;

- (CCUICAPackageDescription *)glyphPackageDescription {
    return [CCUICAPackageDescription descriptionForPackageNamed:@"CCDNDTimer" inBundle:[NSBundle bundleForClass:[self class]]];
}

- (UIImage *)iconGlyph {
    return [UIImage imageNamed:@"Icon" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil];
}

static void enableDND() {
    if (!assertionService) assertionService = (DNDModeAssertionService *)[%c(DNDModeAssertionService) serviceForClientIdentifier:@"com.apple.donotdisturb.control-center.module"];
    DNDModeAssertionDetails *newAssertion = [%c(DNDModeAssertionDetails) userRequestedAssertionDetailsWithIdentifier:@"com.apple.control-center.manual-toggle" modeIdentifier:@"com.apple.donotdisturb.mode.default" lifetime:nil];
    [assertionService takeModeAssertionWithDetails:newAssertion error:NULL];
}

static void disableDND() {
    if (!assertionService) assertionService = (DNDModeAssertionService *)[NSClassFromString(@"DNDModeAssertionService") serviceForClientIdentifier:@"com.apple.donotdisturb.control-center.module"];
    [assertionService invalidateAllActiveModeAssertionsWithError:NULL];
}

static bool isDNDEnabled() {
    id service = MSHookIvar<id>(UIApplication.sharedApplication, "_dndNotificationsService");
    if(!service) {
        return 0;
    }
    else {
        id state = MSHookIvar<id>(service, "_currentState");
        return [state isActive];
    }
}

//Return the color selection color of your module here
//exact color as the original moon icon of DND
- (UIColor *)selectedColor
{
    return [UIColor colorWithRed:142/255.0 green:83/255.0 blue:251/255.0 alpha:1];
}

- (BOOL)isSelected
{
  //add observer only once, since adding more observers will flood you with the same notifications!
    static dispatch_once_t onceToken2;
    dispatch_once(&onceToken2, ^{
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(cancelToggle) name:@"com.0xkuj.ccdndtimer.timerover" object:nil];
    });
    NSMutableDictionary* timerLeftDict = [[NSMutableDictionary alloc] initWithContentsOfFile:DND_TIMER_PLIST];
    NSDate* lastFireDate = [timerLeftDict objectForKey:@"DNDFireDate"];
    long timeDelta = [lastFireDate timeIntervalSinceDate:[NSDate date]];
    if (timeDelta > 0 && isDNDEnabled() && !gotDeselected) {
        return YES;
    }
    return _selected;
}

- (void)setSelected:(BOOL)selected
{
    _selected = selected;
    [super refreshState];

    if(_selected)
    {
        // no asking popup for the timer, default time = 60 minutes
        NSNumber *hoursAndMinutes = [NSNumber numberWithInt:60];
        [self updateDNDTimerSettingsWithTimeLeft:hoursAndMinutes];
        enableDND();
        [[NSNotificationCenter defaultCenter] postNotificationName:@"com.0xkuj.ccdndtimer.moduleactivated" object:nil];
    }
    else
    {
        gotDeselected = YES;
        disableDND();
        [self updateDNDTimerSettingsWithTimeLeft:[NSNumber numberWithInt:0]];
    }
}

-(void)cancelToggle {
    [self setSelected:NO];
}

-(void)updateDNDTimerSettingsWithTimeLeft:(NSNumber*)timeLeft {
    if ([DNDFireDate timeIntervalSinceDate:[NSDate date]] <= 0 && timeLeft == 0) {
        return;
    }
    DNDFireDate = [NSDate dateWithTimeIntervalSinceNow:([timeLeft intValue]*60)];
    NSMutableDictionary* settingsFile =  [[NSMutableDictionary alloc] init];
    [settingsFile setObject:DNDFireDate forKey:@"DNDFireDate"];
    [settingsFile writeToFile:DND_TIMER_PLIST atomically:YES];
}
@end
