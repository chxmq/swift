import AVFoundation
import AudioToolbox

/// Synthesized alarm tone generator — no audio files needed
final class AlarmSoundManager {
    static let shared = AlarmSoundManager()

    private var audioEngine: AVAudioEngine?
    private var sourceNode: AVAudioSourceNode?
    private var toneTimer: Timer?
    private var isPlaying = false

    // Current playback state
    private var currentFrequencies: [Double] = [440]
    private var currentPhase: [Double] = [0]
    private var volume: Float = 0.5
    private var patternStep = 0

    private init() {}

    // MARK: - Sound Types

    enum SoundType: Int, CaseIterable, Codable {
        // Classic
        case radar = 0
        case beacon = 1
        case pulse = 2
        case chime = 3
        case siren = 4
        case digital = 5
        // Musical
        case marimba = 6
        case harp = 7
        case piano = 8
        case staccato = 9
        // Sci-Fi
        case sonar = 10
        case warp = 11
        case crystal = 12
        case orbital = 13
        case voltage = 14

        var name: String {
            switch self {
            case .radar:    return "Radar"
            case .beacon:   return "Beacon"
            case .pulse:    return "Pulse"
            case .chime:    return "Chime"
            case .siren:    return "Siren"
            case .digital:  return "Digital"
            case .marimba:  return "Marimba"
            case .harp:     return "Harp"
            case .piano:    return "Piano"
            case .staccato: return "Staccato"
            case .sonar:    return "Sonar"
            case .warp:     return "Warp"
            case .crystal:  return "Crystal"
            case .orbital:  return "Orbital"
            case .voltage:  return "Voltage"
            }
        }

        var icon: String {
            switch self {
            case .radar:    return "antenna.radiowaves.left.and.right"
            case .beacon:   return "light.beacon.max"
            case .pulse:    return "waveform.path"
            case .chime:    return "bell.fill"
            case .siren:    return "megaphone.fill"
            case .digital:  return "digitalcrown.horizontal.press"
            case .marimba:  return "pianokeys"
            case .harp:     return "harp"
            case .piano:    return "music.note"
            case .staccato: return "music.quarternote.3"
            case .sonar:    return "circle.dotted.circle"
            case .warp:     return "tornado"
            case .crystal:  return "sparkle"
            case .orbital:  return "globe"
            case .voltage:  return "bolt.fill"
            }
        }

        /// Category for grouped display
        var category: String {
            switch self {
            case .radar, .beacon, .pulse, .chime, .siren, .digital:
                return "Classic"
            case .marimba, .harp, .piano, .staccato:
                return "Musical"
            case .sonar, .warp, .crystal, .orbital, .voltage:
                return "Sci-Fi"
            }
        }

        var frequencies: [Double] {
            switch self {
            case .radar:    return [1046.5]                         // C6
            case .beacon:   return [523.25, 659.25, 783.99]        // C5 E5 G5
            case .pulse:    return [174.61]                         // F3
            case .chime:    return [783.99, 987.77, 1174.66]       // G5 B5 D6
            case .siren:    return [440, 880]                       // sweep
            case .digital:  return [1318.51, 1567.98]              // E6 G6
            case .marimba:  return [523.25, 659.25, 783.99, 1046.5] // C5 E5 G5 C6
            case .harp:     return [261.63, 329.63, 392.0, 523.25]  // C4 E4 G4 C5
            case .piano:    return [440.0, 554.37, 659.25]          // A4 C#5 E5
            case .staccato: return [880.0]                          // A5 quick
            case .sonar:    return [220.0]                          // A3 deep ping
            case .warp:     return [300, 1200]                      // wide sweep
            case .crystal:  return [1567.98, 2093.0, 2637.02]      // G6 C7 E7
            case .orbital:  return [349.23, 440.0, 523.25]          // F4 A4 C5
            case .voltage:  return [110.0, 220.0]                   // A2 A3 buzz
            }
        }

        var burstDuration: Double {
            switch self {
            case .radar:    return 0.15
            case .beacon:   return 0.2
            case .pulse:    return 0.3
            case .chime:    return 0.12
            case .siren:    return 0.8
            case .digital:  return 0.08
            case .marimba:  return 0.10
            case .harp:     return 0.25
            case .piano:    return 0.35
            case .staccato: return 0.06
            case .sonar:    return 0.5
            case .warp:     return 0.6
            case .crystal:  return 0.08
            case .orbital:  return 0.18
            case .voltage:  return 0.12
            }
        }

        var gapDuration: Double {
            switch self {
            case .radar:    return 0.12
            case .beacon:   return 0.1
            case .pulse:    return 0.4
            case .chime:    return 0.08
            case .siren:    return 0.05
            case .digital:  return 0.06
            case .marimba:  return 0.06
            case .harp:     return 0.15
            case .piano:    return 0.2
            case .staccato: return 0.04
            case .sonar:    return 0.8
            case .warp:     return 0.1
            case .crystal:  return 0.05
            case .orbital:  return 0.08
            case .voltage:  return 0.05
            }
        }

