//
//  TransactionBuilderViewController.swift
//  BitKeys
//
//  Created by Peter on 2/7/18.
//  Copyright © 2018 Fontaine. All rights reserved.
//

import UIKit
import Signer
import AVFoundation
import LocalAuthentication
import CoreData
import AES256CBC
import SwiftKeychainWrapper

class TransactionBuilderViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate, UITextFieldDelegate, UITextViewDelegate {
    
    var sweepButton = UIButton()
    var optionsButton = UIButton()
    var walletToSpendFrom = [String:Any]()
    let textView = UILabel()
    var sendButton = UIButton()
    let titleLable = UILabel()
    var addressBook = [[String:Any]]()
    var testnetMode = Bool()
    var mainnetMode = Bool()
    var coldMode = Bool()
    var hotMode = Bool()
    var sweepAmount = String()
    var privateKey = String()
    var imageView:UIView!
    let avCaptureSession = AVCaptureSession()
    var bitcoinAddressQRCode = UIImage()
    var json = NSMutableDictionary()
    var transactionToBeSigned = [String]()
    var privateKeyToSign = String()
    var videoPreview = UIView()
    var addressToDisplay = UITextField()
    var amountToSend = UITextField()
    var moreOptionsButton = UIButton()
    var stringURL = String()
    var recievingAddress = String()
    var sendingFromAddress = String()
    var getReceivingAddressMode = Bool()
    var getPayerAddressMode = Bool()
    var getSignatureMode = Bool()
    var signature = String()
    var amount = ""
    var backButton = UIButton()
    var addressBookButton = UIButton()
    var currency = String()
    var amountInBTC = Double()
    var satoshiAmount = Int()
    var preference = String()
    var transactionID = ""
    var fees:UInt16! = 0
    var manuallySetFee = Bool()
    var transactionView = UITextView()
    var refreshButton = UIButton()
    var exchangeRate = Double()
    var xpubkey = String()
    var privateKeytoDebit = ""
    var high = Bool()
    var medium = Bool()
    var low = Bool()
    var BTC = Bool()
    var USD = Bool()
    var EUR = Bool()
    var SAT = Bool()
    var GBP = Bool()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
       if UserDefaults.standard.object(forKey: "firstTimeHere") != nil {
            
       } else {
            
            UserDefaults.standard.set(true, forKey: "firstTimeHere")
            
            guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
                
                return
                
            }
            
