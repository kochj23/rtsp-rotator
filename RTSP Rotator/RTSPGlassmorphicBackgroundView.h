//
//  RTSPGlassmorphicBackgroundView.h
//  Stream Rotator
//
//  Modern glassmorphic background with animated floating blobs
//  Inspired by iOS design and modern dashboard aesthetics
//
//  Created by Jordan Koch on 1/17/2026.
//  Copyright © 2026 Jordan Koch. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface RTSPGlassmorphicBackgroundView : NSView

// Initializes the glassmorphic background view
- (instancetype)initWithFrame:(NSRect)frameRect;

// Start/stop blob animations
- (void)startAnimations;
- (void)stopAnimations;

@end

NS_ASSUME_NONNULL_END
