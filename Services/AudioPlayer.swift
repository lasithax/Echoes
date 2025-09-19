import Foundation
import AVFoundation

/// Audio player for playing voice notes.
final class AudioPlayer: NSObject, ObservableObject {
	@Published var isPlaying = false
	@Published var duration: TimeInterval = 0
	@Published var currentTime: TimeInterval = 0
	@Published var errorMessage: String?
	
	private var player: AVAudioPlayer?
	private var timer: Timer?
	
	/// Loading raw audio data into the player.
	func load(data: Data) {
		stop()
		do {
			player = try AVAudioPlayer(data: data)
			player?.delegate = self
			duration = player?.duration ?? 0
			currentTime = 0
			isPlaying = false
			errorMessage = nil
		} catch {
			errorMessage = "Failed to load audio: \(error.localizedDescription)"
		}
	}
	
	/// Starts playing and the timer.
	func play() {
		guard let player else { return }
		if player.play() {
			isPlaying = true
			startTimer()
		} else {
			errorMessage = "Unable to start playback"
		}
	}
	
	/// Pauses playing and stops the progress timer.
	func pause() {
		player?.pause()
		isPlaying = false
		stopTimer()
	}
	
	/// Stops playing and clears the player.
	func stop() {
		player?.stop()
		player = nil
		isPlaying = false
		currentTime = 0
		duration = 0
		stopTimer()
	}
	
	/// Ticks while playing to keep the UI in sync with the audio position.
	private func startTimer() {
		stopTimer()
		timer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { [weak self] _ in
			guard let self, let player = self.player else { return }
			self.currentTime = player.currentTime
			if !player.isPlaying {
				self.isPlaying = false
				self.stopTimer()
			}
		}
	}
	
	private func stopTimer() {
		timer?.invalidate()
		timer = nil
	}
}

extension AudioPlayer: AVAudioPlayerDelegate {
	/// Resets state when the clip finishes.
	func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
		DispatchQueue.main.async {
			self.isPlaying = false
			self.stopTimer()
		}
	}
	
	/// Reports errors from the system audio player.
	func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
		DispatchQueue.main.async {
			self.isPlaying = false
			self.stopTimer()
			self.errorMessage = error?.localizedDescription
		}
	}
}
