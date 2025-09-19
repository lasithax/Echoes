import Foundation
import AVFoundation
import SwiftUI

/// Manages voice note recording and playback.
/// Exposes simple state for SwiftUI (recording/playing/time/errors) and
/// stores the most recent recording as an `.m4a` file in the app's Documents folder.
class AudioRecorder: NSObject, ObservableObject {
    private var audioRecorder: AVAudioRecorder?
    private var audioPlayer: AVAudioPlayer?
    
    @Published var isRecording = false
    @Published var isPlaying = false
    @Published var recordingTime: TimeInterval = 0
    @Published var hasRecording = false
    @Published var errorMessage: String?
    
    private var recordingTimer: Timer?
    private var recordingURL: URL?
    
    override init() {
        super.init()
        setupAudioSession()
    }
    
    deinit {
        stopRecording()
        stopPlayback()
    }
    
    /// Preparing the AVAudioSession for recording and playing through the speaker.
    private func setupAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth])
        } catch {
            print("Failed to set up audio session: \(error.localizedDescription)")
        }
    }
    
    /// Checks mic permission and then starts recording if allowed.
    func startRecording() {
        print("DEBUG: startRecording called")
        let permissionStatus = AVAudioSession.sharedInstance().recordPermission
        print("DEBUG: Permission status: \(permissionStatus.rawValue)")
        
        switch permissionStatus {
        case .granted:
            print("DEBUG: Permission granted, beginning recording")
            beginRecording()
        case .denied:
            print("DEBUG: Permission denied")
            errorMessage = "Microphone access denied. Please enable in Settings > Privacy & Security > Microphone > Echoes."
        case .undetermined:
            print("DEBUG: Permission undetermined, requesting")
            // Requesting permission and continue when the user responds
            do {
                AVAudioSession.sharedInstance().requestRecordPermission { [weak self] allowed in
                    DispatchQueue.main.async {
                        print("DEBUG: Permission request result: \(allowed)")
                        if allowed {
                            self?.beginRecording()
                        } else {
                            self?.errorMessage = "Microphone access is required to record voice notes. Please enable in Settings > Privacy & Security > Microphone > Echoes."
                        }
                    }
                }
            } catch {
                print("DEBUG: Error requesting microphone permission: \(error)")
                errorMessage = "Unable to request microphone permission. Please add NSMicrophoneUsageDescription to Info.plist"
            }
        @unknown default:
            print("DEBUG: Unknown permission status")
            errorMessage = "Unable to access microphone"
        }
    }
    
    /// Configuring the recorder, creates a file URL, and begins capturing audio.
    private func beginRecording() {
        print("DEBUG: beginRecording called")
        
        do {
            let audioSession = AVAudioSession.sharedInstance()
            print("DEBUG: Setting audio session active")
            try audioSession.setActive(true)
            
            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let audioFilename = documentsPath.appendingPathComponent("recording_\(Date().timeIntervalSince1970).m4a")
            recordingURL = audioFilename
            print("DEBUG: Recording URL: \(audioFilename)")
            
            let settings = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 44100,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]
            
            print("DEBUG: Creating audio recorder")
            audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
            audioRecorder?.delegate = self
            
            let recordStarted = audioRecorder?.record() ?? false
            print("DEBUG: Recording started: \(recordStarted)")
            
            if recordStarted {
                isRecording = true
                recordingTime = 0
                hasRecording = false
                errorMessage = nil
                
                // Updating the elapsed time so the UI can show a live counter.
                recordingTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
                    self.recordingTime = self.audioRecorder?.currentTime ?? 0
                }
                print("DEBUG: Recording setup complete")
            } else {
                errorMessage = "Failed to start recording"
                print("DEBUG: Failed to start recording")
            }
            
        } catch {
            let errorMsg = "Failed to start recording: \(error.localizedDescription)"
            errorMessage = errorMsg
            print("DEBUG: Recording error: \(errorMsg)")
        }
    }
    
    /// Stops capturing audio and finalizing the file on disk.
    func stopRecording() {
        audioRecorder?.stop()
        recordingTimer?.invalidate()
        recordingTimer = nil
        
        isRecording = false
        hasRecording = recordingURL != nil
    }
    
    /// Loading the finished recording into an AVAudioPlayer and starting to play the recording.
    func startPlayback() {
        guard let url = recordingURL else {
            errorMessage = "No recording to play"
            return
        }
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.delegate = self
            audioPlayer?.play()
            isPlaying = true
            errorMessage = nil
        } catch {
            errorMessage = "Failed to play recording: \(error.localizedDescription)"
        }
    }
    
    /// Stops playing immediately.
    func stopPlayback() {
        audioPlayer?.stop()
        isPlaying = false
    }
    
    /// Returns the raw audio data from disk.
    func getRecordingData() -> Data? {
        guard let url = recordingURL else { return nil }
        return try? Data(contentsOf: url)
    }
    
    /// Deletes the current recording and resets state.
    func clearRecording() {
        stopRecording()
        stopPlayback()
        
        if let url = recordingURL {
            try? FileManager.default.removeItem(at: url)
        }
        
        recordingURL = nil
        hasRecording = false
        recordingTime = 0
    }
    
    /// Formatting a `TimeInterval` as mm:ss for display.
    func formattedTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

/// Updates the UI to match the recording status and shows any errors from the recorder.
extension AudioRecorder: AVAudioRecorderDelegate {
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        DispatchQueue.main.async {
            self.isRecording = false
            self.hasRecording = flag
            if !flag {
                self.errorMessage = "Recording failed"
            }
        }
    }
    
    func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        DispatchQueue.main.async {
            self.isRecording = false
            self.errorMessage = "Recording error: \(error?.localizedDescription ?? "Unknown error")"
        }
    }
}

/// Restores the UI when playback stops or runs into an error.
extension AudioRecorder: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        DispatchQueue.main.async {
            self.isPlaying = false
        }
    }
    
    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        DispatchQueue.main.async {
            self.isPlaying = false
            self.errorMessage = "Playback error: \(error?.localizedDescription ?? "Unknown error")"
        }
    }
}
