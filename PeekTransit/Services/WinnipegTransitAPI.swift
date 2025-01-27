import Foundation
import CoreLocation

enum TransitError: LocalizedError {
    case invalidURL
    case networkError(Error)
    case invalidResponse
    case invalidData
    case serviceDown
    case parseError(String)
    case batchProcessingError(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL configuration"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .invalidResponse:
            return "Invalid response from server"
        case .invalidData:
            return "Invalid data received"
        case .serviceDown:
            return "Transit service is currently unavailable"
        case .parseError(let message):
            return "Data parsing error: \(message)"
        case .batchProcessingError(let message):
            return "Error processing stops: \(message)"
        }
    }
}

class TransitAPI {
    private let apiKey = "uoYzaq2iEyZK1opS6zqo"
    private let baseURL = "https://api.winnipegtransit.com/v3"
    static let shared = TransitAPI()
    @Published private(set) var isLoading = false
    
    private init() {}
    
    private func createURL(path: String, parameters: [String: String] = [:]) -> URL? {
        var components = URLComponents(string: "\(baseURL)/\(path)")
        var queryItems = parameters.map { URLQueryItem(name: $0.key, value: $0.value) }
        queryItems.append(URLQueryItem(name: "api-key", value: apiKey))
        components?.queryItems = queryItems
        return components?.url
    }
    
    private func fetchData(from url: URL) async throws -> Data {
        isLoading = true
        defer { isLoading = false }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw TransitError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw TransitError.networkError(NSError(domain: "", code: httpResponse.statusCode))
        }
        
        return data
    }
    
    func getNearbyStops(userLocation: CLLocation) async throws -> [[String: Any]] {
        guard let url = createURL(
            path: "stops.json",
            parameters: [
                "lat": String(userLocation.coordinate.latitude),
                "lon": String(userLocation.coordinate.longitude),
                "distance": "500",
                "walking": "false"
            ]
        ) else {
            throw TransitError.invalidURL
        }
        
        let data = try await fetchData(from: url)
        
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let stops = json["stops"] as? [[String: Any]] else {
            throw TransitError.parseError("Invalid stops data format")
        }
        
        
        return stops
        
            .sorted { stop1, stop2 in
                guard let distances1 = stop1["distances"] as? [String: Any],
                      let distances2 = stop2["distances"] as? [String: Any],
                      let firstDistance1 = distances1.first,
                      let firstDistance2 = distances2.first,
                      let distanceString1 = firstDistance1.value as? String,
                      let distanceString2 = firstDistance2.value as? String,
                      let distanceValue1 = Double(distanceString1),
                      let distanceValue2 = Double(distanceString2)
                else {
                    return false
                }
                
                return distanceValue1 < distanceValue2
            }
        .prefix(25).map{$0}


    }
    
    
    
    func getVariantsForStops(stops: [[String: Any]]) async throws -> [[String: Any]] {
        var enrichedStops: [[String: Any]] = []
        let currentDate = Date()
        let calendar = Calendar.current
        let endDate = calendar.date(byAdding: .hour, value: 12, to: currentDate)!
        
        let dateFormatter = ISO8601DateFormatter()
        let startTime = dateFormatter.string(from: currentDate)
        let endTime = dateFormatter.string(from: endDate)
        
        for var stop in stops {
            do {
                guard let stopNumber = stop["number"] as? Int else {
                    print("Invalid stop number for stop: \(stop)")
                    continue
                }
                
                guard let url = createURL(path: "stops/\(stopNumber)/schedule.json", parameters: [ "start": startTime, "end": endTime]) else {
                    throw TransitError.invalidURL
                }
                
                let data = try await fetchData(from: url)
                
                guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let schedule = json["stop-schedule"] as? [String: Any],
                      let routeSchedules = schedule["route-schedules"] as? [[String: Any]] else {
                    print("Invalid schedule data for stop \(stopNumber)")
                    continue
                }
                
                let variants = routeSchedules.compactMap { routeSchedule -> [String: Any]? in
                    guard let route = routeSchedule["route"] as? [String: Any],
                          let scheduledStops = routeSchedule["scheduled-stops"] as? [[String: Any]],
                          let firstStop = scheduledStops.first,
                          let variant = firstStop["variant"] as? [String: Any] else {
                        return nil
                    }
                    return ["route": route, "variant": variant]
                }
                
                stop["variants"] = variants
                enrichedStops.append(stop)
                
            } catch {
                print("Error processing stop \(stop["number"] ?? "unknown"): \(error.localizedDescription)")
                continue
            }
        }
        
        if enrichedStops.isEmpty {
            throw TransitError.batchProcessingError("No stops could be processed successfully")
        }
        
        return enrichedStops
    }
    
    func getStopSchedule(stopNumber: Int) async throws -> [String: Any] {
        let currentDate = Date()
        let calendar = Calendar.current
        let currentComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: currentDate)

        var twelveHoursLaterComponents = currentComponents
        twelveHoursLaterComponents.hour! += 12

        if twelveHoursLaterComponents.hour! >= 24 {
            twelveHoursLaterComponents.hour! -= 24
            twelveHoursLaterComponents.day! += 1
        }

        var startOfNextDayComponents = currentComponents
        startOfNextDayComponents.day! += 1
        startOfNextDayComponents.hour = 0
        startOfNextDayComponents.minute = 0
        startOfNextDayComponents.second = 0

        let twelveHoursLater = calendar.date(from: twelveHoursLaterComponents)!
        let startOfNextDay = calendar.date(from: startOfNextDayComponents)!
        let endDate = twelveHoursLater < startOfNextDay ? twelveHoursLater : startOfNextDay

        func formatToISO8601String(from components: DateComponents) -> String {
            let year = String(format: "%04d", components.year!)
            let month = String(format: "%02d", components.month!)
            let day = String(format: "%02d", components.day!)
            let hour = String(format: "%02d", components.hour!)
            let minute = String(format: "%02d", components.minute!)
            let second = String(format: "%02d", components.second!)
            return "\(year)-\(month)-\(day)T\(hour):\(minute):\(second)Z"
        }

        let startTime = formatToISO8601String(from: currentComponents)
        let endTime = formatToISO8601String(from: calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: endDate))
        
        
        guard let url = createURL(
            path: "stops/\(stopNumber)/schedule.json",
            parameters: [
                "start": startTime,
                "end": endTime,
                "usage": "short"
            ]
        ) else {
            throw TransitError.invalidURL
        }
        
        let data = try await fetchData(from: url)
        
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw TransitError.parseError("Invalid schedule data format")
        }
