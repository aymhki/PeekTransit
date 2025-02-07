enum TimeFormat: String, CaseIterable {
    case clockTime = "HH:MM AM/PM"
    case minutesRemaining = "X(X) Minutes remaining"

    static var `default`: TimeFormat {
        return .minutesRemaining
    }
    
    var description: String {
        switch self {
        case .minutesRemaining:
            return "X(X) Minutes remaining when the bus is within 15 minutes with Late (L.) and Early (E.) prefix"
        case .clockTime:
            return "Always clock Time (HH:MM AM/PM) without Late (L.) and Early (E.) prefix"
        }
    }
}
