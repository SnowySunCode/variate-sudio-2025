import Foundation

protocol EditingFeature {
    var id: String { get }
    var displayName: String { get }
    var description: String { get }
    func canRun(on asset: EditingAsset) -> Bool
    func run(on asset: EditingAsset, params: [String: Any], completion: @escaping (Result<EditingAsset, Error>) -> Void)
}
import Foundation

enum EditingAssetType {
    case video, audio, image
}

class EditingAsset {
    let url: URL
    let type: EditingAssetType

    init(url: URL, type: EditingAssetType) {
        self.url = url
        self.type = type
    }
}
import Foundation

class EditingEngine {
    static let shared = EditingEngine()
    private(set) var features: [EditingFeature] = []

    func register(feature: EditingFeature) {
        features.append(feature)
    }

    func feature(withId id: String) -> EditingFeature? {
        features.first(where: { $0.id == id })
    }
}
func registerAllFeatures() {
    EditingEngine.shared.register(feature: TrimFeature())
    EditingEngine.shared.register(feature: ConcatFeature())
    EditingEngine.shared.register(feature: CropFeature())
    EditingEngine.shared.register(feature: SpeedFeature())
    EditingEngine.shared.register(feature: UpscaleFeature())
    EditingEngine.shared.register(feature: RotateFeature())
    EditingEngine.shared.register(feature: FlipFeature())
    EditingEngine.shared.register(feature: FadeAudioFeature())
    EditingEngine.shared.register(feature: VolumeFeature())
    EditingEngine.shared.register(feature: FrameExportFeature())
    EditingEngine.shared.register(feature: ExportFormatFeature())
    EditingEngine.shared.register(feature: BWFilterFeature())
    EditingEngine.shared.register(feature: SepiaFilterFeature())
    EditingEngine.shared.register(feature: InvertFilterFeature())
    EditingEngine.shared.register(feature: PosterizeFilterFeature())
    EditingEngine.shared.register(feature: VignetteFeature())
    EditingEngine.shared.register(feature: SharpenFeature())
    EditingEngine.shared.register(feature: BlurFeature())
    EditingEngine.shared.register(feature: PixelateFeature())
    EditingEngine.shared.register(feature: BrightnessFeature())
    EditingEngine.shared.register(feature: ContrastFeature())
    EditingEngine.shared.register(feature: SaturationFeature())
    EditingEngine.shared.register(feature: ExposureFeature())
    EditingEngine.shared.register(feature: GammaFeature())
    EditingEngine.shared.register(feature: AddAudioFeature())
    EditingEngine.shared.register(feature: RemoveAudioFeature())
    EditingEngine.shared.register(feature: MergeAudioFeature())
    EditingEngine.shared.register(feature: ExtractAudioFeature())
    EditingEngine.shared.register(feature: AudioToWavFeature())
    EditingEngine.shared.register(feature: FadeVideoFeature())
    EditingEngine.shared.register(feature: AddTextFeature())
    EditingEngine.shared.register(feature: AddImageOverlayFeature())
    EditingEngine.shared.register(feature: AddWatermarkFeature())
    EditingEngine.shared.register(feature: AddBorderFeature())
    EditingEngine.shared.register(feature: AddBackgroundFeature())
    EditingEngine.shared.register(feature: ResizeFeature())
    EditingEngine.shared.register(feature: ChangeFPSFeature())
    EditingEngine.shared.register(feature: ChangeBitrateFeature())
    EditingEngine.shared.register(feature: ChangeCanvasFeature())
    EditingEngine.shared.register(feature: SaveMetadataFeature())
    EditingEngine.shared.register(feature: RemoveMetadataFeature())
    EditingEngine.shared.register(feature: AudioReverseFeature())
    EditingEngine.shared.register(feature: VideoReverseFeature())
    EditingEngine.shared.register(feature: AudioTrimFeature())
    EditingEngine.shared.register(feature: AudioPanFeature())
    EditingEngine.shared.register(feature: AudioEQFeature())
    EditingEngine.shared.register(feature: AudioFadeInFeature())
    EditingEngine.shared.register(feature: AudioFadeOutFeature())
    EditingEngine.shared.register(feature: ExportGifFeature())
    EditingEngine.shared.register(feature: ExportFrameSequenceFeature())
    EditingEngine.shared.register(feature: AspectRatioCropFeature())
    EditingEngine.shared.register(feature: DuplicateVideoFeature())
    EditingEngine.shared.register(feature: DuplicateAudioFeature())
    EditingEngine.shared.register(feature: SimpleTransitionFeature())
    EditingEngine.shared.register(feature: ChromaticAberrationFeature())
    EditingEngine.shared.register(feature: ColorGradingFeature())
    EditingEngine.shared.register(feature: KadrForSocialFeature())
    EditingEngine.shared.register(feature: TextStrokeFeature())
    EditingEngine.shared.register(feature: TitleAnimationFeature())
    EditingEngine.shared.register(feature: ImageAnimationFeature())
    EditingEngine.shared.register(feature: MirrorFeature())
    EditingEngine.shared.register(feature: BlurredBackgroundFeature())
    EditingEngine.shared.register(feature: ColoredBackgroundFeature())
    EditingEngine.shared.register(feature: AudioResampleFeature())
    EditingEngine.shared.register(feature: AudioFormatConvertFeature())
    EditingEngine.shared.register(feature: VideoFormatConvertFeature())
}
import AVFoundation

class TrimFeature: EditingFeature {
    let id = "trim"
    let displayName = "Обрезка видео"
    let description = "Обрезка видео по времени"

    func canRun(on asset: EditingAsset) -> Bool { asset.type == .video }
    func run(on asset: EditingAsset, params: [String: Any], completion: @escaping (Result<EditingAsset, Error>) -> Void) {
        guard let start = params["start"] as? Double,
              let duration = params["duration"] as? Double else {
            completion(.failure(NSError(domain: "Trim", code: 1, userInfo: nil)))
            return
        }
        let avAsset = AVAsset(url: asset.url)
        guard let export = AVAssetExportSession(asset: avAsset, presetName: AVAssetExportPresetHighestQuality) else {
            completion(.failure(NSError(domain: "Trim", code: 2, userInfo: nil)))
            return
        }
        let outputURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + "_trim.mov")
        try? FileManager.default.removeItem(at: outputURL)
        export.outputURL = outputURL
        export.outputFileType = .mov
        let startTime = CMTime(seconds: start, preferredTimescale: 600)
        let durationTime = CMTime(seconds: duration, preferredTimescale: 600)
        export.timeRange = CMTimeRange(start: startTime, duration: durationTime)
        export.exportAsynchronously {
            if export.status == .completed {
                let result = EditingAsset(url: outputURL, type: .video)
                completion(.success(result))
            } else {
                completion(.failure(export.error ?? NSError(domain: "Trim", code: 3, userInfo: nil)))
            }
        }
    }
}
import AVFoundation

class ConcatFeature: EditingFeature {
    let id = "concat"
    let displayName = "Склейка видео"
    let description = "Склеить несколько видео подряд"

    func canRun(on asset: EditingAsset) -> Bool { asset.type == .video }

    func run(on asset: EditingAsset, params: [String: Any], completion: @escaping (Result<EditingAsset, Error>) -> Void) {
        guard let others = params["assets"] as? [EditingAsset] else {
            completion(.failure(NSError(domain: "Concat", code: 1, userInfo: nil)))
            return
        }
        let mixComposition = AVMutableComposition()
        var insertTime = CMTime.zero
        for a in [asset] + others {
            let avAsset = AVAsset(url: a.url)
            guard let track = avAsset.tracks(withMediaType: .video).first else { continue }
            let compTrack = mixComposition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)
            try? compTrack?.insertTimeRange(CMTimeRange(start: .zero, duration: avAsset.duration), of: track, at: insertTime)
            insertTime = CMTimeAdd(insertTime, avAsset.duration)
        }
        guard let export = AVAssetExportSession(asset: mixComposition, presetName: AVAssetExportPresetHighestQuality) else {
            completion(.failure(NSError(domain: "Concat", code: 2, userInfo: nil)))
            return
        }
        let outputURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + "_concat.mov")
        try? FileManager.default.removeItem(at: outputURL)
        export.outputURL = outputURL
        export.outputFileType = .mov
        export.exportAsynchronously {
            if export.status == .completed {
                let result = EditingAsset(url: outputURL, type: .video)
                completion(.success(result))
            } else {
                completion(.failure(export.error ?? NSError(domain: "Concat", code: 3, userInfo: nil)))
            }
        }
    }
}
import AVFoundation

class CropFeature: EditingFeature {
    let id = "crop"
    let displayName = "Кроп видео"
    let description = "Обрезка видеокадра по прямоугольнику"

    func canRun(on asset: EditingAsset) -> Bool { asset.type == .video }

    func run(on asset: EditingAsset, params: [String: Any], completion: @escaping (Result<EditingAsset, Error>) -> Void) {
        guard let x = params["x"] as? CGFloat,
              let y = params["y"] as? CGFloat,
              let w = params["w"] as? CGFloat,
              let h = params["h"] as? CGFloat else {
            completion(.failure(NSError(domain: "Crop", code: 1, userInfo: nil)))
            return
        }
        let avAsset = AVAsset(url: asset.url)
        guard let videoTrack = avAsset.tracks(withMediaType: .video).first,
              let exportSession = AVAssetExportSession(asset: avAsset, presetName: AVAssetExportPresetHighestQuality) else {
            completion(.failure(NSError(domain: "Crop", code: 2, userInfo: nil)))
            return
        }
        let composition = AVMutableVideoComposition()
        composition.renderSize = CGSize(width: w, height: h)
        composition.frameDuration = CMTime(value: 1, timescale: Int32(videoTrack.nominalFrameRate))
        let instruction = AVMutableVideoCompositionInstruction()
        instruction.timeRange = CMTimeRange(start: .zero, duration: avAsset.duration)
        let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: videoTrack)
        let transform = CGAffineTransform(translationX: -x, y: -y)
        layerInstruction.setTransform(transform, at: .zero)
        instruction.layerInstructions = [layerInstruction]
        composition.instructions = [instruction]
        exportSession.videoComposition = composition
        let outputURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + "_crop.mov")
        try? FileManager.default.removeItem(at: outputURL)
        exportSession.outputURL = outputURL
        exportSession.outputFileType = .mov
        exportSession.exportAsynchronously {
            if exportSession.status == .completed {
                let result = EditingAsset(url: outputURL, type: .video)
                completion(.success(result))
            } else {
                completion(.failure(exportSession.error ?? NSError(domain: "Crop", code: 3, userInfo: nil)))
            }
        }
    }
}
import AVFoundation

class SpeedFeature: EditingFeature {
    let id = "speed"
    let displayName = "Изменить скорость"
    let description = "Замедление/ускорение видео"

    func canRun(on asset: EditingAsset) -> Bool { asset.type == .video }

