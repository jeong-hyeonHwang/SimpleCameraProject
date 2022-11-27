//
//  RouteFIndingCameraViewController.swift
//  SimpleCameraProject
//
//  Created by 황정현 on 2022/11/26.
//

import UIKit
import SnapKit
import AVFoundation
import Photos

enum CameraAuthorizeStatus {
    case success
    case notAuthorized
    case configurationFailed
}

class RouteFindingCameraViewController: UIViewController {
    
    private lazy var cameraView: CameraView = {
        let view = CameraView()
        
        return view
    }()
    
    private lazy var shutterButton: UIButton = {
        let button = UIButton()
        button.backgroundColor = .clear
        button.layer.borderColor = UIColor.white.cgColor
        button.layer.borderWidth = 4
        button.layer.cornerRadius = 37.5
        
        return button
    }()
    
    private let captureSession = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "session queue")
    private var photoOutput: AVCapturePhotoOutput!
    private var cameraAuthorizeStatus = CameraAuthorizeStatus.success
    private var photoData: Data?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setUpLayout()
        setUpButton()
        
        cameraView.videoPreviewLayer.session = captureSession
        cameraView.videoPreviewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized: // The user has previously granted access to the camera.
            self.setupCaptureSession()
            
        case .notDetermined: // The user has not yet been asked for camera access.
            sessionQueue.suspend()
            AVCaptureDevice.requestAccess(for: .video, completionHandler: { granted in
                if !granted {
                    self.cameraAuthorizeStatus = .notAuthorized
                }
                self.sessionQueue.resume()
            })
        default:
            cameraAuthorizeStatus = .notAuthorized
        }
        
        sessionQueue.async {
            self.setupCaptureSession()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        sessionQueue.async {
            switch self.cameraAuthorizeStatus {
            case .success:
                self.captureSession.startRunning()
                
            case .notAuthorized:
                DispatchQueue.main.async {
                    let changePrivacySetting = "App doesn't have permission to use the camera, please change privacy settings"
                    let message = NSLocalizedString(changePrivacySetting, comment: "Alert message when the user has denied access to the camera")
                    let alertController = UIAlertController(title: "App", message: message, preferredStyle: .alert)
                    
                    alertController.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Alert OK button"),
                                                            style: .cancel,
                                                            handler: nil))
                    
                    alertController.addAction(UIAlertAction(title: NSLocalizedString("Settings", comment: "Alert button to open Settings"),
                                                            style: .`default`,
                                                            handler: { _ in
                        UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!,
                                                  options: [:],
                                                  completionHandler: nil)
                    }))
                    
                    self.present(alertController, animated: true, completion: nil)
                }
                
            case .configurationFailed:
                break
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sessionQueue.async {
            if self.cameraAuthorizeStatus == .success {
                self.captureSession.stopRunning()
            }
        }
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
    
    func setUpLayout() {
        
        let shutterButtonSize: CGFloat = 75
        let safeArea = view.safeAreaLayoutGuide
        let height: CGFloat = UIScreen.main.bounds.width * 16/9
        
        view.addSubview(cameraView)
        cameraView.snp.makeConstraints({
            $0.top.equalTo(view.snp.top)
            $0.leading.equalTo(view.snp.leading)
            $0.trailing.equalTo(view.snp.trailing)
            $0.height.equalTo(height)
        })
        
        view.addSubview(shutterButton)
        shutterButton.snp.makeConstraints({
            $0.bottom.equalTo(safeArea.snp.bottom).inset(16)
            $0.centerX.equalTo(safeArea.snp.centerX)
            $0.width.height.equalTo(shutterButtonSize)
        })
        
        let circleLayer = CAShapeLayer()
        let circleSize: CGFloat = 57
        let circleShape = UIBezierPath(ovalIn: CGRect(x: (shutterButtonSize - circleSize)/2, y: (shutterButtonSize - circleSize)/2, width: circleSize, height: circleSize))
        circleLayer.path = circleShape.cgPath
        circleLayer.fillColor = UIColor.white.cgColor
        shutterButton.layer.addSublayer(circleLayer)
        
    }
    
    func setUpButton() {
        shutterButton.addTarget(self, action: #selector(capturePhoto), for: .touchUpInside)
    }
    
    func setupCaptureSession() {
        sessionQueue.async { [self] in
            
            // Input Setting
            captureSession.beginConfiguration()
            let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera,
                                                      for: .video, position: .unspecified)
            guard
                let videoDeviceInput = try? AVCaptureDeviceInput(device: videoDevice!),
                captureSession.canAddInput(videoDeviceInput)
            else { return }
            captureSession.addInput(videoDeviceInput)
            
            photoOutput = AVCapturePhotoOutput()
            guard captureSession.canAddOutput(photoOutput) else { return }
            captureSession.sessionPreset = .photo
            captureSession.addOutput(photoOutput)
            
            DispatchQueue.main.async {
                
                var initialVideoOrientation: AVCaptureVideoOrientation = .portrait
                if let videoOrientation = AVCaptureVideoOrientation(rawValue: UIInterfaceOrientation.portrait.rawValue) {
                    initialVideoOrientation = videoOrientation
                }
                
                self.cameraView.videoPreviewLayer.connection?.videoOrientation = initialVideoOrientation
            }
            
            captureSession.commitConfiguration()
        }
    }
    
    @objc func capturePhoto() {
        let settings = AVCapturePhotoSettings()
        sessionQueue.async {
            self.photoOutput?.capturePhoto(with: settings, delegate: self)
        }
    }
}

