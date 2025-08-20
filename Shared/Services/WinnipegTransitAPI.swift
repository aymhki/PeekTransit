import Foundation
import SwiftUICore
import CoreLocation
import WidgetKit

actor RequestRateLimiter {
    private var lastRequestTime: Date = Date()
    private let minimumRequestInterval: TimeInterval = 0.1
    
    private var callCount: Int = 0
    private var minuteStartTime: Date = Date()
    private let maxCallsPerMinute: Int = 100
    
    
    func waitIfNeeded() async {
        let currentTime = Date()
        
        let timeElapsedSinceMinuteStart = currentTime.timeIntervalSince(minuteStartTime)
        if timeElapsedSinceMinuteStart >= 60.0 {
            callCount = 0
            minuteStartTime = currentTime
        }
        
        if callCount >= maxCallsPerMinute {
            let timeToWaitForNewMinute = 60.0 - timeElapsedSinceMinuteStart + minimumRequestInterval
            if timeToWaitForNewMinute > 0 {
                // print("\n***** Rate limit reached (\(maxCallsPerMinute) calls/minute). Waiting \(Int(timeToWaitForNewMinute)) seconds for next minute...")
                try? await Task.sleep(nanoseconds: UInt64(timeToWaitForNewMinute * 1_000_000_000))
                
                callCount = 0
                minuteStartTime = Date()
            }
        }
        
        let timeSinceLastRequest = currentTime.timeIntervalSince(lastRequestTime)
        if timeSinceLastRequest < minimumRequestInterval {
           try? await Task.sleep(nanoseconds: UInt64((minimumRequestInterval - timeSinceLastRequest) * 1_000_000_000))
        }
        
        callCount += 1
        lastRequestTime = Date()
        
        // print("\n***** API Call #\(callCount) in current minute")
    }
    
    func getCallStats() -> (callCount: Int, timeRemaining: TimeInterval) {
        let currentTime = Date()
        let timeElapsed = currentTime.timeIntervalSince(minuteStartTime)
        let timeRemaining = max(0, 60.0 - timeElapsed)
        return (callCount: callCount, timeRemaining: timeRemaining)
    }
    
    func resetCounter() {
        callCount = 0
        minuteStartTime = Date()
    }
}

class TransitAPI {
    private let apiKey = Config.shared.transitAPIKey
    private let baseURL = "https://api.winnipegtransit.com/v4"
    static let shared = TransitAPI()
    @Published private(set) var isLoading = false
    private let rateLimiter = RequestRateLimiter()
    static let winnipegTimeZone = TimeZone(identifier: "America/Winnipeg")!
    
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
       await rateLimiter.waitIfNeeded()

        
        isLoading = true
        
        defer {
            isLoading = false
        }
        
        
        // print("\n***** Sent: \(url.absoluteString) at \(Date())")
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw TransitError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            // print(httpResponse)
            throw TransitError.networkError(NSError(domain: "", code: httpResponse.statusCode))
            
        }
        