    func run(on asset: EditingAsset, params: [String: Any], completion: @escaping (Result<EditingAsset, Error>) -> Void) {
        guard let factor = params["factor"] as? Float else {
            completion(.failure(NSError(domain: "Speed", code: 1, userInfo: nil)))
            return
        }
        let avAsset = AVAsset(url: asset.url)
        let composition = AVMutableComposition()
        guard let videoTrack = avAsset.tracks(withMediaType: .video).first else {
            completion(.failure(NSError(domain: "Speed", code: 2, userInfo: nil)))
            return
        }
        let compTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)
        try? compTrack?.insertTimeRange(CMTimeRange(start: .zero, duration: avAsset.duration), of: videoTrack, at: .zero)
        compTrack?.scaleTimeRange(CMTimeRange(start: .zero, duration: avAsset.duration), toDuration: CMTimeMultiplyByFloat64(avAsset.duration, multiplier: 1/Double(factor)))
        let outputURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + "_speed.mov")
        try? FileManager.default.removeItem(at: outputURL)
        guard let exportSession = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetHighestQuality) else {
            completion(.failure(NSError(domain: "Speed", code: 3, userInfo: nil)))
            return
        }
        exportSession.outputURL = outputURL
        exportSession.outputFileType = .mov
        exportSession.exportAsynchronously {
            if exportSession.status == .completed {
                let result = EditingAsset(url: outputURL, type: .video)
                completion(.success(result))
            } else {
                completion(.failure(exportSession.error ?? NSError(domain: "Speed", code: 4, userInfo: nil)))
            }
        }
    }
}
import AVFoundation

class UpscaleFeature: EditingFeature {
    let id = "upscale"
    let displayName = "Апскейл видео"
    let description = "Масштабирование видео до большего разрешения"

    func canRun(on asset: EditingAsset) -> Bool { asset.type == .video }

    func run(on asset: EditingAsset, params: [String: Any], completion: @escaping (Result<EditingAsset, Error>) -> Void) {
        guard let width = params["width"] as? CGFloat,
              let height = params["height"] as? CGFloat else {
            completion(.failure(NSError(domain: "Upscale", code: 1, userInfo: nil)))
            return
        }
        let avAsset = AVAsset(url: asset.url)
        guard let videoTrack = avAsset.tracks(withMediaType: .video).first,
              let exportSession = AVAssetExportSession(asset: avAsset, presetName: AVAssetExportPresetHighestQuality) else {
            completion(.failure(NSError(domain: "Upscale", code: 2, userInfo: nil)))
            return
        }
        let composition = AVMutableVideoComposition()
        composition.renderSize = CGSize(width: width, height: height)
        composition.frameDuration = CMTime(value: 1, timescale: Int32(videoTrack.nominalFrameRate))
        let instruction = AVMutableVideoCompositionInstruction()
        instruction.timeRange = CMTimeRange(start: .zero, duration: avAsset.duration)
        let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: videoTrack)
        let scale = CGAffineTransform(scaleX: width / videoTrack.naturalSize.width, y: height / videoTrack.naturalSize.height)
        layerInstruction.setTransform(scale, at: .zero)
        instruction.layerInstructions = [layerInstruction]
        composition.instructions = [instruction]
        exportSession.videoComposition = composition
        let outputURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + "_upscale.mov")
        try? FileManager.default.removeItem(at: outputURL)
        exportSession.outputURL = outputURL
        exportSession.outputFileType = .mov
        exportSession.exportAsynchronously {
            if exportSession.status == .completed {
                let result = EditingAsset(url: outputURL, type: .video)
                completion(.success(result))
            } else {
                completion(.failure(exportSession.error ?? NSError(domain: "Upscale", code: 3, userInfo: nil)))
            }
        }
    }
}
import AVFoundation

class RotateFeature: EditingFeature {
    let id = "rotate"
    let displayName = "Повернуть видео"
    let description = "Поворот видео на угол"

    func canRun(on asset: EditingAsset) -> Bool { asset.type == .video }

    func run(on asset: EditingAsset, params: [String: Any], completion: @escaping (Result<EditingAsset, Error>) -> Void) {
        guard let angle = params["angle"] as? CGFloat else {
            completion(.failure(NSError(domain: "Rotate", code: 1, userInfo: nil)))
            return
        }
        let avAsset = AVAsset(url: asset.url)
        guard let videoTrack = avAsset.tracks(withMediaType: .video).first,
              let exportSession = AVAssetExportSession(asset: avAsset, presetName: AVAssetExportPresetHighestQuality) else {
            completion(.failure(NSError(domain: "Rotate", code: 2, userInfo: nil)))
            return
        }
        let composition = AVMutableVideoComposition()
        composition.renderSize = videoTrack.naturalSize
        composition.frameDuration = CMTime(value: 1, timescale: Int32(videoTrack.nominalFrameRate))
        let instruction = AVMutableVideoCompositionInstruction()
        instruction.timeRange = CMTimeRange(start: .zero, duration: avAsset.duration)
        let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: videoTrack)
        let t = CGAffineTransform(rotationAngle: angle)
        layerInstruction.setTransform(t, at: .zero)
        instruction.layerInstructions = [layerInstruction]
        composition.instructions = [instruction]
        exportSession.videoComposition = composition
        let outputURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + "_rot.mov")
        try? FileManager.default.removeItem(at: outputURL)
        exportSession.outputURL = outputURL
        exportSession.outputFileType = .mov
        exportSession.exportAsynchronously {
            if exportSession.status == .completed {
                let result = EditingAsset(url: outputURL, type: .video)
                completion(.success(result))
            } else {
                completion(.failure(exportSession.error ?? NSError(domain: "Rotate", code: 3, userInfo: nil)))
            }
        }
    }
}
import AVFoundation

class FlipFeature: EditingFeature {
    let id = "flip"
    let displayName = "Отразить видео"
    let description = "Отразить по горизонтали/вертикали"

    func canRun(on asset: EditingAsset) -> Bool { asset.type == .video }

    func run(on asset: EditingAsset, params: [String: Any], completion: @escaping (Result<EditingAsset, Error>) -> Void) {
        guard let horizontal = params["horizontal"] as? Bool,
              let vertical = params["vertical"] as? Bool else {
            completion(.failure(NSError(domain: "Flip", code: 1, userInfo: nil)))
            return
        }
        let avAsset = AVAsset(url: asset.url)
        guard let videoTrack = avAsset.tracks(withMediaType: .video).first,
              let exportSession = AVAssetExportSession(asset: avAsset, presetName: AVAssetExportPresetHighestQuality) else {
            completion(.failure(NSError(domain: "Flip", code: 2, userInfo: nil)))
            return
        }
        let composition = AVMutableVideoComposition()
        composition.renderSize = videoTrack.naturalSize
        composition.frameDuration = CMTime(value: 1, timescale: Int32(videoTrack.nominalFrameRate))
        let instruction = AVMutableVideoCompositionInstruction()
        instruction.timeRange = CMTimeRange(start: .zero, duration: avAsset.duration)
        let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: videoTrack)
        var t = CGAffineTransform.identity
        if horizontal { t = t.scaledBy(x: -1, y: 1).translatedBy(x: -videoTrack.naturalSize.width, y: 0) }
        if vertical { t = t.scaledBy(x: 1, y: -1).translatedBy(x: 0, y: -videoTrack.naturalSize.height) }
        layerInstruction.setTransform(t, at: .zero)
        instruction.layerInstructions = [layerInstruction]
        composition.instructions = [instruction]
        exportSession.videoComposition = composition
        let outputURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + "_flip.mov")
        try? FileManager.default.removeItem(at: outputURL)
        exportSession.outputURL = outputURL
        exportSession.outputFileType = .mov
        exportSession.exportAsynchronously {
            if exportSession.status == .completed {
                let result = EditingAsset(url: outputURL, type: .video)
                completion(.success(result))
            } else {
                completion(.failure(exportSession.error ?? NSError(domain: "Flip", code: 3, userInfo: nil)))
            }
        }
    }
}
import AVFoundation

class FadeAudioFeature: EditingFeature {
    let id = "fade_audio"
    let displayName = "Аудио Fade In/Out"
    let description = "Плавное появление и затухание аудио дорожки"

    func canRun(on asset: EditingAsset) -> Bool { asset.type == .video || asset.type == .audio }

    func run(on asset: EditingAsset, params: [String: Any], completion: @escaping (Result<EditingAsset, Error>) -> Void) {
        // Пример — fade in/out для аудиотрека через AVMutableAudioMixInputParameters
        guard let fadeIn = params["fadeIn"] as? Double,
              let fadeOut = params["fadeOut"] as? Double else {
            completion(.failure(NSError(domain: "FadeAudio", code: 1, userInfo: nil)))
            return
        }
        let avAsset = AVAsset(url: asset.url)
        guard let audioTrack = avAsset.tracks(withMediaType: .audio).first else {
            completion(.failure(NSError(domain: "FadeAudio", code: 2, userInfo: nil)))
            return
        }
        let mix = AVMutableAudioMix()
        let params = AVMutableAudioMixInputParameters(track: audioTrack)
        params.setVolumeRamp(fromStartVolume: 0, toEndVolume: 1, timeRange: CMTimeRange(start: .zero, duration: CMTime(seconds: fadeIn, preferredTimescale: 600)))
        params.setVolumeRamp(fromStartVolume: 1, toEndVolume: 0, timeRange: CMTimeRange(start: avAsset.duration - CMTime(seconds: fadeOut, preferredTimescale: 600), duration: CMTime(seconds: fadeOut, preferredTimescale: 600)))
        mix.inputParameters = [params]
        guard let export = AVAssetExportSession(asset: avAsset, presetName: AVAssetExportPresetAppleM4A) else {
            completion(.failure(NSError(domain: "FadeAudio", code: 3, userInfo: nil)))
            return
        }
        let outputURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + "_fadeaudio.m4a")
        try? FileManager.default.removeItem(at: outputURL)
        export.outputURL = outputURL
        export.outputFileType = .m4a
        export.audioMix = mix
        export.exportAsynchronously {
            if export.status == .completed {
                let result = EditingAsset(url: outputURL, type: .audio)
                completion(.success(result))
            } else {
                completion(.failure(export.error ?? NSError(domain: "FadeAudio", code: 4, userInfo: nil)))
            }
        }
    }
}
import AVFoundation

class VolumeFeature: EditingFeature {
    let id = "volume"
    let displayName = "Изменить громкость"
    let description = "Изменить громкость аудио дорожки"

    func canRun(on asset: EditingAsset) -> Bool { asset.type == .audio || asset.type == .video }

    func run(on asset: EditingAsset, params: [String: Any], completion: @escaping (Result<EditingAsset, Error>) -> Void) {
        guard let newVolume = params["volume"] as? Float else {
            completion(.failure(NSError(domain: "Volume", code: 1, userInfo: nil)))
            return
        }
        let avAsset = AVAsset(url: asset.url)
        guard let audioTrack = avAsset.tracks(withMediaType: .audio).first else {
            completion(.failure(NSError(domain: "Volume", code: 2, userInfo: nil)))
            return
        }
        let mix = AVMutableAudioMix()
        let params = AVMutableAudioMixInputParameters(track: audioTrack)
        params.setVolume(newVolume, at: .zero)
        mix.inputParameters = [params]
        guard let export = AVAssetExportSession(asset: avAsset, presetName: AVAssetExportPresetAppleM4A) else {
            completion(.failure(NSError(domain: "Volume", code: 3, userInfo: nil)))
            return
        }
        let outputURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + "_volume.m4a")
        try? FileManager.default.removeItem(at: outputURL)
        export.outputURL = outputURL
        export.outputFileType = .m4a
        export.audioMix = mix
        export.exportAsynchronously {
            if export.status == .completed {
                let result = EditingAsset(url: outputURL, type: .audio)
                completion(.success(result))
            } else {
                completion(.failure(export.error ?? NSError(domain: "Volume", code: 4, userInfo: nil)))
            }
        }
    }
}
import AVFoundation
import UIKit