        var burstsPerCycle: Int {
            switch self {
            case .radar:    return 3
            case .beacon:   return 3
            case .pulse:    return 2
            case .chime:    return 3
            case .siren:    return 1
            case .digital:  return 4
            case .marimba:  return 4
            case .harp:     return 4
            case .piano:    return 3
            case .staccato: return 6
            case .sonar:    return 1
            case .warp:     return 1
            case .crystal:  return 3
            case .orbital:  return 3
            case .voltage:  return 5
            }
        }

        /// Whether this type uses frequency sweep instead of discrete tones
        var isSweep: Bool {
            self == .siren || self == .warp
        }
    }

    // MARK: - Playback

    /// Play a preview of a sound type (short burst)
    func preview(_ type: SoundType) {
        stop()

        let freqs = type.frequencies
        playTone(frequencies: [freqs[0]], duration: 0.25, volume: 0.3)
    }

    /// Start playing an alarm sound on loop
    func startAlarm(_ type: SoundType, intensity: Int = 1) {
        guard !isPlaying else { return }
        isPlaying = true
        patternStep = 0

        let vol: Float = [0.3, 0.5, 0.8][min(intensity, 2)]
        playPattern(type: type, volume: vol)
    }

    /// Stop all alarm sounds
    func stop() {
        isPlaying = false
        toneTimer?.invalidate()
        toneTimer = nil
        stopEngine()
    }

    // MARK: - Engine

    private func playPattern(type: SoundType, volume: Float) {
        guard isPlaying else { return }

        let freqs = type.frequencies
        let freqIndex = patternStep % freqs.count

        // For sweep types, sweep between frequencies
        if type.isSweep && freqs.count >= 2 {
            playSweep(from: freqs[0], to: freqs[1], duration: type.burstDuration, volume: volume)
        } else {
            playTone(frequencies: [freqs[freqIndex]], duration: type.burstDuration, volume: volume)
        }

        patternStep += 1

        // Schedule next burst
        let isEndOfCycle = patternStep % type.burstsPerCycle == 0
        let gap = isEndOfCycle ? type.gapDuration + 0.6 : type.gapDuration
        let delay = type.burstDuration + gap

        toneTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
            self?.playPattern(type: type, volume: volume)
        }
    }

    private func playTone(frequencies: [Double], duration: Double, volume: Float) {
        stopEngine()

        let engine = AVAudioEngine()
        let sampleRate = engine.outputNode.outputFormat(forBus: 0).sampleRate
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!

        var phases = Array(repeating: 0.0, count: frequencies.count)

        let source = AVAudioSourceNode(format: format) { _, _, frameCount, audioBufferList -> OSStatus in
            let bufferList = UnsafeMutableAudioBufferListPointer(audioBufferList)
            let buffer = bufferList[0]
            let ptr = buffer.mData!.assumingMemoryBound(to: Float.self)

            for frame in 0..<Int(frameCount) {
                var sample: Float = 0
                for (i, freq) in frequencies.enumerated() {
                    let phaseIncrement = 2.0 * Double.pi * freq / sampleRate
                    sample += Float(sin(phases[i])) / Float(frequencies.count)
                    phases[i] += phaseIncrement
                    if phases[i] > 2.0 * Double.pi {
                        phases[i] -= 2.0 * Double.pi
                    }
                }
                ptr[frame] = sample * volume
            }
            return noErr
        }

        engine.attach(source)
        engine.connect(source, to: engine.mainMixerNode, format: format)

        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
            try engine.start()
        } catch {
            return
        }

        self.audioEngine = engine
        self.sourceNode = source

        // Stop after duration
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) { [weak self] in
            self?.stopEngine()
        }
    }

    private func playSweep(from startFreq: Double, to endFreq: Double, duration: Double, volume: Float) {
        stopEngine()

        let engine = AVAudioEngine()
        let sampleRate = engine.outputNode.outputFormat(forBus: 0).sampleRate
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
        let totalSamples = Int(sampleRate * duration)
        var sampleIndex = 0
        var phase = 0.0

        let source = AVAudioSourceNode(format: format) { _, _, frameCount, audioBufferList -> OSStatus in
            let bufferList = UnsafeMutableAudioBufferListPointer(audioBufferList)
            let buffer = bufferList[0]
            let ptr = buffer.mData!.assumingMemoryBound(to: Float.self)

            for frame in 0..<Int(frameCount) {
                let progress = Double(sampleIndex) / Double(totalSamples)
                let freq = startFreq + (endFreq - startFreq) * progress
                let phaseIncrement = 2.0 * Double.pi * freq / sampleRate
                ptr[frame] = Float(sin(phase)) * volume
                phase += phaseIncrement
                if phase > 2.0 * Double.pi {
                    phase -= 2.0 * Double.pi
                }
                sampleIndex += 1
            }
            return noErr
        }

        engine.attach(source)
        engine.connect(source, to: engine.mainMixerNode, format: format)

        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
            try engine.start()
        } catch {
            return
        }

        self.audioEngine = engine
        self.sourceNode = source

        DispatchQueue.main.asyncAfter(deadline: .now() + duration) { [weak self] in
            self?.stopEngine()
        }
    }

    private func stopEngine() {
        audioEngine?.stop()
        if let source = sourceNode {
            audioEngine?.detach(source)
        }
        audioEngine = nil
        sourceNode = nil
    }
}
