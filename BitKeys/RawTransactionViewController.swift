//
//  RawTransactionViewController.swift
//  BitKeys
//
//  Created by Peter on 7/1/18.
//  Copyright © 2018 Fontaine. All rights reserved.
//

import UIKit
import AVFoundation

class RawTransactionViewController: UIViewController, UITextViewDelegate, AVCaptureMetadataOutputObjectsDelegate {
    
    var scanView = UIView()
    var pushRawTransactionButton = UIButton()
    var decodeRawTransactionButton = UIButton()
    var scanQRCodeButton = UIButton()
    var rawTransactionView = UITextView()
    var backButton = UIButton()
    var imageView = UIView()
    var testnetMode = Bool()
    var mainnetMode = Bool()
    var rawTransaction = String()
    var transactionID = String()
    let avCaptureSession = AVCaptureSession()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        mainnetMode = checkSettingsForKey(keyValue: "mainnetMode")
        testnetMode = checkSettingsForKey(keyValue: "testnetMode")
        
        rawTransactionView.delegate = self

        backButton = UIButton(frame: CGRect(x: 5, y: 20, width: 55, height: 55))
        backButton.showsTouchWhenHighlighted = true
        backButton.setImage(#imageLiteral(resourceName: "back2.png"), for: .normal)
        backButton.addTarget(self, action: #selector(self.dismissRawView), for: .touchUpInside)
        
        rawTransactionView.frame = CGRect(x: (view.frame.width / 2) - ((view.frame.width - 10) / 2), y: view.frame.minY + 100, width: view.frame.width - 10, height: 325)
        rawTransactionView.textAlignment = .left
        rawTransactionView.backgroundColor = UIColor.groupTableViewBackground
        rawTransactionView.keyboardDismissMode = .interactive
        rawTransactionView.isEditable = true
        rawTransactionView.font = UIFont.systemFont(ofSize: 22, weight: .regular)
        rawTransactionView.returnKeyType = UIReturnKeyType.done
        
        
        pushRawTransactionButton = UIButton(frame: CGRect(x: view.center.x - 150, y: self.rawTransactionView.frame.maxY + 10, width: 300, height: 55))
        pushRawTransactionButton.showsTouchWhenHighlighted = true
        pushRawTransactionButton.titleLabel?.textAlignment = .center
        pushRawTransactionButton.layer.cornerRadius = 10
        pushRawTransactionButton.backgroundColor = UIColor.black
        addShadow(view:self.pushRawTransactionButton)
        pushRawTransactionButton.setTitle("Push", for: .normal)
        pushRawTransactionButton.addTarget(self, action: #selector(self.pushRawTransaction), for: .touchUpInside)
        
        
        decodeRawTransactionButton = UIButton(frame: CGRect(x: view.center.x - 150, y: self.pushRawTransactionButton.frame.maxY + 10, width: 300, height: 55))
        decodeRawTransactionButton.showsTouchWhenHighlighted = true
        decodeRawTransactionButton.titleLabel?.textAlignment = .center
        decodeRawTransactionButton.layer.cornerRadius = 10
        decodeRawTransactionButton.backgroundColor = UIColor.black
        addShadow(view:self.decodeRawTransactionButton)
        decodeRawTransactionButton.setTitle("Decode", for: .normal)
        decodeRawTransactionButton.addTarget(self, action: #selector(self.decodeRawTransaction), for: .touchUpInside)
        
        scanQRCodeButton.removeFromSuperview()
        scanQRCodeButton = UIButton(frame: CGRect(x: self.view.frame.maxX - 60, y: 20, width: 50, height: 50))
        scanQRCodeButton.showsTouchWhenHighlighted = true
        scanQRCodeButton.titleLabel?.textAlignment = .center
        scanQRCodeButton.layer.cornerRadius = 10
        scanQRCodeButton.setImage(#imageLiteral(resourceName: "qr.png"), for: .normal)
        scanQRCodeButton.addTarget(self, action: #selector(self.scanRawTransaction), for: .touchUpInside)
        view.addSubview(self.scanQRCodeButton)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.dismissKeyboard (_:)))
        
        view.addGestureRecognizer(tapGesture)
        view.addSubview(backButton)
        view.addSubview(rawTransactionView)
        view.addSubview(pushRawTransactionButton)
        view.addSubview(decodeRawTransactionButton)
    }

    @objc func dismissKeyboard (_ sender: UITapGestureRecognizer) {
        rawTransactionView.resignFirstResponder()
    }
    
    @objc func dismissRawView() {
    
        self.dismiss(animated: true, completion: nil)
        
    }
    
    @objc func dismissScanView() {
        
        avCaptureSession.stopRunning()
        imageView.removeFromSuperview()
        scanView.removeFromSuperview()
    }
    
    @objc func scanRawTransaction() {
        
        rawTransactionView.text = ""
        scanView.frame = view.frame
        scanView.backgroundColor = UIColor.white
        
        self.backButton = UIButton(frame: CGRect(x: 5, y: 20, width: 55, height: 55))
        self.backButton.showsTouchWhenHighlighted = true
        self.backButton.setImage(#imageLiteral(resourceName: "back2.png"), for: .normal)
        self.backButton.addTarget(self, action: #selector(self.dismissScanView), for: .touchUpInside)
        
        self.rawTransactionView.resignFirstResponder()
        
        self.imageView.frame = CGRect(x: self.view.center.x - ((self.view.frame.width - 50)/2), y: 150, width: self.view.frame.width - 50, height: self.view.frame.width - 50)
        addShadow(view: self.imageView)
        
        DispatchQueue.main.async {
            self.view.addSubview(self.scanView)
            self.scanView.addSubview(self.imageView)
            self.scanView.addSubview(self.backButton)
        }
        
        func scanQRCode() {
            
            do {
                
                try scanQRNow()
                print("scanQRNow")
                
            } catch {
                
                print("Failed to scan QR Code")
            }
            
        }
        
        scanQRCode()
        
    }
    
    enum error: Error {
        
        case noCameraAvailable
        case videoInputInitFail
        
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if (text as NSString).rangeOfCharacter(from: CharacterSet.newlines).location == NSNotFound {
            return true
        }
        self.rawTransactionView.resignFirstResponder()
        return false
    }
    
    func scanQRNow() throws {
        
        guard let avCaptureDevice = AVCaptureDevice.default(for: AVMediaType.video) else {
            
            print("no camera")
            throw error.noCameraAvailable
            
        }
        
        guard let avCaptureInput = try? AVCaptureDeviceInput(device: avCaptureDevice) else {
            
            print("failed to int camera")
            throw error.videoInputInitFail
        }
        
        let avCaptureMetadataOutput = AVCaptureMetadataOutput()
        avCaptureMetadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
        
        if let inputs = self.avCaptureSession.inputs as? [AVCaptureDeviceInput] {
            for input in inputs {
                self.avCaptureSession.removeInput(input)
            }
        }
        
        if let outputs = self.avCaptureSession.outputs as? [AVCaptureMetadataOutput] {
            for output in outputs {
                self.avCaptureSession.removeOutput(output)
            }
        }
        
        self.avCaptureSession.addInput(avCaptureInput)
        self.avCaptureSession.addOutput(avCaptureMetadataOutput)
        avCaptureMetadataOutput.metadataObjectTypes = [AVMetadataObject.ObjectType.qr]
        let avCaptureVideoPreviewLayer = AVCaptureVideoPreviewLayer(session: avCaptureSession)
        avCaptureVideoPreviewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        avCaptureVideoPreviewLayer.frame = self.imageView.bounds
        self.imageView.layer.addSublayer(avCaptureVideoPreviewLayer)
        self.avCaptureSession.startRunning()
        
    }
    
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        if metadataObjects.count > 0 {
            print("metadataOutput")
            
            let machineReadableCode = metadataObjects[0] as! AVMetadataMachineReadableCodeObject
            
            if machineReadableCode.type == AVMetadataObject.ObjectType.qr {
                
                self.rawTransactionView.text = machineReadableCode.stringValue!
                self.avCaptureSession.stopRunning()
                self.dismissScanView()
            }
        }
    }
    
    @objc func decodeRawTransaction() {
        
        print("decodeRawTransaction")
        
        self.rawTransaction = self.rawTransactionView.text
        
        if self.rawTransaction != "" {
            
            self.addSpinner()
            
            var url:URL!
            
            if testnetMode {
                
                url = URL(string: "https://api.blockcypher.com/v1/btc/test3/txs/decode?token=a9d88ea606fb4a92b5134d34bc1cb2a0")
                
            } else {
                
                url = URL(string: "https://api.blockcypher.com/v1/btc/main/txs/decode?token=a9d88ea606fb4a92b5134d34bc1cb2a0")
                
            }
            
            var request = URLRequest(url: url)
            request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
            request.httpMethod = "POST"
            request.httpBody = "{\"tx\":\"\(self.rawTransactionView.text!)\"}".data(using: .utf8)
            
            let task = URLSession.shared.dataTask(with: request) { (data, response, error) -> Void in
                
                do {
                    
                    if error != nil {
                        
                        self.removeSpinner()
                        
                        DispatchQueue.main.async {
                            
                            displayAlert(viewController: self, title: "Error", message: "\(String(describing: error))")
                            
                        }
                        
                    } else {
                        
                        if let urlContent = data {
                            
                            do {
                                
                                let jsonAddressResult = try JSONSerialization.jsonObject(with: urlContent, options: JSONSerialization.ReadingOptions.mutableLeaves) as! NSDictionary
                                
                                self.removeSpinner()
                                
                                if let error = jsonAddressResult["errors"] as? NSArray {
                                    
                                    self.removeSpinner()
                                    
                                    DispatchQueue.main.async {
                                        
                                        var errors = [String]()
                                        
                                        for e in error {
                                            
                                            if let errordescription = (e as? NSDictionary)?["error"] as? String {
                                                
                                                errors.append(errordescription)
                                                
                                            }
                                            
                                        }
                                        
                                        displayAlert(viewController: self, title: "Error", message: "\(errors)")
                                        
                                    }
                                    
                                } else if let error = jsonAddressResult["error"] as? String {
                                    
                                    DispatchQueue.main.async {
                                        
                                        displayAlert(viewController: self, title: "Error", message: "\(error)")
                                        
                                    }
                                    
                                } else {
                                    
                                    displayAlert(viewController: self, title: "Decoded Transaction", message: "\(jsonAddressResult)")
                                    
                                }
                                
                            } catch {
                                
                                print("JSon processing failed")
                                self.removeSpinner()
                            }
                        }
                    }
                }
            }
            
            task.resume()
            
        } else {
            
            DispatchQueue.main.async {
                
                displayAlert(viewController: self, title: "Error", message: "You need to paste or type a raw transaction into the text field.")
                
            }
            
        }
        
    }
    
    @objc func pushRawTransaction() {
        
        self.rawTransaction = self.rawTransactionView.text
        
        if self.rawTransaction != "" {
            
            self.addSpinner()
            var url:URL!
            
            if testnetMode {
                
                url = URL(string: "https://api.blockcypher.com/v1/btc/test3/txs/push?token=a9d88ea606fb4a92b5134d34bc1cb2a0")
                
            } else if mainnetMode {
                
                url = URL(string: "https://api.blockcypher.com/v1/btc/main/txs/push?token=a9d88ea606fb4a92b5134d34bc1cb2a0")
                
            }
            
            var request = URLRequest(url: url)
            request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
            request.httpMethod = "POST"
            request.httpBody = "{\"tx\":\"\(self.rawTransactionView.text!)\"}".data(using: .utf8)
            
            let task = URLSession.shared.dataTask(with: request) { (data, response, error) -> Void in
                
                do {
                    
                    if error != nil {
                        
                        self.removeSpinner()
                        
                        DispatchQueue.main.async {
                            
                            displayAlert(viewController: self, title: "Error", message: "\(String(describing: error))")
                            
                        }
                        
                    } else {
                        
                        if let urlContent = data {
                            
                            do {
                                
                                let jsonAddressResult = try JSONSerialization.jsonObject(with: urlContent, options: JSONSerialization.ReadingOptions.mutableLeaves) as! NSDictionary
                                
                                self.removeSpinner()
                                
                                if let error = jsonAddressResult["errors"] as? NSArray {
                                    
                                    self.removeSpinner()
                                    
                                    DispatchQueue.main.async {
                                        
                                        var errors = [String]()
                                        
                                        for e in error {
                                            
                                            if let errordescription = (e as? NSDictionary)?["error"] as? String {
                                                
                                                errors.append(errordescription)
                                            }
                                            
                                        }
                                        
                                        displayAlert(viewController: self, title: "Error", message: "\(errors)")
                                        
                                    }
                                    
                                } else if let error = jsonAddressResult["error"] as? String {
                                    
                                    DispatchQueue.main.async {
                                        
                                        displayAlert(viewController: self, title: "Error", message: "\(error)")
                                        
                                    }
                                    
                                } else {
                                    
                                    if let txCheck = jsonAddressResult["tx"] as? NSDictionary {
                                        
                                        if let hashCheck = txCheck["hash"] as? String {
                                            
                                            self.transactionID = hashCheck
                                            
                                            DispatchQueue.main.async {
                                                
                                                self.removeSpinner()
                                                
                                                let alert = UIAlertController(title: NSLocalizedString("Transaction Sent", comment: ""), message: "Transaction ID: \(hashCheck)", preferredStyle: UIAlertControllerStyle.actionSheet)
                                                
                                                alert.addAction(UIAlertAction(title: NSLocalizedString("Copy to Clipboard", comment: ""), style: .default, handler: { (action) in
                                                    
                                                    UIPasteboard.general.string = hashCheck
                                                    
                                                    self.dismiss(animated: true, completion: nil)
                                                    
                                                }))
                                                
                                                alert.addAction(UIAlertAction(title: NSLocalizedString("Done", comment: ""), style: .cancel, handler: { (action) in
                                                    
                                                    self.dismiss(animated: true, completion: nil)
                                                    
                                                }))
                                                
                                                alert.popoverPresentationController?.sourceView = self.view // works for both iPhone & iPad
                                                
                                                self.present(alert, animated: true) {
                                                    print("option menu presented")
                                                }
                                                
                                            }
                                        }
                                    }
                                    
                                }
                                
                            } catch {
                                
                                print("JSon processing failed")
                                self.removeSpinner()
                            }
                        }
                        
                    }
                }
            }
            task.resume()
            
        } else {
            
            DispatchQueue.main.async {
                
                displayAlert(viewController: self, title: "Error", message: "You need to paste or type a raw transaction into the text field.")
                
            }
            
        }
    }
    
    func addSpinner() {
        print("addSpinner")
        
        DispatchQueue.main.async {
            if self.imageView != nil {
                self.imageView.removeFromSuperview()
            }
            let bitcoinImage = UIImage(named: "Bitsense image.png")
            self.imageView = UIImageView(image: bitcoinImage!)
            self.imageView.center = self.view.center
            self.imageView.frame = CGRect(x: self.view.center.x - 25, y: 20, width: 50, height: 50)
            rotateAnimation(imageView: self.imageView as! UIImageView)
            self.view.addSubview(self.imageView)
        }
        
    }
    
    func removeSpinner() {
        print("removeSpinner")
        
        DispatchQueue.main.async {
            
            if self.imageView != nil {
                
                self.imageView.removeFromSuperview()
                
            }
            
        }
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask { return UIInterfaceOrientationMask.portrait }

}