class FrameExportFeature: EditingFeature {
    let id = "frame_export"
    let displayName = "Экспорт кадра"
    let description = "Сохранить кадр из видео в файл"

    func canRun(on asset: EditingAsset) -> Bool { asset.type == .video }

    func run(on asset: EditingAsset, params: [String: Any], completion: @escaping (Result<EditingAsset, Error>) -> Void) {
        guard let timeSeconds = params["time"] as? Double else {
            completion(.failure(NSError(domain: "FrameExport", code: 1, userInfo: nil)))
            return
        }
        let avAsset = AVAsset(url: asset.url)
        let generator = AVAssetImageGenerator(asset: avAsset)
        generator.appliesPreferredTrackTransform = true
        let time = CMTime(seconds: timeSeconds, preferredTimescale: 600)
        do {
            let cgImage = try generator.copyCGImage(at: time, actualTime: nil)
            let uiImage = UIImage(cgImage: cgImage)
            let outputURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + "_frame.jpg")
            if let data = uiImage.jpegData(compressionQuality: 1.0) {
                try? data.write(to: outputURL)
                let result = EditingAsset(url: outputURL, type: .image)
                completion(.success(result))
            } else {
                completion(.failure(NSError(domain: "FrameExport", code: 4, userInfo: nil)))
            }
        } catch {
            completion(.failure(error))
        }
    }
}
import AVFoundation

class ExportFormatFeature: EditingFeature {
    let id = "export_format"
    let displayName = "Экспорт в формат"
    let description = "Экспорт видео или аудио в другой формат"

    func canRun(on asset: EditingAsset) -> Bool { asset.type == .video || asset.type == .audio }

    func run(on asset: EditingAsset, params: [String: Any], completion: @escaping (Result<EditingAsset, Error>) -> Void) {
        guard let format = params["format"] as? String else {
            completion(.failure(NSError(domain: "ExportFormat", code: 1, userInfo: nil)))
            return
        }
        let avAsset = AVAsset(url: asset.url)
        let preset: String
        let fileType: AVFileType
        let ext: String
        switch format {
        case "mp4":
            preset = AVAssetExportPresetHighestQuality
            fileType = .mp4
            ext = "mp4"
        case "mov":
            preset = AVAssetExportPresetHighestQuality
            fileType = .mov
            ext = "mov"
        case "m4a":
            preset = AVAssetExportPresetAppleM4A
            fileType = .m4a
            ext = "m4a"
        case "wav":
            preset = AVAssetExportPresetPassthrough
            fileType = .wav
            ext = "wav"
        default:
            completion(.failure(NSError(domain: "ExportFormat", code: 2, userInfo: nil)))
            return
        }
        guard let export = AVAssetExportSession(asset: avAsset, presetName: preset) else {
            completion(.failure(NSError(domain: "ExportFormat", code: 3, userInfo: nil)))
            return
        }
        let outputURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + "_export.\(ext)")
        try? FileManager.default.removeItem(at: outputURL)
        export.outputURL = outputURL
        export.outputFileType = fileType
        export.exportAsynchronously {
            if export.status == .completed {
                let result = EditingAsset(url: outputURL, type: asset.type)
                completion(.success(result))
            } else {
                completion(.failure(export.error ?? NSError(domain: "ExportFormat", code: 4, userInfo: nil)))
            }
        }
    }
}
import AVFoundation
import CoreImage
import UIKit

class BWFilterFeature: EditingFeature {
    let id = "bw_filter"
    let displayName = "Чёрно-белый фильтр"
    let description = "Конвертирует видео или изображение в чёрно-белое"

    func canRun(on asset: EditingAsset) -> Bool { asset.type == .video || asset.type == .image }

    func run(on asset: EditingAsset, params: [String: Any], completion: @escaping (Result<EditingAsset, Error>) -> Void) {
        if asset.type == .image {
            guard let inputImage = CIImage(contentsOf: asset.url) else {
                completion(.failure(NSError(domain: "BWFilter", code: 1, userInfo: nil)))
                return
            }
            let filter = CIFilter(name: "CIPhotoEffectMono")
            filter?.setValue(inputImage, forKey: kCIInputImageKey)
            guard let output = filter?.outputImage else {
                completion(.failure(NSError(domain: "BWFilter", code: 2, userInfo: nil)))
                return
            }
            let context = CIContext()
            guard let cgimg = context.createCGImage(output, from: output.extent) else {
                completion(.failure(NSError(domain: "BWFilter", code: 3, userInfo: nil)))
                return
            }
            let ui = UIImage(cgImage: cgimg)
            let outputURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + "_bw.jpg")
            if let data = ui.jpegData(compressionQuality: 1.0) {
                try? data.write(to: outputURL)
                let result = EditingAsset(url: outputURL, type: .image)
                completion(.success(result))
            } else {
                completion(.failure(NSError(domain: "BWFilter", code: 4, userInfo: nil)))
            }
        } else {
            // Для видео реализуется через AVVideoComposition и CIFilter
            completion(.failure(NSError(domain: "BWFilter", code: 99, userInfo: [NSLocalizedDescriptionKey: "Реализуй через AVVideoComposition с CIFilter"])))
        }
    }
}
import AVFoundation
import CoreImage
import UIKit

class SepiaFilterFeature: EditingFeature {
    let id = "sepia_filter"
    let displayName = "Сепия фильтр"
    let description = "Тонирование изображения или видео в сепию"

    func canRun(on asset: EditingAsset) -> Bool { asset.type == .video || asset.type == .image }

    func run(on asset: EditingAsset, params: [String: Any], completion: @escaping (Result<EditingAsset, Error>) -> Void) {
        if asset.type == .image {
            guard let inputImage = CIImage(contentsOf: asset.url) else {
                completion(.failure(NSError(domain: "SepiaFilter", code: 1, userInfo: nil)))
                return
            }
            let filter = CIFilter(name: "CISepiaTone")
            filter?.setValue(inputImage, forKey: kCIInputImageKey)
            filter?.setValue(1.0, forKey: kCIInputIntensityKey)
            guard let output = filter?.outputImage else {
                completion(.failure(NSError(domain: "SepiaFilter", code: 2, userInfo: nil)))
                return
            }
            let context = CIContext()
            guard let cgimg = context.createCGImage(output, from: output.extent) else {
                completion(.failure(NSError(domain: "SepiaFilter", code: 3, userInfo: nil)))
                return
            }
            let ui = UIImage(cgImage: cgimg)
            let outputURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + "_sepia.jpg")
            if let data = ui.jpegData(compressionQuality: 1.0) {
                try? data.write(to: outputURL)
                let result = EditingAsset(url: outputURL, type: .image)
                completion(.success(result))
            } else {
                completion(.failure(NSError(domain: "SepiaFilter", code: 4, userInfo: nil)))
            }
        } else {
            // Для видео реализуется через AVVideoComposition и CIFilter
            completion(.failure(NSError(domain: "SepiaFilter", code: 99, userInfo: [NSLocalizedDescriptionKey: "Реализуй через AVVideoComposition с CIFilter"])))
        }
    }
}
import AVFoundation
import CoreImage
import UIKit

class InvertFilterFeature: EditingFeature {
    let id = "invert_filter"
    let displayName = "Инверсия цвета"
    let description = "Инвертирует цвета изображения или видео"

    func canRun(on asset: EditingAsset) -> Bool { asset.type == .video || asset.type == .image }

    func run(on asset: EditingAsset, params: [String: Any], completion: @escaping (Result<EditingAsset, Error>) -> Void) {
        if asset.type == .image {
            guard let inputImage = CIImage(contentsOf: asset.url) else {
                completion(.failure(NSError(domain: "InvertFilter", code: 1, userInfo: nil)))
                return
            }
            let filter = CIFilter(name: "CIColorInvert")
            filter?.setValue(inputImage, forKey: kCIInputImageKey)
            guard let output = filter?.outputImage else {
                completion(.failure(NSError(domain: "InvertFilter", code: 2, userInfo: nil)))
                return
            }
            let context = CIContext()
            guard let cgimg = context.createCGImage(output, from: output.extent) else {
                completion(.failure(NSError(domain: "InvertFilter", code: 3, userInfo: nil)))
                return
            }
            let ui = UIImage(cgImage: cgimg)
            let outputURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + "_invert.jpg")
            if let data = ui.jpegData(compressionQuality: 1.0) {
                try? data.write(to: outputURL)
                let result = EditingAsset(url: outputURL, type: .image)
                completion(.success(result))
            } else {
                completion(.failure(NSError(domain: "InvertFilter", code: 4, userInfo: nil)))
            }
        } else {
            // Для видео реализуется через AVVideoComposition и CIFilter
            completion(.failure(NSError(domain: "InvertFilter", code: 99, userInfo: [NSLocalizedDescriptionKey: "Реализуй через AVVideoComposition с CIFilter"])))
        }
    }
}
import AVFoundation
import CoreImage
import UIKit

class PosterizeFilterFeature: EditingFeature {
    let id = "posterize_filter"
    let displayName = "Постеризация"
    let description = "Постеризация изображения или видео"

    func canRun(on asset: EditingAsset) -> Bool { asset.type == .video || asset.type == .image }

    func run(on asset: EditingAsset, params: [String: Any], completion: @escaping (Result<EditingAsset, Error>) -> Void) {
        if asset.type == .image {
            guard let inputImage = CIImage(contentsOf: asset.url) else {
                completion(.failure(NSError(domain: "PosterizeFilter", code: 1, userInfo: nil)))
                return
            }
            let filter = CIFilter(name: "CIColorPosterize")
            filter?.setValue(inputImage, forKey: kCIInputImageKey)
            filter?.setValue(params["levels"] ?? 6, forKey: "inputLevels")
            guard let output = filter?.outputImage else {
                completion(.failure(NSError(domain: "PosterizeFilter", code: 2, userInfo: nil)))
                return
            }
            let context = CIContext()
            guard let cgimg = context.createCGImage(output, from: output.extent) else {
                completion(.failure(NSError(domain: "PosterizeFilter", code: 3, userInfo: nil)))
                return
            }
            let ui = UIImage(cgImage: cgimg)
            let outputURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + "_poster.jpg")
            if let data = ui.jpegData(compressionQuality: 1.0) {
                try? data.write(to: outputURL)
                let result = EditingAsset(url: outputURL, type: .image)
                completion(.success(result))
            } else {
                completion(.failure(NSError(domain: "PosterizeFilter", code: 4, userInfo: nil)))
            }
        } else {
            // Для видео реализуется через AVVideoComposition и CIFilter
            completion(.failure(NSError(domain: "PosterizeFilter", code: 99, userInfo: [NSLocalizedDescriptionKey: "Реализуй через AVVideoComposition с CIFilter"])))
        }
    }
}
import AVFoundation
import CoreImage
import UIKit

class VignetteFeature: EditingFeature {
    let id = "vignette_filter"
    let displayName = "Виньетирование"
    let description = "Добавить виньетку на изображение или видео"

    func canRun(on asset: EditingAsset) -> Bool { asset.type == .video || asset.type == .image }

