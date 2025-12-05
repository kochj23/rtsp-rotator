//
//  RTSPUniFiProtectPreferences+RTSPS.h
//  RTSP Rotator
//
//  RTSPS vs RTSP preference extensions
//

#import <Foundation/Foundation.h>
#import "RTSPUniFiProtectPreferences.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * @brief Category for RTSPS/RTSP protocol selection preferences
 *
 * Extends RTSPUniFiProtectPreferences to add protocol selection UI and logic.
 *
 * Background:
 * - RTSPS (port 7441): Secure/encrypted but AVFoundation doesn't support self-signed certs
 * - RTSP (port 554): Non-secure but works perfectly with AVFoundation
 */
@interface RTSPUniFiProtectPreferences (RTSPS)

/**
 * Show protocol selection dialog
 *
 * Allows user to choose between RTSPS (secure, requires VLCKit) and
 * RTSP (non-secure, works with AVFoundation)
 */
- (void)showProtocolSelectionDialog;

/**
 * Get current protocol preference
 *
 * @return YES for RTSPS (secure), NO for RTSP (non-secure)
 */
+ (BOOL)useSecureRTSP;

/**
 * Set protocol preference
 *
 * @param useSecure YES for RTSPS, NO for RTSP
 */
+ (void)setUseSecureRTSP:(BOOL)useSecure;

@end

NS_ASSUME_NONNULL_END