//        do {
//            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
//            print("Received: \(json)")
//        } catch {
//            print("Error occurred during JSON deserialization: \(error)")
//        }
        
        
        
        return data
    }
    
    func getNearbyStops(userLocation: CLLocation, forShort: Bool) async throws -> [Stop] {
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
        
        var finalStopsToReturn: [Stop] = []
        
        for stop in stops {
            finalStopsToReturn.append(Stop(from: stop))
        }
        
        var processedStops: [(stop: Stop, distance: Double)] = []
        
        for var stop in finalStopsToReturn {
            if forShort {
                stop.name = stop.name.replacingOccurrences(of: "@", with: " @ ")
            }
            
            processedStops.append((stop: stop, distance: stop.distance))
        }
        
        let currentDate = Date()
        
        processedStops = processedStops.filter { ($0.stop.effectiveFrom == nil || currentDate >= $0.stop.effectiveFrom ?? Date())  &&
                                                ($0.stop.effectiveTo == nil || currentDate <= $0.stop.effectiveTo ?? Date())
        }
        
        let sortedStops = processedStops
            .sorted { $0.distance < $1.distance }
            .prefix(getMaxStopsAllowedToFetch())
            .map { $0.stop }
        
        return sortedStops
    }
    
    func searchStops(query: String, forShort: Bool) async throws -> [Stop] {
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
        
        var finalStopsToReturn: [Stop] = [];
        
        if forShort {
            for stopData in stops {
                var toAdd: Stop = Stop(from: stopData)
                toAdd.name = toAdd.name.replacingOccurrences(of: "@", with: " @ ")
                finalStopsToReturn.append(toAdd)
            }
        } else {
            for stopData in stops {
                finalStopsToReturn.append(Stop(from: stopData))
            }
        }
        
        return Array(finalStopsToReturn.prefix(getMaxStopsAllowedToFetchForSearch()))
    }

    private func createVariantsForStop(_ stopNumber: Int, currentDate: Date, endDate: Date, forShort: Bool) async -> [Variant] {

        var variantToReturn: [Variant] = []
        
        guard let url = createURL(
            path: "routes.json",
            parameters: [
                "stop": stopNumber,
                "usage": forShort ? "short" : "long"
            ]
        ) else {
            print("Warning: Invalid URL for stop \(stopNumber), returning original variant")
            return variantToReturn
        }
        
        do {
            let data = try await fetchData(from: url)
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                    let routeSchedules = json["routes"] as? [[String: Any]]
            else {
                print("Warning: Invalid stop schedule data format for stop \(stopNumber), returning original variant")
                return variantToReturn
            }
            
            for routeSchedule in routeSchedules {
                guard let badgeStyle = routeSchedule["badge-style"] as? [String: Any],
                      let backgroundColor = badgeStyle["background-color"] as? String,
                      let borderColor = badgeStyle["border-color"] as? String,
                      let textColor = badgeStyle["color"] as? String,
                      let variants = routeSchedule["variants"] as? [[String: Any]]
                else {
                    print("Warning: Invalid route schedule format, skipping this route")
                    continue
                }
                
                let effectiveFrom = routeSchedule["effective-from"] as? String ?? ""
                let effectiveTo = routeSchedule["effective-to"] as? String ?? ""
                let name = routeSchedule["name"] as? String ?? "No Route Name"
                let number = routeSchedule["number"] as? String ?? "No Route Number"
                
                var routeKeyToUse = ""
                
                if let routeKey = routeSchedule["key"] as? String {
                    routeKeyToUse = routeKey
                } else if let routeKey = routeSchedule["key"] as? Int {
                    routeKeyToUse = String(routeKey)
                } else {
                    print("Warning: Invalid route key format or key not found, skipping this route")
                    continue
                }
                
                
                for variantData in variants {
                    do {
                        var enrichedVariantData = variantData
                        enrichedVariantData["background-color"] = backgroundColor
                        enrichedVariantData["border-color"] = borderColor
                        enrichedVariantData["text-color"] = textColor
                        enrichedVariantData["name"] = name == "No Route Name" ? number == "No Route Number" ? "No Route Name or Number" : number : name
                        enrichedVariantData["effective-from"] = effectiveFrom
                        enrichedVariantData["effective-to"] = effectiveTo
                        
                        let vaenrichedVariantDatariant = Variant(from: enrichedVariantData)
                        
                        variantToReturn.append(vaenrichedVariantDatariant)
                        
                        
                    } catch {
                        print("Warning: Failed to process variant data: \(error), skipping this variant")
                        continue
                    }
                    
                }
                
                
                do {
                    
                    var newRouteForThisKey = Route(key: routeKeyToUse, name: name, textColor: textColor, backgroundColor: backgroundColor, borderColor: borderColor, variants: variantToReturn)
                    
                    RouteCacheManager.shared.cacheRoute(newRouteForThisKey)
                    
                } catch {
                    print("Warning: Failed to cache route \(routeKeyToUse): \(error), continuing with next route")
                    continue
                }
            }
            
        } catch {
            print("Warning: Failed to fetch data for stop \(stopNumber): \(error), returning original variant")
        }
        
        return variantToReturn
    }

    
    private func validateCaches(stops: [Stop], enrichedStops: [Stop], currentDate: Date, endDate: Date, forShort: Bool) async throws -> Bool {
        let stopNumbers = stops.compactMap { $0.number  }
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
        
        var allVariantsToUse: [Variant] = []
        
        for variant in allVariants {
            allVariantsToUse.append(Variant(from: variant));
        }
        
        
        let bulkVariantsSet = Set(allVariantsToUse.compactMap { variant -> String? in
            return variant.key.split(separator: "-").first?.description
        })
        
        for enrichedStop in enrichedStops {
            let variants = enrichedStop.variants
            
            for variant in variants {
                
                let variantIdentifier = variant.key.split(separator: "-").first?.description ?? ""
                
                if !bulkVariantsSet.contains(variantIdentifier) {
                    
                    print("\n**********\n \(variant.key) from stop \(enrichedStop.number) was not found in the bulk variants request \n**********\n")
                    return false
                }
            }
        }
        
        return true
    }
    
    
    func getVariantsForStops(stops: [Stop], onStopEnriched: @escaping (Stop) async -> Void) async -> [Stop] {
        var enrichedStops: [Stop] = []
        let currentDate = Date()
        let calendar = Calendar.current
        let endDate = calendar.date(byAdding: .hour, value: getTimePeriodAllowedForNextBusRoutes(), to: currentDate)!
        
        for var stop in stops {
            if stop.number != -1 {
                var stopVariants: [Variant]
                
                if let cachedVariants = VariantsCacheManager.shared.getCachedVariants(for: stop.number), cachedVariants.count > 0 {
                    stopVariants = cachedVariants
                } else {
                    stopVariants = await createVariantsForStop(stop.number, currentDate: currentDate, endDate: endDate, forShort: getGlobalAPIForShortUsage())
                    do {
                        VariantsCacheManager.shared.cacheVariants(stopVariants, for: stop.number)
                    } catch {
                        print("Warning: Failed to cache variants for stop \(stop.number): \(error), continuing without caching")
                    }
                }
                
                if !stopVariants.isEmpty {
                    stopVariants = stopVariants.filter { variantObjects in
                        return !(variantObjects.key.prefix(1) == "S" || variantObjects.key.prefix(1) == "W" || variantObjects.key.prefix(1) == "I")
                    }
                    
                    stop.variants = stopVariants
                    enrichedStops.append(stop)
                    
                    await onStopEnriched(stop)
                }
            }
        }
        
        do {
          let cachesValid = try await validateCaches(stops: stops, enrichedStops: enrichedStops, currentDate: currentDate, endDate: endDate, forShort: getGlobalAPIForShortUsage())
            
            if !cachesValid {
                print("Warning: Caches invalid, clearing and retrying")
                VariantsCacheManager.shared.clearAllCaches()
                return await getVariantsForStops(stops: stops, onStopEnriched: onStopEnriched)
            }
        } catch {
            print("Warning: Failed to validate caches: \(error), proceeding with current results")
        }
        
        return enrichedStops
    }
    
    func getOnlyVariantsForStop(stop: Stop) async throws -> [Variant] {
        let currentDate = Date()
        let calendar = Calendar.current
        let endDate = calendar.date(byAdding: .hour, value: getTimePeriodAllowedForNextBusRoutes(), to: currentDate)!
        
        if stop.number != -1 {
            var stopVariants: [Variant] = []
            
            guard let url = createURL(
                path: "variants.json",
                parameters: [
                    "stop": stop.number,
                    "usage": getGlobalAPIForShortUsage() ? "short" : "long"
                ]
            ) else {
                print("Warning: Invalid URL for stop \(stop.number), returning original variant")
                return []
            }
            
            let data = try await fetchData(from: url)
            
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let allVariants = json["variants"] as? [[String: Any]] else {
                throw TransitError.parseError("Invalid bulk variants data format")
            }
            
            
            
            for currentVariant in allVariants {
                var variantToAdd = Variant(from: currentVariant)
                stopVariants.append(variantToAdd)
            }
            
            if !stopVariants.isEmpty {
                
                stopVariants = stopVariants.filter { variantObjects in
                    return !(variantObjects.key.prefix(1) == "S" || variantObjects.key.prefix(1) == "W" || variantObjects.key.prefix(1) == "I") &&
                    
                    (
                        (variantObjects.effectiveFrom == nil || currentDate >= variantObjects.effectiveFrom ?? Date())  &&
                     (variantObjects.effectiveTo == nil || currentDate <= variantObjects.effectiveTo ?? Date())
                    )
                }
                
                return Array(Set<Variant>(stopVariants))
            }
        }
        
        
        return []
    }
    
    func getStopSchedule(stopNumber: Int) async throws -> [String: Any] {
        let currentDate = Date()
        let calendar = Calendar.current
        let startDate = calendar.date(byAdding: .minute, value: -5, to: currentDate)!
        
        let currentComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: startDate)

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
        // let startOfNextDay = calendar.date(from: startOfNextDayComponents)!
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
                           let variantName = variant["name"] as? String,
                           let cancelled = stop["cancelled"] as? String,
                           let times = stop["times"] as? [String: Any],
                           let arrival = times["departure"] as? [String: Any] {
                            
                            let estimatedTime = arrival["estimated"] as? String
                            let scheduledTime = arrival["scheduled"] as? String
                            var finalArrivalText = ""
                            var arrivalState = getOKStatusTextString()

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
                                
                                guard let estimatedDate = dateFormatter.date(from: estimatedTimeStr),
                                      let scheduledDate = dateFormatter.date(from: scheduledTimeStr) else {
                                    continue
                                }
                                
                                let timeDifferenceSeconds = estimatedDate.timeIntervalSince(currentDate)
                                let timeDifference = Int(ceil(timeDifferenceSeconds / 60))
                                let delay = Int(ceil(estimatedDate.timeIntervalSince(scheduledDate) / 60))
                                

                                
                                    if timeDifference < -getMinutesAllowedToKeepDueBusesInSchedule() {
                                        continue
                                    }
                                
                                
                                if cancelled == "true" {
                                    arrivalState = getCancelledStatusTextString()
                                    finalArrivalText = ""
                                } else {
                                    if (timeDifference < 0 && timeFormat != TimeFormat.clockTime) {
                                        finalArrivalText = "\(Int(-timeDifference)) \(getMinutesPassedTextInArrivalTimes())"
                                    } else if (timeDifference <= getPeriodBeforeStartingToShowMinutesUntilNextBusInMinutes() && timeFormat != TimeFormat.clockTime) {
                                        finalArrivalText = "\(Int(timeDifference)) \(getMinutesRemainingTextInArrivalTimes())"
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
                                            finalArrivalText += " \(getGlobalAMText())"
                                        } else {
                                            finalArrivalText += " \(getGlobalPMText())"
                                        }
                                    }
                                    
                                    if (delay > 0 && timeDifference <= getPeriodBeforeStartingToShowMinutesUntilNextBusInMinutes() && timeFormat != TimeFormat.clockTime) {
                                        arrivalState = getLateStatusTextString()
                                        finalArrivalText = "\(Int(timeDifference)) \(getMinutesRemainingTextInArrivalTimes())"
                                    } else if delay < 0 && timeDifference <= getPeriodBeforeStartingToShowMinutesUntilNextBusInMinutes() {
                                        arrivalState = getEarlyStatusTextString()
                                        finalArrivalText = "\(Int(timeDifference)) \(getMinutesRemainingTextInArrivalTimes())"
                                    } else {
                                        arrivalState = getOKStatusTextString()
                                    }
                                    
                                    if (timeDifference <= 0 && timeDifference >= -getMinutesAllowedToKeepDueBusesInSchedule()) {
                                        finalArrivalText = getDueStatusTextString()
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
            
            if timeA == getDueStatusTextString() && timeB != getDueStatusTextString() {
                return true
            }
            if timeB == getDueStatusTextString() && timeA != getDueStatusTextString() {
                return false
            }
            if timeA == getDueStatusTextString() && timeB == getDueStatusTextString() {
                return true
            }
            
            let isMinutesA = timeA.hasSuffix(getMinutesRemainingTextInArrivalTimes())
            let isMinutesB = timeB.hasSuffix(getMinutesRemainingTextInArrivalTimes())
            
            if isMinutesA && isMinutesB {
                let minutesA = Int(timeA.components(separatedBy: " ")[0]) ?? 0
                let minutesB = Int(timeB.components(separatedBy: " ")[0]) ?? 0
                
                if minutesA != minutesB {
                    return minutesA < minutesB
                }
                
                let stateA = componentsA[2]
                let stateB = componentsB[2]
                
                if stateA != stateB {
                    if stateA == getOKStatusTextString() { return true }
                    if stateB == getOKStatusTextString() { return false }
                    if stateA == getEarlyStatusTextString() { return true }
                    if stateB == getEarlyStatusTextString() { return false }
                }
                
                return true
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
                let isAMA = timeComponentsA[1] == getGlobalAMText()
                let isAMB = timeComponentsB[1] == getGlobalAMText()
                
                let calendar = Calendar.current
                let currentDate = Date()
                let currentHour = calendar.component(.hour, from: currentDate)
                
                if !isAMA && hourA != 12 { hourA += 12 }
                if isAMA && hourA == 12 { hourA = 0 }
                if !isAMB && hourB != 12 { hourB += 12 }
                if isAMB && hourB == 12 { hourB = 0 }
                
                var totalMinutesA = hourA * 60 + minuteA
                var totalMinutesB = hourB * 60 + minuteB
                
                
                if currentHour >= 12 {
                    if isAMA {
                        totalMinutesA += 24 * 60
                    }
                    if isAMB {
                        totalMinutesB += 24 * 60
                    }
                }
    
                
                return totalMinutesA < totalMinutesB
            }
            
            return false
        })
    }
    
    func cleanScheduleMixedTimeFormat(schedule: [String: Any]) -> [String] {
        var busScheduleList: [String] = []
        let currentDate = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        var variantMinutesAdded: [String: Bool] = [:]
        var tempScheduleEntries: [(key: String, name: String, state: String, time: String, sortValue: Int)] = []
        
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
                           let arrival = times["departure"] as? [String: Any] {
                            
                            let estimatedTime = arrival["estimated"] as? String
                            let scheduledTime = arrival["scheduled"] as? String
                            var finalArrivalText = ""
                            var arrivalState = getOKStatusTextString()
                            var sortValue = 0
                            
                            if let estimatedTimeStr = estimatedTime,
                               let scheduledTimeStr = scheduledTime {
                                
                                let estimatedTimeParsedDateAndTime = estimatedTimeStr.components(separatedBy: "T")
                                let scheduledTimeParsedDateAndTime = scheduledTimeStr.components(separatedBy: "T")
                                let estimatedTimeParsedDate = estimatedTimeParsedDateAndTime[0].components(separatedBy: "-")
                                let estimatedTimeParsedTime = estimatedTimeParsedDateAndTime[1].components(separatedBy: ":")
                                let scheduledTimeParsedDate = scheduledTimeParsedDateAndTime[0].components(separatedBy: "-")
                                let scheduledTimeParsedTime = scheduledTimeParsedDateAndTime[1].components(separatedBy: ":")
                                
                                let estimatedTotalMinutes = (Int(estimatedTimeParsedDate[0])! * 525600) +
                                                          (Int(estimatedTimeParsedDate[1])! * 43800) +
                                                          (Int(estimatedTimeParsedDate[2])! * 1440) +
                                                          (Int(estimatedTimeParsedTime[0])! * 60) +
                                                          Int(estimatedTimeParsedTime[1])!
                                
                                let scheduledTotalMinutes = (Int(scheduledTimeParsedDate[0])! * 525600) +
                                                          (Int(scheduledTimeParsedDate[1])! * 43800) +
                                                          (Int(scheduledTimeParsedDate[2])! * 1440) +
                                                          (Int(scheduledTimeParsedTime[0])! * 60) +
                                                          Int(scheduledTimeParsedTime[1])!
                                
                                let currentDateComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: currentDate)
                                let currentTotalMinutes = (currentDateComponents.year! * 525600) +
                                                        (currentDateComponents.month! * 43800) +
                                                        (currentDateComponents.day! * 1440) +
                                                        (currentDateComponents.hour! * 60) +
                                                        currentDateComponents.minute!
                            
                                
                                guard let estimatedDate = dateFormatter.date(from: estimatedTimeStr),
                                      let scheduledDate = dateFormatter.date(from: scheduledTimeStr) else {
                                    continue
                                }
                                
                                let timeDifferenceSeconds = estimatedDate.timeIntervalSince(currentDate)
                                let timeDifference = Int(ceil(timeDifferenceSeconds / 60))
                                let delay = Int(round(estimatedDate.timeIntervalSince(scheduledDate) / 60))
                                
                                if timeDifference < -getMinutesAllowedToKeepDueBusesInSchedule() {
                                    continue
                                }
                                
                                if cancelled == "true" {
                                    arrivalState = getCancelledStatusTextString()
                                    finalArrivalText = ""
                                    sortValue = Int.max
                                } else {
                                    var timeIn12HourFormat = ""
                                    var timeInMinutes = ""
                                    var finalHour = Int(estimatedTimeParsedTime[0])!
                                    let am = finalHour < 12
                                    
                                    if finalHour == 0 {
                                        finalHour = 12
                                    } else if finalHour > 12 {
                                        finalHour -= 12
                                    }
                                    
                                    timeIn12HourFormat = "\(finalHour):\(estimatedTimeParsedTime[1]) \(am ? getGlobalAMText() : getGlobalPMText())"
                                    
                                    if timeDifference <= getPeriodBeforeStartingToShowMinutesUntilNextBusInMinutes() {
                                        timeInMinutes = "\(Int(timeDifference)) \(getMinutesRemainingTextInArrivalTimes())"
                                    }
                                    
                                    if (delay > 0 && timeDifference <= getPeriodBeforeStartingToShowMinutesUntilNextBusInMinutes()) {
                                        arrivalState = getLateStatusTextString()
                                    } else if delay < 0 && timeDifference <= getPeriodBeforeStartingToShowMinutesUntilNextBusInMinutes() {
                                        arrivalState = getEarlyStatusTextString()
                                    } else {
                                        arrivalState = getOKStatusTextString()
                                    }
                                    
                                    if (timeDifference <= 0 && timeDifference >= -getMinutesAllowedToKeepDueBusesInSchedule()) {
                                        timeInMinutes = getDueStatusTextString()
                                        sortValue = -1
                                    } else {
                                        sortValue = Int(timeDifference)
                                    }
                                    
                                    if let firstPart = variantKey.split(separator: "-").first {
                                        variantKey = String(firstPart)
                                    }
                                    
                                    if (variantKey.contains("BLUE")) {
                                        variantKey = "B"
                                    }
                                    
                                    let variantIdentifier = "\(variantKey)\(getScheduleStringSeparator())\(variantName)"
                                    
                                    if !variantMinutesAdded[variantIdentifier, default: false] && timeDifference <= getPeriodBeforeStartingToShowMinutesUntilNextBusInMinutes() {
                                        finalArrivalText = timeInMinutes
                                        variantMinutesAdded[variantIdentifier] = true
                                    } else {
                                        finalArrivalText = timeIn12HourFormat
                                    }
                                }
                            } else {
                                finalArrivalText = "Time Unavailable"
                                sortValue = Int.max
                            }
                            
                            tempScheduleEntries.append((
                                key: variantKey,
                                name: variantName,
                                state: arrivalState,
                                time: finalArrivalText,
                                sortValue: sortValue
                            ))
                        }
                    }
                }
            }
        }
        
        let sortedEntries = tempScheduleEntries.sorted { entry1, entry2 in
            if entry1.time == getDueStatusTextString() {
                return true
            }
            if entry2.time == getDueStatusTextString() {
                return false
            }
            
            if entry1.sortValue != entry2.sortValue {
                return entry1.sortValue < entry2.sortValue
            }
            
            if let route1 = Int(entry1.key), let route2 = Int(entry2.key) {
                return route1 < route2
            }
            
            return entry1.key < entry2.key
        }
        
        busScheduleList = sortedEntries.map { entry in
            "\(entry.key)\(getScheduleStringSeparator())\(entry.name)\(getScheduleStringSeparator())\(entry.state)\(getScheduleStringSeparator())\(entry.time)"
        }
        
        return busScheduleList
    }
    
    func getLocationKey(latitude: Double, longitude: Double) async throws -> String? {
        guard let url = createURL(
            path: "locations.json",
            parameters: [
                "lat": String(latitude),
                "lon": String(longitude),
                // "distance": "30",
                //"max-results": "3"
            ]
        ) else {
            throw TransitError.invalidURL
        }
        
        let data = try await fetchData(from: url)
        
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let locations = json["locations"] as? [[String: Any]],
              let firstLocation = locations.first else {
            return nil
        }
        
        guard let locationType = firstLocation["type"] as? String else {
            return nil
        }
        
        let key: String
        if let stringKey = firstLocation["key"] as? String {
            key = stringKey
        } else if let intKey = firstLocation["key"] as? Int {
            key = String(intKey)
        } else {
            return nil
        }
        
        switch locationType {
        case "intersection":
            return "intersections/\(key)"
        case "monument":
            return "monuments/\(key)"
        case "address":
            return "addresses/\(key)"
        default:
            return nil
        }
    }
    
    func findTrip(from origin: CLLocation, to destination: CLLocation) async throws -> [TripPlan] {
        var allPlans: [TripPlan] = []
        
        var parameters: [String: Any] = [
            "origin": "geo/\(origin.coordinate.latitude),\(origin.coordinate.longitude)",
            "destination": "geo/\(destination.coordinate.latitude),\(destination.coordinate.longitude)",
            "usage": getGlobalAPIForShortUsage() ? "short" : "long"
        ]
        
        guard let url = createURL(path: "trip-planner.json", parameters: parameters) else {
            throw TransitError.invalidURL
        }
        
        var data = try await fetchData(from: url)
        
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let plansArray = json["plans"] as? [[String: Any]] else {
            throw TransitError.parseError("Invalid trip planner data format")
        }
        
        for planDict in plansArray {
            do {
                let plan = try TripPlan(from: planDict)
                allPlans.append(plan)
            } catch {
                print("Error parsing plan: \(error)")
            }
        }
        
        var foundAtTransfers: Int? = nil
        
        for transfers in 0...5 {
            parameters["max-transfers"] = transfers
            
            guard let url = createURL(path: "trip-planner.json", parameters: parameters) else {
                throw TransitError.invalidURL
            }
            
            data = try await fetchData(from: url)
            
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let plansArray = json["plans"] as? [[String: Any]] else {
                throw TransitError.parseError("Invalid trip planner data format")
            }
            
            var plansForThisTransfer: [TripPlan] = []
            for planDict in plansArray {
                do {
                    let plan = try TripPlan(from: planDict)
                    plansForThisTransfer.append(plan)
                } catch {
                    print("Error parsing plan: \(error)")
                }
            }
            
            if !plansForThisTransfer.isEmpty {
                if foundAtTransfers == nil {
                    foundAtTransfers = transfers
                    allPlans.append(contentsOf: plansForThisTransfer)
                } else {
                    allPlans.append(contentsOf: plansForThisTransfer)
                    break
                }
            } else if foundAtTransfers != nil {
                continue
            }
            
            if transfers < 5 {
                try await Task.sleep(nanoseconds: 1_000_000_000)
            }
        }
        
        return Array(Set(allPlans))
    }

    func findTripWithLocationKey(
        from currentLocationKey: String,
        toLocationKey: String,
        walkSpeed: Double = 5.0,
        maxWalkTime: Int = 15,
        minTransferWait: Int = 2,
        maxTransferWait: Int = 15,
        maxTransfers: Int = 3,
        mode: String = "depart-after",
        date: Date? = nil
    ) async throws -> [TripPlan] {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm:ss"

        
        var allPlans: [TripPlan] = []
        
        var parameters: [String: Any] = [
            "origin": currentLocationKey,
            "destination": toLocationKey,
            // "walk-speed": walkSpeed,
            // "max-walk-time": maxWalkTime,
            // "min-transfer-wait": minTransferWait,
            // "max-transfer-wait": maxTransferWait,
            // "mode": mode,
            // "date": dateFormatter.string(from: winnipegDate),
            // "time": timeFormatter.string(from: winnipegDate),
            "usage": getGlobalAPIForShortUsage() ? "short" : "long"
        ]
        
        guard let url = createURL(path: "trip-planner.json", parameters: parameters) else {
            throw TransitError.invalidURL
        }
        
        var data = try await fetchData(from: url)
        
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let plansArray = json["plans"] as? [[String: Any]] else {
            throw TransitError.parseError("Invalid trip planner data format")
        }
        
        for planDict in plansArray {
            do {
                let plan = try TripPlan(from: planDict)
                allPlans.append(plan)
            } catch {
                print("Error parsing plan: \(error)")
            }
        }
        
        var foundAtTransfers: Int? = nil
        
        for transfers in 0...5 {
            parameters["max-transfers"] = transfers
            
            guard let url = createURL(path: "trip-planner.json", parameters: parameters) else {
                throw TransitError.invalidURL
            }
            
            data = try await fetchData(from: url)
            
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let plansArray = json["plans"] as? [[String: Any]] else {
                throw TransitError.parseError("Invalid trip planner data format")
            }
            
            var plansForThisTransfer: [TripPlan] = []
            for planDict in plansArray {
                do {
                    let plan = try TripPlan(from: planDict)
                    plansForThisTransfer.append(plan)
                } catch {
                    print("Error parsing plan: \(error)")
                }
            }
            
            if !plansForThisTransfer.isEmpty {
                if foundAtTransfers == nil {
                    foundAtTransfers = transfers
                    allPlans.append(contentsOf: plansForThisTransfer)
                } else {
                    allPlans.append(contentsOf: plansForThisTransfer)
                    break
                }
            } else if foundAtTransfers != nil {
                continue
            }
            
            if transfers < 5 {
                try await Task.sleep(nanoseconds: 1_000_000_000)  // 1 second delay
            }
        }
        
        return Array(Set(allPlans))
    }
}

