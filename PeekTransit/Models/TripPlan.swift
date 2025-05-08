import Foundation
import CoreLocation

struct TripPlan: Hashable {
    let planNumber: Int
    let startTime: Date
    let endTime: Date
    let startTimeString: String
    let endTimeString: String
    let duration: Int
    let walkingDuration: Int
    let waitingDuration: Int
    let ridingDuration: Int
    let segments: [TripSegment]
    let tripPlanDict: [String: Any]
    
    private struct RouteWeights {
        static let durationWeight: Double = 0.45
        static let transfersWeight: Double = 0.25
        static let walkingWeight: Double = 0.20
        static let waitingWeight: Double = 0.10
        static let longWalkingPenalty: Double = 1.5
        static let manyTransfersPenalty: Double = 1.4
        static let longWalkingThreshold = 12
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
        
        
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"

        
        self.startTime = dateFormatter.date(from: startTimeStr) ?? Date()
        self.endTime = dateFormatter.date(from: endTimeStr) ?? Date()

        let startTimeFormatted = timeFormatter.string(from: self.startTime)
        let endTimeFormatted = timeFormatter.string(from: self.endTime)
        
        self.startTimeString = startTimeFormatted
        self.endTimeString = endTimeFormatted
        
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
    
    
    static func calculateRouteScore(route: TripPlan) -> Double {
        let normalizedDuration = Double(route.duration) / 90.0        // Normalized to 90 min
        let transferCount = route.segments.count - 1                  // Actual transfer count
        let normalizedTransfers = Double(max(0, transferCount)) / 3.0 // Normalized to 3 transfers
        let normalizedWalking = Double(route.walkingDuration) / 20.0  // Normalized to 20 min
        let normalizedWaiting = Double(route.waitingDuration) / 15.0  // Normalized to 15 min
        
        var score = 0.0
        
        score += normalizedDuration * RouteWeights.durationWeight
        score += normalizedTransfers * RouteWeights.transfersWeight
        score += normalizedWalking * RouteWeights.walkingWeight
        score += normalizedWaiting * RouteWeights.waitingWeight
        
        if route.walkingDuration > RouteWeights.longWalkingThreshold {
            let excessWalking = Double(route.walkingDuration - RouteWeights.longWalkingThreshold) / 10.0
            score *= (1.0 + (excessWalking * (RouteWeights.longWalkingPenalty - 1.0)))
        }
        
        if transferCount > RouteWeights.highTransferThreshold {
            let excessTransfers = Double(transferCount - RouteWeights.highTransferThreshold)
            score *= (1.0 + (excessTransfers * (RouteWeights.manyTransfersPenalty - 1.0) / 2.0))
        }
        
        return score
    }
    
    private let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "hh:mm a"
        return formatter
    }()
    
    static func getTopRecommendedRoutes(from availableRoutes: [TripPlan], limit: Int = 5) -> [TripPlan] {
        guard !availableRoutes.isEmpty else { return [] }
        
        var walkingGroups: [Bool: [TripPlan]] = [true: [], false: []]
        
        for route in availableRoutes {
            let isFirstSegmentWalking = route.segments.first?.type == .walk
            if isFirstSegmentWalking {
                walkingGroups[true]?.append(route)
            } else {
                walkingGroups[false]?.append(route)
            }
        }
        
        walkingGroups[true]?.sort { route1, route2 in
            guard let walkSegment1 = route1.segments.first, let walkSegment2 = route2.segments.first else {
                return false
            }
            return walkSegment1.duration < walkSegment2.duration
        }
        
        var finalSortedWalkingGroups: [Bool: [TripPlan]] = [true: [], false: []]
        
        for (isWalking, routes) in walkingGroups {
            let segmentCountGroups = Dictionary(grouping: routes) { route in
                return route.segments.count
            }.sorted { $0.key < $1.key }
            
            var sortedBySegmentCount: [TripPlan] = []
            
            for (_, routesWithSameSegmentCount) in segmentCountGroups {
                let sortedByStartTime = routesWithSameSegmentCount.sorted { $0.startTime < $1.startTime }
                var startTimeGroups: [[TripPlan]] = []
                var currentTimeGroup: [TripPlan] = []
                var previousStartTime: Date?
                let timeThreshold = 1 * 60
                
                for route in sortedByStartTime {
                    if let prevTime = previousStartTime,
                       abs(route.startTime.timeIntervalSince(prevTime)) <= Double(timeThreshold) {
                        currentTimeGroup.append(route)
                    } else {
                        if !currentTimeGroup.isEmpty {
                            startTimeGroups.append(currentTimeGroup)
                        }
                        currentTimeGroup = [route]
                        previousStartTime = route.startTime
                    }
                }
                
                if !currentTimeGroup.isEmpty {
                    startTimeGroups.append(currentTimeGroup)
                }
                
                var segmentGroupRoutes: [TripPlan] = []
                for group in startTimeGroups {
                    let sortedByDuration = group.sorted { route1, route2 in
                        if abs(route1.duration - route2.duration) <= 60 { // Within 1 minute threshold
                            return calculateRouteScore(route: route1) < calculateRouteScore(route: route2)
                        }
                        return route1.duration < route2.duration
                    }
                    segmentGroupRoutes.append(contentsOf: sortedByDuration)
                }
                
                sortedBySegmentCount.append(contentsOf: segmentGroupRoutes)
            }
            
            finalSortedWalkingGroups[isWalking] = sortedBySegmentCount
        }
        
        var finalRoutes: [TripPlan] = []
        finalRoutes.append(contentsOf: finalSortedWalkingGroups[false] ?? [])
        finalRoutes.append(contentsOf: finalSortedWalkingGroups[true] ?? [])
        
        let actualLimit = min(limit, finalRoutes.count)
        return Array(finalRoutes.prefix(actualLimit))
    }
    
    private static func sortWalkingSegment(routes: [TripPlan]) -> [TripPlan] {
        return routes.sorted { (route1, route2) -> Bool in
            let isFirstSegmentWalking1 = route1.segments.first?.type == .walk
            let isFirstSegmentWalking2 = route2.segments.first?.type == .walk
            
            if isFirstSegmentWalking1 && isFirstSegmentWalking2 {
                return route1.segments.first!.duration < route2.segments.first!.duration
            } else if isFirstSegmentWalking1 && !isFirstSegmentWalking2 {
                return false
            } else if !isFirstSegmentWalking1 && isFirstSegmentWalking2 {
                return true
            } else {
                return calculateRouteScore(route: route1) < calculateRouteScore(route: route2)
            }
        }
    }
    
    public static func == (lhs: TripPlan, rhs: TripPlan) -> Bool {
        guard lhs.startTime == rhs.startTime,
              lhs.endTime == rhs.endTime,
              lhs.duration == rhs.duration,
              lhs.walkingDuration == rhs.walkingDuration,
              lhs.waitingDuration == rhs.waitingDuration,
              lhs.ridingDuration == rhs.ridingDuration,
              lhs.segments.count == rhs.segments.count else {
            return false
        }
        
        return lhs.segments == rhs.segments
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(startTime)
        hasher.combine(endTime)
        hasher.combine(duration)
        hasher.combine(walkingDuration)
        hasher.combine(waitingDuration)
        hasher.combine(ridingDuration)
        hasher.combine(segments)
    }
}
