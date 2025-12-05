//
//  RTSPSmartAlerts.h
//  RTSP Rotator
//
//  AI-powered object detection alerts using Vision framework
//

#import <Foundation/Foundation.h>
#import <Vision/Vision.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, RTSPDetectedObjectType) {
    RTSPDetectedObjectTypePerson,
    RTSPDetectedObjectTypeVehicle,
    RTSPDetectedObjectTypeAnimal,
    RTSPDetectedObjectTypePackage
};

@class RTSPSmartAlerts;

@protocol RTSPSmartAlertsDelegate <NSObject>
@optional
- (void)smartAlerts:(RTSPSmartAlerts *)alerts didDetectObject:(RTSPDetectedObjectType)objectType confidence:(CGFloat)confidence;
@end

@interface RTSPSmartAlerts : NSObject

- (instancetype)initWithPlayer:(AVPlayer *)player;

@property (nonatomic, weak) id<RTSPSmartAlertsDelegate> delegate;
@property (nonatomic, assign) BOOL enabled;
@property (nonatomic, assign) CGFloat confidenceThreshold; // 0.0-1.0, default: 0.7
@property (nonatomic, assign) NSTimeInterval checkInterval; // default: 1.0

- (void)startMonitoring;
- (void)stopMonitoring;

@end

NS_ASSUME_NONNULL_END
