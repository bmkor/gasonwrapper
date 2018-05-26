//
//  JSON.swift
//  gasonwrapper
//
//  Created by Benjamin on 19/5/2018.
//  Copyright © 2018 Benjamin. All rights reserved.
//

import Foundation
import JSONPrivate

public enum JSONType{
    case JSON_NUMBER
    case JSON_STRING
    case JSON_ARRAY
    case JSON_OBJECT
    case JSON_BOOL
    case JSON_NULL
}

open class JSON{
    fileprivate var j:JSONPrivate
    
    public init(data:Data) throws{
        do {
            j = try JSONPrivate(data: data)
        } catch let e as NSError{
            throw e
        }
    }
    
    private init(JSON:JSONPrivate) {
        j = JSON
    }
    
    public var getType:JSONType{
        switch j.type() {
        case .json_array:
            return JSONType.JSON_ARRAY
        case .json_false, .json_true:
            return JSONType.JSON_BOOL
        case .json_null:
            return JSONType.JSON_NULL
        case .json_number:
            return JSONType.JSON_NUMBER
        case .json_object:
            return JSONType.JSON_OBJECT
        case .json_string:
            return JSONType.JSON_STRING
        }
    }
    
    public var array:[JSON]?{
        get{
            return j.array()?.compactMap({JSON(JSON: $0)})
        }
    }
    
    public var object:[String:JSON]?{
        get{
            return j.object()?.reduce([:], { (dict, j) -> [String:JSON] in
                var d = dict
                d[j.key] = JSON(JSON: j.value)
                return d
            })
        }
    }
    
    public var bool:Bool?{
        get{
            guard let b = j.toBool() else {return nil}
            return b == NSNumber(value: true) ? true : false
        }
    }
    
    public var float:Float?{
        get{
            return j.toNumber()?.floatValue
        }
    }
    
    public var int:Int?{
        get{
            return j.toNumber()?.intValue
        }
    }
    
    public var double:Double?{
        get{
            return j.toNumber()?.doubleValue
        }
    }
    
    public var string:String?{
        get{
            return j.toString()
        }
    }
    
    
    public subscript(index: UInt) -> JSON?{
        get{
            guard let jz = j[index] else {return nil}
            return JSON(JSON: jz)
        }
    }
    
    public subscript(key: String) -> JSON?{
        get{
            guard let jz = j[key] else {return nil}
            return JSON(JSON: jz)
        }
    }
}

extension JSON:CustomStringConvertible{
    public var description: String{
        get{
            return j.description
        }
    }
}
