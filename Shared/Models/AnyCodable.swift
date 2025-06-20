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
                value = array.map { $0.value }
            } else if let dictionary = try? container.decode([String: AnyCodable].self) {
                value = dictionary.mapValues { $0.value }
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
        case let double as Double:
            try container.encode(double)
        case let string as String:
            try container.encode(string)
        case let stops as [Stop]:
            try container.encode(stops)
        case let stop as Stop:
            try container.encode(stop)
        case let variants as [Variant]:
            try container.encode(variants)
        case let variant as Variant:
            try container.encode(variant)
        default:
            if let stops = value as? [Stop] {
                try container.encode(stops)
            } else if let stop = value as? Stop {
                try container.encode(stop)
            } else if let variants = value as? [Variant] {
                try container.encode(variants)
            } else if let variant = value as? Variant {
                try container.encode(variant)
            } else if let selectedStops = value as? [Stop] {
                try container.encode(selectedStops)
            } else if let perferredStops = value as? [Stop] {
                try container.encode(perferredStops)
            } else if let selectedVariants = value as? [Variant] {
                try container.encode(selectedVariants)
            } else if let  array = value as? [Any] {
                try container.encode(array.map { AnyCodable($0) })
            } else if let dict = value as? [String: Any] {
                try container.encode(dict.mapValues { AnyCodable($0) })
            } else {
                let context = EncodingError.Context(codingPath: container.codingPath, debugDescription: "AnyCodable value cannot be encoded")
                throw EncodingError.invalidValue(value, context)
            }
        }
    }
}
