import SwiftUI
import MapKit

struct TripSegment {
    let type: SegmentType
    let startTime: Date
    let endTime: Date
    let duration: Int
    let routeKey: Int?
    let routeNumber: String?
    let routeName: String?
    let variantKey: String?
    let variantName: String?
    let fromStop: StopInfo?
    let toStop: StopInfo?
    
    init(from dict: [String: Any], parsedSegments: [TripSegment], currentSegmentIndex: Int, segmentsArray: [[String: Any]]) throws {
        guard let typeString = dict["type"] as? String,
              let type = SegmentType(rawValue: typeString),
              let times = dict["times"] as? [String: Any],
              let startTimeStr = times["start"] as? String,
              let endTimeStr = times["end"] as? String,
              let durations = times["durations"] as? [String: Any],
              let totalDuration = durations["total"] as? Int else {
            throw TransitError.parseError("Invalid trip segment data")
        }
        
        let dateFormatter = ISO8601DateFormatter()
        
        // Initialize basic properties first
        self.type = type
        self.startTime = dateFormatter.date(from: startTimeStr) ?? Date()
        self.endTime = dateFormatter.date(from: endTimeStr) ?? Date()
        self.duration = totalDuration
        
        // Handle route information
        if type == .ride, let routeDict = dict["route"] as? [String: Any] {
            self.routeKey = routeDict["key"] as? Int
            
            if let routeNumStr = routeDict["number"] as? String {
                self.routeNumber = routeNumStr
            } else if let routeNumInt = routeDict["number"] as? Int {
                self.routeNumber = String(routeNumInt)
            } else {
                self.routeNumber = nil
            }
            
            self.routeName = routeDict["name"] as? String
            
            if let variantDict = dict["variant"] as? [String: Any] {
                self.variantKey = variantDict["key"] as? String
                self.variantName = variantDict["name"] as? String
            } else {
                self.variantKey = nil
                self.variantName = nil
            }
        } else {
            self.routeKey = nil
            self.routeNumber = nil
            self.routeName = nil
            self.variantKey = nil
            self.variantName = nil
        }
        
        // Handle fromStop
        let fromStopInfo: StopInfo?
        if let from = dict["from"] as? [String: Any] {
            if let stopDict = from["stop"] as? [String: Any] {
                fromStopInfo = StopInfo(from: stopDict)
            } else if from["origin"] as? [String: Any] != nil {
                fromStopInfo = StopInfo(name: "Current Location")
            } else {
                fromStopInfo = TripSegment.getLastValidStopInfo(from: segmentsArray, currentIndex: currentSegmentIndex)
            }
        } else {
            fromStopInfo = TripSegment.getLastValidStopInfo(from: segmentsArray, currentIndex: currentSegmentIndex)
        }
        
        // Handle toStop
        let toStopInfo: StopInfo?
        if let to = dict["to"] as? [String: Any] {
            if let stopDict = to["stop"] as? [String: Any] {
                toStopInfo = StopInfo(from: stopDict)
            } else if to["destination"] as? [String: Any] != nil {
                toStopInfo = StopInfo(name: "Destination")
            } else {
                toStopInfo = TripSegment.getNextValidStopInfo(from: segmentsArray, currentIndex: currentSegmentIndex)
            }
        } else {
            toStopInfo = TripSegment.getNextValidStopInfo(from: segmentsArray, currentIndex: currentSegmentIndex)
        }
        
        self.fromStop = fromStopInfo
        self.toStop = toStopInfo
    }
    
    // Changed to static method
    private static func getLastValidStopInfo(from segments: [[String: Any]], currentIndex: Int) -> StopInfo {
        // Start from the current index and go backwards
        for index in (0..<currentIndex).reversed() {
            let segment = segments[index]
            if let to = segment["to"] as? [String: Any],
               let stopDict = to["stop"] as? [String: Any],
               let stopInfo = StopInfo(from: stopDict),
               stopInfo.key != -1,
               stopInfo.location != nil {
                return stopInfo
            }
        }
        return StopInfo(name: "Unknown Location")
    }
    
    // Changed to static method
    private static func getNextValidStopInfo(from segments: [[String: Any]], currentIndex: Int) -> StopInfo {
        // Start from the current index and go forwards
        for index in (currentIndex + 1)..<segments.count {
            let segment = segments[index]
            if let from = segment["from"] as? [String: Any],
               let stopDict = from["stop"] as? [String: Any],
               let stopInfo = StopInfo(from: stopDict),
               stopInfo.key != -1,
               stopInfo.location != nil {
                return stopInfo
            }
        }
        return StopInfo(name: "Unknown Location")
    }
}
