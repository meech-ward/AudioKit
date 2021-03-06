//
//  AKVariableDelayAudioUnit.h
//  AudioKit
//
//  Created by Aurelius Prochazka, revision history on Github.
//  Copyright © 2017 AudioKit. All rights reserved.
//

#pragma once
#import "AKAudioUnit.h"

@interface AKVariableDelayAudioUnit : AKAudioUnit
- (void)clear;
@property (nonatomic) float time;
@property (nonatomic) float feedback;
@end
