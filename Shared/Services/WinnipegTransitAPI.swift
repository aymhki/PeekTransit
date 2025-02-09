import Foundation
import CoreLocation
import WidgetKit



class TransitAPI {
    private let apiKey = "uoYzaq2iEyZK1opS6zqo"
    private let baseURL = "https://api.winnipegtransit.com/v3"
    static let shared = TransitAPI()
    @Published private(set) var isLoading = false
    
    init() {}
    
    func createURL(path: String, parameters: [String: Any] = [:]) -> URL? {
        var components = URLComponents(string: "\(baseURL)/\(path)")
        var queryItems = parameters.map { key, value in
            let stringValue: String
            switch value {
            case let number as NSNumber:
                stringValue = number.stringValue
            case let string as String:
                stringValue = string
            case let bool as Bool:
                stringValue = bool ? "true" : "false"
            case let array as [Any]:
                stringValue = array.map { String(describing: $0) }.joined(separator: ",")
            case let date as Date:
                stringValue = ISO8601DateFormatter().string(from: date)
            case is NSNull:
                stringValue = ""
            default:
                stringValue = String(describing: value)
            }
            return URLQueryItem(name: key, value: stringValue)
        }
        queryItems.append(URLQueryItem(name: "api-key", value: apiKey))
        components?.queryItems = queryItems
        return components?.url
    }
    
