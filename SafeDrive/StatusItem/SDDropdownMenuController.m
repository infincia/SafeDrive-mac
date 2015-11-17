
//  Copyright (c) 2014 Infincia LLC. All rights reserved.
//

#import "SDDropdownMenuController.h"

#import "SDAPI.h"
#import "SDMountController.h"
#import "SDSystemAPI.h"

@interface SDDropdownMenuController ()
@property SDAPI *safeDriveAPI;
@property SDMountController *mountController;
@property SDSystemAPI *sharedSystemAPI;

-(void)setMenuBarImage:(NSImage *)image;
-(void)disconnectVolume;
@end

@implementation SDDropdownMenuController

- (instancetype)init
{
    self = [super init];
    if (self) {
        [[NSBundle mainBundle] loadNibNamed:@"SDDropdownMenu" owner:self topLevelObjects:nil];
        
        self.safeDriveAPI = [SDAPI sharedAPI];
        self.mountController = [SDMountController sharedAPI];
        self.sharedSystemAPI = [SDSystemAPI sharedAPI];

        // register SDMountStateProtocol notifications
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(mountStateMounted:) name:SDMountStateMountedNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(mountStateUnmounted:) name:SDMountStateUnmountedNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(mountStateDetails:) name:SDMountStateDetailsNotification object:nil];
 
        // register SDVolumeEventProtocol notifications
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(volumeDidMount:) name:SDVolumeDidMountNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(volumeDidUnmount:) name:SDVolumeDidUnmountNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(volumeShouldUnmount:) name:SDVolumeShouldUnmountNotification object:nil];

    }
    return self;
}

-(void)awakeFromNib {
    self.statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSSquareStatusItemLength];

    // menu loaded from SDDropdownMenu.xib
    self.statusItem.menu = self.statusItemMenu;

    // this sets the tooltip of the menu bar item using a localized string from SafeDrive.strings
    self.statusItem.toolTip = NSLocalizedString(@"SafeDriveAppName", @"Safe Drive Application Name");

    #warning This icon needs to be replaced!
    [self setMenuBarImage:[NSImage imageNamed:NSImageNameLockLockedTemplate]];

}




#pragma mark - Internal methods

-(void)setMenuBarImage:(NSImage *)image {
    // needed for OS X 10.10's dark mode
    [image setTemplate:YES];

    [self.statusItem setImage:image];
}


-(void)disconnectVolume {
    NSString *volumeName = self.sharedSystemAPI.currentVolumeName;
    NSLog(@"Dismounting volume: %@", volumeName);
    [self.mountController unmountVolumeWithName:volumeName success:^(NSURL *mountURL, NSError *mountError) {
        //
    } failure:^(NSURL *mountURL, NSError *mountError) {
        //
    }];

}


#pragma mark - IBActions

-(IBAction)toggleMount:(id)sender {
    switch (self.mountController.mountState) {
        case SDMountStateMounted: {
            [self disconnectVolume];
            break;
        }
        case SDMountStateUnmounted: {
            [[NSNotificationCenter defaultCenter] postNotificationName:SDApplicationShouldOpenAccountWindow object:nil];
            break;
        }
        case SDMountStateUnknown: {
            //
        }
        default: {
            break;
        }
    }
}


-(IBAction)openPreferencesWindow:(id)sender {
    [[NSNotificationCenter defaultCenter] postNotificationName:SDApplicationShouldOpenPreferencesWindow object:nil];
}

-(IBAction)openAboutWindow:(id)sender {
    [[NSNotificationCenter defaultCenter] postNotificationName:SDApplicationShouldOpenAboutWindow object:nil];
}


#pragma mark - SDVolumeEventProtocol methods

-(void)volumeDidMount:(NSNotification *)notification {

}

-(void)volumeDidUnmount:(NSNotification *)notification {

}

-(void)volumeSubprocessDidTerminate:(NSNotification *)notification {

}

-(void)volumeShouldUnmount:(NSNotification *)notification {
    [self disconnectVolume];
}


#pragma mark - SDMountStateProtocol methods

-(void)mountStateMounted:(NSNotification*)notification {
    self.connectMenuItem.title = NSLocalizedString(@"Disconnect", @"Menu title for disconnecting the volume");

    #warning These icons need to be replaced!
    [self setMenuBarImage:[NSImage imageNamed:NSImageNameLockUnlockedTemplate]];
}

-(void)mountStateUnmounted:(NSNotification*)notification {
    self.connectMenuItem.title = NSLocalizedString(@"Connect", @"Menu title for connecting the volume");

    #warning These icons need to be replaced!
    [self setMenuBarImage:[NSImage imageNamed:NSImageNameLockLockedTemplate]];
}

-(void)mountStateDetails:(NSNotification *)notification {

}

@end
