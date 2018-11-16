//
//  AddStringViewController.swift
//  LocalizationEditor
//
//  Created by Liu on 2018/11/16.
//  Copyright © 2018 Igor Kulman. All rights reserved.
//

import Foundation
import Cocoa

class AddStringViewController: NSViewController {
    
    @IBOutlet weak var textField: NSTextField!
    
    var dataSource: LocalizationsDataSource?
    
    var didAddKey: (() -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    @IBAction func addButtonAction(_ sender: Any) {
        let key = textField.stringValue
        guard !key.isEmpty else {
            return
        }
        dataSource?.add(key: key)
        didAddKey?()
        self.view.window?.close()
    }
    
    @IBAction func cancelButtonAction(_ sender: Any) {
        self.view.window?.close()
    }
    
}
