//
//  AKDSPBase.hpp
//  AudioKit
//
//  Created by Andrew Voelkel, revision history on GitHub.
//  Copyright © 2017 AudioKit. All rights reserved.
//

#pragma once
#ifdef __cplusplus

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import <algorithm>

/**
 Base class for DSPKernels. Many of the methods are virtual, because the base AudioUnit class
 does not know the type of the subclass at compile time.
 */

struct AKDSPBase {

protected:

    int _nChannels;                               /* From Apple Example code */
    double _sampleRate;                           /* From Apple Example code */
    AudioBufferList* _inBufferListPtr = nullptr;  /* From Apple Example code */
    AudioBufferList* _outBufferListPtr = nullptr; /* From Apple Example code */

    // To support AKAudioUnit functions
    bool _initialized = true;
    bool _playing = true;
    int64_t _now = 0;  // current time in samples

public:

    /** The Render function. */
    virtual void process(uint32_t frameCount, uint32_t bufferOffset) = 0;

    /** Uses the ParameterAddress as a key */
    virtual void setParameter(uint64_t address, float value, bool immediate = false) {}

    /** Uses the ParameterAddress as a key */
    virtual float getParameter(uint64_t address) { return 0.0; }

    /** Get the DSP into initialized state */
    virtual void reset() {}

    virtual void setBuffers(AudioBufferList* inBufs, AudioBufferList* outBufs) {
        _inBufferListPtr = inBufs;
        _outBufferListPtr = outBufs;
    }

    virtual void init(int nChannels, double sampleRate) {
        this->_nChannels = nChannels; this->_sampleRate = sampleRate;
    }

    // Add for compatibility with AKAudioUnit
    virtual void start() { _playing = true; }
    virtual void stop() { _playing = false; }
    virtual bool isPlaying() { return _playing; }
    virtual bool isSetup() { return _initialized; }


    /**
     Handles the event list processing and rendering loop. Should be called from AU renderBlock
     From Apple Example code
     */
    void processWithEvents(AudioTimeStamp const *timestamp, AUAudioFrameCount frameCount,
                           AURenderEvent const *events) {

        _now = timestamp->mSampleTime;
        AUAudioFrameCount framesRemaining = frameCount;
        AURenderEvent const *event = events;

        while (framesRemaining > 0) {
            // If there are no more events, we can process the entire remaining segment and exit.
            if (event == nullptr) {
                AUAudioFrameCount const bufferOffset = frameCount - framesRemaining;
                process(framesRemaining, bufferOffset);
                return;
            }

            // **** start late events late.
            auto timeZero = AUEventSampleTime(0);
            auto headEventTime = event->head.eventSampleTime;
            AUAudioFrameCount const framesThisSegment = AUAudioFrameCount(std::max(timeZero, headEventTime - _now));

            // Compute everything before the next event.
            if (framesThisSegment > 0) {
                AUAudioFrameCount const bufferOffset = frameCount - framesRemaining;
                process(framesThisSegment, bufferOffset);

                // Advance frames.
                framesRemaining -= framesThisSegment;
                // Advance time.
                _now += framesThisSegment;
            }
            performAllSimultaneousEvents(_now, event);
        }
    }

private:

    /** From Apple Example code */
    void handleOneEvent(AURenderEvent const *event) {
        switch (event->head.eventType) {
            case AURenderEventParameter:
            case AURenderEventParameterRamp: {
                // AUParameterEvent const& paramEvent = event->parameter;
                // startRamp(paramEvent.parameterAddress, paramEvent.value, paramEvent.rampDurationSampleFrames);
                break;
            }
            case AURenderEventMIDI:
                // handleMIDIEvent(event->MIDI);
                break;
            default:
                break;
        }
    }

    /** From Apple Example code */
    void performAllSimultaneousEvents(AUEventSampleTime now, AURenderEvent const *&event) {
        do {
            handleOneEvent(event);
            event = event->head.next;
            // While event is not null and is simultaneous (or late).
        } while (event && event->head.eventSampleTime <= now);
    }

};

#endif

