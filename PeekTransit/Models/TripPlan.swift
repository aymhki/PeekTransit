import Foundation
import CoreLocation

struct TripPlan {
    let planNumber: Int
    let startTime: Date
    let endTime: Date
    let duration: Int
    let walkingDuration: Int
    let waitingDuration: Int
    let ridingDuration: Int
    let segments: [TripSegment]
    
    init(from planDict: [String: Any]) throws {
        guard let planNumber = planDict["number"] as? Int,
              let times = planDict["times"] as? [String: Any],
              let startTimeStr = times["start"] as? String,
              let endTimeStr = times["end"] as? String,
              let durations = times["durations"] as? [String: Any],
              let totalDuration = durations["total"] as? Int,
              let walkingDuration = durations["walking"] as? Int,
              let waitingDuration = durations["waiting"] as? Int,
              let ridingDuration = durations["riding"] as? Int,
              let segmentsArray = planDict["segments"] as? [[String: Any]] else {
            throw TransitError.parseError("Invalid trip plan data")
        }
        
        
        self.planNumber = planNumber
        self.duration = totalDuration
        self.walkingDuration = walkingDuration
        self.waitingDuration = waitingDuration
        self.ridingDuration = ridingDuration
        
        print(planDict)
        
        let dateFormatter = ISO8601DateFormatter()
        self.startTime = dateFormatter.date(from: startTimeStr) ?? Date()
        self.endTime = dateFormatter.date(from: endTimeStr) ?? Date()
        
        var parsedSegments: [TripSegment] = []
        var i = 0
        
        for segmentDict in segmentsArray {
            if let segment = try? TripSegment(from: segmentDict, parsedSegments: parsedSegments, currentSegmentIndex: i, segmentsArray: segmentsArray) {
                parsedSegments.append(segment)
            }
            
            i+=1
        }
        
        self.segments = parsedSegments
    }
}



