//
//  RecordUIViewController.swift
//  ReplayKitSandbox
//
//  Created by Sonam on 12/14/17.
//  Copyright © 2017 ustwo. All rights reserved.
//

import UIKit

@objc class RecordViewController: UIViewController {
    
    private let startRecordBtn = UIButton(type: UIButtonType.roundedRect)
    private let progressView = UIView(frame: CGRect.zero)
    private var progressWidthConstraint: NSLayoutConstraint?
    
    public var recordDuration: CGFloat = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
    }
    
    private func setupView() {
        
        //*** Start button
        startRecordBtn.backgroundColor = .purple
        startRecordBtn.addTarget(self, action: #selector(didTapStartRecording), for: .touchUpInside)
        view.addSubview(startRecordBtn)
        setupStartBtnConstraints()
        
        //*** Progress tracker
        if recordTimeHasBeenSet() {
            view.addSubview(progressView)
            setupProgressViewConstraints()
        }
    }
    
    override func viewDidLayoutSubviews() {
        
        super.viewDidLayoutSubviews()
        startRecordBtn.layer.masksToBounds = true
        startRecordBtn.layer.cornerRadius = startRecordBtn.frame.width/2
    }
    
    public func relayoutInterface() {
        
        startRecordBtn.isHidden = false
        if recordTimeHasBeenSet() {
            progressWidthConstraint?.constant = 0
            progressView.isHidden = false
        }
    }
    
    @objc func didTapStartRecording() {
        
        ReplayKitNative.shared.startScreenCaptureAndSaveToFile()
        self.beginRecordProgress()
    }
    
    private func beginRecordProgress() {
        
        startRecordBtn.isHidden = true
        
     if recordTimeHasBeenSet() {
            progressView.backgroundColor = UIColor(red: 219/255, green: 48/255, blue: 103/155, alpha: 1.0)
            
            UIView.animate(withDuration: 15.0, delay: 0.0, options: .curveLinear, animations: {
                
                guard let safeWidthConstraint = self.progressWidthConstraint else { return }
                safeWidthConstraint.constant = self.view.frame.width
                self.view.layoutIfNeeded()
                
            }) { (completed) in
                
                ReplayKitNative.shared.stopScreenCapture()
                self.progressView.isHidden = true
            }
        }
    }
    
    
    //MARK: - Autolayout
    
    private func setupStartBtnConstraints() {
        
        startRecordBtn.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint(item: startRecordBtn, attribute: .centerX, relatedBy: .equal, toItem: view, attribute: .centerX, multiplier: 1.0, constant: 0).isActive = true
        
        NSLayoutConstraint(item: startRecordBtn, attribute: .bottom, relatedBy: .equal, toItem: view, attribute: .bottom, multiplier: 1.0, constant: -30).isActive = true
        
        NSLayoutConstraint(item: startRecordBtn, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: 80.0).isActive = true
        
        NSLayoutConstraint(item: startRecordBtn, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: 80.0).isActive = true
        
    }
    
    private func setupProgressViewConstraints() {
        
        progressView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint(item: progressView, attribute: .left, relatedBy: .equal, toItem: view, attribute: .left, multiplier: 1.0, constant: 0).isActive = true
        
        NSLayoutConstraint(item: progressView, attribute: NSLayoutAttribute.bottom, relatedBy: .equal, toItem: view, attribute: .bottom, multiplier: 1.0, constant: 0).isActive = true
        
        NSLayoutConstraint(item: progressView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: 40.0).isActive = true
        
        
        progressWidthConstraint = NSLayoutConstraint(item: progressView, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: 0)
        
        progressWidthConstraint?.isActive = true
        
    }
    
    //MARK: - Helpers
    
    // An optional type was not used here to allow for the property to be exposed to objective-c
    func recordTimeHasBeenSet() -> Bool {
        return recordDuration > 0.0
    }
}
