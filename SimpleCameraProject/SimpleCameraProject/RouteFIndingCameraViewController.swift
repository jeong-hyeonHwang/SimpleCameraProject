//
//  RouteFIndingCameraViewController.swift
//  SimpleCameraProject
//
//  Created by 황정현 on 2022/11/26.
//

import UIKit
import SnapKit
import PhotosUI
import AVFoundation

class RouteFindingCameraViewController: UIViewController {
    
    private lazy var cameraView: UIView = {
        let view = UIView()
        
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
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setUpLayout()
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
     
}
