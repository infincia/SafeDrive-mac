
#ifndef NSURL_LSSharedItems_h
#define NSURL_LSSharedItems_h

#import <Foundation/Foundation.h>

@interface NSURL (LSSharedItems)

- (BOOL)addFavoriteItem;
- (BOOL)addFavoriteVolume;

- (BOOL)removeFavoriteItem;
- (BOOL)removeFavoriteVolume;

@end

#endif /* NSURL_LSSharedItems_h */
