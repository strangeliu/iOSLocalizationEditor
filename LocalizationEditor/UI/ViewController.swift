//
//  ViewController.swift
//  LocalizationEditor
//
//  Created by Igor Kulman on 30/05/2018.
//  Copyright © 2018 Igor Kulman. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {

    // MARK: - Outlets

    @IBOutlet private weak var tableView: NSTableView!
    @IBOutlet private weak var selectButton: NSPopUpButton!
    @IBOutlet private weak var progressIndicator: NSProgressIndicator!
    @IBOutlet private var defaultSelectItem: NSMenuItem!

    // MARK: - Properties

    private let dataSource = LocalizationsDataSource()

    override func viewDidLoad() {
        super.viewDidLoad()

        setupMenu()
        setupData()
    }

    // MARK: - Setup

    private func setupMenu() {
        let appDelegate = NSApplication.shared.delegate as! AppDelegate
        appDelegate.openFolderMenuItem.action = #selector(ViewController.openAction(sender:))
        selectButton.menu?.removeAllItems();
        selectButton.menu?.addItem(defaultSelectItem)
    }

    private func setupData() {
        let cellIdentifiers = [KeyCell.identifier, LocalizationCell.identifier]
        cellIdentifiers.forEach { identifier in
            let cell = NSNib(nibNamed: NSNib.Name(rawValue: identifier), bundle: nil)
            tableView.register(cell, forIdentifier: NSUserInterfaceItemIdentifier(rawValue: identifier))
        }

        tableView.delegate = self
        tableView.dataSource = dataSource
    }
    
    private func setupSetupLocalizationSelectionMenu(files: [LocalizationGroup]){
        selectButton.menu?.removeAllItems()
        files.map({NSMenuItem(title: $0.name, action: #selector(ViewController.selectAction(sender:)), keyEquivalent: "")}).forEach({selectButton.menu?.addItem($0)})
    }

    private func reloadData(with languages: [String], title: String?) {
        let prefix = "LocalizationEditor"
        self.view.window?.title = title.flatMap({"\(prefix) [\($0)]"}) ?? prefix // TODO

        let columns = tableView.tableColumns
        columns.forEach {
            self.tableView.removeTableColumn($0)
        }

        let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("key"))
        column.title = ""
        tableView.addTableColumn(column)

        languages.forEach { language in
            let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier(language))
            column.title = language == "Base" ? language : "\(emojiFlag(countryCode: language)) \(language.uppercased())"
            self.tableView.addTableColumn(column)
        }

        tableView.reloadData()
    }

    private func emojiFlag(countryCode: String) -> String {
        var string = ""
        var country = countryCode.uppercased()
        for uS in country.unicodeScalars {
            if let scalar = UnicodeScalar(127_397 + uS.value) {
                string.append(String(scalar))
            }
        }
        return string
    }
    
    @IBAction @objc func selectAction(sender: NSMenuItem) {
        let title = sender.title
        let languages = self.dataSource.select(name: title)

        self.reloadData(with: languages, title:title)
    }

    @IBAction @objc func openAction(sender _: NSMenuItem) {
        let openPanel = NSOpenPanel()
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseDirectories = true
        openPanel.canCreateDirectories = true
        openPanel.canChooseFiles = false
        openPanel.begin { [unowned self] (result) -> Void in
            if result.rawValue == NSApplication.ModalResponse.OK.rawValue {
                if let url = openPanel.url {
                    self.progressIndicator.startAnimation(self)
                    self.dataSource.load(folder: url) { [unowned self] languages, title, localizationFiles in
                        self.reloadData(with: languages, title:title)
                        self.progressIndicator.stopAnimation(self)

                        if let title = title{
                            self.setupSetupLocalizationSelectionMenu(files: localizationFiles)
                            self.selectButton.selectItem(at: self.selectButton.indexOfItem(withTitle: title))
                        }
                        else {
                            self.setupMenu()
                        }
                    }
                }
            }
        }
    }
    
    override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
        if let controller = segue.destinationController as? NSWindowController, let c = controller.contentViewController as? AddStringViewController {
            c.dataSource = self.dataSource
            c.didAddKey = {
                self.tableView.reloadData()
            }
        }
    }
    
    override func performSegue(withIdentifier identifier: NSStoryboard.SegueIdentifier, sender: Any?) {
        
    }
}

// MARK: - Delegate

extension ViewController: NSTableViewDelegate {
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard let identifier = tableColumn?.identifier else {
            return nil
        }

        switch identifier.rawValue {
        case "key":
            let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: KeyCell.identifier), owner: self)! as! KeyCell
            if let key = dataSource.getKey(row: row) {
                cell.key = key
                return cell
            } else {
                let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: LocalizationCell.identifier), owner: self)! as! LocalizationCell
                return cell
            }
        default:
            let language = identifier.rawValue
            let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: LocalizationCell.identifier), owner: self)! as! LocalizationCell
            cell.delegate = self
            cell.language = language
            cell.value = row < dataSource.numberOfRows(in: tableView) ? dataSource.getLocalization(language: language, row: row) : nil
            return cell
        }
    }
    
    
}

extension ViewController: LocalizationCellDelegate {
    
    func userDidUpdateLocalizationString(language: String, string: LocalizationString, with value: String) {
        dataSource.updateLocalization(language: language, string: string, with: value)
    }
}
