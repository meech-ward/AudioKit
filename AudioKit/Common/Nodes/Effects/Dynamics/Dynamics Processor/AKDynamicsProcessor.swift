//
//  AKDynamicsProcessor.swift
//  AudioKit
//
//  Created by Aurelius Prochazka, revision history on Github.
//  Copyright © 2017 AudioKit. All rights reserved.
//

/// AudioKit version of Apple's DynamicsProcessor Audio Unit
///
open class AKDynamicsProcessor: AKNode, AKToggleable, AUEffect, AKInput {

    /// Four letter unique description of the node
    public static let ComponentDescription = AudioComponentDescription(appleEffect: kAudioUnitSubType_DynamicsProcessor)

    private var au: AUWrapper
    fileprivate var mixer: AKMixer

    /// Threshold (dB) ranges from -40 to 20 (Default: -20)
    @objc open dynamic var threshold: Double = -20 {
        didSet {
            threshold = (-40...20).clamp(threshold)
            au[kDynamicsProcessorParam_Threshold] = threshold
        }
    }

    /// Head Room (dB) ranges from 0.1 to 40.0 (Default: 5)
    @objc open dynamic var headRoom: Double = 5 {
        didSet {
            headRoom = (0.1...40).clamp(headRoom)
            au[kDynamicsProcessorParam_HeadRoom] = headRoom
        }
    }

    /// Expansion Ratio (rate) ranges from 1 to 50.0 (Default: 2)
    @objc open dynamic var expansionRatio: Double = 2 {
        didSet {
            expansionRatio = (1...50).clamp(expansionRatio)
            au[kDynamicsProcessorParam_ExpansionRatio] = expansionRatio
        }
    }

    /// Expansion Threshold (rate) ranges from 1 to 50.0 (Default: 2)
    @objc open dynamic var expansionThreshold: Double = 2 {
        didSet {
            expansionThreshold = (1...50).clamp(expansionThreshold)
            au[kDynamicsProcessorParam_ExpansionThreshold] = expansionThreshold
        }
    }

    /// Attack Time (secs) ranges from 0.0001 to 0.2 (Default: 0.001)
    @objc open dynamic var attackTime: Double = 0.001 {
        didSet {
            attackTime = (0.000_1...0.2).clamp(attackTime)
            au[kDynamicsProcessorParam_AttackTime] = attackTime
        }
    }

    /// Release Time (secs) ranges from 0.01 to 3 (Default: 0.05)
    @objc open dynamic var releaseTime: Double = 0.05 {
        didSet {
            releaseTime = (0.01...3).clamp(releaseTime)
            au[kDynamicsProcessorParam_ReleaseTime] = releaseTime
        }
    }

    /// Master Gain (dB) ranges from -40 to 40 (Default: 0)
    @objc open dynamic var masterGain: Double = 0 {
        didSet {
            masterGain = (-40...40).clamp(masterGain)
            au[kDynamicsProcessorParam_MasterGain] = masterGain
        }
    }

    /// Compression Amount (dB) read only
    @objc open dynamic var compressionAmount: Double {
        return au[kDynamicsProcessorParam_CompressionAmount]
    }

    /// Input Amplitude (dB) read only
    @objc open dynamic var inputAmplitude: Double {
        return au[kDynamicsProcessorParam_InputAmplitude]
    }

    /// Output Amplitude (dB) read only
    @objc open dynamic var outputAmplitude: Double {
        return au[kDynamicsProcessorParam_OutputAmplitude]
    }

    /// Dry/Wet Mix (Default 100)
    @objc open dynamic var dryWetMix: Double = 100 {
        didSet {
            dryWetMix = (0...100).clamp(dryWetMix)

            inputGain?.volume = 1 - dryWetMix / 100
            effectGain?.volume = dryWetMix / 100
        }
    }

    fileprivate var lastKnownMix: Double = 100
    fileprivate var inputGain: AKMixer?
    fileprivate var effectGain: AKMixer?
    fileprivate var inputMixer = AKMixer()

