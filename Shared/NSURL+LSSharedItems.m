
#import "NSURL+LSSharedItems.h"
#import <dlfcn.h>

@implementation NSURL(LSSharedItems)

- (BOOL)addFavoriteItem {
    return [self addTo: kLSSharedFileListFavoriteItems];
}

- (BOOL)addFavoriteVolume {
    return [self addTo: kLSSharedFileListFavoriteVolumes];
}


- (BOOL)removeFavoriteItem {
    return [self removeFrom: kLSSharedFileListFavoriteItems];
}

- (BOOL)removeFavoriteVolume {
    return [self removeFrom: kLSSharedFileListFavoriteVolumes];
}

- (BOOL)isFavoriteItemPresent {
    return [self isPresentIn: kLSSharedFileListFavoriteItems];
}

- (BOOL)isFavoriteVolumePresent {
    return [self isPresentIn: kLSSharedFileListFavoriteVolumes];
}

// private API

- (BOOL)addTo:(CFStringRef)list {
    // leaving this here but disabled for the moment, because it's not enough to
    // just check one function at runtime, every reference to these deprecated
    // functions needs to be loaded with dlsym or the app itself will fail to
    // load
    
    /*
    if (![NSURL LSFunctionsAvailable]) {
        return NO;
    }
    */

    BOOL result = NO;
    if (self.isFileURL) {
        LSSharedFileListRef listRef = LSSharedFileListCreate(NULL, list, NULL);
        if (listRef) {
            LSSharedFileListItemRef itemRef = LSSharedFileListInsertItemURL(listRef,
                                                                            kLSSharedFileListItemLast,
                                                                            NULL,
                                                                            NULL,
                                                                            (__bridge CFURLRef)self,
                                                                            NULL,
                                                                            NULL);
            
            if (itemRef) {
                CFRelease(itemRef);
                result = YES;
                
            }
            CFRelease(listRef);
        }
    }
    return result;
}

- (BOOL)removeFrom:(CFStringRef)list {
    /*
    if (![NSURL LSFunctionsAvailable]) {
        return NO;
    }
    */

    BOOL result = NO;
    if (self.isFileURL) {
        LSSharedFileListRef listRef = LSSharedFileListCreate(NULL, list, NULL);
        if (listRef) {
            CFArrayRef snapshotRef = LSSharedFileListCopySnapshot(listRef, NULL);
            NSArray* favoritesList = CFBridgingRelease(snapshotRef);

            for (id favorite in favoritesList) {
                LSSharedFileListItemRef itemRef = (__bridge LSSharedFileListItemRef)favorite;
                
                CFURLRef itemURLRef;
                
                // CFErrorRef err;
                
                // itemURLRef = LSSharedFileListItemCopyResolvedURL(itemRef, 0, &err);
                
                if (LSSharedFileListItemResolve(itemRef,
                                                kLSSharedFileListNoUserInteraction |
                                                kLSSharedFileListDoNotMountVolumes,
                                                &itemURLRef,
                                                NULL) == noErr) {

                    NSURL *itemURL = (NSURL *)CFBridgingRelease(itemURLRef);
                    if ([itemURL isEqual: self]) {
                        if (LSSharedFileListItemRemove(listRef, itemRef) == noErr) {
                            result = YES;
                        }
                    }
                } else {
                    /**
                      * this is error prone so we leave it disabled for now. The
                      * display names are not going to be unique and users can
                      * change the name of the drive to anything they want at the
                      * moment, which could result in removing unrelated favorite
                      * items with more generic names
                    ***/
                    
                    
                    CFStringRef displayNameRef = LSSharedFileListItemCopyDisplayName(itemRef);
                    if (displayNameRef) {
                        NSString* displayName = CFBridgingRelease(displayNameRef);
                        if ([displayName isEqual: self.lastPathComponent]) {
                            if (LSSharedFileListItemRemove(listRef, itemRef) == noErr) {
                                result = YES;
                            }
                        }
                    } else {
                        /**
                          * Sidebar item has no url or name, it's useless even
                          * if it isn't ours so we remove it
                          *
                         **/
                        LSSharedFileListItemRemove(listRef, itemRef);
                    }
                }
            }
            CFRelease(listRef);
        }
    }
    return result;
}

- (BOOL)isPresentIn:(CFStringRef)list {
    /*
     if (![NSURL LSFunctionsAvailable]) {
     return NO;
     }
     */
    
    BOOL result = NO;
    if (self.isFileURL) {
        LSSharedFileListRef listRef = LSSharedFileListCreate(NULL, list, NULL);
        if (listRef) {
            CFArrayRef snapshotRef = LSSharedFileListCopySnapshot(listRef, NULL);
            NSArray* favoritesList = CFBridgingRelease(snapshotRef);
            
            for (id favorite in favoritesList) {
                LSSharedFileListItemRef itemRef = (__bridge LSSharedFileListItemRef)favorite;
                
                CFURLRef itemURLRef;
                
                // CFErrorRef err;
                
                // itemURLRef = LSSharedFileListItemCopyResolvedURL(itemRef, 0, &err);
                
                if (LSSharedFileListItemResolve(itemRef,
                                                kLSSharedFileListNoUserInteraction |
                                                kLSSharedFileListDoNotMountVolumes,
                                                &itemURLRef,
                                                NULL) == noErr) {
                    
                    NSURL *itemURL = (NSURL *)CFBridgingRelease(itemURLRef);
                    if ([itemURL isEqual: self]) {
                        result = YES;
                        break;
                    }
                } else {
                    /**
                     * this is error prone so we leave it disabled for now. The
                     * display names are not going to be unique and users can
                     * change the name of the drive to anything they want at the
                     * moment, which could result in removing unrelated favorite
                     * items with more generic names
                     ***/
                    
                    
                    CFStringRef displayNameRef = LSSharedFileListItemCopyDisplayName(itemRef);
                    if (displayNameRef) {
                        NSString* displayName = CFBridgingRelease(displayNameRef);
                        if ([displayName isEqual: self.lastPathComponent]) {
                            if (LSSharedFileListItemRemove(listRef, itemRef) == noErr) {
                                result = YES;
                                break;
                            }
                        }
                    }
                }
            }
            CFRelease(listRef);
        }
    }
    return result;
}

/*
+ (BOOL)LSFunctionsAvailable {
    static LSSharedFileListItemRef (*_LSSharedFileListInsertItemURLFn)(LSSharedFileListRef       inList,
                                                                       LSSharedFileListItemRef   insertAfterThisItem,
                                                                       CFStringRef               inDisplayName,
                                                                       IconRef                   inIconRef,
                                                                       CFURLRef                  inURL,
                                                                       CFDictionaryRef           inPropertiesToSet,
                                                                       CFArrayRef                inPropertiesToClear) = NULL;
    
    if (!_LSSharedFileListInsertItemURLFn) {
#pragma GCC diagnostic ignored "-Wpedantic"
#pragma clang diagnostic push
        _LSSharedFileListInsertItemURLFn = dlsym(RTLD_DEFAULT, "_LSSharedFileListInsertItemURLFn");
#pragma clang diagnostic pop
        
        if (!_LSSharedFileListInsertItemURLFn) {
            return NO;
        }
    }
    
    return YES;
}
*/

@end
