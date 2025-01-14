//
//  VideoMainViewController.swift
//  Video Trim Tool
//
//  Created by Faisal on 25/01/17.
//  Copyright © 2017 Faisal. All rights reserved.
//

import UIKit
import AVFoundation
import MobileCoreServices
import CoreMedia
import AssetsLibrary
import Photos
class VideoMainViewController: UIViewController {
    var isPlaying = true
    var isSliderEnd = true
    var playbackTimeCheckerTimer: Timer! = nil
    let playerObserver: Any? = nil
    
    let exportSession: AVAssetExportSession! = nil
    var player: AVPlayer!
    var playerItem: AVPlayerItem!
    var playerLayer: AVPlayerLayer!
    var asset: AVAsset!
    
    var url:NSURL! = nil
    var startTime: CGFloat = 0.0
    var stopTime: CGFloat  = 0.0
    var thumbTime: CMTime!
    var thumbtimeSeconds: Int!
    var audioIsPresent = true
    var caseOfExport: Int = 5 // varable deretmines how it exports videos
    //                           0 - exports full video with desired slowtime
    //                           1 - exports video trimmed from the left only
    //                           2 - exports video trimmed from the right only
    //                           3 - exports video trimmed from both sides
    
    
    var videoPlaybackPosition: CGFloat = 0.0
    var cache:NSCache<AnyObject, AnyObject>!
    var rangeSlider: RangeSlider! = nil
    
    @IBOutlet weak var layoutContainer: UIView!
    @IBOutlet weak var selectButton: UIButton!
    @IBOutlet weak var videoLayer: UIView!
    @IBOutlet weak var cropButton: UIButton!
    
    @IBOutlet weak var frameContainerView: UIView!
    @IBOutlet weak var imageFrameView: UIView!
    
    @IBOutlet weak var startView: UIView!
    @IBOutlet weak var startTimeText: UITextField!
    
    @IBOutlet weak var endView: UIView!
    @IBOutlet weak var endTimeText: UITextField!
    
    @IBOutlet weak var slowDownSlider: UISlider!
    
    @IBOutlet weak var stackView: UIStackView!
    
    override func viewDidLoad()
    {
        
        super.viewDidLoad()
        loadViews()
        
        
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //Loading Views
    func loadViews()
    {
        //Whole layout view
        layoutContainer.layer.borderWidth = 1.0
        layoutContainer.layer.borderColor = UIColor.white.cgColor
        
        selectButton.layer.cornerRadius = 5.0
        cropButton.layer.cornerRadius   = 5.0
        
        //Hiding buttons and view on load
        cropButton.isHidden         = true
        startView.isHidden          = true
        endView.isHidden            = true
        frameContainerView.isHidden = true
        slowDownSlider.isHidden = true
        stackView.isHidden = true
        
        //Style for startTime
        startTimeText.layer.cornerRadius = 5.0
        startTimeText.layer.borderWidth  = 1.0
        startTimeText.layer.borderColor  = UIColor.white.cgColor
        
        //Style for endTime
        endTimeText.layer.cornerRadius = 5.0
        endTimeText.layer.borderWidth  = 1.0
        endTimeText.layer.borderColor  = UIColor.white.cgColor
        
        imageFrameView.layer.cornerRadius = 5.0
        imageFrameView.layer.borderWidth  = 1.0
        imageFrameView.layer.borderColor  = UIColor.white.cgColor
        imageFrameView.layer.masksToBounds = true
        
        
        player = AVPlayer()
        
        
        //Allocating NsCahe for temp storage
        cache = NSCache()
    }
    
    //Action for select Video
    @IBAction func selectVideoUrl(_ sender: Any)
    {
        //Selecting Video type
        let myImagePickerController        = UIImagePickerController()
        myImagePickerController.sourceType = .photoLibrary
        myImagePickerController.mediaTypes = [(kUTTypeMovie) as String]
        myImagePickerController.delegate   = self
        myImagePickerController.isEditing  = false
        present(myImagePickerController, animated: true, completion: {  })
    }
    
    //Action for crop video
    @IBAction func cropVideo(_ sender: Any)
    {
        
//        player.pause()
        let start = Float(startTimeText.text!)
        let end   = Float(endTimeText.text!)
        
        //2 is the index of the video that will be slowed down. 1 and 3 are just cropped and saved.
        
        if (start == 0.0){//if the left thumb of the slider is at the end
            if end == Float(asset.duration.seconds).rounded() { //if the right thumb of the slider is at the end
                self.caseOfExport = 0
                cropVideo(sourceURL1: url, startTime: start!, endTime: end!, indexOfVideo: 2)
            } else {
                self.caseOfExport = 2
                cropVideo(sourceURL1: url, startTime: start!, endTime: end!, indexOfVideo: 2)
                cropVideo(sourceURL1: url, startTime: end!, endTime: Float(asset.duration.seconds), indexOfVideo: 3)
            }
        } else {
            if end == Float(asset.duration.seconds).rounded() {//if the right thumb of the slider is at the end
                self.caseOfExport = 1
                cropVideo(sourceURL1: url, startTime: 0.0, endTime: start!, indexOfVideo: 1)
                cropVideo(sourceURL1: url, startTime: start!, endTime: end!, indexOfVideo: 2)
            }else{
                self.caseOfExport = 3
                cropVideo(sourceURL1: url, startTime: Float(0.0), endTime: start!, indexOfVideo: 1)
                cropVideo(sourceURL1: url, startTime: end!, endTime: Float(asset.duration.seconds), indexOfVideo: 3)
                cropVideo(sourceURL1: url, startTime: start!, endTime: end!, indexOfVideo: 2)
            }
        }
    }
    
    @IBAction func onSliderChange(_ sender: UISlider) {
        sender.value = roundf(sender.value)
        switch sender.value {
        case -4:
            player.rate = 1 / 3
        case -3:
            player.rate = 1 / 2.5
        case -2:
            player.rate = 1 / 2
        case -1:
            player.rate = 1 / 1.5
        case 0:
            player.rate = 1
        case 1:
            player.rate = 1 * 1.5
        case 2:
            player.rate = 1 * 2
        case 3:
            player.rate = 1 * 2.5
        case 4:
            player.rate = 1 * 3
        default:
            print("tes")
        }
    }
}


//Subclass of VideoMainViewController
extension VideoMainViewController:UIImagePickerControllerDelegate,UINavigationControllerDelegate,UITextFieldDelegate
{
    //Delegate method of image picker
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true, completion: nil)
        
