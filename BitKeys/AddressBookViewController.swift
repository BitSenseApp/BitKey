//
//  AddressBookViewController.swift
//  BitKeys
//
//  Created by Peter on 6/14/18.
//  Copyright © 2018 Fontaine. All rights reserved.
//

import UIKit

class AddressBookViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet var addressBookTable: UITableView!
    
    var backButton = UIButton()
    var addButton = UIButton()
    var addressBook: [[String: Any]] = []
    var imageView:UIView!
    var hotMainnetArray = [[String: Any]]()
    var hotTestnetArray = [[String: Any]]()
    var coldMainnetArray = [[String: Any]]()
    var coldTestnetArray = [[String: Any]]()
    var sections = Int()
    var addressToExport = String()
    var privateKeyToExport = String()
    var refresher: UIRefreshControl!
    var multiSigMode = Bool()
    var keyArray = [[String: Any]]()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        addressBookTable.delegate = self
        refresher = UIRefreshControl()
        refresher.addTarget(self, action: #selector(self.getArrays), for: UIControlEvents.valueChanged)
        addressBookTable.addSubview(refresher)
        addBackButton()
        addPlusButton()
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        
        
        if UserDefaults.standard.object(forKey: "addressBook") != nil {
            
            addressBook = UserDefaults.standard.object(forKey: "addressBook") as! [[String: Any]]
            print("addressBook = \(addressBook)")
        }
        
        getArrays()
        
        
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if (segue.identifier == "goHome") {
            
            if self.privateKeyToExport != "" {
                
                let vc = segue.destination as! ViewController
                vc.bitcoinAddress = addressToExport
                vc.privateKeyWIF = privateKeyToExport
                vc.exportPrivateKeyFromTable = true
                
            } else {
                
                let vc = segue.destination as! ViewController
                vc.bitcoinAddress = addressToExport
                vc.exportAddressFromTable = true
                
            }
            
            
        }
        
    }
    
    @objc func getArrays() {
        
        if UserDefaults.standard.object(forKey: "addressBook") != nil {
            
            addressBook = UserDefaults.standard.object(forKey: "addressBook") as! [[String: Any]]
            print("addressBook = \(addressBook)")
        }
        
        self.hotMainnetArray.removeAll()
        self.coldMainnetArray.removeAll()
        self.hotTestnetArray.removeAll()
        self.coldTestnetArray.removeAll()
        
        self.sections = 0
        
        for address in self.addressBook {
            
            let network = address["network"] as! String
            let type = address["type"] as! String
            
            if network == "mainnet" && type == "hot" {
                
                self.hotMainnetArray.append(address)
                self.sections = sections + 1
                
            } else if network == "testnet" && type == "hot" {
                
                self.hotTestnetArray.append(address)
                self.sections = sections + 1
                
            } else if network == "mainnet" && type == "cold" {
                
                self.coldMainnetArray.append(address)
                self.sections = sections + 1
                
            } else if network == "testnet" && type == "cold" {
                
                self.coldTestnetArray.append(address)
                self.sections = sections + 1
                
            }
            
        }
        
        for (index, address) in hotMainnetArray.enumerated() {
            
            let addressToCheck = address["address"] as! String
            self.checkBalance(address: addressToCheck, index: index, network: "mainnet", type: "hot")
            
        }
        
        for (index, address) in hotTestnetArray.enumerated() {
            
            let addressToCheck = address["address"] as! String
            self.checkBalance(address: addressToCheck, index: index, network: "testnet", type: "hot")
            
        }
        
        for (index, address) in coldMainnetArray.enumerated() {
            
            let addressToCheck = address["address"] as! String
            self.checkBalance(address: addressToCheck, index: index, network: "mainnet", type: "cold")
            
        }
        
        for (index, address) in coldTestnetArray.enumerated() {
            
            let addressToCheck = address["address"] as! String
            self.checkBalance(address: addressToCheck, index: index, network: "testnet", type: "cold")
            
        }
        
        addressBookTable.reloadData()
        
    }
    
    func addBackButton() {
        print("addBackButton")
        
        DispatchQueue.main.async {
            
            self.backButton.removeFromSuperview()
            self.backButton = UIButton(frame: CGRect(x: 5, y: 20, width: 55, height: 55))
            self.backButton.showsTouchWhenHighlighted = true
            self.backButton.setImage(#imageLiteral(resourceName: "back2.png"), for: .normal)
            self.backButton.addTarget(self, action: #selector(self.back), for: .touchUpInside)
            self.view.addSubview(self.backButton)
            
        }
        
    }
    
    func addPlusButton() {
        print("addPlusButton")
        
        DispatchQueue.main.async {
            
            self.addButton.removeFromSuperview()
            self.addButton = UIButton(frame: CGRect(x: self.view.frame.width - 40, y: 25, width: 35, height: 35))
            self.addButton.showsTouchWhenHighlighted = true
            self.addButton.setImage(#imageLiteral(resourceName: "add.png"), for: .normal)
            self.addButton.addTarget(self, action: #selector(self.add), for: .touchUpInside)
            self.view.addSubview(self.addButton)
            
        }
        
    }
    
    @objc func add() {
        
        print("add")
        
        var signaturesRequired = UInt()
        
        if self.keyArray.count > 0 {
            
            //alert to ask how many signatures
            let alert = UIAlertController(title: "How many signatures?", message: "This number needs to be between 1 and \(self.keyArray.count)", preferredStyle: .alert)
            
            alert.addTextField { (textField1) in
                
                textField1.keyboardType = UIKeyboardType.decimalPad
                textField1.placeholder = "1 to \(self.keyArray.count)"
                
            }
            
            alert.addAction(UIAlertAction(title: NSLocalizedString("Add", comment: ""), style: .default, handler: { (action) in
                
                signaturesRequired = UInt(alert.textFields![0].text!)!
                
                if signaturesRequired <= self.keyArray.count {
                    
                    self.createMultiSig(wallets: self.keyArray as! [[String : Any]], signaturesRequired: signaturesRequired)
                    
                }
                
            }))
            
            alert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: { (action) in
                
            }))
            
            self.present(alert, animated: true, completion: nil)
        }
        
        
    }
    
    func createMultiSig(wallets: [[String:Any]], signaturesRequired: UInt) {
        
        var testnet = Bool()
        var mainnet = Bool()
        var network = ""
        
        for wallet in wallets {
            
            if wallet["network"] as! String == "mainnet" {
                
                mainnet = true
                network = "mainnet"
                
            } else {
                
                testnet = true
                network = "testnet"
                
            }
            
        }
        
        if mainnet && testnet {
            
            displayAlert(viewController: self, title: "Error", message: "You can not create a multi sig wallet with a testnet wallet and a mainnet wallet, choose wallets only from the same network.")
            
        } else {
            
            var publickKeyArray = [Any]()
            
            for wallet in wallets {
                
                let publicKeyData = BTCDataFromHex(wallet["publicKey"] as! String)
                publickKeyArray.append(publicKeyData as Data!)
                
            }
            
            if let multiSigWallet = BTCScript.init(publicKeys: publickKeyArray, signaturesRequired: signaturesRequired) {
                
                let multiSigAddress1 = multiSigWallet.scriptHashAddress.description
                let multiSigAddress2 = multiSigAddress1.components(separatedBy: " ")
                let multiSigAddress = multiSigAddress2[1].replacingOccurrences(of: ">", with: "")
                let redemptionScript = multiSigWallet.hex!
                
                for (index, wallet) in self.addressBook.enumerated() {
                    
                    for address in wallets {
                        
                        if wallet["address"] as! String == address["address"] as! String {
                            
                            self.addressBook[index]["redemptionScript"] = redemptionScript
                            print("self.addressBook =\(self.addressBook)")
                            
                        }
                        
                    }
                    
                }
                
                DispatchQueue.main.async {
                    
                    UserDefaults.standard.set(self.addressBook, forKey: "addressBook")
                    
                    saveWallet(viewController: self, address: multiSigAddress, privateKey: "", publicKey: "", redemptionScript: redemptionScript, network: network, type: "cold")
                    
                }
                
            } else {
                
                displayAlert(viewController: self, title: "Error", message: "Sorry there was an error creating your multi sig wallet")
            }
            
        }
        
    }
    
    @objc func back() {
        
        self.dismiss(animated: true, completion: nil)
        
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        
        return 4
        
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if tableView == self.addressBookTable {
           
            if section == 0 {
                
                return hotMainnetArray.count
                
            } else if section == 1 {
                
                return hotTestnetArray.count
                
            } else if section == 2 {
                
                return coldMainnetArray.count
                
            } else if section == 3 {
                
                return coldTestnetArray.count
                
            }
            
        }
        
       return 0
        
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "LabelCell", for: indexPath)
        
        if indexPath.section == 0 {
            
            let label = self.hotMainnetArray[indexPath.row]["label"] as! String
            let address = self.hotMainnetArray[indexPath.row]["address"] as! String
            let balance = self.hotMainnetArray[indexPath.row]["balance"] as! String
            
            if label != "" {
                
                cell.textLabel?.text = "\(label) \(balance)"
                    
            } else {
                
                cell.textLabel?.text = "\(address) \(balance)"
                
            }
            
        } else if indexPath.section == 1 {
            
            let label = self.hotTestnetArray[indexPath.row]["label"] as! String
            let address = self.hotTestnetArray[indexPath.row]["address"] as! String
            let balance = self.hotTestnetArray[indexPath.row]["balance"] as! String
            
            if label != "" {
                
                cell.textLabel?.text = "\(label) \(balance)"
                
            } else {
                
                cell.textLabel?.text = "\(address) \(balance)"
                
            }
            
        } else if indexPath.section == 2 {
            
            let label = self.coldMainnetArray[indexPath.row]["label"] as! String
            let address = self.coldMainnetArray[indexPath.row]["address"] as! String
            let balance = self.coldMainnetArray[indexPath.row]["balance"] as! String
            
            if label != "" {
                
                cell.textLabel?.text = "\(label) \(balance)"
                
            } else {
                
                cell.textLabel?.text = "\(address) \(balance)"
                
            }
            
        } else if indexPath.section == 3 {
            
            let label = self.coldTestnetArray[indexPath.row]["label"] as! String
            let address = self.coldTestnetArray[indexPath.row]["address"] as! String
            let balance = self.coldTestnetArray[indexPath.row]["balance"] as! String
            
            if label != "" {
                
                cell.textLabel?.text = "\(label) \(balance)"
                
            } else {
                
                cell.textLabel?.text = "\(address) \(balance)"
                
            }
            
        }
        
        if multiSigMode {
            
            if cell.isSelected {
                
                cell.isSelected = false
                
                if cell.accessoryType == UITableViewCellAccessoryType.none {
                    
                    cell.accessoryType = UITableViewCellAccessoryType.checkmark
                    
                } else {
                    
                    cell.accessoryType = UITableViewCellAccessoryType.none
                    
                }
                
            }
            
        }
        
        return cell
        
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        
        if section == 0 && self.hotMainnetArray.count > 0 {
            
            return "Hot - Mainnet"
            
        } else if section == 1 && self.hotTestnetArray.count > 0 {
            
            return "Hot - Testnet"
            
        } else if section == 2 && self.coldMainnetArray.count > 0 {
            
            return "Cold - Mainnet"
            
        } else if section == 3 && self.coldTestnetArray.count > 0 {
            
            return "Cold - Testnet"
            
        }
        
        return nil
        
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let cell = tableView.cellForRow(at: indexPath)!
        
        if keyArray.count == 0 {
            
            self.multiSigMode = false
            
        }
        
       if indexPath.section == 0 {
            
            for (index, wallet) in self.addressBook.enumerated() {
                
                if self.hotMainnetArray[indexPath.row]["address"] as! String == wallet["address"] as! String{
                    
                    print("wallet = \(self.addressBook[index])")
                    
                    if multiSigMode != true {
                        
                      self.showKeyManagementAlert(wallet: self.addressBook[index], cell: cell)
                        
                    } else {
                        
                        if self.addressBook[index]["publicKey"] as! String != "" && self.addressBook[index]["redemptionScript"] as! String == "" {
                            
                            if cell.isSelected {
                                
                                cell.isSelected = false
                                
                                if cell.accessoryType == UITableViewCellAccessoryType.none {
                                    
                                    cell.accessoryType = UITableViewCellAccessoryType.checkmark
                                    self.keyArray.append(self.addressBook[index])
                                    print("keyArray = \(self.keyArray)")
                                    
                                } else {
                                    
                                    cell.accessoryType = UITableViewCellAccessoryType.none
                                    self.keyArray.remove(at: indexPath.row)
                                    print("keyArray = \(self.keyArray)")
                                    
                                }
                                
                            }
                            
                        } else {
                            
                            displayAlert(viewController: self, title: "Error", message: "Unable to use wallets that are alread used for other multi sig wallets.")
                            
                        }
                        
                    }
                    
                }
                
            }
            
        } else if indexPath.section == 1 {
            
            for (index, wallet) in self.addressBook.enumerated() {
                
                if self.hotTestnetArray[indexPath.row]["address"] as! String == wallet["address"] as! String{
                    
                    print("wallet = \(self.addressBook[index])")
                    
                    if multiSigMode != true {
                        
                        self.showKeyManagementAlert(wallet: self.addressBook[index], cell: cell)
                        
                    } else {
                        
                        if self.addressBook[index]["publicKey"] as! String != "" {
                            
                            if cell.isSelected {
                                
                                cell.isSelected = false
                                
                                if cell.accessoryType == UITableViewCellAccessoryType.none {
                                    
                                    cell.accessoryType = UITableViewCellAccessoryType.checkmark
                                    self.keyArray.append(self.addressBook[index])
                                    print("keyArray = \(self.keyArray)")
                                    
                                } else {
                                    
                                    cell.accessoryType = UITableViewCellAccessoryType.none
                                    self.keyArray.remove(at: indexPath.row)
                                    print("keyArray = \(self.keyArray)")
                                    
                                }
                                
                            }
                            
                        } else {
                            
                            displayAlert(viewController: self, title: "Error", message: "This wallet does not contain a public key and therefore we can not use it to create a multi sig wallet.")
                        }
                        
                    }
                    
                }
                
            }
            
        } else if indexPath.section == 2 {
            
            for (index, wallet) in self.addressBook.enumerated() {
                
                if self.coldMainnetArray[indexPath.row]["address"] as! String == wallet["address"] as! String{
                    
                    print("wallet = \(self.addressBook[index])")
                    
                    if multiSigMode != true {
                        
                        self.showKeyManagementAlert(wallet: self.addressBook[index], cell: cell)
                        
                    } else {
                        
                        if self.addressBook[index]["publicKey"] as! String != "" {
                            
                            if cell.isSelected {
                                
                                cell.isSelected = false
                                
                                if cell.accessoryType == UITableViewCellAccessoryType.none {
                                    
                                    cell.accessoryType = UITableViewCellAccessoryType.checkmark
                                    self.keyArray.append(self.addressBook[index])
                                    print("keyArray = \(self.keyArray)")
                                    
                                } else {
                                    
                                    cell.accessoryType = UITableViewCellAccessoryType.none
                                    self.keyArray.remove(at: indexPath.row)
                                    print("keyArray = \(self.keyArray)")
                                    
                                }
                                
                            }
                            
                        } else {
                            
                            displayAlert(viewController: self, title: "Error", message: "This wallet does not contain a public key and therefore we can not use it to create a multi sig wallet.")
                        }
                        
                    }
                    
                }
                
            }
            
        } else if indexPath.section == 3 {
            
            for (index, wallet) in self.addressBook.enumerated() {
                
                if self.coldTestnetArray[indexPath.row]["address"] as! String == wallet["address"] as! String{
                    
                    print("wallet = \(self.addressBook[index])")
                    
                    if multiSigMode != true {
                        
                        self.showKeyManagementAlert(wallet: self.addressBook[index], cell: cell)
                        
                    } else {
                        
                        if self.addressBook[index]["publicKey"] as! String != "" {
                           
                            //self.keyArray.append(self.addressBook[index])
                            if multiSigMode {
                                
                                if cell.isSelected {
                                    
                                    cell.isSelected = false
                                    //remove from keyArray
                                    
                                    if cell.accessoryType == UITableViewCellAccessoryType.none {
                                        
                                        cell.accessoryType = UITableViewCellAccessoryType.checkmark
                                        self.keyArray.append(self.addressBook[index])
                                        print("keyArray = \(self.keyArray)")
                                        
                                    } else {
                                        
                                        cell.accessoryType = UITableViewCellAccessoryType.none
                                        self.keyArray.remove(at: indexPath.row)
                                        print("keyArray = \(self.keyArray)")
                                        
                                    }
                                    
                                }
                                
                            }
                            
                        } else {
                            
                            displayAlert(viewController: self, title: "Error", message: "This wallet does not contain a public key and therefore we can not use it to create a multi sig wallet.")
                        }
                        
                        
                        
                    }
                    
                }
                
            }
            
        }
        
    }
    
    
    
    /*
     // Override to support conditional editing of the table view.
     override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
     // Return false if you do not want the specified item to be editable.
     return true
     }
     */
    
    
    
    
     // Override to support editing the table view.
     func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        
        if editingStyle == .delete {
            
            if indexPath.section == 0 {
                
                for (index, wallet) in self.addressBook.enumerated() {
                    
                    if self.hotMainnetArray[indexPath.row]["address"] as! String == wallet["address"] as! String {
                        
                        self.addressBook.remove(at: index)
                        UserDefaults.standard.set(self.addressBook, forKey: "addressBook")
                        
                    }
                    
                }
                
                self.hotMainnetArray.remove(at: indexPath.row)
                tableView.deleteRows(at: [indexPath], with: .fade)
                
            } else if indexPath.section == 1 {
                
                for (index, wallet) in self.addressBook.enumerated() {
                    
                    if self.hotTestnetArray[indexPath.row]["address"] as! String == wallet["address"] as! String {
                        
                        self.addressBook.remove(at: index)
                        UserDefaults.standard.set(self.addressBook, forKey: "addressBook")
                        
                    }
                    
                }
                
                self.hotTestnetArray.remove(at: indexPath.row)
                tableView.deleteRows(at: [indexPath], with: .fade)
                
            } else if indexPath.section == 2 {
                
                for (index, wallet) in self.addressBook.enumerated() {
                    
                    if self.coldMainnetArray[indexPath.row]["address"] as! String == wallet["address"] as! String {
                        
                        self.addressBook.remove(at: index)
                        UserDefaults.standard.set(self.addressBook, forKey: "addressBook")
                        
                    }
                    
                }
                
                self.coldMainnetArray.remove(at: indexPath.row)
                tableView.deleteRows(at: [indexPath], with: .fade)
                
            } else if indexPath.section == 3 {
                
                for (index, wallet) in self.addressBook.enumerated() {
                    
                    if self.coldTestnetArray[indexPath.row]["address"] as! String == wallet["address"] as! String{
                        
                        self.addressBook.remove(at: index)
                        UserDefaults.standard.set(self.addressBook, forKey: "addressBook")
                        
                    }
                    
                }
                
                self.coldTestnetArray.remove(at: indexPath.row)
                tableView.deleteRows(at: [indexPath], with: .fade)
                
            }
            
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
            
        }
        
     }
    
    
    /*
     // Override to support rearranging the table view.
     override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {
     
     }
     */
    
    /*
     // Override to support conditional rearranging of the table view.
     override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
     // Return false if you do not want the item to be re-orderable.
     return true
     }
     */
    
    func showKeyManagementAlert(wallet: [String: Any], cell: UITableViewCell) {
        
        DispatchQueue.main.async {
            
            let alert = UIAlertController(title: nil, message: "Please select an option", preferredStyle: UIAlertControllerStyle.actionSheet)
            
            if wallet["publicKey"] as! String != "" && wallet["redemptionScript"] as! String == "" || wallet["privateKey"] as! String != "" && wallet["redemptionScript"] as! String == "" {
                
                alert.addAction(UIAlertAction(title: NSLocalizedString("Create Multi-Sig", comment: ""), style: .default, handler: { (action) in
                    
                    self.multiSigMode = true
                    cell.accessoryType = UITableViewCellAccessoryType.checkmark
                    self.keyArray.append(wallet)
                    
                }))
                
            }
            
            
                
            alert.addAction(UIAlertAction(title: NSLocalizedString("Export Keys", comment: ""), style: .default, handler: { (action) in
                    
                self.addressToExport = wallet["address"] as! String
                self.privateKeyToExport = wallet["privateKey"] as! String
                self.performSegue(withIdentifier: "goHome", sender: self)
                    
            }))
                
 
            alert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: { (action) in
                
            }))
            
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    func checkBalance(address: String, index: Int, network: String, type: String) {
        print("checkBalance")
        
        addSpinner()
        var url:NSURL!
        var btcAmount = ""
        
        func getSegwitBalance() {
            
            let task = URLSession.shared.dataTask(with: url! as URL) { (data, response, error) -> Void in
                
                do {
                    
                    if error != nil {
                        
                        print(error as Any)
                        self.removeSpinner()
                        
                    } else {
                        
                        if let urlContent = data {
                            
                            do {
                                
                                let jsonAddressResult = try JSONSerialization.jsonObject(with: urlContent, options: JSONSerialization.ReadingOptions.mutableLeaves) as! NSDictionary
                                
                                if let btcAmountCheck = ((jsonAddressResult["data"] as? NSArray)?[0] as? NSDictionary)?["sum_value_unspent"] as? Double {
                                    
                                    let btcAmount = String(btcAmountCheck)
                                    
                                    if network == "mainnet" && type == "hot" {
                                        
                                        self.hotMainnetArray[index]["balance"] = " - " + btcAmount + " BTC"
                                        
                                    } else if network == "testnet" && type == "hot" {
                                        
                                        self.hotTestnetArray[index]["balance"] = " - " + btcAmount + " BTC"
                                        
                                    } else if network == "mainnet" && type == "cold" {
                                        
                                        self.coldMainnetArray[index]["balance"] = " - " + btcAmount + " BTC"
                                        
                                    } else if network == "testnet" && type == "cold" {
                                        
                                        self.coldTestnetArray[index]["balance"] = " - " + btcAmount + " BTC"
                                        
                                    }
                                    
                                    DispatchQueue.main.async {
                                        
                                        self.addressBookTable.reloadData()
                                        self.removeSpinner()
                                        
                                    }
                                    
                                } else {
                                    
                                    self.removeSpinner()
                                    
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
        }
        
        func getLegacyBalance() {
          
            let task = URLSession.shared.dataTask(with: url! as URL) { (data, response, error) -> Void in
                
                do {
                    
                    if error != nil {
                        
                        print(error as Any)
                        self.removeSpinner()
                        
                    } else {
                        
                        if let urlContent = data {
                            
                            do {
                                
                                let jsonAddressResult = try JSONSerialization.jsonObject(with: urlContent, options: JSONSerialization.ReadingOptions.mutableLeaves) as! NSDictionary
                                
                                if let finalBalanceCheck = jsonAddressResult["final_balance"] as? Double {
                                    
                                    btcAmount = String(finalBalanceCheck / 100000000)
                                    
                                    if network == "mainnet" && type == "hot" {
                                        
                                        self.hotMainnetArray[index]["balance"] = " - " + btcAmount + " BTC"
                                        
                                    } else if network == "testnet" && type == "hot" {
                                        
                                        self.hotTestnetArray[index]["balance"] = " - " + btcAmount + " BTC"
                                        
                                    } else if network == "mainnet" && type == "cold" {
                                        
                                        self.coldMainnetArray[index]["balance"] = " - " + btcAmount + " BTC"
                                        
                                    } else if network == "testnet" && type == "cold" {
                                        
                                        self.coldTestnetArray[index]["balance"] = " - " + btcAmount + " BTC"
                                        
                                    }
                                    
                                    DispatchQueue.main.async {
                                        
                                        self.addressBookTable.reloadData()
                                        self.removeSpinner()
                                        
                                        
                                    }
                                    
                                } else {
                                    
                                    self.removeSpinner()
                                    
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
            
        }
        
        if address.hasPrefix("1") || address.hasPrefix("3") {
            
            url = NSURL(string: "https://blockchain.info/rawaddr/\(address)")
            getLegacyBalance()
            
        } else if address.hasPrefix("m") || address.hasPrefix("2") || address.hasPrefix("n") {
            
            url = NSURL(string: "https://testnet.blockchain.info/rawaddr/\(address)")
            getLegacyBalance()
            
        } else if address.hasPrefix("b") {
            
            url = NSURL(string: "https://api.blockchair.com/bitcoin/dashboards/address/\(address)")
            getSegwitBalance()
            
        } else if address.hasPrefix("t") {
            
            displayAlert(viewController: self, title: "Error", message: "We are unable to find a balance for address: \(address).\n\nWe can not find a testnet blockexplorer that is bech32 compatible, if you know of one please email us at tripkeyapp@gmail.com")
            
        }
        
        
    }
    
    func addSpinner() {
        
        DispatchQueue.main.async {
            
            if self.imageView != nil {
              self.imageView.removeFromSuperview()
            }
            let bitcoinImage = UIImage(named: "img_311477.png")
            self.imageView = UIImageView(image: bitcoinImage!)
            self.imageView.center = self.view.center
            self.imageView.frame = CGRect(x: self.view.center.x - 25, y: 20, width: 50, height: 50)
            rotateAnimation(imageView: self.imageView as! UIImageView)
            self.view.addSubview(self.imageView)
            
        }
        
    }
    
    func removeSpinner() {
        
        DispatchQueue.main.async {
            
            self.imageView.removeFromSuperview()
            self.refresher.endRefreshing()
        }
    }

}
