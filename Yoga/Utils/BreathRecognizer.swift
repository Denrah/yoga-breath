//
//  BreathRecognizer.swift
//  Yoga
//

import Foundation
import AVFoundation

class BreathRecognizer: NSObject {
  private let threshold: Float
  private var recorder: AVAudioRecorder?
  
  private var isBreathing = false {
    didSet {
      if isBreathing != oldValue {
        self.onBreathChanged?(isBreathing)
      }
    }
  }
  
  var onBreathChanged: ((_ isBreathing: Bool) -> Void)?
  
  init(threshold: Float) throws {
    self.threshold = threshold
    super.init()
    try self.setupAudioRecorder()
  }
  
  func start() {
    recorder?.prepareToRecord()
    recorder?.isMeteringEnabled = true
    recorder?.record()
    
    Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
      self?.handleTimerTick()
    }
  }
  
  private func setupAudioRecorder() throws {
    try AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.record)
    try AVAudioSession.sharedInstance().setActive(true)
    
    let url = NSURL.fileURL(withPath: NSTemporaryDirectory()).appendingPathComponent("yogaTempRecord")
    
    let settings: [String: Any] = [
      AVSampleRateKey: 44100.0,
      AVFormatIDKey: Int(kAudioFormatAppleLossless),
      AVNumberOfChannelsKey: 1,
      AVEncoderAudioQualityKey: AVAudioQuality.max.rawValue
    ]
    
    try recorder = AVAudioRecorder(url: url, settings: settings)
  }
  
  private func handleTimerTick() {
    guard let recorder = recorder else { return }
    recorder.updateMeters()
    
    let average = recorder.averagePower(forChannel: 0) * 0.4
    let peak = recorder.peakPower(forChannel: 0) * 0.6
    let combinedPower = average + peak
    
    isBreathing = (combinedPower > threshold)
  }
}
