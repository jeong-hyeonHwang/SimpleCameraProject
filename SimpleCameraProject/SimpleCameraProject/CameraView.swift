//
//  CameraView.swift
//  SimpleCameraProject
//
//  Created by 황정현 on 2022/11/26.
//

import UIKit
import AVFoundation

class CameraView: UIView {
    
    // 실시간으로 현재 화면에 찍히고 있는 뷰를 송출하는 역할을 하는 Layer
    var videoPreviewLayer: AVCaptureVideoPreviewLayer {
        guard let layer = layer as? AVCaptureVideoPreviewLayer else {
            fatalError("Expected `AVCaptureVideoPreviewLayer` type for layer. Check PreviewView.layerClass implementation.")
        }
        return layer
    }
    
    override class var layerClass: AnyClass {
        return AVCaptureVideoPreviewLayer.self
    }
}
