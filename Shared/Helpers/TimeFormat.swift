enum TimeFormat: String, CaseIterable {
    case clockTime = "HH:MM AM/PM"
    case minutesRemaining = "X(X) Minutes remaining"

    static var `default`: TimeFormat {
        return .minutesRemaining
    }
    
    var `description`: String {
        switch self {
        case .minutesRemaining:
            return "X(X) Minutes remaining when the bus is within 15 minutes with \(getLateStatusTextString()) (L.) and \(getEarlyStatusTextString()) (E.) prefix"
        case .clockTime:
            return "Always clock Time (HH:MM AM/PM) without \(getLateStatusTextString()) (L.) and \(getEarlyStatusTextString()) (E.) prefix"
        }
    }
    
    var `brief`: String {
        switch self {
        case .minutesRemaining:
            return "X(X) min."
        case .clockTime:
            return "HH:MM AM/PM"
        }
    }
}