extension RouteFindingCameraViewController: AVCapturePhotoCaptureDelegate {
    
    func photoOutput(_ output: AVCapturePhotoOutput, willCapturePhotoFor resolvedSettings: AVCaptureResolvedPhotoSettings) {
        AudioServicesDisposeSystemSoundID(1108)
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didCapturePhotoFor resolvedSettings: AVCaptureResolvedPhotoSettings) {
        AudioServicesDisposeSystemSoundID(1108)
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error = error {
            print("Error capturing photo: \(error)")
            return
        } else {
            guard let data = photo.fileDataRepresentation() else { return }
            
            guard let image = UIImage(data: data) else { return }
            let orientationFixedImage = image.fixOrientation()
            
            let height = orientationFixedImage.size.height
            let imageWidth = orientationFixedImage.size.width
            
            let resizedWidth = height * 9 / 16
            let originXCoordinate = (imageWidth - resizedWidth)/2
            let rect = CGRect(x: originXCoordinate, y: 0, width: resizedWidth, height: height)
            
            guard let resizedImage = orientationFixedImage.cropped(rect: rect) else { return }
            photoData = resizedImage.pngData()
        }
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishCaptureFor resolvedSettings: AVCaptureResolvedPhotoSettings, error: Error?) {
        
        print("Captured!")
        
        if let error = error {
            print("Error capturing photo: \(error)")
            return
        }
        
        guard let photoData = photoData else {
            print("No photo data resource")
            return
        }
        
        PHPhotoLibrary.requestAuthorization({ status in
            if status == .authorized {
                PHPhotoLibrary.shared().performChanges({
                    let options = PHAssetResourceCreationOptions()
                    let creationRequest = PHAssetCreationRequest.forAsset()
                    creationRequest.addResource(with: .photo, data: photoData as Data, options: options)
                }, completionHandler: { _, error in
                    if let error = error {
                        print("Error occurred while saving photo to photo library: \(error)")
                    }
                }
                )
            } else {
                print("no...")
            }
        })
    }
    
}

extension UIImage {
    // https://stackoverflow.com/questions/158914/cropping-an-uiimage
    func cropped(rect: CGRect) -> UIImage? {
        if let image = self.cgImage!.cropping(to: rect) {
            return UIImage(cgImage: image)
        } else if let image = (self.ciImage)?.cropped(to: rect) {
            return UIImage(ciImage: image)
        }
        return nil
    }
    
    // https://github.com/Juhwa-Lee1023/SolDoKu/blob/main/Sudoku/Extensions/UIImage%2B.swift
    func fixOrientation() -> UIImage {
        
        // 이미지의 방향이 올바를 경우 수정하지 않는다.
        if self.imageOrientation == UIImage.Orientation.up {
            return self
        }
        
        // 이미지를 변환시키기 위한 함수 선언
        var transform: CGAffineTransform = CGAffineTransform.identity
        
        // 이미지의 상태에 맞게 이미지를 돌린다.
        if ( self.imageOrientation == UIImage.Orientation.down || self.imageOrientation == UIImage.Orientation.downMirrored ) {
            transform = transform.translatedBy(x: self.size.width, y: self.size.height)
            transform = transform.rotated(by: CGFloat(Double.pi))
        } else if ( self.imageOrientation == UIImage.Orientation.left || self.imageOrientation == UIImage.Orientation.leftMirrored ) {
            transform = transform.translatedBy(x: self.size.width, y: 0)
            transform = transform.rotated(by: CGFloat(Double.pi / 2.0))
        } else if ( self.imageOrientation == UIImage.Orientation.right || self.imageOrientation == UIImage.Orientation.rightMirrored ) {
            transform = transform.translatedBy(x: 0, y: self.size.height)
            transform = transform.rotated(by: CGFloat(-Double.pi / 2.0))
        }
        
        if ( self.imageOrientation == UIImage.Orientation.upMirrored || self.imageOrientation == UIImage.Orientation.downMirrored ) {
            transform = transform.translatedBy(x: self.size.width, y: 0)
            transform = transform.scaledBy(x: -1, y: 1)
        } else if ( self.imageOrientation == UIImage.Orientation.leftMirrored || self.imageOrientation == UIImage.Orientation.rightMirrored ) {
            transform = transform.translatedBy(x: self.size.height, y: 0)
            transform = transform.scaledBy(x: -1, y: 1)
        }
        
        // 이미지 변환용 값 선언
        let cgValue: CGContext = CGContext(data: nil, width: Int(self.size.width), height: Int(self.size.height),
                                           bitsPerComponent: self.cgImage!.bitsPerComponent, bytesPerRow: 0,
                                           space: self.cgImage!.colorSpace!,
                                           bitmapInfo: self.cgImage!.bitmapInfo.rawValue)!
        
        cgValue.concatenate(transform)
        
        if ( self.imageOrientation == UIImage.Orientation.left ||
             self.imageOrientation == UIImage.Orientation.leftMirrored ||
             self.imageOrientation == UIImage.Orientation.right ||
             self.imageOrientation == UIImage.Orientation.rightMirrored ) {
            cgValue.draw(self.cgImage!, in: CGRect(x: 0, y: 0, width: self.size.height, height: self.size.width))
        } else {
            cgValue.draw(self.cgImage!, in: CGRect(x: 0, y: 0, width: self.size.width, height: self.size.height))
        }
        
        return UIImage(cgImage: cgValue.makeImage()!)
    }
}
