import Foundation
import AVFoundation
import Speech
import SwiftUI
import Observation

@Observable
final class SpeechRecognizer: NSObject, SFSpeechRecognizerDelegate {
    enum RecognizerError: Error {
        case nilRecognizer
        case notAuthorizedToRecognize
        case notPermittedToRecord
        case recognizerIsUnavailable

        var message: String {
            switch self {
            case .nilRecognizer: return "Can't initialize speech recognizer"
            case .notAuthorizedToRecognize: return "Not authorized to recognize speech"
            case .notPermittedToRecord: return "Not permitted to record audio"
            case .recognizerIsUnavailable: return "Recognizer is unavailable"
            }
        }
    }

    var transcript: String = ""
    var isRecognizerAvailable: Bool = true  // This will track availability

    private var audioEngine: AVAudioEngine?
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?
    private var recognizer: SFSpeechRecognizer?

    private var selectedLocale: Locale = Locale.current {
        didSet {
            updateRecognizer(locale: selectedLocale)
        }
    }

    // Initialize with the current locale
    init(locale: Locale = Locale.current) {
        super.init()
        updateRecognizer(locale: locale)
        
        Task(priority: .background) {
            do {
                guard recognizer != nil else {
                    throw RecognizerError.nilRecognizer
                }
                guard await SFSpeechRecognizer.hasAuthorizationToRecognize() else {
                    throw RecognizerError.notAuthorizedToRecognize
                }
                guard await AVAudioSession.sharedInstance().hasPermissionToRecord() else {
                    throw RecognizerError.notPermittedToRecord
                }
            } catch {
                speakError(error)
            }
        }
    }

    deinit {
        reset()
    }
    
    func reset() {
        stopTranscribing()
        
        transcript = ""
    }

    func transcribe() {
        DispatchQueue(label: "Speech Recognizer Queue", qos: .background).async { [weak self] in
            guard let self = self, let recognizer = self.recognizer, recognizer.isAvailable else {
                self?.speakError(RecognizerError.recognizerIsUnavailable)
                return
            }

            do {
                let (audioEngine, request) = try Self.prepareEngine()
                self.audioEngine = audioEngine
                self.request = request

                self.task = recognizer.recognitionTask(with: request) { result, error in
                    if let result = result {
                        self.speak(result.bestTranscription.formattedString)
                    }
                    
                    if result?.isFinal ?? false || error != nil {
                        audioEngine.stop()
                        audioEngine.inputNode.removeTap(onBus: 0)
                    }
                }
            } catch {
                self.reset()
                self.speakError(error)
            }
        }
    }

    func stopTranscribing() {
        task?.cancel()
        audioEngine?.stop()
        audioEngine = nil
        request = nil
        task = nil
    }

    private static func prepareEngine() throws -> (AVAudioEngine, SFSpeechAudioBufferRecognitionRequest) {
        let audioEngine = AVAudioEngine()
        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = false
        
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)

        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, when in
            request.append(buffer)
        }

        audioEngine.prepare()
        try audioEngine.start()

        return (audioEngine, request)
    }

    /// Updates the recognizer with the given locale and sets the delegate.
    func updateRecognizer(locale: Locale) {
        reset()
        recognizer = SFSpeechRecognizer(locale: locale)
        recognizer?.delegate = self // Set the delegate to this class
    }

    func changeLocale(to locale: Locale) {
        selectedLocale = locale
    }

    /// Error handling
    private func speakError(_ error: Error) {
        let errorMessage: String
        if let recognizerError = error as? RecognizerError {
            errorMessage = recognizerError.message
        } else {
            errorMessage = error.localizedDescription
        }
        //transcript = "<< \(errorMessage) >>"
    }

    private func speak(_ message: String) {
        transcript += "\n" + message
    }

    // MARK: - SFSpeechRecognizerDelegate
    func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        DispatchQueue.main.async {
            self.isRecognizerAvailable = available
//            if available {
//                self.speak("Speech recognition available")
//            } else {
//                self.speak("Speech recognition not available")
//            }
        }
    }
}

// Helper to request permissions
extension SFSpeechRecognizer {
    static func hasAuthorizationToRecognize() async -> Bool {
        await withCheckedContinuation { continuation in
            requestAuthorization { status in
                continuation.resume(returning: status == .authorized)
            }
        }
    }
}

// Helper for AVAudioSession permissions
extension AVAudioSession {
    func hasPermissionToRecord() async -> Bool {
        await withCheckedContinuation { continuation in
            AVAudioSession.sharedInstance().requestRecordPermission { authorized in
                continuation.resume(returning: authorized)
            }
        }
    }
}




