import Foundation
import SwiftUI

struct Stop: Hashable, Codable {
    var key: Int
    var name: String
    let number: Int
    var effectiveFrom: Date?
    var effectiveTo: Date?
    var direction: String
    var side: String
    var street: Street
    var crossStreet: Street
    var centre: Centre
    var distance: Double
    var variants: [Variant] = []
    var selectedVariants: [Variant] = []
    
    private enum CodingKeys: String, CodingKey {
        case key, name, number, direction, side, street, centre, distance, variants, selectedVariants
        case effectiveFrom = "effective-from"
        case effectiveTo = "effective-to"
        case crossStreet = "cross-street"
    }
    
    init(from json: [String: Any]) {
        let key = json["key"] as? Int ?? -1
        let name = json["name"] as? String ?? "Unknown Stop"
        let number = json["number"] as? Int ?? -1
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        
        let effectiveFromString = json["effective-from"] as? String ?? ""
        let effectiveToString = json["effective-to"] as? String ?? ""
        let effectiveFrom = dateFormatter.date(from: effectiveFromString) ?? nil
        let effectiveTo = dateFormatter.date(from: effectiveToString) ?? nil
        
        let direction = json["direction"] as? String ?? "Unknown Direction"
        let side = json["side"] as? String ?? "Unknown Side"
        
        let streetData = json["street"] as? [String: Any] ?? [:]
        let crossStreetData = json["cross-street"] as? [String: Any] ?? [:]
        let centreData = json["centre"] as? [String: Any] ?? [:]
        
        let street = Street(from: streetData)
        let crossStreet = Street(from: crossStreetData)
        let centre = Centre(from: centreData)
        var distanceValue: Double = Double.infinity
        
        if let distances = json["distances"] as? [String: Any],
           let firstDistance = distances.first,
           let distanceDouble = firstDistance.value as? Double {
            distanceValue = distanceDouble
        } else if let distances = json["distances"] as? [String: Any],
                  let firstDistance = distances.first,
                  let distanceString = firstDistance.value as? String,
                  let distance = Double(distanceString) {
            distanceValue = distance
        }
        
        var variantsList: [Variant] = []
        if let variantsData = json["variants"] as? [[String: Any]] {
            variantsList = variantsData.compactMap { variantDict in
                guard !variantDict.isEmpty else { return nil }
                return Variant(from: variantDict)
            }
        }

        self.key = key
        self.name = name
        self.number = number
        self.effectiveFrom = effectiveFrom
        self.effectiveTo = effectiveTo
        self.direction = direction
        self.side = side
        self.street = street
        self.crossStreet = crossStreet
        self.centre = centre
        self.distance = distanceValue
        self.variants = variantsList
        self.selectedVariants = json["selectedVariants"] as? [Variant] ?? []
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        key = try container.decode(Int.self, forKey: .key)
        name = try container.decode(String.self, forKey: .name)
        number = try container.decode(Int.self, forKey: .number)
        effectiveFrom = try container.decode(Date.self, forKey: .effectiveFrom)
        effectiveTo = try container.decode(Date.self, forKey: .effectiveTo)
        direction = try container.decode(String.self, forKey: .direction)
        side = try container.decode(String.self, forKey: .side)
        street = try container.decode(Street.self, forKey: .street)
        crossStreet = try container.decode(Street.self, forKey: .crossStreet)
        centre = try container.decode(Centre.self, forKey: .centre)
        distance = try container.decode(Double.self, forKey: .distance)
        variants = try container.decodeIfPresent([Variant].self, forKey: .variants) ?? []
        selectedVariants = try container.decodeIfPresent([Variant].self, forKey: .selectedVariants) ?? []
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(key, forKey: .key)
        try container.encode(name, forKey: .name)
        try container.encode(number, forKey: .number)
        try container.encode(effectiveFrom, forKey: .effectiveFrom)
        try container.encode(effectiveTo, forKey: .effectiveTo)
        try container.encode(direction, forKey: .direction)
        try container.encode(side, forKey: .side)
        try container.encode(street, forKey: .street)
        try container.encode(crossStreet, forKey: .crossStreet)
        try container.encode(centre, forKey: .centre)
        try container.encode(distance, forKey: .distance)
        try container.encode(variants, forKey: .variants)
        try container.encode(selectedVariants, forKey: .selectedVariants)
    }
    