            let context = appDelegate.persistentContainer.viewContext
            let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "TransactionSettings")
            
            do {
                
                let results = try context.fetch(fetchRequest) as [NSManagedObject]
                
                if results.count > 0 {
                    
                    
                } else {
                    
                    let entity = NSEntityDescription.entity(forEntityName: "TransactionSettings", in: context)
                    let mySettings = NSManagedObject(entity: entity!, insertInto: context)
                    mySettings.setValue(true, forKey: "dollar")
                    mySettings.setValue(false, forKey: "bitcoin")
                    mySettings.setValue(false, forKey: "satoshi")
                    mySettings.setValue(false, forKey: "pounds")
                    mySettings.setValue(false, forKey: "euro")
                    mySettings.setValue(0, forKey: "customFee")
                    mySettings.setValue(false, forKey: "high")
                    mySettings.setValue(true, forKey: "low")
                    mySettings.setValue(false, forKey: "medium")
                    
                    do {
                        
                        try context.save()
                        
                    } catch {
                        
                        print("Failed saving")
                        
                    }
                    
                }
                
            } catch {
                
                print("Failed")
                
            }
            
        }
        
        addressToDisplay.delegate = self
        amountToSend.delegate = self
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.dismissKeyboard (_:)))
        self.view.addGestureRecognizer(tapGesture)
        
    }
    
    @objc func dismissKeyboard (_ sender: UITapGestureRecognizer) {
        addressToDisplay.resignFirstResponder()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        recievingAddress = ""
        getUserDefaults()
        getReceivingAddressMode = true
        getSignatureMode = false
        addBackButton()
        addAmount()
        addChooseOptionButton()
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        
        self.sendingFromAddress = ""
        self.recievingAddress = ""
        self.privateKey = ""
        self.privateKeyToSign = ""
        self.walletToSpendFrom = [:]
        self.privateKeytoDebit = ""
        
    }
    
    func getUserDefaults() {
        
        print("checkUserDefaults")
        
        addressBook = checkAddressBook()
        hotMode = checkSettingsForKey(keyValue: "hotMode")
        coldMode = checkSettingsForKey(keyValue: "coldMode")
        mainnetMode = checkSettingsForKey(keyValue: "mainnetMode")
        testnetMode = checkSettingsForKey(keyValue: "testnetMode")
        high = checkTransactionSettingsForKey(keyValue: "high") as! Bool
        medium = checkTransactionSettingsForKey(keyValue: "medium") as! Bool
        low = checkTransactionSettingsForKey(keyValue: "low") as! Bool
        BTC = checkTransactionSettingsForKey(keyValue: "bitcoin") as! Bool
        SAT = checkTransactionSettingsForKey(keyValue: "satoshi") as! Bool
        USD = checkTransactionSettingsForKey(keyValue: "dollar") as! Bool
        GBP = checkTransactionSettingsForKey(keyValue: "pounds") as! Bool
        EUR = checkTransactionSettingsForKey(keyValue: "euro") as! Bool
        fees = checkTransactionSettingsForKey(keyValue: "customFee") as! UInt16
        
        if addressBook.count == 0 {
            
            self.coldMode = true
            self.hotMode = false
            
        }
        
        if high {
            preference = "high"
        } else if low {
            preference = "low"
        } else if medium {
            preference = "medium"
        } else if fees != 0 {
            preference = ""
            self.manuallySetFee = true
        }
        
        if let networkCheck = walletToSpendFrom["network"] as? String {
            
            if networkCheck == "testnet" {
                
                self.testnetMode = true
                self.mainnetMode = false
                
            } else if networkCheck == "mainnet" {
                
                self.mainnetMode = true
                self.testnetMode = false
                
            }
        }
        
   }
    
    func addAddressBookButton() {
        print("addAddressBookButton")
        
        DispatchQueue.main.async {
            
            if self.addressBook.count > 0 {
                
                self.addressBookButton.removeFromSuperview()
                self.addressBookButton = UIButton(frame: CGRect(x: 10, y: self.view.frame.maxY - 60, width: 50, height: 50))
                self.addressBookButton.showsTouchWhenHighlighted = true
                self.addressBookButton.setImage(#imageLiteral(resourceName: "addressBook.png"), for: .normal)
                self.addressBookButton.addTarget(self, action: #selector(self.openAddressBook), for: .touchUpInside)
                self.view.addSubview(self.addressBookButton)
                
            }
            
        }
        
    }
    
    @objc func openAddressBook() {
        print("openAddressBook")
        
            DispatchQueue.main.async {
                
                if self.addressBook.count > 0 {
                    
                    var message = String()
                    
                    if self.getReceivingAddressMode {
                        
                        message = "Select the recepient wallet"
                        
                    } else {
                        
                        message = "Select the wallet to debit"
                        
                    }
                    
                    if self.getReceivingAddressMode {
                        
                        let alert = UIAlertController(title: "Which Wallet?", message: message, preferredStyle: UIAlertControllerStyle.actionSheet)
                        
                        for (index, wallet) in self.addressBook.enumerated() {
                            
                            if self.testnetMode {
                                
                                if wallet["network"] as! String == "testnet" {
                                    
                                    if wallet["address"] as! String != self.sendingFromAddress {
                                        
                                        var walletName = wallet["label"] as! String
                                        
                                        if walletName == "" {
                                            
                                            walletName = wallet["address"] as! String
                                        }
                                        
                                        alert.addAction(UIAlertAction(title: NSLocalizedString(walletName, comment: ""), style: .default, handler: { (action) in
                                            
                                            let bitcoinAddress = self.addressBook[index]["address"] as! String
                                            self.processKeys(key: bitcoinAddress)
                                            
                                        }))
                                        
                                    }
                                    
                                }
                                
                            } else if self.mainnetMode {
                                
                                if wallet["network"] as! String == "mainnet" {
                                    
                                    if wallet["address"] as! String != self.sendingFromAddress {
                                        
                                        var walletName = wallet["label"] as! String
                                        
                                        if walletName == "" {
                                            
                                            walletName = wallet["address"] as! String
                                        }
                                        
                                        alert.addAction(UIAlertAction(title: NSLocalizedString(walletName, comment: ""), style: .default, handler: { (action) in
                                            
                                            let bitcoinAddress = self.addressBook[index]["address"] as! String
                                            self.processKeys(key: bitcoinAddress)
                                            
                                        }))
                                        
                                    }
                                    
                                }
                                
                            }
                            
                        }
                        
                        alert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: { (action) in
                            
                        }))
                        
                        alert.popoverPresentationController?.sourceView = self.view
                        
                        self.present(alert, animated: true) {
                        }
                        
                    } else if self.getPayerAddressMode {
                        
                        let alert = UIAlertController(title: "Which Wallet?", message: message, preferredStyle: UIAlertControllerStyle.actionSheet)
                        
                        if self.hotMode {
                            
                            for (index, wallet) in self.addressBook.enumerated() {
                                
                                if wallet["address"] as! String != self.recievingAddress {
                                    
                                    if self.testnetMode {
                                        
                                        if wallet["network"] as! String == "testnet" {
                                            
                                            if wallet["privateKey"] as! String != "" {
                                                
                                                var walletName = wallet["label"] as! String
                                                
                                                if walletName == "" {
                                                    
                                                    walletName = wallet["address"] as! String
                                                }
                                                
                                                alert.addAction(UIAlertAction(title: NSLocalizedString(walletName, comment: ""), style: .default, handler: { (action) in
                                                    
                                                    let bitcoinAddress = self.addressBook[index]["address"] as! String
                                                    self.sendingFromAddress = bitcoinAddress
                                                    self.privateKeytoDebit = self.addressBook[index]["privateKey"] as! String
                                                    self.getSignatureMode = true
                                                    self.removeScanner()
                                                    self.makeHTTPPostRequest()
                                                    
                                                }))
                                                
                                            }
                                            
                                        }
                                        
                                    } else if self.mainnetMode {
                                        
                                        if wallet["network"] as! String == "mainnet" {
                                            
                                            if wallet["privateKey"] as! String != "" {
                                                
                                                var walletName = wallet["label"] as! String
                                                
                                                if walletName == "" {
                                                    
                                                    walletName = wallet["address"] as! String
                                                }
                                                
                                                alert.addAction(UIAlertAction(title: NSLocalizedString(walletName, comment: ""), style: .default, handler: { (action) in
                                                    
                                                    let bitcoinAddress = self.addressBook[index]["address"] as! String
                                                    self.sendingFromAddress = bitcoinAddress
                                                    self.privateKeytoDebit = self.addressBook[index]["privateKey"] as! String
                                                    self.getSignatureMode = true
                                                    self.removeScanner()
                                                    self.makeHTTPPostRequest()
                                                    
                                                }))
                                                
                                            }
                                            
                                        }
                                        
                                    }
                                    
                                }
                                
                            }
                            
                        } else if self.coldMode {
                            
                            for (index, wallet) in self.addressBook.enumerated() {
                                
                                if wallet["address"] as! String != self.recievingAddress {
                                    
                                    if self.testnetMode {
                                        
                                        if wallet["network"] as! String == "testnet" {
                                            
                                            var walletName = wallet["label"] as! String
                                            
                                            if walletName == "" {
                                                
                                                walletName = wallet["address"] as! String
                                            }
                                            
                                            alert.addAction(UIAlertAction(title: NSLocalizedString(walletName, comment: ""), style: .default, handler: { (action) in
                                                
                                                let bitcoinAddress = self.addressBook[index]["address"] as! String
                                                self.processKeys(key: bitcoinAddress)
                                                
                                            }))
                                            
                                        }
                                        
                                    } else if self.mainnetMode {
                                        
                                        if wallet["network"] as! String == "mainnet" {
                                            
                                            var walletName = wallet["label"] as! String
                                            
                                            if walletName == "" {
                                                
                                                walletName = wallet["address"] as! String
                                            }
                                            
                                            alert.addAction(UIAlertAction(title: NSLocalizedString(walletName, comment: ""), style: .default, handler: { (action) in
                                                
                                                let bitcoinAddress = self.addressBook[index]["address"] as! String
                                                self.processKeys(key: bitcoinAddress)
                                                
                                            }))
                                            
                                        }
                                        
                                    }
                                    
                                }
                                
                            }
                            
                        }
                        
                        alert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: { (action) in
                            
                        }))
                        
                        alert.popoverPresentationController?.sourceView = self.view
                        
                        self.present(alert, animated: true) {
                        }
                        
                    } else {
                        
                        print("oops")
                    }
                    
                }
                
            }
            
    }
   
   func addChooseOptionButton() {
        
        self.optionsButton.removeFromSuperview()
        self.optionsButton = UIButton(frame: CGRect(x: self.view.frame.maxX - 50, y: 20, width: 45, height: 45))
        self.optionsButton.showsTouchWhenHighlighted = true
        self.optionsButton.setImage(#imageLiteral(resourceName: "settings2.png"), for: .normal)
        self.optionsButton.addTarget(self, action: #selector(self.getAmount), for: .touchUpInside)
        self.view.addSubview(self.optionsButton)
    
        self.moreOptionsButton.removeFromSuperview()
        self.moreOptionsButton = UIButton(frame: CGRect(x: 10, y: self.view.frame.maxY - 320, width: 35, height: 35))
        self.moreOptionsButton.setImage(#imageLiteral(resourceName: "tool2.png"), for: .normal)
        self.moreOptionsButton.showsTouchWhenHighlighted = true
        self.moreOptionsButton.addTarget(self, action: #selector(addRawTransactionView), for: .touchUpInside)
        self.view.addSubview(self.moreOptionsButton)
    
        self.sweepButton.removeFromSuperview()
        self.sweepButton = UIButton(frame: CGRect(x: self.view.frame.maxX - 45, y: self.view.frame.maxY - 320, width: 35, height: 35))
        self.sweepButton.setImage(#imageLiteral(resourceName: "sweep.jpeg"), for: .normal)
        self.sweepButton.showsTouchWhenHighlighted = true
        self.sweepButton.addTarget(self, action: #selector(sweep), for: .touchUpInside)
        self.view.addSubview(self.sweepButton)
        
    }
    
    @objc func sweep() {
        
        self.amount = "-1"
        self.amountToSend.removeFromSuperview()
        self.getReceivingAddressMode = true
        self.moreOptionsButton.removeFromSuperview()
        self.sweepButton.removeFromSuperview()
        self.optionsButton.removeFromSuperview()
        self.addScanner()
    }
    
    @objc func getAmount() {
        print("getAmount")
        
        self.performSegue(withIdentifier: "goToTransactionSettings", sender: self)
        
    }
    
    @objc func addRawTransactionView() {
        
        print("addRawTransactionView")
        self.performSegue(withIdentifier: "goToRawTransaction", sender: self)
        
        
    }
    
    func addBackButton() {
        
        DispatchQueue.main.async {
            
            self.backButton = UIButton(frame: CGRect(x: 5, y: 20, width: 55, height: 55))
            self.backButton.showsTouchWhenHighlighted = true
            self.backButton.setImage(#imageLiteral(resourceName: "back2.png"), for: .normal)
            self.backButton.addTarget(self, action: #selector(self.home), for: .touchUpInside)
            self.view.addSubview(self.backButton)
            
        }
        
    }
    
    @objc func home() {
        
        self.dismiss(animated: true, completion: nil)
                    
    }

    func addQRScannerView() {
        print("addQRScannerView")
        
        self.videoPreview.frame = CGRect(x: self.view.center.x - ((self.view.frame.width - 50)/2), y: self.addressToDisplay.frame.maxY + 10, width: self.view.frame.width - 50, height: self.view.frame.width - 50)
        addShadow(view:self.videoPreview)
        self.view.addSubview(self.videoPreview)
    }
    
    func addAmount() {
        print("addAmount")
        
        self.amountToSend.frame = CGRect(x: self.view.frame.minX + 5, y: self.view.frame.minY + 150, width: self.view.frame.width - 10, height: 50)
        self.amountToSend.textAlignment = .center
        self.amountToSend.borderStyle = .roundedRect
        self.amountToSend.backgroundColor = UIColor.groupTableViewBackground
        self.amountToSend.keyboardType = UIKeyboardType.decimalPad
        self.amountToSend.addDoneButtonToKeyboard(myAction:  #selector(self.saveAmountInSatoshis))
        
        if BTC {
            currency = "BTC"
            self.amountToSend.placeholder = "Amount to send in Bitcoin"
            self.amountToSend.becomeFirstResponder()
        } else if SAT {
            currency = "SAT"
            self.amountToSend.placeholder = "Amount to send in Satoshis"
            self.amountToSend.becomeFirstResponder()
        } else if GBP {
            currency = "GBP"
            self.amountToSend.placeholder = "Amount to send in Pounds"
            self.amountToSend.becomeFirstResponder()
        } else if USD {
            currency = "USD"
            self.amountToSend.placeholder = "Amount to send in Dollars"
            self.amountToSend.becomeFirstResponder()
        } else if EUR {
            currency = "EUR"
            self.amountToSend.placeholder = "Amount to send in Euros"
            self.amountToSend.becomeFirstResponder()
        }
        
        self.view.addSubview(self.amountToSend)
        
    }
    
    @objc func saveAmountInSatoshis() {
        print("saveAmountInSatoshis")
        
        if self.amountToSend.text != "" {
            
            self.optionsButton.removeFromSuperview()
            
            self.amount = self.amountToSend.text!
            self.amountToSend.text = ""
            self.amountToSend.resignFirstResponder()
            self.amountToSend.removeFromSuperview()
            
            if self.currency != "BTC" && self.currency != "SAT" {
                    
                    self.getSatoshiAmount()
                    
                } else {
                    
                    self.getSatsAndBTCs()
                }
                
        } else {
            
           shakeAlert(viewToShake: self.amountToSend)
            
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
    
    func addTextInput() {
        print("addTextInput")
        
        self.addressToDisplay.frame = CGRect(x: self.view.frame.minX + 25, y: 150, width: self.view.frame.width - 50, height: 50)
        self.addressToDisplay.textAlignment = .center
        self.addressToDisplay.borderStyle = .roundedRect
        self.addressToDisplay.autocorrectionType = .no
        self.addressToDisplay.autocapitalizationType = .none
        self.addressToDisplay.backgroundColor = UIColor.groupTableViewBackground
        self.addressToDisplay.returnKeyType = UIReturnKeyType.go
        
        if getReceivingAddressMode {
          
            self.addressToDisplay.placeholder = "Scan or Type Receiving Address"
            
        } else if getPayerAddressMode {
            
            self.addressToDisplay.placeholder = "Scan or Type Debit Address"
            
        } else if getSignatureMode {
            
            self.addressToDisplay.placeholder = "Scan or Type Private Key to debit"
            
        }
        
        self.view.addSubview(self.addressToDisplay)
        
    }
    
    func processKeys(key: String) {
        
        if getReceivingAddressMode {
            
            var addressAlreadySaved = false
                
            func processReceivingAddress(network: String) {
                
                for wallet in self.addressBook {
                    
                    if wallet["address"] as! String == key {
                        
                        addressAlreadySaved = true
                        
                    }
                    
                }
                
                if addressAlreadySaved != true {
                    
                        DispatchQueue.main.async {
                            
                            let alert = UIAlertController(title: "Save this address?", message: "Would you like to save this address for future payments?", preferredStyle: UIAlertControllerStyle.alert)
                            
                            alert.addAction(UIAlertAction(title: NSLocalizedString("Yes", comment: ""), style: .default, handler: { (action) in
                                
                                saveWallet(viewController: self, address: key, privateKey: "", publicKey: "", redemptionScript: "", network: network, type: "cold")
                                
                                self.recievingAddress = key
                                self.getReceivingAddressMode = false
                                self.getPayerAddressMode = true
                                self.removeScanner()
                                self.addScanner()
                                self.addressToDisplay.text = ""
                                
                            }))
                            
                            alert.addAction(UIAlertAction(title: NSLocalizedString("No", comment: ""), style: .default, handler: { (action) in
                                
                                self.recievingAddress = key
                                self.getReceivingAddressMode = false
                                self.getPayerAddressMode = true
                                self.removeScanner()
                                self.addScanner()
                                self.addressToDisplay.text = ""
                                
                                
                            }))
                            
                            self.present(alert, animated: true, completion: nil)
                        }
                        
                } else {
                    
                    self.recievingAddress = key
                    self.getReceivingAddressMode = false
                    self.getPayerAddressMode = true
                    self.removeScanner()
                    self.addScanner()
                    self.addressToDisplay.text = ""
                    
                }
                
            }
                
            if let _ = BTCPublicKeyAddressTestnet.init(string: key) {
                    
                processReceivingAddress(network: "testnet")
                    
            } else if let _ = BTCAddress.init(string: key) {
                    
                processReceivingAddress(network: "mainnet")
                    
            } else {
                    
                displayAlert(viewController: self, title: "Error", message: "That is not a valid Bitcoin Address")
            }
                
        } else if getPayerAddressMode {
                
            func processPayerAddress() {
                    
                self.sendingFromAddress = key
                self.getPayerAddressMode = false
                self.getSignatureMode = true
                self.removeScanner()
                self.addressToDisplay.text = ""
                self.makeHTTPPostRequest()
                    
            }
            
            if let _ = BTCPublicKeyAddressTestnet.init(string: key) {
                    
                processPayerAddress()
                    
            } else if let _ = BTCAddress.init(string: key) {
                    
                processPayerAddress()
                    
            } else {
                    
                displayAlert(viewController: self, title: "Error", message: "That is not a valid Bitcoin Address")
                    
            }
            
        } else if getSignatureMode {
                
            if let _ = BTCPrivateKeyAddressTestnet.init(string: key) {
                
                self.removeSpinner()
                self.removeScanner()
                self.getPrivateKeySignature(key: key)
                    
            } else if let _ = BTCPrivateKeyAddress.init(string: key) {
                    
                self.removeSpinner()
                self.removeScanner()
                self.getPrivateKeySignature(key: key)
                    
            } else {
                    
                displayAlert(viewController: self, title: "Error", message: "That is not a valid Bitcoin Private Key")
                    
            }
        }
            
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        print("textFieldDidEndEditing")
        
        
        let key = textField.text!
        
        if textField == self.addressToDisplay {
            
            if self.getSignatureMode || self.getPayerAddressMode || self.getReceivingAddressMode && textField != self.amountToSend {
                
                if key != "" {
                    
                    if let _ = BTCAddress.init(string: textField.text) {
                        
                        processKeys(key: key)
                        
                    } else if let _ = BTCPrivateKeyAddress.init(string: textField.text) {
                        
                        processKeys(key: key)
                        
                    } else if let _ = BTCPublicKeyAddressTestnet.init(string: textField.text) {
                        
                        processKeys(key: key)
                        
                    } else if let _ = BTCPrivateKeyAddressTestnet.init(string: textField.text) {
                        
                        processKeys(key: key)
                        
                    } else {
                        
                        displayAlert(viewController: self, title: "Error", message: "That is not a valid Bitcoin Key.")
                        
                    }
                    
                } else {
                    
                    shakeAlert(viewToShake: textField)
                    
                }
                
            } else {
                
                processKeys(key: key)
                
            }
            
        }
            
    }
    
    func getSatsAndBTCs() {
        print("getSatsAndBTCs")
        
        if self.amount == "-1" {
            
            self.amountToSend.removeFromSuperview()
            self.addScanner()
            
        } else if self.currency == "BTC" && self.amount != "-1" {
            
            self.amountInBTC = Double(self.amount)!
            self.satoshiAmount = Int(self.amountInBTC * 100000000)
            self.addScanner()
            
        } else if self.currency == "SAT" && self.amount != "-1" {
            
            self.satoshiAmount = Int(self.amount)!
            self.amountInBTC = Double(self.amount)! / 100000000
            self.addScanner()
            
        }
        
    }
    
    func getSatoshiAmount() {
        print("getSatoshiAmount")
        
        if isInternetAvailable() == true {
            
            self.addSpinner()
            var url:NSURL!
            url = NSURL(string: "https://api.coindesk.com/v1/bpi/currentprice.json")
            
            let task = URLSession.shared.dataTask(with: url! as URL) { (data, response, error) -> Void in
                
                do {
                    
                    if error != nil {
                        
                        self.removeSpinner()
                        print(error as Any)
                        DispatchQueue.main.async {
                            displayAlert(viewController: self, title: "Error", message: "\(String(describing: error))")
                        }
                        
                    } else {
                        
                        if let urlContent = data {
                            
                            do {
                                
                                let jsonQuoteResult = try JSONSerialization.jsonObject(with: urlContent, options: JSONSerialization.ReadingOptions.mutableLeaves) as! NSDictionary
                                
                                if let exchangeCheck = jsonQuoteResult["bpi"] as? NSDictionary {
                                    
                                    if let exchangeRateCheck = exchangeCheck[self.currency] as? NSDictionary {
                                        
                                        if let rateCheck = exchangeRateCheck["rate_float"] as? Float {
                                            
                                            self.exchangeRate = Double(rateCheck)
                                            self.amountInBTC = Double(self.amount)! / Double(rateCheck)
                                            self.satoshiAmount = Int(self.amountInBTC * 100000000)
                                            
                                            DispatchQueue.main.async {
                                                
                                                self.removeSpinner()
                                                self.amountToSend.removeFromSuperview()
                                                self.addScanner()
                                                
                                            }
                                        }
                                    }
                                }
                                
                            } catch {
                                
                                self.removeSpinner()
                                print("JSon processing failed")
                                DispatchQueue.main.async {
                                    displayAlert(viewController: self, title: "Error", message: "Please try again")
                                }
                                
                            }
                        }
                    }
                }
            }
            
            task.resume()
            
        } else {
            
            displayAlert(viewController: self, title: "Oops", message: "We need internet to get the exchange rate, please check your connection.")
            
        }
        
        
        
    }
    
    func addScanner() {
        print("addScanner")
        
        if self.getPayerAddressMode, let _ = self.walletToSpendFrom["label"] as? String {
            
            if self.hotMode {
                
             self.privateKeytoDebit = self.walletToSpendFrom["privateKey"] as! String
                
            } else if self.coldMode {
                
                self.getPayerAddressMode = false
                self.getSignatureMode = true
                
            }
            
            self.makeHTTPPostRequest()
            
        } else if self.getPayerAddressMode {
            
                displayAlert(viewController: self, title: "Success", message: "We got your receiving address\n\n\(self.recievingAddress)\n\nNow we need the debit address.")
            
            DispatchQueue.main.async {
                
                self.addTextInput()
                self.addQRScannerView()
                self.scanQRCode()
                
            }
        
        } else {
           
            DispatchQueue.main.async {
                
                self.addTextInput()
                self.addQRScannerView()
                self.scanQRCode()
                
            }
            
        }
        
    }
    
    func removeScanner() {
        print("removeScanner")
        
        DispatchQueue.main.async {
            
            self.avCaptureSession.stopRunning()
            self.addressBookButton.removeFromSuperview()
            self.addressToDisplay.removeFromSuperview()
            self.videoPreview.removeFromSuperview()
            
        }
        
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        print("textFieldShouldReturn")
        
        self.view.endEditing(true)
        return false
    }
    
    func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
        print("textFieldShouldEndEditing")
        
        if textField == addressToDisplay {
            
          addressToDisplay.resignFirstResponder()
            
        }
        
        return true
    }
    
    enum error: Error {
        
        case noCameraAvailable
        case videoInputInitFail
        
    }
    
    func scanQRCode() {
        
        if self.getReceivingAddressMode || self.getPayerAddressMode {
            
            self.addAddressBookButton()
            
        }
        
        do {
            
            try scanQRNow()
            print("scanQRNow")
            
        } catch {
            
            print("Failed to scan QR Code")
            
        }
    }
    
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        if metadataObjects.count > 0 {
            print("metadataOutput")
            
            let machineReadableCode = metadataObjects[0] as! AVMetadataMachineReadableCodeObject
            
            if machineReadableCode.type == AVMetadataObject.ObjectType.qr {
                
                stringURL = machineReadableCode.stringValue!
                
                if stringURL.contains("bitcoin:") {
                    
                    stringURL = stringURL.replacingOccurrences(of: "bitcoin:", with: "")
                    
                    if stringURL.contains("?") {
                        
                        let stringArray = stringURL.split(separator: "?")
                        stringURL = String(stringArray[0])
                        
                    }
                    
                }
                
                let key = stringURL
                
                if self.getSignatureMode || self.getPayerAddressMode || self.getReceivingAddressMode {
                    
                    if key != "" {
                        
                        if let _ = BTCAddress.init(string: key) {
                            
                            processKeys(key: key)
                            self.avCaptureSession.stopRunning()
                            
                        } else if let _ = BTCPrivateKeyAddress.init(string: key) {
                            
                            processKeys(key: key)
                            self.avCaptureSession.stopRunning()
                            
                        } else if let _ = BTCPublicKeyAddressTestnet.init(string: key) {
                            
                            processKeys(key: key)
                            self.avCaptureSession.stopRunning()
                            
                        } else if let _ = BTCPrivateKeyAddressTestnet.init(string: key) {
                            
                            processKeys(key: key)
                            self.avCaptureSession.stopRunning()
                            
                        } else {
                            
                            displayAlert(viewController: self, title: "Error", message: "That is not a valid Bitcoin Key.")
                        }
                        
                    } else {
                        
                        shakeAlert(viewToShake: imageView)
                        
                    }
                    
                } else {
                    
                    processKeys(key: key)
                    
                }
                
            }
        }
    }
    
    func getPrivateKeySignature(key: String) {
        print("getPrivateKeySignature")
        
        func signNow(privateKey: String) {
            
            if let privateKey = BTCPrivateKeyAddress(string: privateKey) {
                
                let key = BTCKey.init(privateKeyAddress: privateKey)
                
                var receiveAddress = ""
                var sendAddress = ""
                
                for wallet in self.addressBook {
                    
                    if wallet["address"] as! String == self.sendingFromAddress {
                        
                        sendAddress = wallet["label"] as! String
                    }
                    
                    if wallet["address"] as! String == self.recievingAddress {
                        
                        receiveAddress = wallet["label"] as! String
                        
                    }
                    
                }
                
                DispatchQueue.main.async {
                    
                    var message = String()
                    
                    func postAlert() {
                        
                        let publicKey = key?.publicKey
                        let publicKeyString = BTCHexFromData(publicKey as Data!)
                        self.privateKeyToSign = (key?.privateKey.hex())!
                        
                        var signatureArray = [String]()
                        var pubkeyArray = [String]()
                        
                        for transaction in self.transactionToBeSigned {
                            
                            SignerGetSignature(self.privateKeyToSign, transaction)
                            
                            if let signature = Signer.signature() {
                                
                                signatureArray.append(signature)
                                pubkeyArray.append(publicKeyString!)
                                
                            } else {
                                
                                DispatchQueue.main.async {
                                    displayAlert(viewController: self, title: "Error", message: "Error creating signatures.")
                                }
                            }
                            
                            
                        }
                        
                        self.json["signatures"] = signatureArray
                        self.json["pubkeys"] = pubkeyArray
                        
                        DispatchQueue.main.async {
                            self.sendButton.removeFromSuperview()
                            self.sendButton = UIButton(frame: CGRect(x: 20, y: self.view.frame.maxY - 60, width: self.view.frame.width - 40, height: 50))
                            self.sendButton.showsTouchWhenHighlighted = true
                            self.sendButton.layer.cornerRadius = 10
                            self.sendButton.backgroundColor = UIColor.black
                            addShadow(view:self.sendButton)
                            self.sendButton.addTarget(self, action: #selector(self.postTransaction), for: .touchUpInside)
                            self.sendButton.setTitle("Send", for: .normal)
                            self.view.addSubview(self.sendButton)
                            
                            self.titleLable.frame = CGRect(x: 10, y: 60, width: self.view.frame.width - 20, height: 60)
                            self.titleLable.textAlignment = .center
                            self.titleLable.font = .systemFont(ofSize: 28)
                            self.titleLable.adjustsFontSizeToFitWidth = true
                            self.titleLable.numberOfLines = 2
                            self.titleLable.text = "Confirm before sending"
                            self.view.addSubview(self.titleLable)
                            
                            
                            self.textView.frame = CGRect(x: 10, y: self.titleLable.frame.maxY + 20, width: self.view.frame.width - 20, height: 350)
                            self.textView.font = .systemFont(ofSize: 18)
                            self.textView.adjustsFontSizeToFitWidth = true
                            self.textView.numberOfLines = 20
                            self.textView.text = "\(message)"
                            self.view.addSubview(self.textView)
                        }
                        
                    }
                    
                    
                    
                    if self.currency != "BTC" && self.currency != "SAT" {
                        
                        let feeInFiat = self.exchangeRate * (Double(self.fees) / 100000000)
                        let roundedFiatFeeAmount = round(100 * feeInFiat) / 100
                        let roundedFiatToSendAmount = (round(100 * Double(self.amount)!) / 100).withCommas()
                        
                        if receiveAddress != "" && sendAddress != "" {
                            
                            message = "From:\n\n\"\(sendAddress)\"\n\(self.sendingFromAddress)\n\n\nTo:\n\n\"\(receiveAddress)\"\n\(self.recievingAddress)\n\n\nAmount:\n\n\(roundedFiatToSendAmount) \(self.currency) with a miner fee of \(self.fees.withCommas()) Satoshis or \(roundedFiatFeeAmount) \(self.currency)"
                            
                        } else if receiveAddress != "" {
                            
                            message = "From:\n\n\(self.sendingFromAddress)\n\n\nTo:\n\n\"\(receiveAddress)\"\n\(self.recievingAddress)\n\n\nAmount:\n\n\(roundedFiatToSendAmount) \(self.currency) with a miner fee of \(self.fees.withCommas()) Satoshis or \(roundedFiatFeeAmount) \(self.currency)"
                            
                        } else if sendAddress != "" {
                            
                            message = "From:\n\n\"\(sendAddress)\"\n\(self.sendingFromAddress)\n\n\nTo:\n\n\(self.recievingAddress)\n\n\n\nAmount:\n\n\(roundedFiatToSendAmount) \(self.currency) with a miner fee of \(self.fees.withCommas()) Satoshis or \(roundedFiatFeeAmount) \(self.currency)"
                            
                        }
                        
                        
                        postAlert()
                        
                    } else if self.currency == "BTC" || self.currency == "SAT" {
                        
                        if receiveAddress != "" && sendAddress != "" {
                            
                            message = "From:\n\n\"\(sendAddress)\"\n\(self.sendingFromAddress)\n\n\nTo:\n\n\"\(receiveAddress)\"\n\(self.recievingAddress)\n\n\nAmount:\n\n\(self.amount) \(self.currency) with a miner fee of \(self.fees.withCommas()) Satoshis"
                            
                        } else if receiveAddress != "" {
                            
                            message = "From:\n\n\(self.sendingFromAddress)\n\n\nTo:\n\n\"\(receiveAddress)\"\n\(self.recievingAddress)\n\n\nAmount:\n\n\(self.amount) \(self.currency) with a miner fee of \(self.fees.withCommas()) Satoshis"
                            
                        } else if sendAddress != "" {
                            
                            message = "From:\n\n\"\(sendAddress)\"\n\(self.sendingFromAddress)\n\n\nTo:\n\n\(self.recievingAddress)\n\n\nAmount:\n\n\(self.amount) \(self.currency) with a miner fee of \(self.fees.withCommas()) Satoshis"
                            
                        }
                        
                        if self.amount == "-1" {
                            
                            if receiveAddress != "" && sendAddress != "" {
                                
                                message = "From:\n\n\"\(sendAddress)\"\n\(self.sendingFromAddress)\n\n\nTo:\n\n\"\(receiveAddress)\"\n\(self.recievingAddress)\n\n\nAmount:\n\nAll Bitcoin to be sweeped with a miner fee of \(self.fees.withCommas()) Satoshis"
                                
                            } else if receiveAddress != "" {
                                
                                message = "From:\n\n\(self.sendingFromAddress)\n\n\nTo:\n\n\"\(receiveAddress)\"\n\(self.recievingAddress)\n\n\nAmount:\n\nAll Bitcoin to be sweeped with a miner fee of \(self.fees.withCommas()) Satoshis"
                                
                            } else if sendAddress != "" {
                                
                                message = "From:\n\n\"\(sendAddress)\"\n\(self.sendingFromAddress)\n\n\nTo:\n\n\(self.recievingAddress)\n\n\nAmount:\n\nAll Bitcoin to be sweeped with a miner fee of \(self.fees.withCommas()) Satoshis"
                                
                            }
                            
                        }
                        
                        postAlert()
                        
                    }
                    
                }
                
            } else {
                
                DispatchQueue.main.async {
                    
                    displayAlert(viewController: self, title: "Error", message: "The Private Key is not valid, please try again.")
                    
                }
                
            }
            
        }
        
        if let _ = BTCPrivateKeyAddressTestnet.init(string: key) {
            
            signNow(privateKey: key)
            
        } else if let _ = BTCPrivateKeyAddress.init(string: key) {
            
            signNow(privateKey: key)
            
        } else {
            
            let password = KeychainWrapper.standard.string(forKey: "AESPassword")!
            let decrypted = AES256CBC.decryptString(key, password: password)!
            signNow(privateKey: decrypted)
            
        }
        
    }
    
    func scanQRNow() throws {
        
        if self.getReceivingAddressMode {
          
            guard let avCaptureDevice = AVCaptureDevice.default(for: AVMediaType.video) else {
                
                print("no camera")
                throw error.noCameraAvailable
                
            }
            
            guard let avCaptureInput = try? AVCaptureDeviceInput(device: avCaptureDevice) else {
                
                print("failed to int camera")
                throw error.videoInputInitFail
            }
            
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
            
            let avCaptureMetadataOutput = AVCaptureMetadataOutput()
            avCaptureMetadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            self.avCaptureSession.addInput(avCaptureInput)
            self.avCaptureSession.addOutput(avCaptureMetadataOutput)
            avCaptureMetadataOutput.metadataObjectTypes = [AVMetadataObject.ObjectType.qr]
            let avCaptureVideoPreviewLayer = AVCaptureVideoPreviewLayer(session: avCaptureSession)
            avCaptureVideoPreviewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
            avCaptureVideoPreviewLayer.frame = videoPreview.bounds
            self.videoPreview.layer.addSublayer(avCaptureVideoPreviewLayer)
            
        }
        
        self.avCaptureSession.startRunning()
        
    }
    
    func makeHTTPPostRequest() {
        print("makeHTTPPostRequest")
        
        if isInternetAvailable() == true {
            
            self.addSpinner()
            var url:URL!
            
            if self.sendingFromAddress.hasPrefix("m") || self.sendingFromAddress.hasPrefix("2") || self.sendingFromAddress.hasPrefix("n") {
                
                url = URL(string: "https://api.blockcypher.com/v1/btc/test3/txs/new")
                
            } else if self.sendingFromAddress.hasPrefix("1") || self.sendingFromAddress.hasPrefix("3") {
                
                url = URL(string: "https://api.blockcypher.com/v1/btc/main/txs/new")
                
            }
            
            var request = URLRequest(url: url)
            request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
            request.httpMethod = "POST"
            
            if self.amount == "-1" {
                
                self.satoshiAmount = -1
            }
            
            if self.manuallySetFee {
                
                request.httpBody = "{\"inputs\": [{\"addresses\": [\"\(self.sendingFromAddress)\"]}], \"outputs\": [{\"addresses\": [\"\(self.recievingAddress)\"], \"value\": \(self.satoshiAmount)}],\"fees\": \(self.fees!)}".data(using: .utf8)
                
            } else {
                
                request.httpBody = "{\"inputs\": [{\"addresses\": [\"\(self.sendingFromAddress)\"]}], \"outputs\": [{\"addresses\": [\"\(self.recievingAddress)\"], \"value\": \(self.satoshiAmount)}],\"preference\": \"\(self.preference)\"}".data(using: .utf8)
                
            }
            
            
            
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
                                    
                                } else {
                                    
                                    if let toSignCheck = jsonAddressResult["tosign"] as? NSArray {
                                        
                                        for tosign in toSignCheck {
                                            
                                            self.transactionToBeSigned.append(tosign as! String)
                                            
                                        }
                                        
                                        self.json = jsonAddressResult.mutableCopy() as! NSMutableDictionary
                                        self.removeScanner()
                                        
                                        if let sizeCheck = (jsonAddressResult["tx"] as? NSDictionary)?["fees"] as? NSInteger {
                                                
                                            self.fees = UInt16(sizeCheck)
                                                
                                        }
                                        
                                        if self.hotMode {
                                            
                                            self.getPrivateKeySignature(key: self.privateKeytoDebit)
                                            self.removeSpinner()
                                            
                                        } else {
                                            
                                            DispatchQueue.main.async {
                                                
                                                self.removeSpinner()
                                                
                                                if self.coldMode {
                                                    
                                                    let alert = UIAlertController(title: NSLocalizedString("Turn Airplane Mode On", comment: ""), message: "We need to scan your Private Key so that we can create a signature to sign your transaction with, you may enable airplane mode during this operation for maximum security, this is optional. We NEVER save your Private Keys, the signature is created locally and the internet is not used at all, however we will need the internet after you sign the transaction in order to send the bitcoins.", preferredStyle: UIAlertControllerStyle.alert)
                                                    
                                                    alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: { (action) in
                                                        
                                                        DispatchQueue.main.async {
                                                            
                                                            self.addScanner()
                                                            
                                                        }
                                                        
                                                    }))
                                                    
                                                    self.present(alert, animated: true, completion: nil)
                                                    
                                                }
                                                
                                            }
                                            
                                        }
                                        
                                    }
                                    
                                }
                                
                            } catch {
                                
                                self.removeSpinner()
                                print("JSon processing failed")
                                
                                DispatchQueue.main.async {
                                    
                                    displayAlert(viewController: self, title: "Error", message: "Please try again.")
                                    
                                }
                            }
                        }
                    }
                }
            }
            
            task.resume()
            
        } else {
            
            displayAlert(viewController: self, title: "Oops", message: "We need internet to verify your Bitcoin actually exists before you can spend it, please check your connection and try again.")
        }
        
        
    }
    
    @objc func postTransaction() {
        print("postTransaction")
        
        func sendNow() {
            
            if isInternetAvailable() != false {
                
                self.sendButton.removeFromSuperview()
                self.titleLable.removeFromSuperview()
                self.textView.removeFromSuperview()
                
                self.addSpinner()
                let jsonData = try? JSONSerialization.data(withJSONObject: self.json)
                var url:URL!
                
                if self.sendingFromAddress.hasPrefix("m") || self.sendingFromAddress.hasPrefix("2") || self.sendingFromAddress.hasPrefix("n") {
                    
                    url = URL(string: "https://api.blockcypher.com/v1/btc/test3/txs/send")
                    
                } else if self.sendingFromAddress.hasPrefix("1") || self.sendingFromAddress.hasPrefix("3") {
                    
                    url = URL(string: "https://api.blockcypher.com/v1/btc/main/txs/send")
                    
                }
                
                var request = URLRequest(url: url)
                request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
                request.httpMethod = "POST"
                request.httpBody = jsonData
                
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
                                        
                                    } else {
                                        
                                        if let txCheck = jsonAddressResult["tx"] as? NSDictionary {
                                            
                                            if let hashCheck = txCheck["hash"] as? String {
                                                
                                                self.transactionID = hashCheck
                                                self.removeScanner()
                                                
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
                                                    }
                                                    
                                                }
                                            }
                                        }
                                    }
                                    
                                } catch {
                                    
                                    print("JSon processing failed")
                                    
                                    self.removeSpinner()
                                    
                                    DispatchQueue.main.async {
                                        
                                        displayAlert(viewController: self, title: "Error", message: "Please try again.")
                                        
                                    }
                                }
                            }
                        }
                    }
                }
                
                task.resume()
                
            } else {
                
                displayAlert(viewController: self, title: "Oops", message: "You need to turn your wifi back on to actually send the transaction, don't worry we already signed the transaction with your private key and its not saved onto the phone at all, please turn wifi on and try again.")
            }
            
        }
        
        func authenticationWithTouchID() {
            
            let localAuthenticationContext = LAContext()
            localAuthenticationContext.localizedFallbackTitle = "Use Passcode"
            
            var authError: NSError?
            let reasonString = "To Spend From Your Wallet"
            
            if localAuthenticationContext.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &authError) {
                
                localAuthenticationContext.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reasonString) { success, evaluateError in
                    
                    if success {
                        
                       sendNow()
                                
                        
                    } else {
                        
                        guard let error = evaluateError else {
                            return
                        }
                        
                        displayAlert(viewController: self, title: "Error", message: evaluateAuthenticationPolicyMessageForLA(errorCode: error._code))
                        
                        
                    }
                }
            } else {
                
                guard let error = authError else {
                    return
                }
                
                displayAlert(viewController: self, title: "Error", message: evaluateAuthenticationPolicyMessageForLA(errorCode: error._code))
            }
        }
        
        func evaluatePolicyFailErrorMessageForLA(errorCode: Int) -> String {
            var message = ""
            if #available(iOS 11.0, macOS 10.13, *) {
                switch errorCode {
                case LAError.biometryNotAvailable.rawValue:
                    message = "Authentication could not start because the device does not support biometric authentication."
                    
                case LAError.biometryLockout.rawValue:
                    message = "Authentication could not continue because the user has been locked out of biometric authentication, due to failing authentication too many times."
                    
                case LAError.biometryNotEnrolled.rawValue:
                    message = "Authentication could not start because the user has not enrolled in biometric authentication."
                    
                default:
                    message = "Did not find error code on LAError object"
                }
            } else {
                switch errorCode {
                case LAError.touchIDLockout.rawValue:
                    message = "Too many failed attempts."
                    
                case LAError.touchIDNotAvailable.rawValue:
                    message = "TouchID is not available on the device"
                    
                case LAError.touchIDNotEnrolled.rawValue:
                    message = "TouchID is not enrolled on the device"
                    
                default:
                    message = "Did not find error code on LAError object"
                }
            }
            
            return message;
        }
        
        func evaluateAuthenticationPolicyMessageForLA(errorCode: Int) -> String {
            
            var message = ""
            
            switch errorCode {
                
            case LAError.authenticationFailed.rawValue:
                message = "The user failed to provide valid credentials"
                
            case LAError.appCancel.rawValue:
                message = "Authentication was cancelled by application"
                
            case LAError.invalidContext.rawValue:
                message = "The context is invalid"
                
            case LAError.notInteractive.rawValue:
                message = "Not interactive"
                
            case LAError.passcodeNotSet.rawValue:
                message = "Passcode is not set on the device"
                
            case LAError.systemCancel.rawValue:
                message = "Authentication was cancelled by the system"
                
            case LAError.userCancel.rawValue:
                message = "The user did cancel"
                
            case LAError.userFallback.rawValue:
                message = "The user chose to use the fallback"
                
            default:
                message = evaluatePolicyFailErrorMessageForLA(errorCode: errorCode)
            }
            
            return message
        }
        
        
        if UserDefaults.standard.object(forKey: "bioMetricsEnabled") != nil {
            
            DispatchQueue.main.async {
                authenticationWithTouchID()
            }
            
            
        } else if let _ = KeychainWrapper.standard.string(forKey: "unlockAESPassword") {
            
            var password = String()
            
            DispatchQueue.main.async {
                let alert = UIAlertController(title: "Please input your password", message: "Please enter your password to spend from your wallet", preferredStyle: .alert)
                
                alert.addTextField { (textField1) in
                    
                    textField1.placeholder = "Enter Password"
                    textField1.isSecureTextEntry = true
                    
                }
                
                alert.addAction(UIAlertAction(title: NSLocalizedString("Spend", comment: ""), style: .destructive, handler: { (action) in
                    
                    password = alert.textFields![0].text!
                    
                    if password == KeychainWrapper.standard.string(forKey: "unlockAESPassword") {
                        
                        sendNow()
                        
                    } else {
                        
                        displayAlert(viewController: self, title: "Error", message: "Incorrect password!")
                    }
                    
                }))
                
                alert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .default, handler: { (action) in
                    
                }))
                
                self.present(alert, animated: true, completion: nil)
            }
            
        } else {
            
            sendNow()
            
        }
        
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask { return UIInterfaceOrientationMask.portrait }
    
}

extension UITextField {
    
    func addDoneButtonToKeyboard(myAction:Selector){
        
        let doneToolbar: UIToolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: 300, height: 40))
        doneToolbar.barStyle = UIBarStyle.default
        let flexSpace = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.flexibleSpace, target: nil, action: nil)
        let done: UIBarButtonItem = UIBarButtonItem(title: "Next", style: UIBarButtonItemStyle.done, target: TransactionBuilderViewController(), action: myAction)
        var items = [UIBarButtonItem]()
        items.append(flexSpace)
        items.append(done)
        doneToolbar.items = items
        doneToolbar.sizeToFit()
        self.inputAccessoryView = doneToolbar
        
    }
}