        url = info[UIImagePickerController.InfoKey(rawValue: UIImagePickerController.InfoKey.mediaURL.rawValue)] as? NSURL
        asset   = AVURLAsset.init(url: url as URL)
        
        thumbTime = asset.duration
        thumbtimeSeconds = Int(CMTimeGetSeconds(thumbTime))
        
        viewAfterVideoIsPicked()
        
        let item:AVPlayerItem = AVPlayerItem(asset: asset)
        player                = AVPlayer(playerItem: item)
        playerLayer           = AVPlayerLayer(player: player)
        playerLayer.frame     = videoLayer.bounds
        
        playerLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        player.actionAtItemEnd   = AVPlayer.ActionAtItemEnd.none
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(tapOnVideoLayer))
        videoLayer.addGestureRecognizer(tap)
        tapOnVideoLayer(tap: tap)
        
        videoLayer.layer.addSublayer(playerLayer)
        player.play()
    }
    
    func viewAfterVideoIsPicked()
    {
        //Rmoving player if alredy exists
        if(playerLayer != nil)
        {
            playerLayer.removeFromSuperlayer()
        }
        
        createImageFrames() //creates the image frames on the view, which trims the video
        
        //unhide buttons and view after video selection
        cropButton.isHidden         = false
        startView.isHidden          = false
        endView.isHidden            = false
        frameContainerView.isHidden = false
        slowDownSlider.isHidden = false
        stackView.isHidden = false
        
        
        isSliderEnd = true
        startTimeText.text! = "\(0.0)"
        endTimeText.text   = "\(thumbtimeSeconds!)"
        createRangeSlider()
    }
    
    //Tap action on video player
    @objc func tapOnVideoLayer(tap: UITapGestureRecognizer)
    {
        isPlaying = !isPlaying
        if isPlaying
        {
            player.play()
        }
        else
        {
            player.pause()
        }
        
    }
    
    
    
    //MARK: CreatingFrameImages
    func createImageFrames()
    {
        //creating assets
        let assetImgGenerate : AVAssetImageGenerator    = AVAssetImageGenerator(asset: asset)
        assetImgGenerate.appliesPreferredTrackTransform = true
        assetImgGenerate.requestedTimeToleranceAfter    = CMTime.zero;
        assetImgGenerate.requestedTimeToleranceBefore   = CMTime.zero;
        
        
        assetImgGenerate.appliesPreferredTrackTransform = true
        let thumbTime: CMTime = asset.duration
        let thumbtimeSeconds  = Int(CMTimeGetSeconds(thumbTime))
        let maxLength         = "\(thumbtimeSeconds)" as NSString
        
        let thumbAvg  = thumbtimeSeconds/6
        var startTime = 1
        var startXPosition:CGFloat = 0.0
        
        //loop for 6 number of frames
        for _ in 0...5
        {
            let imageButton = UIButton()
            let xPositionForEach = CGFloat(imageFrameView.frame.width)/6
            imageButton.frame = CGRect(x: CGFloat(startXPosition), y: CGFloat(0), width: xPositionForEach, height: CGFloat(imageFrameView.frame.height))
            do {
                let time:CMTime = CMTimeMakeWithSeconds(Float64(startTime),preferredTimescale: Int32(maxLength.length))
                let img = try assetImgGenerate.copyCGImage(at: time, actualTime: nil)
                let image = UIImage(cgImage: img)
                imageButton.setImage(image, for: .normal)
            }
            catch
                _ as NSError
            {
                print("Image generation failed with error (error)")
            }
            
            startXPosition = startXPosition + xPositionForEach
            startTime = startTime + thumbAvg
            imageButton.isUserInteractionEnabled = false
            imageFrameView.addSubview(imageButton)
        }
    }
    
    //Create range slider
    func createRangeSlider()
    {
        //Remove slider if already present
        let subViews = frameContainerView.subviews
        for subview in subViews{
            if subview.tag == 1000 {
                subview.removeFromSuperview()
            }
        }
        
        rangeSlider = RangeSlider(frame: frameContainerView.bounds)
        frameContainerView.addSubview(rangeSlider)
        rangeSlider.tag = 1000
        
        //Range slider action
        rangeSlider.addTarget(self, action: #selector(VideoMainViewController.rangeSliderValueChanged(_:)), for: .valueChanged)
        rangeSlider.addTarget(self, action: #selector(VideoMainViewController.rangeSliderDragFinished(_:)), for: .touchUpInside)
        
        let time = DispatchTime.now() + Double(Int64(NSEC_PER_SEC)) / Double(NSEC_PER_SEC)
        DispatchQueue.main.asyncAfter(deadline: time) {
            self.rangeSlider.trackHighlightTintColor = UIColor.clear
            self.rangeSlider.curvaceousness = 1.0
        }
        
    }
    
    //MARK: rangeSlider Delegate
    @objc func rangeSliderValueChanged(_ rangeSlider: RangeSlider) {
        player.pause()
        isPlaying = false
        if(isSliderEnd == true)
        {
            rangeSlider.minimumValue = 0.0
            rangeSlider.maximumValue = Double(thumbtimeSeconds)
            
            rangeSlider.upperValue = Double(thumbtimeSeconds)
            isSliderEnd = !isSliderEnd
            
        }
        
        startTimeText.text = "\(rangeSlider.lowerValue)"
        endTimeText.text   = "\(rangeSlider.upperValue)"
        
        //print(rangeSlider.lowerLayerSelected)
        if(rangeSlider.lowerLayerSelected)
        {
            seekVideo(toPos: CGFloat(rangeSlider.lowerValue))
        }
        else
        {
            seekVideo(toPos: CGFloat(rangeSlider.upperValue))
        }
    }
    
    @objc func rangeSliderDragFinished(_ rangeSlider: RangeSlider){
        seekVideo(toPos: CGFloat(rangeSlider.lowerValue))
    }
    
    
    //MARK: TextField Delegates
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange,
                   replacementString string: String) -> Bool
    {
        let maxLength     = 3
        let currentString = startTimeText.text! as NSString
        let newString     = currentString.replacingCharacters(in: range, with: string) as NSString
        return newString.length <= maxLength
    }
    
    //Seek video when slide
    func seekVideo(toPos pos: CGFloat) {
        videoPlaybackPosition = pos
        let time: CMTime = CMTimeMakeWithSeconds(Float64(videoPlaybackPosition), preferredTimescale: player.currentTime().timescale)
        player.seek(to: time, toleranceBefore: CMTime.zero, toleranceAfter: CMTime.zero)
        
        if(pos == CGFloat(thumbtimeSeconds))
        {
            player.pause()
        }
    }
    
    //Trim Video Function
    func cropVideo(sourceURL1: NSURL, startTime:Float, endTime:Float, indexOfVideo: Int)
    {
        let manager = FileManager.default
        
        guard let documentDirectory = try? manager.url(for: .documentDirectory,
                                                       in: .userDomainMask,
                                                       appropriateFor: nil,
                                                       create: true) else {return}
        guard let mediaType = "mp4" as? String else {return}
        //        guard (sourceURL1 as? NSURL) != nil else {return}
        
        if mediaType == kUTTypeMovie as String || mediaType == "mp4" as String
        {
            let start = startTime
            let end = endTime
            
            var outputURL = documentDirectory.appendingPathComponent("output")
            do {
                try manager.createDirectory(at: outputURL, withIntermediateDirectories: true, attributes: nil)
                
                switch indexOfVideo {
                case 1:
                    outputURL = outputURL.appendingPathComponent("1.mp4")
                case 2:
                    outputURL = outputURL.appendingPathComponent("2.mp4")
                case 3:
                    outputURL = outputURL.appendingPathComponent("3.mp4")
                default:
                    print("index out of bounds")
                }
            }catch let error {
                print(error)
            }
            
            //Remove existing file
            _ = try? manager.removeItem(at: outputURL)
            
            
            
            guard let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetHighestQuality) else {return}
            exportSession.outputURL = outputURL
            exportSession.outputFileType = AVFileType.mp4
            
            var timeRange: CMTimeRange?
            
            switch indexOfVideo {
            case 1:
                let startTime = CMTime(seconds: Double(start), preferredTimescale: 1000)
                let endTime = CMTime(seconds: Double(end), preferredTimescale: 1000)
                timeRange = CMTimeRange(start: startTime, end: endTime)
                print(timeRange)
            case 2:
                let startTime = CMTime(seconds: Double(start), preferredTimescale: 1000)
                let endTime = CMTime(seconds: Double(end), preferredTimescale: 1000)
                timeRange = CMTimeRange(start: startTime, end: endTime)
            case 3:
                let startTime = CMTime(seconds: Double(start), preferredTimescale: 1000)
                let endTime = CMTime(seconds: Double(end), preferredTimescale: 1000)
                timeRange = CMTimeRange(start: startTime, end: endTime)
            default:
                print("index out of bounds")
            }
            
            exportSession.timeRange = timeRange!
            exportSession.exportAsynchronously{
                
                let video2URL = documentDirectory.appendingPathComponent("output").appendingPathComponent("2.mp4")
                switch exportSession.status {
                case .completed:
                    print("2nd video export session successful")
                    DispatchQueue.main.async {
                        switch self.slowDownSlider.value {
                        case -4:
                            self.slowDownVideo(fromURL: video2URL, by: 5, withMode: .Slower)
                        case -3:
                            self.slowDownVideo(fromURL: video2URL, by: 4, withMode: .Slower)
                        case -2:
                            self.slowDownVideo(fromURL: video2URL, by: 3, withMode: .Slower)
                        case -1:
                            self.slowDownVideo(fromURL: video2URL, by: 2, withMode: .Slower)
                        case 0:
                            self.slowDownVideo(fromURL: video2URL, by: 1, withMode: .Faster)
                        case 1:
                            self.slowDownVideo(fromURL: video2URL, by: 2, withMode: .Faster)
                        case 2:
                            self.slowDownVideo(fromURL: video2URL, by: 3, withMode: .Faster)
                        case 3:
                            self.slowDownVideo(fromURL: video2URL, by: 4, withMode: .Faster)
                        case 4:
                            self.slowDownVideo(fromURL: video2URL, by: 5, withMode: .Faster)
                        default:
                            print("tes")
                        }
                    }
                    
                case .failed:
                    print("failed \(String(describing: exportSession.error))")
                    
                case .cancelled:
                    print("cancelled \(String(describing: exportSession.error))")
                    
                default:
                    print(exportSession.error!)
                }
            }
        }
    }
    
    //Save Video to Photos Library
    private func saveToCameraRoll(URL: NSURL!) {
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: URL as URL)
        }) { saved, error in
            if saved {
                DispatchQueue.main.async {
                    let alertController = UIAlertController(title: "video was successfully saved to Camera roll", message: nil, preferredStyle: .alert)
                    let defaultAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                    alertController.addAction(defaultAction)
                    self.present(alertController, animated: true, completion: nil)
                    
                    self.audioIsPresent = false
                }
            }
            else {
                print(error!)
            }
            
        }}
    
    
    private func slowDownVideo(fromURL url: URL,  by scale: Int64, withMode mode: SpeedoMode){
        VSVideoSpeeder.shared.scaleAsset(fromURL: url as URL, by: scale, withMode: mode) { (exporter) in
            if let exporter = exporter {
                switch exporter.status {
                case .failed: do {
                    print(exporter.error?.localizedDescription ?? "Error in exporting..")
                }
                case .completed: do {
                    print("Scaled and slowed video has been exported successfully!")
                    //                    self.saveToCameraRoll(URL: VSVideoSpeeder.shared.urlToSave as NSURL?)
                    self.mergeVideosAndSave(video2URL: VSVideoSpeeder.shared.urlToSave as URL?, case: self.caseOfExport)
                }
                case .unknown: break
                case .waiting: break
                case .exporting: break
                case .cancelled: break
                }
            }
            else {
                /// Error
                print("Exporter is not initialized.")
            }
        }
    }
    
    private func mergeVideosAndSave(video2URL: URL?, case: Int){
        guard let documentDirectory = try? FileManager.default.url(for: .documentDirectory,
                                                                   in: .userDomainMask,
                                                                   appropriateFor: nil,
                                                                   create: true) else {return}
        let fileDirectory = documentDirectory.appendingPathComponent("output")
        let video1URL = fileDirectory.appendingPathComponent("1.mp4")
        let video3URL = fileDirectory.appendingPathComponent("3.mp4")
        
        let movie = AVMutableComposition()
        let videoTrack = movie.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)
        var audioTrack = movie.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid) //movie.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)
        
        
        let video1Asset = AVAsset(url: video1URL) //1st video
        let video2Asset = AVAsset(url: video2URL!) //2nd video
        let video3Asset = AVAsset(url: video3URL) //3rd video
        
        
        var video2AudioTrack = video2Asset.tracks(withMediaType: .audio).first
        var video1AudioTrack = video2Asset.tracks(withMediaType: .audio).first
        var video3AudioTrack = video2Asset.tracks(withMediaType: .audio).first
        
        if video2AudioTrack == nil {
            print("audio is nil")
            self.audioIsPresent = false
        } else {
            audioTrack = movie.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)!
            video2AudioTrack = video2Asset.tracks(withMediaType: .audio).first!
            video1AudioTrack = video2Asset.tracks(withMediaType: .audio).first!
            video3AudioTrack = video2Asset.tracks(withMediaType: .audio).first! //2
        }
        
        //loads the 2nd video video tracks
        let video2VideoTrack = video2Asset.tracks(withMediaType: .video).first!
        let video2Range = CMTimeRangeMake(start: CMTime.zero, duration: video2Asset.duration)
        
        //loads the first video tracks
        var video1VideoTrack = video2Asset.tracks(withMediaType: .video).first!
        var video1Range = CMTimeRangeMake(start: CMTime.zero, duration: video2Asset.duration)
        
        //loads the 3rd videotracks
        var video3VideoTrack = video2Asset.tracks(withMediaType: .video).first!
        var video3Range = CMTimeRangeMake(start: CMTime.zero, duration: video2Asset.duration)
        
        switch caseOfExport {
        case 0:
            print("nothing to do here")
        case 1:
            
            if self.audioIsPresent {
                video1AudioTrack = video1Asset.tracks(withMediaType: .audio).first!
            }
            video1VideoTrack = video1Asset.tracks(withMediaType: .video).first!
            video1Range = CMTimeRangeMake(start: CMTime.zero, duration: video1Asset.duration)
        case 2:
            if self.audioIsPresent {
                video3AudioTrack = video3Asset.tracks(withMediaType: .audio).first! //2
            }
            video3VideoTrack = video3Asset.tracks(withMediaType: .video).first!
            video3Range = CMTimeRangeMake(start: CMTime.zero, duration: video3Asset.duration)
            
        case 3:
            if self.audioIsPresent {
                video1AudioTrack = video1Asset.tracks(withMediaType: .audio).first!
                video3AudioTrack = video3Asset.tracks(withMediaType: .audio).first! //2
            }
            
            video1VideoTrack = video1Asset.tracks(withMediaType: .video).first!
            video1Range = CMTimeRangeMake(start: CMTime.zero, duration: video1Asset.duration)
            
            video3VideoTrack = video3Asset.tracks(withMediaType: .video).first!
            video3Range = CMTimeRangeMake(start: CMTime.zero, duration: video3Asset.duration)
        default:
            print("out of bounds")
        }
        
        do{
            switch caseOfExport {
            case 0:
                try videoTrack?.insertTimeRange(video2Range, of: video2VideoTrack, at:CMTime.zero ) //   inserts the second video to the composition
                if self.audioIsPresent {
                    try audioTrack?.insertTimeRange(video2Range, of: video2AudioTrack!, at: CMTime.zero)
                }
                
            case 1:
                try videoTrack?.insertTimeRange(video1Range, of: video1VideoTrack, at: CMTime.zero) //inserts the first video to the composition
                //here was the audio track for video 1
                
                try videoTrack?.insertTimeRange(video2Range, of: video2VideoTrack, at:(videoTrack?.asset?.duration)! ) //   inserts the second video to the composition
                //here was the audio track for video 2
                
                if self.audioIsPresent {
                    try audioTrack?.insertTimeRange(video1Range, of: video1AudioTrack!, at: CMTime.zero) // inserts the first video audio
                    try audioTrack?.insertTimeRange(video2Range, of: video2AudioTrack!, at: CMTime(seconds: video1Asset.duration.seconds, preferredTimescale: 1000))
                }
                
            case 2:
                try videoTrack?.insertTimeRange(video2Range, of: video2VideoTrack, at: CMTime.zero ) //  inserts the second video to the composition
                //here was the audio track for video 2
                
                try videoTrack?.insertTimeRange(video3Range, of: video3VideoTrack, at:(videoTrack?.asset?.duration)! ) // inserts the third video to composition
                //here was the audio track for video 3
                
                if self.audioIsPresent {
                    try audioTrack?.insertTimeRange(video2Range, of: video2AudioTrack!, at: CMTime.zero)
                    try audioTrack?.insertTimeRange(video3Range, of: video3AudioTrack!, at: CMTime(seconds: video1Asset.duration.seconds + video2Asset.duration.seconds, preferredTimescale: 1000)) //
                }
                
            case 3:
                
                try videoTrack?.insertTimeRange(video1Range, of: video1VideoTrack, at: CMTime.zero) //inserts the first video to the composition
                //here was the first video audio track
                
                try videoTrack?.insertTimeRange(video2Range, of: video2VideoTrack, at:(videoTrack?.asset?.duration)! ) //   inserts the second video to the composition
                //here was the second video audio track
                
                try videoTrack?.insertTimeRange(video3Range, of: video3VideoTrack, at:(videoTrack?.asset?.duration)! ) //  inserts the third video to composition
                //there was the third video audio track
                
                if self.audioIsPresent {
                    try audioTrack?.insertTimeRange(video1Range, of: video1AudioTrack!, at: CMTime.zero) // inserts the first video audio
                    try audioTrack?.insertTimeRange(video2Range, of: video2AudioTrack!, at: CMTime(seconds: video1Asset.duration.seconds, preferredTimescale: 1000))
                    try audioTrack?.insertTimeRange(video3Range, of: video3AudioTrack!, at: CMTime(seconds: video1Asset.duration.seconds + video2Asset.duration.seconds, preferredTimescale: 1000)) //
                }
                
            default:
                print("out of bounds")
            }
            
        } catch {
            print(LocalizedError.self)
        }
        
        let outputMovieURL = fileDirectory.appendingPathComponent("4.mp4")
        
        do {
            if FileManager.default.fileExists(atPath: outputMovieURL.path) {
                try FileManager.default.removeItem(at: outputMovieURL) // just in case
            }
        } catch {
            print(error.localizedDescription)
        }
        
        print("preparing to export mix composition")
        let exporter = AVAssetExportSession(asset: movie,
                                            presetName: AVAssetExportPresetHighestQuality) //1
        //configure exporter
        exporter?.outputURL = outputMovieURL//2
        exporter?.outputFileType = .mov
        //export!
        exporter?.exportAsynchronously(completionHandler: { [weak exporter] in
            DispatchQueue.main.async {
                if let error = exporter?.error { //3
                    print("failed \(error.localizedDescription)")
                } else {
                    print("movie has been exported to \(outputMovieURL)")
                    print(print("preparing to transfer to gallery"))
                    self.saveToCameraRoll(URL: outputMovieURL as NSURL)
                    do{
                        try FileManager.default.removeItem(at: video1URL)
                        try FileManager.default.removeItem(at: video2URL!)
                        try FileManager.default.removeItem(at: video3URL)
                    }catch{
                        print(error)
                    }
                }
            }
        })
    }
}