    public static func == (lhs: Stop, rhs: Stop) -> Bool {
        return lhs.key == rhs.key &&
               lhs.name == rhs.name &&
               lhs.number == rhs.number &&
               lhs.direction == rhs.direction &&
               lhs.side == rhs.side &&
               lhs.street == rhs.street &&
               lhs.crossStreet == rhs.crossStreet &&
               lhs.centre == rhs.centre
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(key)
        hasher.combine(name)
        hasher.combine(number)
        hasher.combine(direction)
        hasher.combine(side)
        hasher.combine(street)
        hasher.combine(crossStreet)
        hasher.combine(centre)
    }
}

struct Street: Hashable, Codable {
    let key: Int
    let name: String
    let type: String
    
    init(from street: [String: Any]) {
        let key = street["key"] as? Int ?? -1
        let name = street["name"] as? String ?? "Unknown Street"
        let type = street["type"] as? String ?? "Unknown Type"
        
        self.key = key
        self.name = name
        self.type = type
    }
    
    public static func == (lhs: Street, rhs: Street) -> Bool {
        return lhs.key == rhs.key && lhs.name == rhs.name && lhs.type == rhs.type
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(key)
        hasher.combine(name)
        hasher.combine(type)
    }
}

struct Centre: Hashable, Codable {
    let utm: UTM
    let geographic: Geographic
    
    init(from centre: [String: Any]) {
        let utmData = centre["utm"] as? [String: Any] ?? [:]
        let geographicData = centre["geographic"] as? [String: Any] ?? [:]
        
        self.utm = UTM(from: utmData)
        self.geographic = Geographic(from: geographicData)
    }
    
    public static func == (lhs: Centre, rhs: Centre) -> Bool {
        return lhs.utm == rhs.utm && lhs.geographic == rhs.geographic
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(utm)
        hasher.combine(geographic)
    }
}

struct UTM: Hashable, Codable {
    let zone: String
    let x: Int
    let y: Int
    
    init(from utm: [String: Any]) {
        let zone = utm["zone"] as? String ?? "Unknown Zone"
        let x = utm["x"] as? Int ?? 0
        let y = utm["y"] as? Int ?? 0
        
        self.zone = zone
        self.x = x
        self.y = y
    }
    
    public static func == (lhs: UTM, rhs: UTM) -> Bool {
        return lhs.zone == rhs.zone && lhs.x == rhs.x && lhs.y == rhs.y
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(zone)
        hasher.combine(x)
        hasher.combine(y)
    }
}

struct Geographic: Hashable, Codable {
    let latitude: Double
    let longitude: Double
    
    init(from geographic: [String: Any]) {
        let latitude = geographic["latitude"] as? Double ?? 0.0
        let longitude = geographic["longitude"] as? Double ?? 0.0
        
        self.latitude = latitude
        self.longitude = longitude
    }
    
    public static func == (lhs: Geographic, rhs: Geographic) -> Bool {
        return lhs.latitude == rhs.latitude && lhs.longitude == rhs.longitude
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(latitude)
        hasher.combine(longitude)
    }
}

struct Variant: Hashable, Codable {
    var key: String
    var name: String
    var effectiveFrom: Date?
    var effectiveTo: Date?
    var backgroundColor: Color?
    var borderColor: Color?
    var textColor: Color?
    
    enum CodingKeys: String, CodingKey {
        case key
        case name
        case effectiveFrom = "effective-from"
        case effectiveTo = "effective-to"
        case backgroundColor = "background-color"
        case borderColor = "border-color"
        case textColor = "text-color"
    }
    
