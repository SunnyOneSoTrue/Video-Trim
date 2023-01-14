//
//  CameraRollManager.swift
//  Video Trim Tool
//
//  Created by Alexandre Kakhiani on 14.01.23.
//  Copyright © 2023 Faisal. All rights reserved.
//

import Foundation


class CameraRollManager {
    
    ///Saves Video to Photos Library
    func saveToCameraRoll(URL: NSURL!) {
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: URL as URL)
        }) { saved, error in
            if saved {
                DispatchQueue.main.async {
                    let alertController = UIAlertController(title: "video was successfully saved to Camera roll", message: nil, preferredStyle: .alert)
                    let defaultAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                    alertController.addAction(defaultAction)
                    self.present(alertController, animated: true, completion: nil)
                }
            }}}
    
}