    func run(on asset: EditingAsset, params: [String: Any], completion: @escaping (Result<EditingAsset, Error>) -> Void) {
        if asset.type == .image {
            guard let inputImage = CIImage(contentsOf: asset.url) else {
                completion(.failure(NSError(domain: "VignetteFilter", code: 1, userInfo: nil)))
                return
            }
            let filter = CIFilter(name: "CIVignette")
            filter?.setValue(inputImage, forKey: kCIInputImageKey)
            filter?.setValue(params["intensity"] ?? 1.0, forKey: kCIInputIntensityKey)
            filter?.setValue(params["radius"] ?? 2.0, forKey: kCIInputRadiusKey)
            guard let output = filter?.outputImage else {
                completion(.failure(NSError(domain: "VignetteFilter", code: 2, userInfo: nil)))
                return
            }
            let context = CIContext()
            guard let cgimg = context.createCGImage(output, from: output.extent) else {
                completion(.failure(NSError(domain: "VignetteFilter", code: 3, userInfo: nil)))
                return
            }
            let ui = UIImage(cgImage: cgimg)
            let outputURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + "_vignette.jpg")
            if let data = ui.jpegData(compressionQuality: 1.0) {
                try? data.write(to: outputURL)
                let result = EditingAsset(url: outputURL, type: .image)
                completion(.success(result))
            } else {
                completion(.failure(NSError(domain: "VignetteFilter", code: 4, userInfo: nil)))
            }
        } else {
            // Для видео реализуется через AVVideoComposition и CIFilter
            completion(.failure(NSError(domain: "VignetteFilter", code: 99, userInfo: [NSLocalizedDescriptionKey: "Реализуй через AVVideoComposition с CIFilter"])))
        }
    }
}
import AVFoundation
import CoreImage
import UIKit

class SharpenFeature: EditingFeature {
    let id = "sharpen_filter"
    let displayName = "Резкость"
    let description = "Изменить резкость изображения или видео"

    func canRun(on asset: EditingAsset) -> Bool { asset.type == .video || asset.type == .image }

    func run(on asset: EditingAsset, params: [String: Any], completion: @escaping (Result<EditingAsset, Error>) -> Void) {
        if asset.type == .image {
            guard let inputImage = CIImage(contentsOf: asset.url) else {
                completion(.failure(NSError(domain: "SharpenFilter", code: 1, userInfo: nil)))
                return
            }
            let filter = CIFilter(name: "CISharpenLuminance")
            filter?.setValue(inputImage, forKey: kCIInputImageKey)
            filter?.setValue(params["sharpness"] ?? 0.4, forKey: kCIInputSharpnessKey)
            guard let output = filter?.outputImage else {
                completion(.failure(NSError(domain: "SharpenFilter", code: 2, userInfo: nil)))
                return
            }
            let context = CIContext()
            guard let cgimg = context.createCGImage(output, from: output.extent) else {
                completion(.failure(NSError(domain: "SharpenFilter", code: 3, userInfo: nil)))
                return
            }
            let ui = UIImage(cgImage: cgimg)
            let outputURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + "_sharpen.jpg")
            if let data = ui.jpegData(compressionQuality: 1.0) {
                try? data.write(to: outputURL)
                let result = EditingAsset(url: outputURL, type: .image)
                completion(.success(result))
            } else {
                completion(.failure(NSError(domain: "SharpenFilter", code: 4, userInfo: nil)))
            }
        } else {
            // Для видео реализуется через AVVideoComposition и CIFilter
            completion(.failure(NSError(domain: "SharpenFilter", code: 99, userInfo: [NSLocalizedDescriptionKey: "Реализуй через AVVideoComposition с CIFilter"])))
        }
    }
}
import AVFoundation
import CoreImage
import UIKit

class BlurFeature: EditingFeature {
    let id = "blur_filter"
    let displayName = "Размытие"
    let description = "Размытие изображения или видео"

    func canRun(on asset: EditingAsset) -> Bool { asset.type == .video || asset.type == .image }

    func run(on asset: EditingAsset, params: [String: Any], completion: @escaping (Result<EditingAsset, Error>) -> Void) {
        if asset.type == .image {
            guard let inputImage = CIImage(contentsOf: asset.url) else {
                completion(.failure(NSError(domain: "BlurFilter", code: 1, userInfo: nil)))
                return
            }
            let filter = CIFilter(name: "CIGaussianBlur")
            filter?.setValue(inputImage, forKey: kCIInputImageKey)
            filter?.setValue(params["radius"] ?? 8.0, forKey: kCIInputRadiusKey)
            guard let output = filter?.outputImage else {
                completion(.failure(NSError(domain: "BlurFilter", code: 2, userInfo: nil)))
                return
            }
            let context = CIContext()
            guard let cgimg = context.createCGImage(output, from: inputImage.extent) else {
                completion(.failure(NSError(domain: "BlurFilter", code: 3, userInfo: nil)))
                return
            }
            let ui = UIImage(cgImage: cgimg)
            let outputURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + "_blur.jpg")
            if let data = ui.jpegData(compressionQuality: 1.0) {
                try? data.write(to: outputURL)
                let result = EditingAsset(url: outputURL, type: .image)
                completion(.success(result))
            } else {
                completion(.failure(NSError(domain: "BlurFilter", code: 4, userInfo: nil)))
            }
        } else {
            // Для видео реализуется через AVVideoComposition и CIFilter
            completion(.failure(NSError(domain: "BlurFilter", code: 99, userInfo: [NSLocalizedDescriptionKey: "Реализуй через AVVideoComposition с CIFilter"])))
        }
    }
}

import AVFoundation
import CoreImage
import UIKit

class PixelateFeature: EditingFeature {
    let id = "pixelate_filter"
    let displayName = "Пикселизация"
    let description = "Пикселизация изображения или видео"

    func canRun(on asset: EditingAsset) -> Bool { asset.type == .video || asset.type == .image }

    func run(on asset: EditingAsset, params: [String: Any], completion: @escaping (Result<EditingAsset, Error>) -> Void) {
        if asset.type == .image {
            guard let inputImage = CIImage(contentsOf: asset.url) else {
                completion(.failure(NSError(domain: "PixelateFilter", code: 1, userInfo: nil)))
                return
            }
            let filter = CIFilter(name: "CIPixellate")
            filter?.setValue(inputImage, forKey: kCIInputImageKey)
            filter?.setValue(params["scale"] ?? 10.0, forKey: kCIInputScaleKey)
            guard let output = filter?.outputImage else {
                completion(.failure(NSError(domain: "PixelateFilter", code: 2, userInfo: nil)))
                return
            }
            let context = CIContext()
            guard let cgimg = context.createCGImage(output, from: output.extent) else {
                completion(.failure(NSError(domain: "PixelateFilter", code: 3, userInfo: nil)))
                return
            }
            let ui = UIImage(cgImage: cgimg)
            let outputURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + "_pixelate.jpg")
            if let data = ui.jpegData(compressionQuality: 1.0) {
                try? data.write(to: outputURL)
                let result = EditingAsset(url: outputURL, type: .image)
                completion(.success(result))
            } else {
                completion(.failure(NSError(domain: "PixelateFilter", code: 4, userInfo: nil)))
            }
        } else {
            // Для видео реализуется через AVVideoComposition и CIFilter
            completion(.failure(NSError(domain: "PixelateFilter", code: 99, userInfo: [NSLocalizedDescriptionKey: "Реализуй через AVVideoComposition с CIFilter"])))
        }
    }
}
import AVFoundation
import CoreImage
import UIKit

class BrightnessFeature: EditingFeature {
    let id = "brightness"
    let displayName = "Яркость"
    let description = "Изменить яркость изображения или видео"

    func canRun(on asset: EditingAsset) -> Bool { asset.type == .video || asset.type == .image }

    func run(on asset: EditingAsset, params: [String: Any], completion: @escaping (Result<EditingAsset, Error>) -> Void) {
        if asset.type == .image {
            guard let inputImage = CIImage(contentsOf: asset.url) else {
                completion(.failure(NSError(domain: "Brightness", code: 1, userInfo: nil)))
                return
            }
            let filter = CIFilter(name: "CIColorControls")
            filter?.setValue(inputImage, forKey: kCIInputImageKey)
            filter?.setValue(params["brightness"] ?? 0.0, forKey: kCIInputBrightnessKey)
            guard let output = filter?.outputImage else {
                completion(.failure(NSError(domain: "Brightness", code: 2, userInfo: nil)))
                return
            }
            let context = CIContext()
            guard let cgimg = context.createCGImage(output, from: output.extent) else {
                completion(.failure(NSError(domain: "Brightness", code: 3, userInfo: nil)))
                return
            }
            let ui = UIImage(cgImage: cgimg)
            let outputURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + "_brightness.jpg")
            if let data = ui.jpegData(compressionQuality: 1.0) {
                try? data.write(to: outputURL)
                let result = EditingAsset(url: outputURL, type: .image)
                completion(.success(result))
            } else {
                completion(.failure(NSError(domain: "Brightness", code: 4, userInfo: nil)))
            }
        } else {
            // Для видео реализуется через AVVideoComposition и CIFilter
            completion(.failure(NSError(domain: "Brightness", code: 99, userInfo: [NSLocalizedDescriptionKey: "Реализуй через AVVideoComposition с CIFilter"])))
        }
    }
}
import AVFoundation
import CoreImage
import UIKit

class ContrastFeature: EditingFeature {
    let id = "contrast"
    let displayName = "Контраст"
    let description = "Изменить контраст изображения или видео"

    func canRun(on asset: EditingAsset) -> Bool { asset.type == .video || asset.type == .image }

    func run(on asset: EditingAsset, params: [String: Any], completion: @escaping (Result<EditingAsset, Error>) -> Void) {
        if asset.type == .image {
            guard let inputImage = CIImage(contentsOf: asset.url) else {
                completion(.failure(NSError(domain: "Contrast", code: 1, userInfo: nil)))
                return
            }
            let filter = CIFilter(name: "CIColorControls")
            filter?.setValue(inputImage, forKey: kCIInputImageKey)
            filter?.setValue(params["contrast"] ?? 1.0, forKey: kCIInputContrastKey)
            guard let output = filter?.outputImage else {
                completion(.failure(NSError(domain: "Contrast", code: 2, userInfo: nil)))
                return
            }
            let context = CIContext()
            guard let cgimg = context.createCGImage(output, from: output.extent) else {
                completion(.failure(NSError(domain: "Contrast", code: 3, userInfo: nil)))
                return
            }
            let ui = UIImage(cgImage: cgimg)
            let outputURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + "_contrast.jpg")
            if let data = ui.jpegData(compressionQuality: 1.0) {
                try? data.write(to: outputURL)
                let result = EditingAsset(url: outputURL, type: .image)
                completion(.success(result))
            } else {
                completion(.failure(NSError(domain: "Contrast", code: 4, userInfo: nil)))
            }
        } else {
            // Для видео реализуется через AVVideoComposition и CIFilter
            completion(.failure(NSError(domain: "Contrast", code: 99, userInfo: [NSLocalizedDescriptionKey: "Реализуй через AVVideoComposition с CIFilter"])))
        }
    }
}
import AVFoundation
import CoreImage
import UIKit

class SaturationFeature: EditingFeature {
    let id = "saturation"
    let displayName = "Насыщенность"
    let description = "Изменить насыщенность изображения или видео"

