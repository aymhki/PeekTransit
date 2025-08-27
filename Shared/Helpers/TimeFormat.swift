enum TimeFormat: String, CaseIterable {
    case clockTime = "HH:MM AM/PM"
    case minutesRemaining = "X(X) Minutes remaining"

    static var `default`: TimeFormat {
        return .minutesRemaining
    }
    
    var formattedValue: String {
        switch self {
        case .clockTime:
            return "HH:MM \(getGlobalAMText())/\(getGlobalPMText())"
        case .minutesRemaining:
            return self.rawValue
        }
    }
    
    var `description`: String {
        switch self {
        case .minutesRemaining:
            return "X(X) Minutes remaining when the bus is within 15 minutes with \(getLateStatusTextString()) (L.) and \(getEarlyStatusTextString()) (E.) prefix"
        case .clockTime:
            return "Always clock Time (HH:MM \(getGlobalAMText())/\(getGlobalPMText()) without \(getLateStatusTextString()) (L.) and \(getEarlyStatusTextString()) (E.) prefix"
        }
    }
    
    var `brief`: String {
        switch self {
        case .minutesRemaining:
            return "X(X) \(getMinutesRemainingTextInArrivalTimes())"
        case .clockTime:
            return "HH:MM \(getGlobalAMText())/\(getGlobalPMText())"
        }
    }
}