    // Store the internal effect
    fileprivate var internalEffect: AVAudioUnitEffect

    /// Tells whether the node is processing (ie. started, playing, or active)
    @objc open dynamic var isStarted = true

    /// Initialize the dynamics processor node
    ///
    /// - Parameters:
    ///   - input: Input node to process
    ///   - threshold: Threshold (dB) ranges from -40 to 20 (Default: -20)
    ///   - headRoom: Head Room (dB) ranges from 0.1 to 40.0 (Default: 5)
    ///   - expansionRatio: Expansion Ratio (rate) ranges from 1 to 50.0 (Default: 2)
    ///   - expansionThreshold: Expansion Threshold (rate) ranges from 1 to 50.0 (Default: 2)
    ///   - attackTime: Attack Time (secs) ranges from 0.0001 to 0.2 (Default: 0.001)
    ///   - releaseTime: Release Time (secs) ranges from 0.01 to 3 (Default: 0.05)
    ///   - masterGain: Master Gain (dB) ranges from -40 to 40 (Default: 0)
    ///   - compressionAmount: Compression Amount (dB) ranges from -40 to 40 (Default: 0)
    ///   - inputAmplitude: Input Amplitude (dB) ranges from -40 to 40 (Default: 0)
    ///   - outputAmplitude: Output Amplitude (dB) ranges from -40 to 40 (Default: 0)
    ///
    @objc public init(
        _ input: AKNode? = nil,
        threshold: Double = -20,
        headRoom: Double = 5,
        expansionRatio: Double = 2,
        expansionThreshold: Double = 2,
        attackTime: Double = 0.001,
        releaseTime: Double = 0.05,
        masterGain: Double = 0,
        compressionAmount: Double = 0,
        inputAmplitude: Double = 0,
        outputAmplitude: Double = 0) {

        self.threshold = threshold
        self.headRoom = headRoom
        self.expansionRatio = expansionRatio
        self.expansionThreshold = expansionThreshold
        self.attackTime = attackTime
        self.releaseTime = releaseTime
        self.masterGain = masterGain

        inputGain = AKMixer()
        inputGain?.volume = 0
        mixer = AKMixer(inputGain)

        effectGain = AKMixer()
        effectGain?.volume = 1

        input?.connect(to: inputMixer)
        inputMixer.connect(to: [inputGain!, effectGain!])

        let effect = _Self.effect
        self.internalEffect = effect

        AudioKit.engine.attach(effect)

        au = AUWrapper(effect)

        if let node = effectGain?.avAudioNode {
            AudioKit.engine.connect(node, to: effect)
        }
        AudioKit.engine.connect(effect, to: mixer.avAudioNode)

        super.init(avAudioNode: mixer.avAudioNode)

        au[kDynamicsProcessorParam_Threshold] = threshold
        au[kDynamicsProcessorParam_HeadRoom] = headRoom
        au[kDynamicsProcessorParam_ExpansionRatio] = expansionRatio
        au[kDynamicsProcessorParam_ExpansionThreshold] = expansionThreshold
        au[kDynamicsProcessorParam_AttackTime] = attackTime
        au[kDynamicsProcessorParam_ReleaseTime] = releaseTime
        au[kDynamicsProcessorParam_MasterGain] = masterGain
    }

    public var inputNode: AVAudioNode {
        return inputMixer.avAudioNode
    }

    // MARK: - Control

    /// Function to start, play, or activate the node, all do the same thing
    @objc open func start() {
        if isStopped {
            dryWetMix = lastKnownMix
            isStarted = true
        }
    }

    /// Function to stop or bypass the node, both are equivalent
    @objc open func stop() {
        if isPlaying {
            lastKnownMix = dryWetMix
            dryWetMix = 0
            isStarted = false
        }
    }

    /// Disconnect the node
    override open func disconnect() {
        stop()

        AudioKit.detach(nodes: [inputMixer.avAudioNode, inputGain!.avAudioNode, effectGain!.avAudioNode, mixer.avAudioNode])
        AudioKit.engine.detach(self.internalEffect)
    }
}
