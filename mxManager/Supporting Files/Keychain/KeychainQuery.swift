//
//  KeychainQuery.swift
//  SwiftKeychain
//
//  Created by Yanko Dimitrov on 11/13/14.
//  Copyright (c) 2014 Yanko Dimitrov. All rights reserved.
//

import Foundation

public class KeychainQuery {
    
    private lazy var queryFields = NSMutableDictionary()
    
    var fields: NSDictionary {
        
        return queryFields
    }
    
    ///////////////////////////////////////////////////////
    // MARK: - Initializers
    ///////////////////////////////////////////////////////
    
    init(keychain: KeychainService) {
        
        addField(kSecAttrAccessible, withValue: keychain.accessMode)
        
        if let accessGroup = keychain.accessGroup {
            
            addField(kSecAttrAccessGroup, withValue: accessGroup)
        }
    }
    
    ///////////////////////////////////////////////////////
    // MARK: - Methods
    ///////////////////////////////////////////////////////
    
    func shouldReturnData() {
        
        addField(kSecReturnData, withValue: true)
    }
    
    func addField(field: String, withValue value: AnyObject) {
        
        queryFields.setObject(value, forKey: field)
    }
    
    func addFields(fields: NSDictionary) {
        
        queryFields.addEntriesFromDictionary(fields)
    }
}
