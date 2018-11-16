//
//  Localization.swift
//  LocalizationEditor
//
//  Created by Igor Kulman on 30/05/2018.
//  Copyright © 2018 Igor Kulman. All rights reserved.
//

import Foundation

class Localization {
    
    private(set) var translations: [LocalizationString]
    
    let language: String
    let path: String

    init(language: String, translations: [LocalizationString], path: String) {
        self.language = language
        self.translations = translations
        self.path = path
    }
    
    func add(string: LocalizationString) {
        if let existString = translations.filter({$0.key == string.key}).first {
            existString.update(value: string.value)
        } else {
            translations.append(string)
            translations.sort { (lhs, rhs) -> Bool in
                lhs.key < rhs.key
            }
        }
    }
}

extension Localization: CustomStringConvertible {
    var description: String {
        return language.uppercased()
    }
}
