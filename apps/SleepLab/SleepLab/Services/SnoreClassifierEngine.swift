import AVFoundation
import CoreML
import Foundation

struct SnoreClassificationResult: Sendable {
    let isSnore: Bool
    let confidence: Double
    let label: String
    let usedCoreML: Bool
}

/// Inférence Core ML (Create ML : classes snore / background) + repli heuristique.
final class SnoreClassifierEngine: @unchecked Sendable {
    /// Sans modèle Create ML, le repli heuristique utilise un seuil légèrement plus bas.
    static let confidenceThreshold = 0.88
    static let snoreLabels: Set<String> = ["snore", "ronflement", "snoring"]

    private var model: MLModel?
    private var waveformInputName: String?
    private var probabilityOutputName: String?
    private var labelOutputName: String?

    init() {
        loadBundledModel()
    }

    var isModelLoaded: Bool { model != nil }

    func classify(waveform: [Float]) -> SnoreClassificationResult? {
        guard waveform.count >= SnoreAudioPipeline.chunkSampleCount else { return nil }
        let chunk = Array(waveform.prefix(SnoreAudioPipeline.chunkSampleCount))

        if let model, let waveformInputName {
            return classifyWithCoreML(chunk: chunk, model: model, inputName: waveformInputName)
        }
        return classifyWithHeuristic(chunk: chunk)
    }

    // MARK: - Core ML

    private func classifyWithCoreML(
        chunk: [Float],
        model: MLModel,
        inputName: String
    ) -> SnoreClassificationResult? {
        guard let array = try? MLMultiArray(
            shape: [NSNumber(value: chunk.count)],
            dataType: .float32
        ) else { return nil }

        let ptr = array.dataPointer.bindMemory(to: Float.self, capacity: chunk.count)
        for (index, sample) in chunk.enumerated() {
            ptr[index] = sample
        }

        let provider = try? MLDictionaryFeatureProvider(dictionary: [inputName: array])
        guard let provider,
              let out = try? model.prediction(from: provider) else { return nil }

        let (label, _) = parseOutputs(out.featureValue(for:))
        let snoreConfidence: Double
        if let probName = probabilityOutputName,
           let dict = out.featureValue(for: probName)?.dictionaryValue as? [String: NSNumber] {
            snoreConfidence = Self.snoreProbability(from: dict)
        } else if Self.snoreLabels.contains(label.lowercased()) {
            snoreConfidence = 0.9
        } else {
            snoreConfidence = 0.1
        }

        return SnoreClassificationResult(
            isSnore: snoreConfidence >= Self.confidenceThreshold,
            confidence: snoreConfidence,
            label: label,
            usedCoreML: true
        )
    }

    private func parseOutputs(
        _ feature: (String) -> MLFeatureValue?
    ) -> (String, Double) {
        if let labelName = labelOutputName,
           let label = feature(labelName)?.stringValue {
            if let probName = probabilityOutputName,
               let dict = feature(probName)?.dictionaryValue as? [String: NSNumber] {
                let key = dict.keys.first { $0 == label } ?? label
                return (label, dict[key]?.doubleValue ?? 0)
            }
            return (label, 0.9)
        }

        if let probName = probabilityOutputName,
           let dict = feature(probName)?.dictionaryValue as? [String: NSNumber] {
            let snoreConf = Self.snoreProbability(from: dict)
            let label = dict.max(by: { $0.value.doubleValue < $1.value.doubleValue })?.key ?? "background"
            return (label, snoreConf)
        }

        return ("background", 0)
    }

    private static func snoreProbability(from dict: [String: NSNumber]) -> Double {
        var best = 0.0
        for (key, value) in dict where snoreLabels.contains(key.lowercased()) {
            best = max(best, value.doubleValue)
        }
        return best
    }

    // MARK: - Heuristic fallback (sans .mlmodel)

    private func classifyWithHeuristic(chunk: [Float]) -> SnoreClassificationResult {
        let rate = Double(SnoreAudioPipeline.targetSampleRate)
        guard let buffer = Self.pcmBuffer(from: chunk, sampleRate: rate),
              let features = AudioSpectralFeatures.analyze(buffer: buffer, sampleRate: rate) else {
            return SnoreClassificationResult(isSnore: false, confidence: 0, label: "background", usedCoreML: false)
        }
        guard features.coughScore < 0.45 else {
            return SnoreClassificationResult(isSnore: false, confidence: 0, label: "background", usedCoreML: false)
        }
        let confidence = min(1, max(0, features.snoreScore * 1.1))
        return SnoreClassificationResult(
            isSnore: confidence >= Self.confidenceThreshold,
            confidence: confidence,
            label: confidence >= Self.confidenceThreshold ? "snore" : "background",
            usedCoreML: false
        )
    }

    private static func pcmBuffer(from samples: [Float], sampleRate: Double) -> AVAudioPCMBuffer? {
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
        guard let buffer = AVAudioPCMBuffer(
            pcmFormat: format,
            frameCapacity: AVAudioFrameCount(samples.count)
        ) else { return nil }
        buffer.frameLength = AVAudioFrameCount(samples.count)
        guard let channel = buffer.floatChannelData?[0] else { return nil }
        for (i, s) in samples.enumerated() { channel[i] = s }
        return buffer
    }

    // MARK: - Model loading

    private func loadBundledModel() {
        let url =
            Bundle.main.url(forResource: "SnoreClassifier", withExtension: "mlmodelc")
            ?? Bundle.main.url(forResource: "SnoreClassifier", withExtension: "mlmodel")
        guard let url else { return }

        do {
            let config = MLModelConfiguration()
            config.computeUnits = .cpuAndNeuralEngine
            let loaded = try MLModel(contentsOf: url, configuration: config)
            model = loaded
            introspect(loaded)
        } catch {
            model = nil
        }
    }

    private func introspect(_ model: MLModel) {
        let desc = model.modelDescription
        for (name, info) in desc.inputDescriptionsByName {
            if info.type == .multiArray {
                waveformInputName = name
                break
            }
        }
        for (name, info) in desc.outputDescriptionsByName {
            if info.type == .string {
                labelOutputName = name
            }
            if info.type == .dictionary {
                probabilityOutputName = name
            }
        }
        waveformInputName = waveformInputName
            ?? desc.inputDescriptionsByName.keys.first
            ?? "waveform"
        labelOutputName = labelOutputName
            ?? ["classLabel", "target", "label"].first(where: { desc.outputDescriptionsByName[$0] != nil })
            ?? "classLabel"
        probabilityOutputName = probabilityOutputName
            ?? ["classProbability", "targetProbability", "classProbabilityDict"].first(where: {
                desc.outputDescriptionsByName[$0] != nil
            })
            ?? "classProbability"
    }
}
