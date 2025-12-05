//
//  RTSPFeedGroupManager.h
//  RTSP Rotator
//
//  Feed groups and playlists
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface RTSPFeedGroup : NSObject <NSCoding, NSSecureCoding>
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *groupID;
@property (nonatomic, strong) NSArray<NSURL *> *feedURLs;
@property (nonatomic, assign) NSTimeInterval rotationInterval;
@property (nonatomic, assign) BOOL enabled;
@end

@interface RTSPFeedGroupManager : NSObject

+ (instancetype)sharedManager;

- (NSArray<RTSPFeedGroup *> *)groups;
@property (nonatomic, strong, nullable) RTSPFeedGroup *activeGroup;

- (void)addGroup:(RTSPFeedGroup *)group;
- (void)removeGroup:(RTSPFeedGroup *)group;
- (void)activateGroup:(RTSPFeedGroup *)group;
- (RTSPFeedGroup *)groupWithID:(NSString *)groupID;
- (BOOL)saveGroups;
- (BOOL)loadGroups;

@end

NS_ASSUME_NONNULL_END