    func canRun(on asset: EditingAsset) -> Bool { asset.type == .video || asset.type == .image }

    func run(on asset: EditingAsset, params: [String: Any], completion: @escaping (Result<EditingAsset, Error>) -> Void) {
        if asset.type == .image {
            guard let inputImage = CIImage(contentsOf: asset.url) else {
                completion(.failure(NSError(domain: "Saturation", code: 1, userInfo: nil)))
                return
            }
            let filter = CIFilter(name: "CIColorControls")
            filter?.setValue(inputImage, forKey: kCIInputImageKey)
            filter?.setValue(params["saturation"] ?? 1.0, forKey: kCIInputSaturationKey)
            guard let output = filter?.outputImage else {
                completion(.failure(NSError(domain: "Saturation", code: 2, userInfo: nil)))
                return
            }
            let context = CIContext()
            guard let cgimg = context.createCGImage(output, from: output.extent) else {
                completion(.failure(NSError(domain: "Saturation", code: 3, userInfo: nil)))
                return
            }
            let ui = UIImage(cgImage: cgimg)
            let outputURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + "_saturation.jpg")
            if let data = ui.jpegData(compressionQuality: 1.0) {
                try? data.write(to: outputURL)
                let result = EditingAsset(url: outputURL, type: .image)
                completion(.success(result))
            } else {
                completion(.failure(NSError(domain: "Saturation", code: 4, userInfo: nil)))
            }
        } else {
            // Для видео реализуется через AVVideoComposition и CIFilter
            completion(.failure(NSError(domain: "Saturation", code: 99, userInfo: [NSLocalizedDescriptionKey: "Реализуй через AVVideoComposition с CIFilter"])))
        }
    }
}
import AVFoundation
import CoreImage
import UIKit

class ExposureFeature: EditingFeature {
    let id = "exposure"
    let displayName = "Экспозиция"
    let description = "Изменить экспозицию изображения или видео"

    func canRun(on asset: EditingAsset) -> Bool { asset.type == .video || asset.type == .image }

    func run(on asset: EditingAsset, params: [String: Any], completion: @escaping (Result<EditingAsset, Error>) -> Void) {
        if asset.type == .image {
            guard let inputImage = CIImage(contentsOf: asset.url) else {
                completion(.failure(NSError(domain: "Exposure", code: 1, userInfo: nil)))
                return
            }
            let filter = CIFilter(name: "CIExposureAdjust")
            filter?.setValue(inputImage, forKey: kCIInputImageKey)
            filter?.setValue(params["ev"] ?? 0.0, forKey: kCIInputEVKey)
            guard let output = filter?.outputImage else {
                completion(.failure(NSError(domain: "Exposure", code: 2, userInfo: nil)))
                return
            }
            let context = CIContext()
            guard let cgimg = context.createCGImage(output, from: output.extent) else {
                completion(.failure(NSError(domain: "Exposure", code: 3, userInfo: nil)))
                return
            }
            let ui = UIImage(cgImage: cgimg)
            let outputURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + "_exposure.jpg")
            if let data = ui.jpegData(compressionQuality: 1.0) {
                try? data.write(to: outputURL)
                let result = EditingAsset(url: outputURL, type: .image)
                completion(.success(result))
            } else {
                completion(.failure(NSError(domain: "Exposure", code: 4, userInfo: nil)))
            }
        } else {
            // Для видео реализуется через AVVideoComposition и CIFilter
            completion(.failure(NSError(domain: "Exposure", code: 99, userInfo: [NSLocalizedDescriptionKey: "Реализуй через AVVideoComposition с CIFilter"])))
        }
    }
}
import AVFoundation
import CoreImage
import UIKit

class GammaFeature: EditingFeature {
    let id = "gamma"
    let displayName = "Гамма-коррекция"
    let description = "Изменение гаммы изображения или видео"

    func canRun(on asset: EditingAsset) -> Bool { asset.type == .video || asset.type == .image }

    func run(on asset: EditingAsset, params: [String: Any], completion: @escaping (Result<EditingAsset, Error>) -> Void) {
        if asset.type == .image {
            guard let inputImage = CIImage(contentsOf: asset.url) else {
                completion(.failure(NSError(domain: "Gamma", code: 1, userInfo: nil)))
                return
            }
            let filter = CIFilter(name: "CIGammaAdjust")
            filter?.setValue(inputImage, forKey: kCIInputImageKey)
            filter?.setValue(params["power"] ?? 1.0, forKey: "inputPower")
            guard let output = filter?.outputImage else {
                completion(.failure(NSError(domain: "Gamma", code: 2, userInfo: nil)))
                return
            }
            let context = CIContext()
            guard let cgimg = context.createCGImage(output, from: output.extent) else {
                completion(.failure(NSError(domain: "Gamma", code: 3, userInfo: nil)))
                return
            }
            let ui = UIImage(cgImage: cgimg)
            let outputURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + "_gamma.jpg")
            if let data = ui.jpegData(compressionQuality: 1.0) {
                try? data.write(to: outputURL)
                let result = EditingAsset(url: outputURL, type: .image)
                completion(.success(result))
            } else {
                completion(.failure(NSError(domain: "Gamma", code: 4, userInfo: nil)))
            }
        } else {
            // Для видео реализуется через AVVideoComposition и CIFilter
            completion(.failure(NSError(domain: "Gamma", code: 99, userInfo: [NSLocalizedDescriptionKey: "Реализуй через AVVideoComposition с CIFilter"])))
        }
    }
}
import AVFoundation

class AddAudioFeature: EditingFeature {
    let id = "add_audio"
    let displayName = "Добавить аудио к видео"
    let description = "Добавление звуковой дорожки к видео"

    func canRun(on asset: EditingAsset) -> Bool { asset.type == .video }

    func run(on asset: EditingAsset, params: [String: Any], completion: @escaping (Result<EditingAsset, Error>) -> Void) {
        guard let audioAsset = params["audio"] as? EditingAsset else {
            completion(.failure(NSError(domain: "AddAudio", code: 1, userInfo: nil)))
            return
        }
        let videoAsset = AVAsset(url: asset.url)
        let audioAssetAV = AVAsset(url: audioAsset.url)
        let mixComposition = AVMutableComposition()
        // Видео
        if let videoTrack = videoAsset.tracks(withMediaType: .video).first,
           let videoCompTrack = mixComposition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid) {
            try? videoCompTrack.insertTimeRange(CMTimeRange(start: .zero, duration: videoAsset.duration), of: videoTrack, at: .zero)
        }
        // Аудио
        if let audioTrack = audioAssetAV.tracks(withMediaType: .audio).first,
           let audioCompTrack = mixComposition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid) {
            try? audioCompTrack.insertTimeRange(CMTimeRange(start: .zero, duration: videoAsset.duration), of: audioTrack, at: .zero)
        }
        guard let export = AVAssetExportSession(asset: mixComposition, presetName: AVAssetExportPresetHighestQuality) else {
            completion(.failure(NSError(domain: "AddAudio", code: 2, userInfo: nil)))
            return
        }
        let outputURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + "_addaudio.mov")
        try? FileManager.default.removeItem(at: outputURL)
        export.outputURL = outputURL
        export.outputFileType = .mov
        export.exportAsynchronously {
            if export.status == .completed {
                let result = EditingAsset(url: outputURL, type: .video)
                completion(.success(result))
            } else {
                completion(.failure(export.error ?? NSError(domain: "AddAudio", code: 3, userInfo: nil)))
            }
        }
    }
}
import AVFoundation

class RemoveAudioFeature: EditingFeature {
    let id = "remove_audio"
    let displayName = "Удалить аудиодорожку"
    let description = "Удаление аудиодорожки из видео"

    func canRun(on asset: EditingAsset) -> Bool { asset.type == .video }

    func run(on asset: EditingAsset, params: [String: Any], completion: @escaping (Result<EditingAsset, Error>) -> Void) {
        let videoAsset = AVAsset(url: asset.url)
        let mixComposition = AVMutableComposition()
        if let videoTrack = videoAsset.tracks(withMediaType: .video).first,
           let videoCompTrack = mixComposition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid) {
            try? videoCompTrack.insertTimeRange(CMTimeRange(start: .zero, duration: videoAsset.duration), of: videoTrack, at: .zero)
        }
        guard let export = AVAssetExportSession(asset: mixComposition, presetName: AVAssetExportPresetHighestQuality) else {
            completion(.failure(NSError(domain: "RemoveAudio", code: 1, userInfo: nil)))
            return
        }
        let outputURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + "_removeaudio.mov")
        try? FileManager.default.removeItem(at: outputURL)
        export.outputURL = outputURL
        export.outputFileType = .mov
        export.exportAsynchronously {
            if export.status == .completed {
                let result = EditingAsset(url: outputURL, type: .video)
                completion(.success(result))
            } else {
                completion(.failure(export.error ?? NSError(domain: "RemoveAudio", code: 2, userInfo: nil)))
            }
        }
    }
}
import AVFoundation

class MergeAudioFeature: EditingFeature {
    let id = "merge_audio"
    let displayName = "Слить несколько аудиофайлов"
    let description = "Объединить несколько аудиофайлов в один"

    func canRun(on asset: EditingAsset) -> Bool { asset.type == .audio }

    func run(on asset: EditingAsset, params: [String: Any], completion: @escaping (Result<EditingAsset, Error>) -> Void) {
        guard let others = params["assets"] as? [EditingAsset] else {
            completion(.failure(NSError(domain: "MergeAudio", code: 1, userInfo: nil)))
            return
        }
        let mixComposition = AVMutableComposition()
        var insertTime = CMTime.zero
        for a in [asset] + others {
            let avAsset = AVAsset(url: a.url)
            guard let track = avAsset.tracks(withMediaType: .audio).first else { continue }
            let compTrack = mixComposition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)
            try? compTrack?.insertTimeRange(CMTimeRange(start: .zero, duration: avAsset.duration), of: track, at: insertTime)
            insertTime = CMTimeAdd(insertTime, avAsset.duration)
        }
        guard let export = AVAssetExportSession(asset: mixComposition, presetName: AVAssetExportPresetAppleM4A) else {
            completion(.failure(NSError(domain: "MergeAudio", code: 2, userInfo: nil)))
            return
        }
        let outputURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + "_mergeaudio.m4a")
        try? FileManager.default.removeItem(at: outputURL)
        export.outputURL = outputURL
        export.outputFileType = .m4a
        export.exportAsynchronously {
            if export.status == .completed {
                let result = EditingAsset(url: outputURL, type: .audio)
                completion(.success(result))
            } else {
                completion(.failure(export.error ?? NSError(domain: "MergeAudio", code: 3, userInfo: nil)))
            }
        }
    }
}
import AVFoundation

class ExtractAudioFeature: EditingFeature {
    let id = "extract_audio"
    let displayName = "Извлечь аудио из видео"
    let description = "Сохранить аудиодорожку из видео"

    func canRun(on asset: EditingAsset) -> Bool { asset.type == .video }