    init(from variant: [String: Any]) {
        key = variant["key"] as? String ?? "Undefined Key"
        name = variant["name"] as? String ?? "Unknown Name"
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        
        let effectiveFromString = variant["effective-from"] as? String ?? ""
        let effectiveToString = variant["effective-to"] as? String ?? ""
        let effectiveFrom = dateFormatter.date(from: effectiveFromString) ?? nil
        let effectiveTo = dateFormatter.date(from: effectiveToString) ?? nil
        
        self.effectiveFrom = effectiveFrom
        self.effectiveTo = effectiveTo
        
        let backgroundColorHex = variant["background-color"] as? String ?? "None"
        let borderColorHex = variant["border-color"] as? String ?? "None"
        let textColorHex = variant["text-color"] as? String ?? "None"
        
        if backgroundColorHex != "None" {
            self.backgroundColor = Color(hex: backgroundColorHex)
        }
        
        if borderColorHex != "None" {
            self.borderColor = Color(hex: borderColorHex)
        }
        
        if textColorHex != "None" {
            self.textColor = Color(hex: textColorHex)
        }
        
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        key = try container.decode(String.self, forKey: .key)
        name = try container.decode(String.self, forKey: .name)
        effectiveFrom = try container.decode(Date.self, forKey: .effectiveFrom)
        effectiveTo = try container.decode(Date.self, forKey: .effectiveTo)
        
        if let backgroundColorHex = try? container.decodeIfPresent(String.self, forKey: .backgroundColor) {
            backgroundColor = Color(hex: backgroundColorHex)
        } else {
            backgroundColor = nil
        }
           
        if let borderColorHex = try? container.decodeIfPresent(String.self, forKey: .borderColor) {
            borderColor = Color(hex: borderColorHex)
        } else {
            borderColor = nil
        }
        
        if let textColorHex = try? container.decodeIfPresent(String.self, forKey: .textColor) {
            textColor = Color(hex: textColorHex)
        } else {
            textColor = nil
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(key, forKey: .key)
        try container.encode(name, forKey: .name)
        try container.encode(effectiveFrom, forKey: .effectiveFrom)
        try container.encode(effectiveTo, forKey: .effectiveTo)

        if let backgroundColor = backgroundColor {
            try container.encode(backgroundColor.toHex(), forKey: .backgroundColor)
        } else {
            try container.encode("None", forKey: .backgroundColor)
        }
        
        if let borderColor = borderColor {
            try container.encode(borderColor.toHex(), forKey: .borderColor)
        } else {
            try container.encode("None", forKey: .borderColor)
        }
        
        if let textColor = textColor {
            try container.encode(textColor.toHex(), forKey: .textColor)
        } else {
            try container.encode("None", forKey: .textColor)
        }
    }
    
    public static func == (lhs: Variant, rhs: Variant) -> Bool {
        return lhs.key.split(separator: "-")[0] == rhs.key.split(separator: "-")[0] && lhs.name == rhs.name // && lhs.effectiveTo == rhs.effectiveTo && lhs.effectiveFrom == rhs.effectiveFrom
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(key.split(separator: "-")[0])
        hasher.combine(name)
//        hasher.combine(effectiveFrom)
//        hasher.combine(effectiveTo)
    }
}

struct Route: Codable, Hashable {
    let key: String
    let name: String
    let textColor: String
    let backgroundColor: String
    let borderColor: String
    var variants: [Variant]?
    
    
    enum CodingKeys: String, CodingKey {
        case key
        case name
        case textColor = "text_color"
        case backgroundColor = "background_color"
        case borderColor = "border_color"
        case variants
    }
    
    init(key: String, name: String, textColor: String, backgroundColor: String, borderColor: String, variants: [Variant]? = nil) {
        self.key = key
        self.name = name
        self.textColor = textColor
        self.backgroundColor = backgroundColor
        self.borderColor = borderColor
        self.variants = variants
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        key = try container.decode(String.self, forKey: .key)
        name = try container.decode(String.self, forKey: .name)
        textColor = try container.decode(String.self, forKey: .textColor)
        backgroundColor = try container.decode(String.self, forKey: .backgroundColor)
        borderColor = try container.decode(String.self, forKey: .borderColor)
        variants = try container.decodeIfPresent([Variant].self, forKey: .variants)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(key, forKey: .key)
        try container.encode(name, forKey: .name)
        try container.encode(textColor, forKey: .textColor)
        try container.encode(backgroundColor, forKey: .backgroundColor)
        try container.encode(borderColor, forKey: .borderColor)
        try container.encodeIfPresent(variants, forKey: .variants)
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(key)
        hasher.combine(name)
        hasher.combine(textColor)
        hasher.combine(backgroundColor)
        hasher.combine(borderColor)
        if let variants = variants {
            hasher.combine(variants)
        }
    }
}