    func fetchData(from url: URL) async throws -> Data {
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
    
    func getNearbyStops(userLocation: CLLocation, forShort: Bool) async throws -> [[String: Any]] {
        guard let url = createURL(
            path: "stops.json",
            parameters: [
                "lat": String(userLocation.coordinate.latitude),
                "lon": String(userLocation.coordinate.longitude),
                "distance": "\(Int(getStopsDistanceRadius()))",
                "walking": "false",
                "usage": forShort ? "short" : "long"
            ]
        ) else {
            throw TransitError.invalidURL
        }
        
        let data = try await fetchData(from: url)
        
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let stops = json["stops"] as? [[String: Any]] else {
            throw TransitError.parseError("Invalid stops data format")
        }
        
        var mutableStops = stops
        if forShort {
            for (index, var stop) in mutableStops.enumerated() {
                if let name = stop["name"] as? String {
                    stop["name"] = name.replacingOccurrences(of: "@", with: " @ ")
                    mutableStops[index] = stop
                }
            }
        }
        
        return mutableStops
        
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
        .prefix(getMaxStopsAllowedToFetch()).map{$0}


    }
    
    func searchStops(query: String, forShort: Bool) async throws -> [[String: Any]] {
        guard let url = createURL(
            path: "stops:\(query).json",
            parameters: [
                "usage": forShort ? "short" : "long"
            ]
        ) else {
            throw TransitError.invalidURL
        }
        
        let data = try await fetchData(from: url)
        
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let stops = json["stops"] as? [[String: Any]] else {
            throw TransitError.parseError("Invalid stops data format")
        }
        
        var mutableStops = stops
        if forShort {
            for (index, var stop) in mutableStops.enumerated() {
                if let name = stop["name"] as? String {
                    stop["name"] = name.replacingOccurrences(of: "@", with: " @ ")
                    mutableStops[index] = stop
                }
            }
        }
        
        return mutableStops.prefix(getMaxStopsAllowedToFetchForSearch()).map{$0}
    }
    
    
    
    private func createVariantsForStop(_ stopNumber: Int, currentDate: Date, endDate: Date, forShort: Bool) async throws -> [[String: Any]] {
        let dateFormatter = ISO8601DateFormatter()
        let startTime = dateFormatter.string(from: currentDate)
        let endTime = dateFormatter.string(from: endDate)
        
        guard let url = createURL(path: "variants.json", parameters: [
            "start": startTime,
            "end": endTime,
            "stop": stopNumber,
            "usage": forShort ? "short" : "long"
        ]) else {
            throw TransitError.invalidURL
        }
        
        let data = try await fetchData(from: url)
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let variantsArray = json["variants"] as? [[String: Any]] else {
            throw TransitError.parseError("Invalid variants data format")
        }
        
        return variantsArray.map { variant -> [String: Any] in
            let route: [String: Any] = [
                "key": stopNumber,
                "number": stopNumber
            ]
            return ["route": route, "variant": variant]
        }
    }
    
    private func validateCaches(stops: [[String: Any]], enrichedStops: [[String: Any]], currentDate: Date, endDate: Date, forShort: Bool) async throws -> Bool {
        let stopNumbers = stops.compactMap { $0["number"] as? Int }
        let stopsParam = stopNumbers.map(String.init).joined(separator: ",")
        
        guard let url = createURL(path: "variants.json", parameters: [
            "start": ISO8601DateFormatter().string(from: currentDate),
            "end": ISO8601DateFormatter().string(from: endDate),
            "stops": stopsParam,
            "usage": forShort ? "short" : "long"
        ]) else {
            throw TransitError.invalidURL
        }
        
        let data = try await fetchData(from: url)
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let allVariants = json["variants"] as? [[String: Any]] else {
            throw TransitError.parseError("Invalid bulk variants data format")
        }
        
        let bulkVariantsSet = Set(allVariants.compactMap { variant -> String? in
            guard let key = variant["key"] as? String,
                  let name = variant["name"] as? String else { return nil }
            return "\(key)\(getCompositKeyLinkerForDictionaries())\(name)"
        })
        
        for enrichedStop in enrichedStops {
            guard let variants = enrichedStop["variants"] as? [[String: Any]] else { continue }
            
            for variant in variants {
                guard let variantData = variant["variant"] as? [String: Any],
                      let key = variantData["key"] as? String,
                      let name = variantData["name"] as? String else { continue }
                
                let variantIdentifier = "\(key)\(getCompositKeyLinkerForDictionaries())\(name)"
                if !bulkVariantsSet.contains(variantIdentifier) {
                    return false
                }
            }
        }
        
        return true
    }
    
    func getVariantsForStops(stops: [[String: Any]]) async throws -> [[String: Any]] {
        var enrichedStops: [[String: Any]] = []
        let currentDate = Date()
        let calendar = Calendar.current
        let endDate = calendar.date(byAdding: .hour, value: getTimePeriodAllowedForNextBusRoutes(), to: currentDate)!
        
        for var stop in stops {
            if let stopNumber = stop["number"] as? Int {
                var stopVariants: [[String: Any]]
                
                if let cachedVariants = VariantsCacheManager.shared.getCachedVariants(for: stopNumber) {
                    stopVariants = cachedVariants
                } else {
                    stopVariants = try await createVariantsForStop(stopNumber, currentDate: currentDate, endDate: endDate, forShort: true)
                    VariantsCacheManager.shared.cacheVariants(stopVariants, for: stopNumber)
                }
                
                if !stopVariants.isEmpty {
                    stopVariants = stopVariants.filter { variantObjects in
                        guard let variantObject = variantObjects["variant"] as? [String: Any],
                        let variantKey = variantObject["key"] as? String 
                        else { return true }
                        return !(variantKey.prefix(1) == "S" || variantKey.prefix(1) == "W")
                    }
                    
                    stop["variants"] = stopVariants
                    enrichedStops.append(stop)
                }
            }
        }
        
        let cachesValid = try await validateCaches(stops: stops, enrichedStops: enrichedStops, currentDate: currentDate, endDate: endDate, forShort: true)
        
        if !cachesValid {
            VariantsCacheManager.shared.clearAllCaches()
            return try await getVariantsForStops(stops: stops)
        }
        
        return enrichedStops
    }
    
    func getOnlyVariantsForStop(stop: [String: Any]) async throws -> [[String: Any]] {
        let currentDate = Date()
        let calendar = Calendar.current
        let endDate = calendar.date(byAdding: .hour, value: getTimePeriodAllowedForNextBusRoutes(), to: currentDate)!
        
        if let stopNumber = stop["number"] as? Int {
            var stopVariants: [[String: Any]]
            
            if let cachedVariants = VariantsCacheManager.shared.getCachedVariants(for: stopNumber) {
                stopVariants = cachedVariants
            } else {
                stopVariants = try await createVariantsForStop(stopNumber, currentDate: currentDate, endDate: endDate, forShort: true)
                VariantsCacheManager.shared.cacheVariants(stopVariants, for: stopNumber)
            }
            
            if !stopVariants.isEmpty {
                stopVariants = stopVariants.filter { variantObjects in
                    guard let variantObject = variantObjects["variant"] as? [String: Any],
                    let variantKey = variantObject["key"] as? String
                    else { return true }
                    return !(variantKey.prefix(1) == "S" || variantKey.prefix(1) == "W")
                }
                
                return stopVariants
            }
        }
        
        
        return []
    }
    
    func getStopSchedule(stopNumber: Int) async throws -> [String: Any] {
        let currentDate = Date()
        let calendar = Calendar.current
        let currentComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: currentDate)

        var periodAllowedForBusRoutes = currentComponents
        periodAllowedForBusRoutes.hour! += getTimePeriodAllowedForNextBusRoutes()

        if periodAllowedForBusRoutes.hour! >= 24 {
            periodAllowedForBusRoutes.hour! -= 24
            periodAllowedForBusRoutes.day! += 1
        }

        var startOfNextDayComponents = currentComponents
        startOfNextDayComponents.day! += 1
        startOfNextDayComponents.hour = 0
        startOfNextDayComponents.minute = 0
        startOfNextDayComponents.second = 0

        let periodOfTimeLater = calendar.date(from: periodAllowedForBusRoutes)!
        let startOfNextDay = calendar.date(from: startOfNextDayComponents)!
        let endDate = periodOfTimeLater // periodOfTimeLater < startOfNextDay ? periodOfTimeLater : startOfNextDay

        func formatToISO8601String(from components: DateComponents) -> String {
            let year = String(format: "%04d", components.year!)
            let month = String(format: "%02d", components.month!)
            let day = String(format: "%02d", components.day!)
            let hour = String(format: "%02d", components.hour!)
            let minute = String(format: "%02d", components.minute!)
            let second = String(format: "%02d", components.second!)
            return "\(year)-\(month)-\(day)T\(hour):\(minute):\(second)"
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

        return json
    }
    
    func cleanStopSchedule(schedule: [String: Any], timeFormat: TimeFormat) -> [String] {
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
                           var variantName = variant["name"] as? String,
                           let cancelled = stop["cancelled"] as? String,
                           let times = stop["times"] as? [String: Any],
                           let arrival = times["departure"] as? [String: Any] {
                            
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
                                
                                var timeDifference = 0.0 //estimatedTotalMinutes - currentTotalMinutes
                                
                                if ( (estimatedTotalMinutes - currentTotalMinutes) < 0 ) {
                                    timeDifference = floor(Double(estimatedTotalMinutes - currentTotalMinutes))
                                } else if ((estimatedTotalMinutes - currentTotalMinutes) > 0 ) {
                                    timeDifference = ceil(Double(estimatedTotalMinutes - currentTotalMinutes))
                                }
                                
                                var delay = estimatedTotalMinutes - scheduledTotalMinutes
                                
//                                if ( (estimatedTotalMinutes - scheduledTotalMinutes) < 0 ) {
//                                    delay = floor(Double(estimatedTotalMinutes - scheduledTotalMinutes))
//                                } else if ( (estimatedTotalMinutes - scheduledTotalMinutes) > 0 ) {
//                                    delay = ceil(Double(estimatedTotalMinutes - scheduledTotalMinutes))
//                                }

                                if timeDifference < -1 {
                                    continue
                                }
                                
                                if cancelled == "true" {
                                    arrivalState = "Cancelled"
                                    finalArrivalText = ""
                                } else {
                                    if (timeDifference < 0 && timeFormat != TimeFormat.clockTime) {
                                        finalArrivalText = "\(Int(-timeDifference)) min. ago"
                                    } else if (timeDifference < 15 && timeFormat != TimeFormat.clockTime) {
                                        finalArrivalText = "\(Int(timeDifference)) min."
                                    } else {
                                        var finalHour = Int(estimatedTimeParsedTime[0])!
                                        let am = finalHour < 12
                                                    
                                        if finalHour == 0 {
                                            finalHour = 12
                                        } else if finalHour > 12 {
                                            finalHour -= 12
                                        }

                                        finalArrivalText = "\(finalHour):\(estimatedTimeParsedTime[1])"

                                        if am {
                                            finalArrivalText += " AM"
                                        } else {
                                            finalArrivalText += " PM"
                                        }
                                    }
                                    
                                    if (delay > 0 && timeDifference < 15 && timeFormat != TimeFormat.clockTime) {
                                        arrivalState = "Late"
                                        finalArrivalText = "\(Int(timeDifference)) min."
                                    } else if delay < 0 && timeDifference < 15 {
                                        arrivalState = "Early"
                                        finalArrivalText = "\(Int(timeDifference)) min."
                                    } else {
                                        arrivalState = "Ok"
                                    }
                                    
                                    if (timeDifference == 0 || (timeDifference > 1 && timeDifference < -1)) {
                                        finalArrivalText = "Due"
                                    }
                                }
                            } else {
                                finalArrivalText = "Time Unavailable"
                            }
                            
                            if let firstPart = variantKey.split(separator: "-").first {
                                variantKey = String(firstPart)
                            }
                            
                            
                            if (variantKey.contains("BLUE")) {
                                variantKey = "B"
                            }
                            
//                            if (variantName.contains("University of Manitoba")) {
//                                variantName = "U of M"
//                            } else if (variantName.contains("Prairie Pointe")) {
//                                variantName = "Prairie P."
//                            } else if (variantName.contains("Kildonan Place")) {
//                                variantName = "Kildonan P."
//                            } else if (variantName.contains("Markham Station")) {
//                                variantName = "Markham S."
//                            } else if (variantName.lowercased().contains("Via Kildare".lowercased())) {
//                                variantName = "V. Kildare"
//                            } else if (variantName.lowercased().contains("Via Regent".lowercased())) {
//                                variantName = "V. Regent"
//                            } else if (variantName.contains("Beaumont Station")) {
//                                variantName = "Beaumont S."
//                            } else if (variantName.contains("Garden City Centre")) {
//                                variantName = "Garden City C."
//                            } else if (variantName.contains("Outlet Collection")) {
//                                variantName = "Outlet"
//                            } else if (variantName.contains("Bridgwater Forest")) {
//                                variantName = "Bridgwater F."
//                            } else if (variantName.contains("Fort Garry Industrial")) {
//                                variantName = "Fort Garry I."
//                            } else if (variantName.contains("Misericordia Health Centre")) {
//                                variantName = "Misericordia HC"
//                            } else if (variantName.contains("Health Sciences Centre")) {
//                                variantName = "Health Sci."
//                            } else if (variantName.contains("Harkness Station")) {
//                                variantName = "Harkness S."
//                            } else if (variantName.contains("Industrial Park")) {
//                                variantName = "Industrial P."
//                            } else if (variantName.contains("South St. Vital")) {
//                                variantName = "S. St. Vital"
//                            } else if (variantName.contains("North Kildonan")) {
//                                variantName = "N. Kildonan"
//                            } else if (variantName.contains("Balmoral Station")) {
//                                variantName = "Balmoral S."
//                            } else if (variantName.contains("Crossroads Station")) {
//                                variantName = "Crossroads S."
//                            } else if (variantName.contains("Southdale Centre")) {
//                                variantName = "Southdale C."
//                            } else if (variantName.contains("St. Vital Centre")) {
//                                variantName = "St. Vital C."
//                            } else if (variantName.contains("Red River College")) {
//                                variantName = "Red River C."
//                            } else if (variantName.contains("Grace Hospital")) {
//                                variantName = "Grace Hosp."
//                            } else if (variantName.contains("Seven Oaks Hospital")) {
//                                variantName = "Seven Oaks"
//                            } else if (variantName.contains("Assiniboine Park")) {
//                                variantName = "Assiniboine Park"
//                            } else if (variantName.contains("North Transcona")) {
//                                variantName = "N. Transcona"
//                            } else if (variantName.contains("South Transcona")) {
//                                variantName = "S. Transcona"
//                            } else if (variantName.contains("Lakeside Meadows")) {
//                                variantName = "Lakeside M."
//                            } else if (variantName.contains("Castlebury Meadows")) {
//                                variantName = "Castlebury M."
//                            } else if (variantName.contains("Garden City Shopping Centre")) {
//                                variantName = "Garden City S. C."
//                            } else if (variantName.contains("Waterford Green Common")) {
//                                variantName = "Waterford G."
//                            } else if (variantName.contains("Birds Hill Provincial Park")) {
//                                variantName = "Birds Hill P. P."
//                            } else if (variantName.contains("Manitoba Institute of Trades")) {
//                                variantName = "MITT"
//                            } else if (variantName.contains("RRC Polytech")) {
//                                variantName = "RRC P."
//                            } else if (variantName.contains("Assiniboine Park Zoo")) {
//                                variantName = "Assiniboine Zoo"
//                            } else if (variantName.contains("Gordon Bell High School")) {
//                                variantName = "Gordon Bell"
//                            } else if (variantName.contains("Tuxedo Business Park")) {
//                                variantName = "Tuxedo B.P."
//                            } else if (variantName.contains("Fort Garry Industrial")) {
//                                variantName = "Fort Garry I."
//                            } else if (variantName.contains("South St. Vital")) {
//                                variantName = "S. St. Vital"
//                            } else if (variantName.contains("Prairie Point")) {
//                                variantName = "Prairie P."
//                            } else if (variantName.contains("South Pointe West")) {
//                                variantName = "S. Pointe W."
//                            } else if (variantName.contains("North Inkster Industrial")) {
//                                variantName = "N. Inkster I."
//                            } else if (variantName.contains("St. Boniface Industrial")) {
//                                variantName = "St. Boniface I."
//                            } else if (variantName.contains("North St. Boniface")) {
//                                variantName = "N. St. Boniface"
//                            } else if (variantName.contains("Windermere Terminal")) {
//                                variantName = "Windermere T."
//                            } else if (variantName.contains("Fort Rouge Station")) {
//                                variantName = "Fort Rouge S."
//                            } else if (variantName.contains("Jubilee Station")) {
//                                variantName = "Jubilee S."
//                            } else if (variantName.contains("Main Street/Cathedral")) {
//                                variantName = "Main/Cathedral"
//                            } else if (variantName.contains("Outlet Collection Mall")) {
//                                variantName = "Outlet Mall"
//                            } else if (variantName.contains("Unicity Mall")) {
//                                variantName = "Unicity M."
//                            } else if (variantName.contains("Crosstown East to Speers")) {
//                                variantName = "Crosstown\nE. S. E."
//                            }
                            
                            busScheduleList.append("\(variantKey)\(getScheduleStringSeparator())\(variantName)\(getScheduleStringSeparator())\(arrivalState)\(getScheduleStringSeparator())\(finalArrivalText)")
                        }
                    }
                }
            }
        }
        
        return busScheduleList.sorted(by: { (str1: String, str2: String) -> Bool in
            let componentsA = str1.components(separatedBy: getScheduleStringSeparator())
            let componentsB = str2.components(separatedBy: getScheduleStringSeparator())
            
            let timeA = componentsA[3]
            let timeB = componentsB[3]
            let stateA = componentsA[2]
            let stateB = componentsB[2]
            
            if timeA == "Due" && timeB != "Due" {
                return true
            }
            if timeB == "Due" && timeA != "Due" {
                return false
            }
            if timeA == "Due" && timeB == "Due" {
                return true
            }
            
            let isMinutesA = timeA.hasSuffix("min.")
            let isMinutesB = timeB.hasSuffix("min.")
            
            if isMinutesA && isMinutesB {
                let minutesA = Int(timeA.components(separatedBy: " ")[0]) ?? 0
                let minutesB = Int(timeB.components(separatedBy: " ")[0]) ?? 0
                
                if stateA != stateB {
                    if stateA == "Early" { return true }
                    if stateB == "Early" { return false }
                    if stateA == "Late" { return true }
                    if stateB == "Late" { return false }
                }
                
                return minutesA < minutesB
            }
            
            if isMinutesA { return true }
            if isMinutesB { return false }
            
            let timeComponentsA = timeA.components(separatedBy: " ")
            let timeComponentsB = timeB.components(separatedBy: " ")
            
            if timeComponentsA.count == 2 && timeComponentsB.count == 2 {
                let hourMinA = timeComponentsA[0].components(separatedBy: ":")
                let hourMinB = timeComponentsB[0].components(separatedBy: ":")
                
                var hourA = Int(hourMinA[0]) ?? 0
                var hourB = Int(hourMinB[0]) ?? 0
                let minuteA = Int(hourMinA[1]) ?? 0
                let minuteB = Int(hourMinB[1]) ?? 0
                let isAMA = timeComponentsA[1] == "AM"
                let isAMB = timeComponentsB[1] == "AM"
                
                if !isAMA && hourA != 12 { hourA += 12 }
                if isAMA && hourA == 12 { hourA = 0 }
                if !isAMB && hourB != 12 { hourB += 12 }
                if isAMB && hourB == 12 { hourB = 0 }
                
                let totalMinutesA = hourA * 60 + minuteA
                let totalMinutesB = hourB * 60 + minuteB
                
                if abs(totalMinutesA - totalMinutesB) > 18 * 60 {
                    return totalMinutesA > totalMinutesB
                }
                
                return totalMinutesA < totalMinutesB
            }
            
            return false
        })
    }
}




