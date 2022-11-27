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
import PhotosUI

enum CameraAuthorizeStatus {
    case success
    case notAuthorized
    case configurationFailed
}

class RouteFindingCameraViewController: UIViewController {

    private var currentLocalIdentifier: String?
    
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
    
    private lazy var photosButton: UIButton = {
        let button = UIButton()
        button.backgroundColor = .white
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.gray.cgColor
        button.layer.cornerRadius = 10
        button.clipsToBounds = true
        
        button.addTarget(self, action: #selector(showPhotoPicker), for: .touchUpInside)
        return button
    }()
    
    private let captureSession = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "session queue")
    private var photoOutput: AVCapturePhotoOutput!
    private var cameraAuthorizeStatus = CameraAuthorizeStatus.success
    private var photoImage: UIImage?
    private var photoData: Data?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setUpLayout()
        setUpButton()
        setPhotosButtonImage()
        
        cameraView.videoPreviewLayer.session = captureSession
        cameraView.videoPreviewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            self.setupCaptureSession()
            break
        case .notDetermined:
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
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        photoImage = nil
        photoData = nil
        
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
        if self.cameraAuthorizeStatus == .success {
            self.captureSession.stopRunning()
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
    
    private func setUpLayout() {
        
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
        
        view.addSubview(photosButton)
        photosButton.snp.makeConstraints({
            $0.leading.equalTo(safeArea.snp.leading).inset(16)
            $0.centerY.equalTo(shutterButton.snp.centerY)
            $0.width.height.equalTo(shutterButtonSize)
        })
        
    }
    
    private func setUpButton() {
        shutterButton.addTarget(self, action: #selector(capturePhoto), for: .touchUpInside)
    }
    
    func fetchLastPhoto(fetchResult: PHFetchResult<PHAsset>) -> UIImage? {
        
        var resultImage: UIImage = UIImage()
        
        let requestOptions = PHImageRequestOptions()
        requestOptions.isSynchronous = true
        
        PHImageManager.default().requestImage(for: fetchResult.object(at: 0) as PHAsset, targetSize: view.frame.size, contentMode: PHImageContentMode.default, options: requestOptions, resultHandler: { (image, _) in
            if let image = image {
                let width = image.size.width
                let height = image.size.height
                let croppedImage = image.cropped(rect: CGRect(x: 0, y: (height - width)/2, width: width, height: width))
                resultImage = croppedImage ?? UIImage()
                
            }
        })
        
        return resultImage
    }
    
    func setPhotosButtonImage() {
        
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key:"creationDate", ascending: false)]
        fetchOptions.fetchLimit = 1
        
        let fetchResult: PHFetchResult = PHAsset.fetchAssets(with: PHAssetMediaType.image, options: fetchOptions)
        
        if fetchResult.count > 0 {
            let image = fetchLastPhoto(fetchResult: fetchResult)
            photosButton.setImage(image, for: .normal)
        }
        
    }
    
    func getAssetThumbnail(asset: PHAsset) -> UIImage {
        let manager = PHImageManager.default()
        let option = PHImageRequestOptions()
        var image = UIImage()
        option.deliveryMode = .highQualityFormat
        option.isSynchronous = true
        manager.requestImage(for: asset, targetSize: CGSize(width: 1000, height: 1000), contentMode: .aspectFit, options: option, resultHandler: {(result, info)->Void in
            image = result!
        })
        
        let rect = scale16_9ImageRect(image:image)
        guard let croppedImage = image.cropped(rect: rect) else { return UIImage()}
        return croppedImage
    }
    
    func scale16_9ImageRect(image: UIImage) -> CGRect  {
        let height = image.size.height
        let imageWidth = image.size.width

        let resizedWidth = height * 9 / 16
        let originXCoordinate = (imageWidth - resizedWidth)/2
        let rect = CGRect(x: originXCoordinate, y: 0, width: resizedWidth, height: height)
        
        return rect

    }
    private func setupCaptureSession() {
        sessionQueue.async { [self] in
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
    
    @objc private func capturePhoto() {
        let settings = AVCapturePhotoSettings()
        sessionQueue.async {
            self.photoOutput?.capturePhoto(with: settings, delegate: self)
        }
    }
    
    @objc func showPhotoPicker() {
        let photoLibrary = PHPhotoLibrary.shared()
        var config = PHPickerConfiguration(photoLibrary: photoLibrary)
        config.filter = .images
        config.preferredAssetRepresentationMode = .current
        config.selectionLimit = 1
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        present(picker, animated: true, completion: nil)
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
            
            let orientationFixedImage = UIImage(data: data)?.fixOrientation() ?? UIImage()
            let rect = scale16_9ImageRect(image: orientationFixedImage)
            
            photoImage = orientationFixedImage.cropped(rect: rect)
            photoData = photoImage?.pngData()
        }
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishCaptureFor resolvedSettings: AVCaptureResolvedPhotoSettings, error: Error?) {
        
        if let error = error {
            print("Error capturing photo: \(error)")
            return
        }
        
        let nextVC = ImageViewController()
        nextVC.setImageView(image: photoImage)
        
        navigationController?.pushViewController(nextVC, animated: true)
        //        PHPhotoLibrary.requestAuthorization({ status in
        //            if status == .authorized {
        //                PHPhotoLibrary.shared().performChanges({
        //                    let options = PHAssetResourceCreationOptions()
        //                    let creationRequest = PHAssetCreationRequest.forAsset()
        //                    creationRequest.addResource(with: .photo, data: photoData as Data, options: options)
        //                }, completionHandler: { _, error in
        //                    if let error = error {
        //                        print("Error occurred while saving photo to photo library: \(error)")
        //                    }
        //                }
        //                )
        //            }
        //        })
    }
    
}

extension RouteFindingCameraViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        
        guard let provider = results.first?.itemProvider else {return}
        
        let identifiers = results.compactMap(\.assetIdentifier)
        let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: identifiers, options: nil)
        currentLocalIdentifier = fetchResult[0].localIdentifier

        provider.loadFileRepresentation(forTypeIdentifier: "public.image") { url, error in
            guard error == nil else {
                print(error as Any)
                return
            }
        }
        
        dismiss(animated: true)
        
        let nextVC = ImageViewController()
        nextVC.setImageView(image: getAssetThumbnail(asset:fetchResult[0]))
        navigationController?.pushViewController(nextVC, animated: true)
        
    }
}

