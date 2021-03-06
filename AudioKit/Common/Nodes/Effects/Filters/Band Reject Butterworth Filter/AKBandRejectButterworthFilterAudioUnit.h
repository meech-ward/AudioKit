//
//  AKBandRejectButterworthFilterAudioUnit.h
//  AudioKit
//
//  Created by Aurelius Prochazka, revision history on Github.
//  Copyright © 2017 AudioKit. All rights reserved.
//

#pragma once

#import "AKAudioUnit.h"

@interface AKBandRejectButterworthFilterAudioUnit : AKAudioUnit
@property (nonatomic) float centerFrequency;
@property (nonatomic) float bandwidth;
@end