//        print(json)
//        print(cleanStopSchedule(schedule: json))
        return json
    }
    
    func cleanStopSchedule(schedule: [String: Any]) -> [String] {
        var busScheduleList: [String] = []
        let currentDate = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        
        if let stopSchedule = schedule["stop-schedule"] as? [String: Any],
           let routeSchedules = stopSchedule["route-schedules"] as? [[String: Any]] {
            
            for routeSchedule in routeSchedules {
                if let scheduledStops = routeSchedule["scheduled-stops"] as? [[String: Any]] {
                    for stop in scheduledStops {
                        if let variant = stop["variant"] as? [String: Any],
                           var variantKey = variant["key"] as? String,
                           let variantName = variant["name"] as? String,
                           let cancelled = stop["cancelled"] as? String,
                           let times = stop["times"] as? [String: Any],
                           let arrival = times["arrival"] as? [String: Any] {
                            
                            let estimatedTime = arrival["estimated"] as? String
                            let scheduledTime = arrival["scheduled"] as? String
                            var finalArrivalText = ""
                            var arrivalState = "Ok"

                            if let estimatedTimeStr = estimatedTime,
                               let scheduledTimeStr = scheduledTime {
                                
                                let estimatedTimeParsedDateAndTime = estimatedTimeStr.components(separatedBy: "T")
                                let scheduledTimeParsedDateAndTime = scheduledTimeStr.components(separatedBy: "T")
                                let estimatedTimeParsedDate = estimatedTimeParsedDateAndTime[0].components(separatedBy: "-")
                                let estimatedTimeParsedTime = estimatedTimeParsedDateAndTime[1].components(separatedBy: ":")
                                let scheduledTimeParsedDate = scheduledTimeParsedDateAndTime[0].components(separatedBy: "-")
                                let scheduledTimeParsedTime = scheduledTimeParsedDateAndTime[1].components(separatedBy: ":")
                                
                                let estimatedTotalMinutes = (Int(estimatedTimeParsedDate[0])! * 525600) + (Int(estimatedTimeParsedDate[1])! * 43800) + (Int(estimatedTimeParsedDate[2])! * 1440) + (Int(estimatedTimeParsedTime[0])! * 60) + Int(estimatedTimeParsedTime[1])!
                                let scheduledTotalMinutes = (Int(scheduledTimeParsedDate[0])! * 525600) + (Int(scheduledTimeParsedDate[1])! * 43800) + (Int(scheduledTimeParsedDate[2])! * 1440) + (Int(scheduledTimeParsedTime[0])! * 60) + Int(scheduledTimeParsedTime[1])!
                                
                                let currentDateComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: currentDate)
                                let currentTotalMinutes = (currentDateComponents.year! * 525600) + (currentDateComponents.month! * 43800) + (currentDateComponents.day! * 1440) + (currentDateComponents.hour! * 60) + currentDateComponents.minute!
                                
                                var timeDifference = 0.0
                                
                                if ( (estimatedTotalMinutes - currentTotalMinutes) < 0 ) {
                                    timeDifference = floor(Double(estimatedTotalMinutes - currentTotalMinutes))
                                } else if ((estimatedTotalMinutes - currentTotalMinutes) > 0 ) {
                                    timeDifference = ceil(Double(estimatedTotalMinutes - currentTotalMinutes))
                                }
                                
                                var delay = 0.0
                                
                                if ( (estimatedTotalMinutes - scheduledTotalMinutes) < 0 ) {
                                    delay = floor(Double(estimatedTotalMinutes - scheduledTotalMinutes))
                                } else if ( (estimatedTotalMinutes - scheduledTotalMinutes) > 0 ) {
                                    delay = ceil(Double(estimatedTotalMinutes - scheduledTotalMinutes))
                                }

                                if timeDifference < -1 {
                                    continue
                                }
                                
                                if cancelled == "true" {
                                    arrivalState = "Cancelled"
                                    finalArrivalText = ""
                                } else {
                                    if timeDifference < 0 {
                                        finalArrivalText = "\(Int(-timeDifference)) min. ago"
                                    } else if timeDifference < 15 {
                                        finalArrivalText = "\(Int(timeDifference)) min."
                                    } else {
                                        var finalHour = Int(estimatedTimeParsedTime[0])!
                                        var am = false

                                        if finalHour > 12 {
                                            finalHour -= 12
                                            am = false
                                        } else {
                                            am = true
                                        }

                                        finalArrivalText = "\(finalHour):\(estimatedTimeParsedTime[1])"

                                        if am {
                                            finalArrivalText += " AM"
                                        } else {
                                            finalArrivalText += " PM"
                                        }
                                    }
                                    
                                    if delay > 0 && timeDifference < 15 {
                                        arrivalState = "Late"
                                        finalArrivalText = "\(Int(timeDifference)) min."
                                    } else if delay < 0 && timeDifference < 15 {
                                        arrivalState = "Early"
                                        finalArrivalText = "\(Int(timeDifference)) min."
                                    } else {
                                        arrivalState = "Ok"
                                    }
                                    
                                    if (timeDifference == 0.0 || (timeDifference > 1 && timeDifference < -1)) {
                                        finalArrivalText = "Due"
                                    }
                                }
                            } else {
                                finalArrivalText = "Time Unavailable"
                            }
                            
                            if let firstPart = variantKey.split(separator: "-").first {
                                variantKey = String(firstPart)
                            }
                            
                            busScheduleList.append("\(variantKey) ---- \(variantName) ---- \(arrivalState) ---- \(finalArrivalText)")
                        }
                    }
                }
            }
        }
        
        // Sort the bus schedule list according to the specified priority
        return busScheduleList.sorted(by: { (str1: String, str2: String) -> Bool in
            let componentsA = str1.components(separatedBy: " ---- ")
            let componentsB = str2.components(separatedBy: " ---- ")
            
            let timeA = componentsA[3]
            let timeB = componentsB[3]
            let stateA = componentsA[2]
            let stateB = componentsB[2]
            
            // Priority 1: "Due" entries come first
            if timeA == "Due" && timeB != "Due" {
                return true
            }
            if timeB == "Due" && timeA != "Due" {
                return false
            }
            if timeA == "Due" && timeB == "Due" {
                return true
            }
            
            // Priority 2: Handle minute-based entries
            let isMinutesA = timeA.hasSuffix("min.")
            let isMinutesB = timeB.hasSuffix("min.")
            
            if isMinutesA && isMinutesB {
                // Extract the minute values
                let minutesA = Int(timeA.components(separatedBy: " ")[0]) ?? 0
                let minutesB = Int(timeB.components(separatedBy: " ")[0]) ?? 0
                
                // Sort by state priority first
                if stateA != stateB {
                    if stateA == "Early" { return true }
                    if stateB == "Early" { return false }
                    if stateA == "Late" { return true }
                    if stateB == "Late" { return false }
                }
                
                // If states are the same, sort by minutes
                return minutesA < minutesB
            }
            
            // If one is minutes and other is time
            if isMinutesA { return true }
            if isMinutesB { return false }
            
            // Priority 3: Handle time format (HH:MM AM/PM)
            let timeComponentsA = timeA.components(separatedBy: " ")
            let timeComponentsB = timeB.components(separatedBy: " ")
            
            if timeComponentsA.count == 2 && timeComponentsB.count == 2 {
                let hourMinA = timeComponentsA[0].components(separatedBy: ":")
                let hourMinB = timeComponentsB[0].components(separatedBy: ":")
                
                let hourA = Int(hourMinA[0]) ?? 0
                let hourB = Int(hourMinB[0]) ?? 0
                let minuteA = Int(hourMinA[1]) ?? 0
                let minuteB = Int(hourMinB[1]) ?? 0
                let isAMA = timeComponentsA[1] == "AM"
                let isAMB = timeComponentsB[1] == "AM"
                
                // Compare AM/PM first
                if isAMA != isAMB {
                    return isAMA
                }
                
                // Compare hours
                if hourA != hourB {
                    return hourA < hourB
                }
                
                // Compare minutes
                return minuteA < minuteB
            }
            
            // Handle any other cases (like "Time Unavailable")
            return false
        })
    }
}
