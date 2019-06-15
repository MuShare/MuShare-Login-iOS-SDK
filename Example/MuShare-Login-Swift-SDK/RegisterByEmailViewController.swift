//
//  RegisterByEmailViewController.swift
//  MuShare-Login-Swift-SDK_Example
//
//  Created by Meng Li on 2019/6/15.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import UIKit
import MuShareLogin

class RegisterByEmailViewController: UIViewController {
    
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var nameTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func submit(_ sender: Any) {
        guard
            let address = emailTextField.text, !address.isEmpty,
            let password = passwordTextField.text, !password.isEmpty,
            let name = nameTextField.text, !name.isEmpty
        else {
            return
        }
        MuShareLogin.shared.registerByEmail(address: address, password: password, name: name, success: {
            
        })
    }
    
}
