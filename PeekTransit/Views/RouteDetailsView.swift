import SwiftUI

struct RouteDetailsView: View {
    let routePlan: TripPlan
    let onDismiss: () -> Void
    let onRouteSelected: (TripPlan) -> Void
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var body: some View {
        
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Recommended Route")
                    .font(.headline)
                Spacer()
                Button(action: onDismiss) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
            
            if isLoading {
                HStack {
                    Spacer()
                    ProgressView()
                        .padding()
                    Spacer()
                }
            } else if let error = errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .padding()
            } else {
                
                VStack(alignment: .leading, spacing: 10) {
                    Text("Total Trip: \(routePlan.duration) minutes")
                        .font(.subheadline)
                    
                    Text("Start Time: \(routePlan.startTimeString)")
                        .font(.subheadline)
                    
                    Text("End Time: \(routePlan.endTimeString)")
                        .font(.subheadline)
                    
                    Spacer()
                    
                    ForEach(routePlan.segments.indices, id: \.self) { index in
                        let segment = routePlan.segments[index]
                        
                        switch segment.type {
                        case .walk:
                            HStack(alignment: .top) {
                                Image(systemName: "figure.walk")
                                    .font(.system(size: 18))
                                    .frame(width: 24, height: 24)
                                    .foregroundColor(.blue)
                                
                                VStack(alignment: .leading) {
                                    Text("Walk \(segment.duration) min")
                                        .fontWeight(.medium)
                                    
                                    if let fromStop = segment.fromStop {
                                        Text("From: \(fromStop.name) (\(segment.startTimeStr))")
                                            .font(.caption)
                                    }
                                    
                                    if let toStop = segment.toStop {
                                        Text("To: \(toStop.name) (\(segment.endTimeStr))")
                                            .font(.caption)
                                    }
                                }
                            }
                            
                        case .ride:
                            HStack(alignment: .top) {
                                
                                Image(systemName: getGlobalBusIconSystemImageName())
                                    .font(.system(size: 18))
                                    .frame(width: 24, height: 24)
                                    .foregroundColor(.blue)
                                
                                
                                VStack(alignment: .leading) {
                                    
                                    if (segment.variantKey == nil || segment.variantName == nil) {
                                        
                                        let displayText = formatRouteDisplay(
                                            number: segment.routeNumber,
                                            name: segment.routeName
                                        )
                                        
                                        Text(displayText)
                                            .fontWeight(.medium)
                                    } else {
                                        if let variantKey = segment.variantKey?.split(separator: "-")[0], let variantName = segment.variantName?.replacingOccurrences(of: variantKey, with: "") {
                                            Text("\(variantKey) \(variantName)")
                                                .fontWeight(.medium)
                                        }
                                    }
                                    
                                    if let fromStop = segment.fromStop {
                                        Text("Board at: \(fromStop.name) (\(segment.startTimeStr))")
                                            .font(.caption)
                                    }
                                    
                                    if let toStop = segment.toStop {
                                        Text("Exit at: \(toStop.name) (\(segment.endTimeStr))")
                                            .font(.caption)
                                    }
                                    
                                    Text("Ride \(segment.duration) min")
                                        .font(.caption)
                                }
                            }
                            
                        case .transfer:
                            HStack {
                                Image(systemName: "arrow.right")
                                    .font(.system(size: 18))
                                    .frame(width: 24, height: 24)
                                    .foregroundColor(.orange)
                                
                                Text("Transfer")
                                    .fontWeight(.medium)
                            }
                        }
                        
                        if index < routePlan.segments.count - 1 {
                            Divider()
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
            }
            
            VStack {
                Button(action: {
                    let firstSegmentWithStop = routePlan.segments.first { ($0.fromStop != nil && $0.fromStop?.key != -1 && $0.fromStop?.location != nil) || ($0.toStop != nil && $0.toStop?.key != -1 && $0.toStop?.location != nil) }
                    
                    
                    if let stopNumber = getStopKeyFromSegment(theSegement: firstSegmentWithStop) {
                        withAnimation {
                            isLoading = true
                            errorMessage = nil
                            onDismiss()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                NotificationCenter.default.post(
                                    name: Notification.Name("FocusOnStop"),
                                    object: nil,
                                    userInfo: ["stopNumber": stopNumber, "showLoading": true]
                                )
                            }
                        }
                    } else {
                        errorMessage = "Could not find a valid stop in the route"
                    }
                }) {
                    Text("Show bus stop on map")
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .cornerRadius(10)
                }
                
                Button(action: {
                    onRouteSelected(routePlan)
                }) {
                    Text("Show bus stop schedule")
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(10)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        
    }
    
    private func formatRouteDisplay(number: String?, name: String?) -> String {
        var displayText = ""
        
        if let routeNumber = number {
            let cleanNumber = routeNumber.replacingOccurrences(of: "Optional(\"", with: "")
                .replacingOccurrences(of: "\")", with: "")
            displayText += cleanNumber
        }
        
        if let routeName = name {
            let cleanName = routeName.replacingOccurrences(of: "Optional(\"", with: "")
                .replacingOccurrences(of: "\")", with: "")
                
            if let routeNumber = number, cleanName.contains(routeNumber) {
                return cleanName
            } else if !cleanName.isEmpty {
                displayText = cleanName
            }
        }
        
        return displayText
    }
    
    private func getStopKeyFromSegment(theSegement: TripSegment?) -> Int? {
        if let fromStopKey = theSegement?.fromStop?.key, fromStopKey != -1 {
            return fromStopKey
        }
        
        if let toStopKey = theSegement?.toStop?.key, toStopKey != -1 {
            return toStopKey
        }
        
        return -1
    }
}

