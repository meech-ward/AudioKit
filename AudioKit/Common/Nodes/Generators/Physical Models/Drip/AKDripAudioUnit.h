//
//  AKDripAudioUnit.h
//  AudioKit
//
//  Created by Aurelius Prochazka, revision history on Github.
//  Copyright © 2017 AudioKit. All rights reserved.
//

#pragma once
#import "AKAudioUnit.h"

@interface AKDripAudioUnit : AKAudioUnit
@property (nonatomic) float intensity;
@property (nonatomic) float dampingFactor;
@property (nonatomic) float energyReturn;
@property (nonatomic) float mainResonantFrequency;
@property (nonatomic) float firstResonantFrequency;
@property (nonatomic) float secondResonantFrequency;
@property (nonatomic) float amplitude;

- (void)trigger;

@end


