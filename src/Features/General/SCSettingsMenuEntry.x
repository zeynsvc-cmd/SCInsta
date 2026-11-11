#import "../../InstagramHeaders.h"
#import "../../Utils.h"

@interface SCIProfileSettingsLongPress : UILongPressGestureRecognizer
@end

@implementation SCIProfileSettingsLongPress

- (instancetype)init {
    self = [super initWithTarget:nil action:NULL];
    if (self) {
        [self addTarget:self action:@selector(openSettings:)];
    }
    return self;
}

- (void)openSettings:(UILongPressGestureRecognizer *)gesture {
    UIWindow *window = gesture.view.window;
    if (gesture.state == UIGestureRecognizerStateBegan && window) {
        [SCIUtils showSettingsVC:window];
    }
}

@end

static void SCIInstallProfileSettingsGesture(UIView *button) {
    NSString *identifier = button.accessibilityIdentifier;
    if (!button.window ||
        !([identifier isEqualToString:@"profile-more-button"] ||
          [identifier isEqualToString:@"profile-more-bar-button"])) {
        return;
    }

    NSArray<UIGestureRecognizer *> *recognizers = button.gestureRecognizers;
    for (UIGestureRecognizer *recognizer in recognizers) {
        if ([recognizer isKindOfClass:[SCIProfileSettingsLongPress class]]) {
            return;
        }
    }

    SCIProfileSettingsLongPress *longPress = [[SCIProfileSettingsLongPress alloc] init];
    for (UIGestureRecognizer *recognizer in recognizers) {
        if ([recognizer isKindOfClass:[UILongPressGestureRecognizer class]]) {
            [recognizer requireGestureRecognizerToFail:longPress];
        }
    }
    [button addGestureRecognizer:longPress];
}

// Older Instagram versions use the Objective-C navigation button.
%hook IGBadgedNavigationButton
- (void)didMoveToWindow {
    %orig;
    SCIInstallProfileSettingsGesture(self);
}
%end

// IGProfileNavigation.IGBadgedNavigationButton in newer Instagram versions.
%hook _TtC19IGProfileNavigation24IGBadgedNavigationButton
- (void)didMoveToWindow {
    %orig;
    SCIInstallProfileSettingsGesture((UIView *)self);
}
%end

// Quick access to tweak settings by holding on home tab button
%hook IGTabBarButton
- (void)didMoveToSuperview {
    %orig;

    // Only work on home/feed tab
    if (![self.accessibilityIdentifier isEqualToString:@"mainfeed-tab"]) return;
    
    if ([SCIUtils getBoolPref:@"settings_shortcut"]) {
        UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
        longPress.minimumPressDuration = 0.3;
        
        // Take precidence over existing gesture recognizers
        for (UIGestureRecognizer *existing in self.gestureRecognizers) {
            [existing requireGestureRecognizerToFail:longPress];
        }
        
        [self addGestureRecognizer:longPress];
    }
}
%new - (void)handleLongPress:(UILongPressGestureRecognizer *)sender {
    if (sender.state != UIGestureRecognizerStateBegan) return;

    [SCIUtils showSettingsVC:[self window]];
}
%end