    func run(on asset: EditingAsset, params: [String: Any], completion: @escaping (Result<EditingAsset, Error>) -> Void) {
        let avAsset = AVAsset(url: asset.url)
        guard let export = AVAssetExportSession(asset: avAsset, presetName: AVAssetExportPresetAppleM4A) else {
            completion(.failure(NSError(domain: "ExtractAudio", code: 1, userInfo: nil)))
            return
        }
        let outputURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + "_extractaudio.m4a")
        try? FileManager.default.removeItem(at: outputURL)
        export.outputURL = outputURL
        export.outputFileType = .m4a
        export.timeRange = CMTimeRange(start: .zero, duration: avAsset.duration)
        export.exportAsynchronously {
            if export.status == .completed {
                let result = EditingAsset(url: outputURL, type: .audio)
                completion(.success(result))
            } else {
                completion(.failure(export.error ?? NSError(domain: "ExtractAudio", code: 2, userInfo: nil)))
            }
        }
    }
}
import AVFoundation

class AudioToWavFeature: EditingFeature {
    let id = "audio_to_wav"
    let displayName = "Аудио в WAV"
    let description = "Конвертация аудиофайла в WAV"

    func canRun(on asset: EditingAsset) -> Bool { asset.type == .audio }

    func run(on asset: EditingAsset, params: [String: Any], completion: @escaping (Result<EditingAsset, Error>) -> Void) {
        let avAsset = AVAsset(url: asset.url)
        guard let export = AVAssetExportSession(asset: avAsset, presetName: AVAssetExportPresetPassthrough) else {
            completion(.failure(NSError(domain: "AudioToWav", code: 1, userInfo: nil)))
            return
        }
        let outputURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".wav")
        try? FileManager.default.removeItem(at: outputURL)
        export.outputURL = outputURL
        export.outputFileType = .wav
        export.exportAsynchronously {
            if export.status == .completed {
                let result = EditingAsset(url: outputURL, type: .audio)
                completion(.success(result))
            } else {
                completion(.failure(export.error ?? NSError(domain: "AudioToWav", code: 2, userInfo: nil)))
            }
        }
    }
}
import AVFoundation

class FadeVideoFeature: EditingFeature {
    let id = "fade_video"
    let displayName = "Видео Fade In/Out"
    let description = "Плавное появление и затухание видео"

    func canRun(on asset: EditingAsset) -> Bool { asset.type == .video }

    func run(on asset: EditingAsset, params: [String: Any], completion: @escaping (Result<EditingAsset, Error>) -> Void) {
        // Для реализации нужен AVVideoComposition с кастомным инструкцией и CALayer-анимацией альфы
        completion(.failure(NSError(domain: "FadeVideo", code: 99, userInfo: [NSLocalizedDescriptionKey: "Реализуй через AVVideoComposition и CALayer с анимацией альфы"])))
    }
}
import AVFoundation
import UIKit

class AddTextFeature: EditingFeature {
    let id = "add_text"
    let displayName = "Добавить текст"
    let description = "Добавить текст поверх видео или изображения"

    func canRun(on asset: EditingAsset) -> Bool { asset.type == .video || asset.type == .image }

    func run(on asset: EditingAsset, params: [String: Any], completion: @escaping (Result<EditingAsset, Error>) -> Void) {
        // Для видео: AVVideoComposition с CALayer, для изображения: рисование на UIImage
        completion(.failure(NSError(domain: "AddText", code: 99, userInfo: [NSLocalizedDescriptionKey: "Реализуй через AVVideoComposition/CALayer или CoreGraphics"])))
    }
}
import AVFoundation
import UIKit

class AddImageOverlayFeature: EditingFeature {
    let id = "add_image_overlay"
    let displayName = "Наложить изображение"
    let description = "Добавить изображение поверх видео или изображения"

    func canRun(on asset: EditingAsset) -> Bool { asset.type == .video || asset.type == .image }

    func run(on asset: EditingAsset, params: [String: Any], completion: @escaping (Result<EditingAsset, Error>) -> Void) {
        // Для видео: AVVideoComposition с CALayer, для изображения: рисование на UIImage
        completion(.failure(NSError(domain: "AddImageOverlay", code: 99, userInfo: [NSLocalizedDescriptionKey: "Реализуй через AVVideoComposition/CALayer или CoreGraphics"])))
    }
}
import AVFoundation
import UIKit

class AddWatermarkFeature: EditingFeature {
    let id = "add_watermark"
    let displayName = "Водяной знак"
    let description = "Добавить водяной знак на видео или изображение"

    func canRun(on asset: EditingAsset) -> Bool { asset.type == .video || asset.type == .image }

    func run(on asset: EditingAsset, params: [String: Any], completion: @escaping (Result<EditingAsset, Error>) -> Void) {
        // Для видео: AVVideoComposition с CALayer, для изображения: рисование на UIImage
        completion(.failure(NSError(domain: "AddWatermark", code: 99, userInfo: [NSLocalizedDescriptionKey: "Реализуй через AVVideoComposition/CALayer или CoreGraphics"])))
    }
}
import AVFoundation
import UIKit

class AddBorderFeature: EditingFeature {
    let id = "add_border"
    let displayName = "Добавить рамку"
    let description = "Добавить рамку к видео или изображению"

    func canRun(on asset: EditingAsset) -> Bool { asset.type == .video || asset.type == .image }

    func run(on asset: EditingAsset, params: [String: Any], completion: @escaping (Result<EditingAsset, Error>) -> Void) {
        // Для видео: AVVideoComposition с CALayer, для изображения: рисование на UIImage
        completion(.failure(NSError(domain: "AddBorder", code: 99, userInfo: [NSLocalizedDescriptionKey: "Реализуй через AVVideoComposition/CALayer или CoreGraphics"])))
    }
}
import AVFoundation
import UIKit

class AddBackgroundFeature: EditingFeature {
    let id = "add_background"
    let displayName = "Фон"
    let description = "Добавить фон под изображение или видео"

    func canRun(on asset: EditingAsset) -> Bool { asset.type == .video || asset.type == .image }

    func run(on asset: EditingAsset, params: [String: Any], completion: @escaping (Result<EditingAsset, Error>) -> Void) {
        // Для видео: AVVideoComposition с CALayer, для изображения: рисование на UIImage
        completion(.failure(NSError(domain: "AddBackground", code: 99, userInfo: [NSLocalizedDescriptionKey: "Реализуй через AVVideoComposition/CALayer или CoreGraphics"])))
    }
}
import AVFoundation

class ResizeFeature: EditingFeature {
    let id = "resize"
    let displayName = "Изменить размер"
    let description = "Изменить размер видео или изображения"

    func canRun(on asset: EditingAsset) -> Bool { asset.type == .video || asset.type == .image }

    func run(on asset: EditingAsset, params: [String: Any], completion: @escaping (Result<EditingAsset, Error>) -> Void) {
        // Для видео: AVVideoComposition с renderSize, для изображения: CoreImage/UIImage
        completion(.failure(NSError(domain: "Resize", code: 99, userInfo: [NSLocalizedDescriptionKey: "Реализуй через AVVideoComposition или CoreImage"])))
    }
}
import AVFoundation

class ChangeFPSFeature: EditingFeature {
    let id = "change_fps"
    let displayName = "Изменить FPS"
    let description = "Изменить частоту кадров видео"

    func canRun(on asset: EditingAsset) -> Bool { asset.type == .video }

    func run(on asset: EditingAsset, params: [String: Any], completion: @escaping (Result<EditingAsset, Error>) -> Void) {
        // Нужно пересборка AVMutableComposition с другим frameDuration у AVMutableVideoComposition
        completion(.failure(NSError(domain: "ChangeFPS", code: 99, userInfo: [NSLocalizedDescriptionKey: "Реализуй через AVMutableVideoComposition"])))
    }
}
import AVFoundation

class ChangeBitrateFeature: EditingFeature {
    let id = "change_bitrate"
    let displayName = "Изменить битрейт"
    let description = "Изменить битрейт видео"

    func canRun(on asset: EditingAsset) -> Bool { asset.type == .video }

    func run(on asset: EditingAsset, params: [String: Any], completion: @escaping (Result<EditingAsset, Error>) -> Void) {
        // Для AVAssetExportSession bitrate задаётся через exportSession.fileLengthLimit или custom preset
        completion(.failure(NSError(domain: "ChangeBitrate", code: 99, userInfo: [NSLocalizedDescriptionKey: "Реализуй через AVAssetExportSession с кастомным bitrate"])))
    }
}
import AVFoundation

class AudioReverseFeature: EditingFeature {
    let id = "audio_reverse"
    let displayName = "Реверс аудио"
    let description = "Развернуть аудиофайл задом наперёд"

    func canRun(on asset: EditingAsset) -> Bool { asset.type == .audio }

    func run(on asset: EditingAsset, params: [String: Any], completion: @escaping (Result<EditingAsset, Error>) -> Void) {
        // Реализация реверса аудио сложна через AVFoundation, требуется чтение буфера, реверс PCM и запись
        completion(.failure(NSError(domain: "AudioReverse", code: 99, userInfo: [NSLocalizedDescriptionKey: "Требует реверса PCM-буфера через AVAudioFile"])))
    }
}
import AVFoundation

class VideoReverseFeature: EditingFeature {
    let id = "video_reverse"
    let displayName = "Реверс видео"
    let description = "Развернуть видео задом наперёд"

    func canRun(on asset: EditingAsset) -> Bool { asset.type == .video }

    func run(on asset: EditingAsset, params: [String: Any], completion: @escaping (Result<EditingAsset, Error>) -> Void) {
        // Реверс видео реализуется через AVAssetReader/Writer, покадрово
        completion(.failure(NSError(domain: "VideoReverse", code: 99, userInfo: [NSLocalizedDescriptionKey: "Требует покадрового чтения и записи через AVAssetReader/Writer"])))
    }
}
import AVFoundation

class AudioTrimFeature: EditingFeature {
    let id = "audio_trim"
    let displayName = "Обрезка аудио"
    let description = "Обрезка аудиофайла по времени"

    func canRun(on asset: EditingAsset) -> Bool { asset.type == .audio }

    func run(on asset: EditingAsset, params: [String: Any], completion: @escaping (Result<EditingAsset, Error>) -> Void) {
        guard let start = params["start"] as? Double,
              let duration = params["duration"] as? Double else {
            completion(.failure(NSError(domain: "AudioTrim", code: 1, userInfo: nil)))
            return
        }
        let avAsset = AVAsset(url: asset.url)
        guard let export = AVAssetExportSession(asset: avAsset, presetName: AVAssetExportPresetAppleM4A) else {
            completion(.failure(NSError(domain: "AudioTrim", code: 2, userInfo: nil)))
            return
        }
        let outputURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + "_audiotrim.m4a")
        try? FileManager.default.removeItem(at: outputURL)
        export.outputURL = outputURL
        export.outputFileType = .m4a
        let startTime = CMTime(seconds: start, preferredTimescale: 600)
        let durationTime = CMTime(seconds: duration, preferredTimescale: 600)
        export.timeRange = CMTimeRange(start: startTime, duration: durationTime)
        export.exportAsynchronously {
            if export.status == .completed {
                let result = EditingAsset(url: outputURL, type: .audio)
                completion(.success(result))
            } else {
                completion(.failure(export.error ?? NSError(domain: "AudioTrim", code: 3, userInfo: nil)))
            }
        }
    }
}
import AVFoundation

class AudioPanFeature: EditingFeature {
    let id = "audio_pan"
    let displayName = "Панорама аудио"
    let description = "Изменить стерео-панораму аудиофайла"

    func canRun(on asset: EditingAsset) -> Bool { asset.type == .audio }

