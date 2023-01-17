//
//  VSVideoSpeeder.swift
//  Video Trim Tool
//
//  Created by Alexandre Kakhiani on 12.01.23.
//  Copyright © 2023 Faisal. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation
import Photos

enum SpeedoMode {
    case Slower
    case Faster
}

class VSVideoSpeeder: NSObject {
    
    var urlToSave: URL?
    
    /// Singleton instance of `VSVideoSpeeder`
    static var shared: VSVideoSpeeder = {
        return VSVideoSpeeder()
    }()
    
    /// Range is between 1x and 5x. Will not happen anything if scale is out of range. Exporter will be nil in case url is invalid or unable to make asset instance.
    func scaleAsset(fromURL url: URL,  by scale: Int64, withMode mode: SpeedoMode, completion: @escaping (_ exporter: AVAssetExportSession?) -> Void) {
        
        /// Check the valid scale
        if scale < 0 || scale > 5 {
            /// Can not proceed, Invalid range
             completion(nil)
            return
        }
        
        /// Asset
        let asset = AVAsset(url: url)
        
        /// Video Tracks
        let videoTracks = asset.tracks(withMediaType: AVMediaType.video)
        if videoTracks.count == 0 {
            /// Can not find any video track
            completion(nil)
            print("there are no videos found")
            return
        }
        
        /// Get the scaled video duration
        let scaledVideoDuration = (mode == .Faster) ? CMTimeMake(value: asset.duration.value / scale, timescale: asset.duration.timescale) : CMTimeMake(value: asset.duration.value * scale, timescale: asset.duration.timescale)
        let timeRange = CMTimeRangeMake(start: CMTime.zero, duration: asset.duration)
        
        /// Video track
        let videoTrack = videoTracks.first!
        
        let mixComposition = AVMutableComposition()
        let compositionVideoTrack = mixComposition.addMutableTrack(withMediaType: AVMediaType.video, preferredTrackID: kCMPersistentTrackID_Invalid)
        
        /// Audio Tracks
        let audioTracks = asset.tracks(withMediaType: AVMediaType.audio)
        if audioTracks.count > 0 {
            /// Use audio if video contains the audio track
            let compositionAudioTrack = mixComposition.addMutableTrack(withMediaType: AVMediaType.audio, preferredTrackID: kCMPersistentTrackID_Invalid)
            
            /// Audio track
            let audioTrack = audioTracks.first!
            do {
                try compositionAudioTrack?.insertTimeRange(timeRange, of: audioTrack, at: CMTime.zero)
                compositionAudioTrack?.scaleTimeRange(timeRange, toDuration: scaledVideoDuration)
            } catch _ {
                /// Ignore audio error
            }
        }
        
        do {
            try compositionVideoTrack?.insertTimeRange(timeRange, of: videoTrack, at: CMTime.zero)
            compositionVideoTrack?.scaleTimeRange(timeRange, toDuration: scaledVideoDuration)
            
            /// Keep original transformation
            compositionVideoTrack?.preferredTransform = videoTrack.preferredTransform
            
            /// Initialize Exporter now
            let outputFileURL = URL(fileURLWithPath: "/output/")
            /// Note:- Please use directory path if you are testing with device.
            
            let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
            //guard let targetURL = documentsDirectory?.appendingPathComponent(outputFileURL.relativeString) else { return }
            
            do {
                if FileManager.default.fileExists(atPath: url.path) {
                    try FileManager.default.removeItem(at: url)
                }
                
                try FileManager.default.replaceItemAt(url, withItemAt: url)
                
            } catch {
                print(error.localizedDescription)
            }
            
            
            let exporter = AVAssetExportSession(asset: mixComposition, presetName: AVAssetExportPresetHighestQuality)
            exporter?.outputURL = url
            exporter?.outputFileType = AVFileType.mov
            exporter?.shouldOptimizeForNetworkUse = true
            self.urlToSave = url
            exporter?.exportAsynchronously(completionHandler: {
                completion(exporter)
            })
            
        } catch let error {
            print(error.localizedDescription)
            completion(nil)
            return
        }
    }
    
    
}
