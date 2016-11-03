//
//  Parameter.swift
//  JenkinsiOS
//
//  Created by Robert on 30.10.16.
//  Copyright © 2016 MobiLab Solutions. All rights reserved.
//

import Foundation

class Parameter: Hashable, Equatable{
    
    var type: ParameterType
    var description: String
    var name: String
    
    var defaultParameterValue: Any?
    var defaultParameterString: String?
    
    var additionalData: AnyObject?
    
    init?(json: [String: Any]) {
        guard let typeString = json[Constants.JSON.type] as? String,
              let name = json[Constants.JSON.name] as? String,
              let description = json[Constants.JSON.description] as? String
            else { return nil }
        
        self.type = ParameterType(value: typeString)
        self.name = name
        self.description = description
        
        if let defaultParameter = json[Constants.JSON.defaultParameterValue] as? [String: Any]{
            defaultParameterValue = defaultParameter[Constants.JSON.value] as? String
            defaultParameterString = defaultParameter[Constants.JSON.value] as? String
        }
        
        if let additionalDataString = type.additionalDataString(){
            additionalData = json[additionalDataString] as AnyObject?
        }
    }
    
    var hashValue: Int{
        return "\(name),\(type.rawValue)".hashValue
    }
}

func ==(rhs: Parameter, lhs: Parameter) -> Bool{
    return rhs.hashValue == lhs.hashValue
}
