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
    let tripPlanDict: [String: Any]
    
    private struct RouteWeights {
        static let durationWeight: Double = 0.4
        static let segmentWeight: Double = 0.2
        static let walkingWeight: Double = 0.25
        static let waitingWeight: Double = 0.15
        static let longWalkingPenalty: Double = 1.2
        static let manyTransfersPenalty: Double = 1.3
        static let longWalkingThreshold = 15
        static let highTransferThreshold = 2
    }
    
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
        
        self.tripPlanDict = planDict
        self.planNumber = planNumber
        self.duration = totalDuration
        self.walkingDuration = walkingDuration
        self.waitingDuration = waitingDuration
        self.ridingDuration = ridingDuration
        
        
        
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
    
    
    func calculateRouteScore() -> Double {
        let normalizedDuration = Double(duration) / 120
        let normalizedSegments = Double(segments.count) / 5.0
        let normalizedWalking = Double(walkingDuration) / 30
        let normalizedWaiting = Double(waitingDuration) / 20
        
        var score = 0.0
        
        score += normalizedDuration * RouteWeights.durationWeight
        score += normalizedSegments * RouteWeights.segmentWeight
        score += normalizedWalking * RouteWeights.walkingWeight
        score += normalizedWaiting * RouteWeights.waitingWeight
        
        
        if walkingDuration > RouteWeights.longWalkingThreshold {
            score *= RouteWeights.longWalkingPenalty
        }
        
        if segments.count > RouteWeights.highTransferThreshold {
            score *= RouteWeights.manyTransfersPenalty
        }
        
        return score
    }
    
    static func getRecommendedRoute(from availableRoutes: [TripPlan]) -> TripPlan {
        guard !availableRoutes.isEmpty else {
            fatalError("No routes available")
        }
        

        return availableRoutes.min { routeA, routeB in
//            if routeA.segments.count != routeB.segments.count {
//                return routeA.segments.count < routeB.segments.count
//            }
            
            if routeA.duration != routeB.duration {
                return routeA.duration < routeB.duration
            }
            
            return routeA.walkingDuration < routeB.walkingDuration
        }!
    }
    
}