    func run(on asset: EditingAsset, params: [String: Any], completion: @escaping (Result<EditingAsset, Error>) -> Void) {
        // AVFoundation не поддерживает pan напрямую, но можно через AVAudioEngine
        completion(.failure(NSError(domain: "AudioPan", code: 99, userInfo: [NSLocalizedDescriptionKey: "Реализуй через AVAudioEngine/AVAudioUnitPan"])))
    }
}
import AVFoundation

class AudioEQFeature: EditingFeature {
    let id = "audio_eq"
    let displayName = "Эквалайзер"
    let description = "Применить эквалайзер к аудио"

    func canRun(on asset: EditingAsset) -> Bool { asset.type == .audio }

    func run(on asset: EditingAsset, params: [String: Any], completion: @escaping (Result<EditingAsset, Error>) -> Void) {
        // Реализация требует AVAudioEngine и AVAudioUnitEQ
        completion(.failure(NSError(domain: "AudioEQ", code: 99, userInfo: [NSLocalizedDescriptionKey: "Реализуй через AVAudioEngine/AVAudioUnitEQ"])))
    }
}
import AVFoundation

class AudioFadeInFeature: EditingFeature {
    let id = "audio_fade_in"
    let displayName = "Fade In аудио"
    let description = "Плавное появление звука"

    func canRun(on asset: EditingAsset) -> Bool { asset.type == .audio }

    func run(on asset: EditingAsset, params: [String: Any], completion: @escaping (Result<EditingAsset, Error>) -> Void) {
        guard let fadeIn = params["fadeIn"] as? Double else {
            completion(.failure(NSError(domain: "AudioFadeIn", code: 1, userInfo: nil)))
            return
        }
        let avAsset = AVAsset(url: asset.url)
        guard let audioTrack = avAsset.tracks(withMediaType: .audio).first else {
            completion(.failure(NSError(domain: "AudioFadeIn", code: 2, userInfo: nil)))
            return
        }
        let mix = AVMutableAudioMix()
        let params = AVMutableAudioMixInputParameters(track: audioTrack)
        params.setVolumeRamp(fromStartVolume: 0, toEndVolume: 1, timeRange: CMTimeRange(start: .zero, duration: CMTime(seconds: fadeIn, preferredTimescale: 600)))
        mix.inputParameters = [params]
        guard let export = AVAssetExportSession(asset: avAsset, presetName: AVAssetExportPresetAppleM4A) else {
            completion(.failure(NSError(domain: "AudioFadeIn", code: 3, userInfo: nil)))
            return
        }
        let outputURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + "_fadein.m4a")
        try? FileManager.default.removeItem(at: outputURL)
        export.outputURL = outputURL
        export.outputFileType = .m4a
        export.audioMix = mix
        export.exportAsynchronously {
            if export.status == .completed {
                let result = EditingAsset(url: outputURL, type: .audio)
                completion(.success(result))
            } else {
                completion(.failure(export.error ?? NSError(domain: "AudioFadeIn", code: 4, userInfo: nil)))
            }
        }
    }
}
import AVFoundation

class AudioFadeOutFeature: EditingFeature {
    let id = "audio_fade_out"
    let displayName = "Fade Out аудио"
    let description = "Плавное затухание звука"

    func canRun(on asset: EditingAsset) -> Bool { asset.type == .audio }

    func run(on asset: EditingAsset, params: [String: Any], completion: @escaping (Result<EditingAsset, Error>) -> Void) {
        guard let fadeOut = params["fadeOut"] as? Double else {
            completion(.failure(NSError(domain: "AudioFadeOut", code: 1, userInfo: nil)))
            return
        }
        let avAsset = AVAsset(url: asset.url)
        guard let audioTrack = avAsset.tracks(withMediaType: .audio).first else {
            completion(.failure(NSError(domain: "AudioFadeOut", code: 2, userInfo: nil)))
            return
        }
        let mix = AVMutableAudioMix()
        let params = AVMutableAudioMixInputParameters(track: audioTrack)
        let duration = avAsset.duration
        params.setVolumeRamp(fromStartVolume: 1, toEndVolume: 0, timeRange: CMTimeRange(start: duration - CMTime(seconds: fadeOut, preferredTimescale: 600), duration: CMTime(seconds: fadeOut, preferredTimescale: 600)))
        mix.inputParameters = [params]
        guard let export = AVAssetExportSession(asset: avAsset, presetName: AVAssetExportPresetAppleM4A) else {
            completion(.failure(NSError(domain: "AudioFadeOut", code: 3, userInfo: nil)))
            return
        }
        let outputURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + "_fadeout.m4a")
        try? FileManager.default.removeItem(at: outputURL)
        export.outputURL = outputURL
        export.outputFileType = .m4a
        export.audioMix = mix
        export.exportAsynchronously {
            if export.status == .completed {
                let result = EditingAsset(url: outputURL, type: .audio)
                completion(.success(result))
            } else {
                completion(.failure(export.error ?? NSError(domain: "AudioFadeOut", code: 4, userInfo: nil)))
            }
        }
    }
}
import AVFoundation

class ExportGifFeature: EditingFeature {
    let id = "export_gif"
    let displayName = "Экспорт в GIF"
    let description = "Экспортировать видео в анимированный GIF"

    func canRun(on asset: EditingAsset) -> Bool { asset.type == .video }

    func run(on asset: EditingAsset, params: [String: Any], completion: @escaping (Result<EditingAsset, Error>) -> Void) {
        // Реализация требует покадрового экспорта и сборки GIF (с помощью ImageIO/CGImageDestination)
        completion(.failure(NSError(domain: "ExportGif", code: 99, userInfo: [NSLocalizedDescriptionKey: "Реализуй через AVAssetImageGenerator и CGImageDestination"])))
    }
}
import AVFoundation
import UIKit

class ExportFrameSequenceFeature: EditingFeature {
    let id = "export_frame_sequence"
    let displayName = "Экспорт покадров"
    let description = "Экспортировать все кадры видео в изображения"

    func canRun(on asset: EditingAsset) -> Bool { asset.type == .video }

    func run(on asset: EditingAsset, params: [String: Any], completion: @escaping (Result<EditingAsset, Error>) -> Void) {
        // Реализация: AVAssetImageGenerator, сохранить все кадры в папку
        completion(.failure(NSError(domain: "ExportFrameSequence", code: 99, userInfo: [NSLocalizedDescriptionKey: "Реализуй через AVAssetImageGenerator, сохраняя кадры в папку"])))
    }
}
import AVFoundation

class AspectRatioCropFeature: EditingFeature {
    let id = "aspect_ratio_crop"
    let displayName = "Обрезка по соотношению"
    let description = "Обрезать изображение или видео по заданному соотношению сторон"

    func canRun(on asset: EditingAsset) -> Bool { asset.type == .video || asset.type == .image }

    func run(on asset: EditingAsset, params: [String: Any], completion: @escaping (Result<EditingAsset, Error>) -> Void) {
        // Для видео: AVVideoComposition с transform, для изображения: CoreImage
        completion(.failure(NSError(domain: "AspectRatioCrop", code: 99, userInfo: [NSLocalizedDescriptionKey: "Реализуй через AVVideoComposition или CoreImage"])))
    }
}
import AVFoundation

class DuplicateVideoFeature: EditingFeature {
    let id = "duplicate_video"
    let displayName = "Дублировать видео"
    let description = "Создать копию видеофайла"

    func canRun(on asset: EditingAsset) -> Bool { asset.type == .video }

    func run(on asset: EditingAsset, params: [String: Any], completion: @escaping (Result<EditingAsset, Error>) -> Void) {
        let outputURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + "_copy.mov")
        do {
            try FileManager.default.copyItem(at: asset.url, to: outputURL)
            completion(.success(EditingAsset(url: outputURL, type: .video)))
        } catch {
            completion(.failure(error))
        }
    }
}
import AVFoundation

class DuplicateAudioFeature: EditingFeature {
    let id = "duplicate_audio"
    let displayName = "Дублировать аудио"
    let description = "Создать копию аудиофайла"

    func canRun(on asset: EditingAsset) -> Bool { asset.type == .audio }

    func run(on asset: EditingAsset, params: [String: Any], completion: @escaping (Result<EditingAsset, Error>) -> Void) {
        let outputURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + "_copy.m4a")
        do {
            try FileManager.default.copyItem(at: asset.url, to: outputURL)
            completion(.success(EditingAsset(url: outputURL, type: .audio)))
        } catch {
            completion(.failure(error))
        }
    }
}
import AVFoundation

class SimpleTransitionFeature: EditingFeature {
    let id = "simple_transition"
    let displayName = "Переход между видео"
    let description = "Добавить простой переход (fade) между двумя видео"

    func canRun(on asset: EditingAsset) -> Bool { asset.type == .video }

    func run(on asset: EditingAsset, params: [String: Any], completion: @escaping (Result<EditingAsset, Error>) -> Void) {
        // Для реализации потребуется AVMutableComposition с перекрытием двух треков и AVMutableVideoCompositionInstruction с переходом
        completion(.failure(NSError(domain: "SimpleTransition", code: 99, userInfo: [NSLocalizedDescriptionKey: "Реализуй через AVMutableComposition с overlap и AVMutableVideoCompositionInstruction"])))
    }
}
import AVFoundation
import CoreImage
import UIKit

class ChromaticAberrationFeature: EditingFeature {
    let id = "chromatic_aberration"
    let displayName = "Хроматическая аберрация"
    let description = "Добавить эффект хроматической аберрации"

    func canRun(on asset: EditingAsset) -> Bool { asset.type == .video || asset.type == .image }

    func run(on asset: EditingAsset, params: [String: Any], completion: @escaping (Result<EditingAsset, Error>) -> Void) {
        // Для изображения: CoreImage с CICMYKHalftone и сдвиг каналов
        // Для видео: через AVVideoComposition и custom CIFilter
        completion(.failure(NSError(domain: "ChromaticAberration", code: 99, userInfo: [NSLocalizedDescriptionKey: "Реализуй через CIFilter/AVVideoComposition"])))
    }
}
import AVFoundation
import CoreImage
import UIKit

class ColorGradingFeature: EditingFeature {
    let id = "color_grading"
    let displayName = "Цветокоррекция"
    let description = "Применить LUT/цветокоррекцию к видео или изображению"

    func canRun(on asset: EditingAsset) -> Bool { asset.type == .video || asset.type == .image }

    func run(on asset: EditingAsset, params: [String: Any], completion: @escaping (Result<EditingAsset, Error>) -> Void) {
        // Для изображения: CoreImage с LUT (CIColorCube)
        // Для видео: AVVideoComposition с custom CIFilter
        completion(.failure(NSError(domain: "ColorGrading", code: 99, userInfo: [NSLocalizedDescriptionKey: "Реализуй через CIColorCube и AVVideoComposition"])))
    }
}
import AVFoundation

class KadrForSocialFeature: EditingFeature {
    let id = "kadr_for_social"
    let displayName = "Кадр соцсети"
    let description = "Обрезать/подогнать под формат соцсетей (9:16, 1:1 и т.д.)"

    func canRun(on asset: EditingAsset) -> Bool { asset.type == .video || asset.type == .image }

