import Foundation

struct AnyCodable: Codable {
    let value: Any
    
    init(_ value: Any) {
        self.value = value
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if container.decodeNil() {
            value = NSNull()
        } else if let bool = try? container.decode(Bool.self) {
            value = bool
        } else if let int = try? container.decode(Int.self) {
            value = int
        } else if let double = try? container.decode(Double.self) {
            value = double
        } else if let string = try? container.decode(String.self) {
            value = string
        } else {
            if let stops = try? container.decode([Stop].self) {
                value = stops
            } else if let stop = try? container.decode(Stop.self) {
                value = stop
            } else if let variants = try? container.decode([Variant].self) {
                value = variants
            } else if let variant = try? container.decode(Variant.self) {
                value = variant
            } else if let selectedVariants = try? container.decode([Variant].self) {
                value = selectedVariants
            } else if let selectedStops = try? container.decode([Stop].self) {
                value = selectedStops
            } else if let perferredStops = try? container.decode([Stop].self) {
                value = perferredStops
            } else if let array = try? container.decode([AnyCodable].self) {
                let decodedArray = array.map { $0.value }
                if let dictArray = decodedArray as? [[String: Any]] {
                    if !dictArray.isEmpty && dictArray[0]["number"] != nil && dictArray[0]["street"] != nil {
                        value = dictArray.map { Stop(from: $0) }
                    } else if !dictArray.isEmpty && dictArray[0]["key"] != nil && dictArray[0]["effective-from"] != nil {
                        value = dictArray.map { Variant(from: $0) }
                    } else {
                        value = decodedArray
                    }
                } else {
                    value = decodedArray
                }
            } else if let dictionary = try? container.decode([String: AnyCodable].self) {
                let decodedDict = dictionary.mapValues { $0.value }
                if decodedDict["number"] != nil && decodedDict["street"] != nil {
                    value = Stop(from: decodedDict)
                } else if decodedDict["key"] != nil && decodedDict["effective-from"] != nil {
                    value = Variant(from: decodedDict)
                } else {
                    value = decodedDict
                }
            } else {
                throw DecodingError.dataCorruptedError(in: container, debugDescription: "AnyCodable value cannot be decoded")
            }
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        switch value {
        case is NSNull:
            try container.encodeNil()
        case let bool as Bool:
            try container.encode(bool)
        case let int as Int:
            try container.encode(int)
        case let int8 as Int8:
            try container.encode(Int(int8))
        case let int16 as Int16:
            try container.encode(Int(int16))
        case let int32 as Int32:
            try container.encode(Int(int32))
        case let int64 as Int64:
            try container.encode(Int(int64))
        case let uint as UInt:
            try container.encode(Int(uint))
        case let uint8 as UInt8:
            try container.encode(Int(uint8))
        case let uint16 as UInt16:
            try container.encode(Int(uint16))
        case let uint32 as UInt32:
            try container.encode(Int(uint32))
        case let uint64 as UInt64:
            try container.encode(Int(uint64))
        case let float as Float:
            try container.encode(Double(float))
        case let double as Double:
            if double.isInfinite {
                try container.encode(double.isSignalingNaN ? "-infinity" : "infinity")
            } else if double.isNaN {
                try container.encode("nan")
            } else {
                try container.encode(double)
            }
        case let cgFloat as CGFloat:
            let doubleValue = Double(cgFloat)
            if doubleValue.isInfinite {
                try container.encode(doubleValue.isSignalingNaN ? "-infinity" : "infinity")
            } else if doubleValue.isNaN {
                try container.encode("nan")
            } else {
                try container.encode(doubleValue)
            }
        case let string as String:
            try container.encode(string)
        case let date as Date:
            try container.encode(date.timeIntervalSince1970)
        case let url as URL:
            try container.encode(url.absoluteString)
        case let stops as [Stop]:
            try container.encode(stops)
        case let stop as Stop:
            try container.encode(stop)
        case let variants as [Variant]:
            try container.encode(variants)
        case let variant as Variant:
            try container.encode(variant)
        case let array as [Any]:
            let encodableArray = try array.map { element -> AnyCodable in
                let testCodable = AnyCodable(element)
                _ = try JSONEncoder().encode(testCodable)
                return testCodable
            }
            try container.encode(encodableArray)
        case let dict as [String: Any]:
            let encodableDict = try dict.compactMapValues { value -> AnyCodable? in
                do {
                    let testCodable = AnyCodable(value)
                    _ = try JSONEncoder().encode(testCodable)
                    return testCodable
                } catch {
                    return nil
                }
            }
            try container.encode(encodableDict)
        default:
            let typeName = String(describing: type(of: value))
            
            if let stringValue = "\(value)" as String? {
                try container.encode(stringValue)
            } else {
                let context = EncodingError.Context(
                    codingPath: container.codingPath,
                    debugDescription: "AnyCodable cannot encode type: \(typeName)"
                )
                throw EncodingError.invalidValue(value, context)
            }
        }
    }
}

