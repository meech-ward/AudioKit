//
//  AKModalResonanceFilterAudioUnit.h
//  AudioKit
//
//  Created by Aurelius Prochazka, revision history on Github.
//  Copyright © 2017 AudioKit. All rights reserved.
//

#pragma once
#import "AKAudioUnit.h"

@interface AKModalResonanceFilterAudioUnit : AKAudioUnit
@property (nonatomic) float frequency;
@property (nonatomic) float qualityFactor;
@end