    func run(on asset: EditingAsset, params: [String: Any], completion: @escaping (Result<EditingAsset, Error>) -> Void) {
        // Для видео: AVVideoComposition с изменением renderSize и transform, для фото — CoreImage
        completion(.failure(NSError(domain: "KadrForSocial", code: 99, userInfo: [NSLocalizedDescriptionKey: "Реализуй через AVVideoComposition/CoreImage"])))
    }
}
import UIKit

class TextStrokeFeature: EditingFeature {
    let id = "text_stroke"
    let displayName = "Контур текста"
    let description = "Добавить контур к тексту на изображении или видео"

    func canRun(on asset: EditingAsset) -> Bool { asset.type == .video || asset.type == .image }

    func run(on asset: EditingAsset, params: [String: Any], completion: @escaping (Result<EditingAsset, Error>) -> Void) {
        // Для видео: CALayer с NSAttributedString и stroke, для изображений — CoreGraphics
        completion(.failure(NSError(domain: "TextStroke", code: 99, userInfo: [NSLocalizedDescriptionKey: "Реализуй через CoreGraphics/CALayer"])))
    }
}
import UIKit

class TitleAnimationFeature: EditingFeature {
    let id = "title_animation"
    let displayName = "Анимация титров"
    let description = "Добавить анимированные титры к видео"

    func canRun(on asset: EditingAsset) -> Bool { asset.type == .video }

    func run(on asset: EditingAsset, params: [String: Any], completion: @escaping (Result<EditingAsset, Error>) -> Void) {
        // CALayer animation — для AVVideoComposition
        completion(.failure(NSError(domain: "TitleAnimation", code: 99, userInfo: [NSLocalizedDescriptionKey: "Реализуй через CALayer и AVSynchronizedLayer"])))
    }
}
import UIKit

class ImageAnimationFeature: EditingFeature {
    let id = "image_animation"
    let displayName = "Анимация изображения"
    let description = "Добавить анимацию изображения к видео"

    func canRun(on asset: EditingAsset) -> Bool { asset.type == .video }

    func run(on asset: EditingAsset, params: [String: Any], completion: @escaping (Result<EditingAsset, Error>) -> Void) {
        // CALayer animation — для AVVideoComposition
        completion(.failure(NSError(domain: "ImageAnimation", code: 99, userInfo: [NSLocalizedDescriptionKey: "Реализуй через CALayer и AVSynchronizedLayer"])))
    }
}
import AVFoundation

class MirrorFeature: EditingFeature {
    let id = "mirror"
    let displayName = "Зеркалирование"
    let description = "Зеркалировать изображение или видео (по вертикали/горизонтали)"

    func canRun(on asset: EditingAsset) -> Bool { asset.type == .video || asset.type == .image }

    func run(on asset: EditingAsset, params: [String: Any], completion: @escaping (Result<EditingAsset, Error>) -> Void) {
        // Для видео: AVVideoComposition с transform, для изображений: CoreImage
        completion(.failure(NSError(domain: "Mirror", code: 99, userInfo: [NSLocalizedDescriptionKey: "Реализуй через AVVideoComposition/CoreImage"])))
    }
}
import AVFoundation
import CoreImage
import UIKit

class BlurredBackgroundFeature: EditingFeature {
    let id = "blurred_background"
    let displayName = "Размытый фон"
    let description = "Добавить размытый фон под видео/фото"

    func canRun(on asset: EditingAsset) -> Bool { asset.type == .video || asset.type == .image }

    func run(on asset: EditingAsset, params: [String: Any], completion: @escaping (Result<EditingAsset, Error>) -> Void) {
        // Для видео: AVVideoComposition + CALayer, для изображений: CoreImage + overlay
        completion(.failure(NSError(domain: "BlurredBackground", code: 99, userInfo: [NSLocalizedDescriptionKey: "Реализуй через AVVideoComposition/CoreImage"])))
    }
}
import AVFoundation
import UIKit

class ColoredBackgroundFeature: EditingFeature {
    let id = "colored_background"
    let displayName = "Цветной фон"
    let description = "Добавить заливку цветом под видео/фото"

    func canRun(on asset: EditingAsset) -> Bool { asset.type == .video || asset.type == .image }

    func run(on asset: EditingAsset, params: [String: Any], completion: @escaping (Result<EditingAsset, Error>) -> Void) {
        // Для видео: AVVideoComposition + CALayer, для изображений: CoreGraphics
        completion(.failure(NSError(domain: "ColoredBackground", code: 99, userInfo: [NSLocalizedDescriptionKey: "Реализуй через AVVideoComposition/CoreGraphics"])))
    }
}
import AVFoundation

class AudioResampleFeature: EditingFeature {
    let id = "audio_resample"
    let displayName = "Ресемплировать аудио"
    let description = "Изменить sample rate аудиофайла"

    func canRun(on asset: EditingAsset) -> Bool { asset.type == .audio }

    func run(on asset: EditingAsset, params: [String: Any], completion: @escaping (Result<EditingAsset, Error>) -> Void) {
        // Требует AVAssetExportSession с кастомным аудионастройками (или AVAudioEngine)
        completion(.failure(NSError(domain: "AudioResample", code: 99, userInfo: [NSLocalizedDescriptionKey: "Реализуй через AVAssetExportSession/AVAudioEngine"])))
    }
}
import AVFoundation

class AudioFormatConvertFeature: EditingFeature {
    let id = "audio_format_convert"
    let displayName = "Конвертировать формат аудио"
    let description = "Конвертировать аудиофайл в другой формат"

    func canRun(on asset: EditingAsset) -> Bool { asset.type == .audio }

    func run(on asset: EditingAsset, params: [String: Any], completion: @escaping (Result<EditingAsset, Error>) -> Void) {
        // AVAssetExportSession с нужным fileType
        completion(.failure(NSError(domain: "AudioFormatConvert", code: 99, userInfo: [NSLocalizedDescriptionKey: "Реализуй через AVAssetExportSession"])))
    }
}
import AVFoundation

class VideoFormatConvertFeature: EditingFeature {
    let id = "video_format_convert"
    let displayName = "Конвертировать формат видео"
    let description = "Конвертировать видеофайл в другой формат"

    func canRun(on asset: EditingAsset) -> Bool { asset.type == .video }

    func run(on asset: EditingAsset, params: [String: Any], completion: @escaping (Result<EditingAsset, Error>) -> Void) {
        // AVAssetExportSession с нужным fileType
        completion(.failure(NSError(domain: "VideoFormatConvert", code: 99, userInfo: [NSLocalizedDescriptionKey: "Реализуй через AVAssetExportSession"])))
    }
}
import AVFoundation

class SaveMetadataFeature: EditingFeature {
    let id = "save_metadata"
    let displayName = "Сохранить метаданные"
    let description = "Сохранить/добавить метаданные к видео или аудио"

    func canRun(on asset: EditingAsset) -> Bool { asset.type == .video || asset.type == .audio }

    func run(on asset: EditingAsset, params: [String: Any], completion: @escaping (Result<EditingAsset, Error>) -> Void) {
        guard let metadataItems = params["metadata"] as? [AVMetadataItem] else {
            completion(.failure(NSError(domain: "SaveMetadata", code: 1, userInfo: nil)))
            return
        }
        let avAsset = AVAsset(url: asset.url)
        guard let export = AVAssetExportSession(asset: avAsset, presetName: AVAssetExportPresetPassthrough) else {
            completion(.failure(NSError(domain: "SaveMetadata", code: 2, userInfo: nil)))
            return
        }
        let outputURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + "_meta.\(asset.type == .audio ? "m4a" : "mov")")
        try? FileManager.default.removeItem(at: outputURL)
        export.outputURL = outputURL
        export.outputFileType = asset.type == .audio ? .m4a : .mov
        export.metadata = metadataItems
        export.exportAsynchronously {
            if export.status == .completed {
                completion(.success(EditingAsset(url: outputURL, type: asset.type)))
            } else {
                completion(.failure(export.error ?? NSError(domain: "SaveMetadata", code: 3, userInfo: nil)))
            }
        }
    }
}
import AVFoundation

class RemoveMetadataFeature: EditingFeature {
    let id = "remove_metadata"
    let displayName = "Удалить метаданные"
    let description = "Удалить все метаданные из видео или аудио"

    func canRun(on asset: EditingAsset) -> Bool { asset.type == .video || asset.type == .audio }

    func run(on asset: EditingAsset, params: [String: Any], completion: @escaping (Result<EditingAsset, Error>) -> Void) {
        let avAsset = AVAsset(url: asset.url)
        guard let export = AVAssetExportSession(asset: avAsset, presetName: AVAssetExportPresetPassthrough) else {
            completion(.failure(NSError(domain: "RemoveMetadata", code: 1, userInfo: nil)))
            return
        }
        let outputURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + "_nometa.\(asset.type == .audio ? "m4a" : "mov")")
        try? FileManager.default.removeItem(at: outputURL)
        export.outputURL = outputURL
        export.outputFileType = asset.type == .audio ? .m4a : .mov
        export.metadata = []
        export.exportAsynchronously {
            if export.status == .completed {
                completion(.success(EditingAsset(url: outputURL, type: asset.type)))
            } else {
                completion(.failure(export.error ?? NSError(domain: "RemoveMetadata", code: 2, userInfo: nil)))
            }
        }
    }
}
import AVFoundation

class ChangeCanvasFeature: EditingFeature {
    let id = "change_canvas"
    let displayName = "Изменить холст"
    let description = "Изменить размер холста/подложки видео"

    func canRun(on asset: EditingAsset) -> Bool { asset.type == .video }

    func run(on asset: EditingAsset, params: [String: Any], completion: @escaping (Result<EditingAsset, Error>) -> Void) {
        guard let width = params["width"] as? CGFloat,
              let height = params["height"] as? CGFloat else {
            completion(.failure(NSError(domain: "ChangeCanvas", code: 1, userInfo: nil)))
            return
        }
        let avAsset = AVAsset(url: asset.url)
        guard let videoTrack = avAsset.tracks(withMediaType: .video).first,
              let exportSession = AVAssetExportSession(asset: avAsset, presetName: AVAssetExportPresetHighestQuality) else {
            completion(.failure(NSError(domain: "ChangeCanvas", code: 2, userInfo: nil)))
            return
        }
        let composition = AVMutableVideoComposition()
        composition.renderSize = CGSize(width: width, height: height)
        composition.frameDuration = CMTime(value: 1, timescale: Int32(videoTrack.nominalFrameRate))
        let instruction = AVMutableVideoCompositionInstruction()
        instruction.timeRange = CMTimeRange(start: .zero, duration: avAsset.duration)
        let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: videoTrack)
        let tx = (width - videoTrack.naturalSize.width) / 2
        let ty = (height - videoTrack.naturalSize.height) / 2
        let transform = CGAffineTransform(translationX: tx, y: ty)
        layerInstruction.setTransform(transform, at: .zero)
        instruction.layerInstructions = [layerInstruction]
        composition.instructions = [instruction]
        exportSession.videoComposition = composition
        let outputURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + "_canvas.mov")
        try? FileManager.default.removeItem(at: outputURL)
        exportSession.outputURL = outputURL
        exportSession.outputFileType = .mov
        exportSession.exportAsynchronously {
            if exportSession.status == .completed {
                completion(.success(EditingAsset(url: outputURL, type: .video)))
            } else {
                completion(.failure(exportSession.error ?? NSError(domain: "ChangeCanvas", code: 3, userInfo: nil)))
            }
        }
    }
}
