import SwiftUI
import MapKit

struct TripSegment {
    let type: SegmentType
    let startTime: Date
    let endTime: Date
    let startTimeStr: String
    let endTimeStr: String
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
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"

        
        self.type = type
        self.startTime = dateFormatter.date(from: startTimeStr) ?? Date()
        self.endTime = dateFormatter.date(from: endTimeStr) ?? Date()
        
        self.startTimeStr = timeFormatter.string(from: self.startTime)
        self.endTimeStr = timeFormatter.string(from: self.endTime)
        
        self.duration = totalDuration
        
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
        

        let fromStopInfo: StopInfo?
        if let from = dict["from"] as? [String: Any] {
            if let stopDict = from["stop"] as? [String: Any] {
                fromStopInfo = StopInfo(from: stopDict)
            } else if let origin = from["origin"] as? [String: Any] {
                fromStopInfo =  Self.parseAddress(from: origin, type: "Current Location")
            } else {
                fromStopInfo = Self.lookupPreviousStop(in: segmentsArray, currentIndex: currentSegmentIndex)
            }
        } else {
            fromStopInfo = Self.lookupPreviousStop(in: segmentsArray, currentIndex: currentSegmentIndex)
        }
        
        let toStopInfo: StopInfo?
        if let to = dict["to"] as? [String: Any] {
            if let stopDict = to["stop"] as? [String: Any] {
                toStopInfo = StopInfo(from: stopDict)
            } else if let destination = to["destination"] as? [String: Any] {
                toStopInfo = Self.parseAddress(from: destination, type: "Destinaion")
            } else {
                toStopInfo = Self.lookupNextStop(in: segmentsArray, currentIndex: currentSegmentIndex)
            }
        } else {
            toStopInfo = Self.lookupNextStop(in: segmentsArray, currentIndex: currentSegmentIndex)
        }
        
        self.fromStop = fromStopInfo
        self.toStop = toStopInfo
    }
    
    private let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "hh:mm a"
        return formatter
    }()
    
    private static func parseAddress(from destination: [String: Any], type: String) -> StopInfo {
            if let monument = destination["monument"] as? [String: Any],
               let address = monument["address"] as? [String: Any],
               let street = address["street"] as? [String: Any],
               let streetName = street["name"] as? String,
               let streetNumber = address["street-number"] as? Int {
                return StopInfo(name: "\(streetNumber) \(streetName)")
            }
            
            if let address = destination["address"] as? [String: Any],
               let street = address["street"] as? [String: Any],
               let streetName = street["name"] as? String,
               let streetNumber = address["street-number"] as? Int {
                return StopInfo(name: "\(streetNumber) \(streetName)")
            }
        
            if let address = destination["address"] as? [String: Any],
               let addressSub = address["address"] as? [String: Any],
               let street = addressSub["street"] as? [String: Any],
               let streetName = street["name"] as? String,
               let streetNumber = address["street-number"] as? Int {
                return StopInfo(name: "\(streetNumber) \(streetName)")
            }
            
            if let intersection = destination["intersection"] as? [String: Any],
               let street = intersection["street"] as? [String: Any],
                let streetName = street["name"] as? String {
                return StopInfo(name: "Closest intersection to destination at \(streetName)")
            }
            
            return StopInfo(name: type)
        }
        
        private static func lookupPreviousStop(in segments: [[String: Any]], currentIndex: Int) -> StopInfo? {
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
            return StopInfo(name: "Location")
        }
        
        private static func lookupNextStop(in segments: [[String: Any]], currentIndex: Int) -> StopInfo? {
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
            return StopInfo(name: "Destination")
        }
    
    
}