//import Foundation
//import AVFoundation
//import Speech
//import SwiftUI
//import Observation
//
///// A helper for transcribing speech to text using SFSpeechRecognizer and AVAudioEngine.
//@Observable
//class SpeechRecognizer {
//    enum RecognizerError: Error {
//        case nilRecognizer
//        case notAuthorizedToRecognize
//        case notPermittedToRecord
//        case recognizerIsUnavailable
//        
//        var message: String {
//            switch self {
//            case .nilRecognizer: return "Can't initialize speech recognizer"
//            case .notAuthorizedToRecognize: return "Not authorized to recognize speech"
//            case .notPermittedToRecord: return "Not permitted to record audio"
//            case .recognizerIsUnavailable: return "Recognizer is unavailable"
//            }
//        }
//    }
//    
//    var transcript: String = ""
//    
//    private var audioEngine: AVAudioEngine?
//    private var request: SFSpeechAudioBufferRecognitionRequest?
//    private var task: SFSpeechRecognitionTask?
//    
//    private var selectedLocale: Locale = Locale.current {
//        didSet {
//            updateRecognizer(locale: selectedLocale)
//        }
//    }
//    
//    //private let recognizer: SFSpeechRecognizer?
//    private var recognizer: SFSpeechRecognizer?
//    
///// Reset the speech recognizer.
//    func reset() {
//        task?.cancel()
//        audioEngine?.stop()
//        audioEngine = nil
//        request = nil
//        task = nil
//        // Optionally clear transcript upon reset
//        // transcript = ""  // Uncomment this if you want to clear transcript on reset
//    }
//    
//    func clear() {
//        transcript = ""
//    }
//    
//    private func speakError(_ error: Error) {
//            var errorMessage = ""
//            if let error = error as? RecognizerError {
//                errorMessage += error.message
//            } else {
//                errorMessage += error.localizedDescription
//            }
//            transcript = "<< \(errorMessage) >>"
//    }
//    
//    private func speak(_ message: String) {
//        transcript += "\n" + message  // Append new transcription to the existing transcript
//    }
//
//    init() {
//        recognizer = SFSpeechRecognizer()
//        
//        // Print supported Locales
//        print(SFSpeechRecognizer.supportedLocales())
//        //
//        
//        Task(priority: .background) {
//            do {
//                guard recognizer != nil else {
//                    throw RecognizerError.nilRecognizer
//                }
//                guard await SFSpeechRecognizer.hasAuthorizationToRecognize() else {
//                    throw RecognizerError.notAuthorizedToRecognize
//                }
//                guard await AVAudioSession.sharedInstance().hasPermissionToRecord() else {
//                    throw RecognizerError.notPermittedToRecord
//                }
//            } catch {
//                speakError(error)
//            }
//        }
//    }
//       
//    deinit {
//       reset()
//    }
//
//    /**
//    Begin transcribing audio.
//
//    Creates a `SFSpeechRecognitionTask` that transcribes speech to text until you call `stopTranscribing()`.
//    The resulting transcription is continuously written to the published `transcript` property.
//    */
//    func transcribe() {
//       DispatchQueue(label: "Speech Recognizer Queue", qos: .background).async { [weak self] in
//           guard let self = self, let recognizer = self.recognizer, recognizer.isAvailable else {
//               self?.speakError(RecognizerError.recognizerIsUnavailable)
//               return
//           }
//           
//           do {
//               let (audioEngine, request) = try Self.prepareEngine()
//               self.audioEngine = audioEngine
//               self.request = request
//               
//               self.task = recognizer.recognitionTask(with: request) { result, error in
//                   let receivedFinalResult = result?.isFinal ?? false
//                   let receivedError = error != nil // != nil mean there's error (true)
//                   
//                   if receivedFinalResult || receivedError {
//                       audioEngine.stop()
//                       audioEngine.inputNode.removeTap(onBus: 0)
//                   }
//                   
//                   if let result = result {
//                       self.speak(result.bestTranscription.formattedString)
//                   }
//               }
//           } catch {
//               self.reset()
//               self.speakError(error)
//           }
//       }
//    }
//    
//    private static func prepareEngine() throws -> (AVAudioEngine, SFSpeechAudioBufferRecognitionRequest) {
//        let audioEngine = AVAudioEngine()
//        
//        let request = SFSpeechAudioBufferRecognitionRequest()
//        //request.shouldReportPartialResults = true
//        request.shouldReportPartialResults = false
//        
//        let audioSession = AVAudioSession.sharedInstance()
//        try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
//        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
//        let inputNode = audioEngine.inputNode
//        
//        let recordingFormat = inputNode.outputFormat(forBus: 0)
//        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) {
//            (buffer: AVAudioPCMBuffer, when: AVAudioTime) in
//            request.append(buffer)
//        }
//        audioEngine.prepare()
//        try audioEngine.start()
//        
//        return (audioEngine, request)
//    }
//    
///// Update the recognizer locale.
//    func updateRecognizer(locale: Locale) {
//        reset()
//        recognizer = SFSpeechRecognizer(locale: locale)
//        
//        Task(priority: .background) {
//            do {
//                guard recognizer != nil else {
//                    throw RecognizerError.nilRecognizer
//                }
//                guard await SFSpeechRecognizer.hasAuthorizationToRecognize() else {
//                    throw RecognizerError.notAuthorizedToRecognize
//                }
//                guard await AVAudioSession.sharedInstance().hasPermissionToRecord() else {
//                    throw RecognizerError.notPermittedToRecord
//                }
//            } catch {
//                speakError(error)
//            }
//        }
//    }
//    
//    func changeLocale(to locale: Locale) {
//        selectedLocale = locale
//    }
//    
///// Stop transcribing audio.
//    func stopTranscribing() {
//        reset()
//    }
//       
//}
//
//extension SFSpeechRecognizer {
//    static func hasAuthorizationToRecognize() async -> Bool {
//        await withCheckedContinuation { continuation in
//            requestAuthorization { status in
//                continuation.resume(returning: status == .authorized)
//            }
//        }
//    }
//}
//
//extension AVAudioSession {
//    func hasPermissionToRecord() async -> Bool {
//        await withCheckedContinuation { continuation in
//            AVAudioApplication.requestRecordPermission() { authorized in
//                continuation.resume(returning: authorized)
//            }
//        }
//    }
//
//}


