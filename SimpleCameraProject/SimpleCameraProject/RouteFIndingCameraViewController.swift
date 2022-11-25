//
//  RouteFIndingCameraViewController.swift
//  SimpleCameraProject
//
//  Created by 황정현 on 2022/11/26.
//

import UIKit
import SnapKit
import AVFoundation

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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setUpLayout()
        cameraView.videoPreviewLayer.session = captureSession
        cameraView.videoPreviewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        cameraAuthorizationCheck()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        sessionQueue.async {
            self.captureSession.startRunning()
        }
    }
    
    func cameraAuthorizationCheck() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized: // The user has previously granted access to the camera.
            print("YES")
            self.setupCaptureSession()
            
        case .notDetermined: // The user has not yet been asked for camera access.
            sessionQueue.suspend()
            AVCaptureDevice.requestAccess(for: .video) { granted in
                if granted {
                    self.setupCaptureSession()
                }
            }
            
        case .denied:
            return
            
        case .restricted: // The user can't grant access due to restrictions.
            return
        @unknown default:
            return
        }
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
            
            let photoOutput = AVCapturePhotoOutput()
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
}
