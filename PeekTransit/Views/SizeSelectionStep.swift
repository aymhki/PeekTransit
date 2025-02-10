import SwiftUI

struct SizeSelectionStep: View {
    @Binding var selectedSize: String
    @Binding var selectedTimeFormat: TimeFormat
    @Binding var showLastUpdatedStatus: Bool
    @State private var isLoading = false
    
    private let availableSizes = [
        "small",
        "medium",
        "large",
        "lockscreen"
    ]
    
    private let timeFormatExplainationText = "Due to the nature of iOS Widgets limitations, a live API widget can only be updated once every five minutes. For that reason, and until there is a fix around this issue it might not be very practical to display X(X) minutes remaining (when the bus is within 15 minutes of arrival time) if the widget updates after that amount of minutes has passed. Select from the options below which format you want the bus arrival times to be displayed in when glancing at your widget.\n\nNote that for both options you can select from the options below to see when the widget was last updated"

    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Text("Select widget size, time format, and last updated status")
                    .font(.title3)
                    .padding([.top, .horizontal])
                
                Picker("Widget Size", selection: $selectedSize) {
                    ForEach(availableSizes, id: \.self) { size in
                        Text(size.capitalized)
                            .tag(size)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                
                ZStack {
                    if isLoading {
                        ProgressView("Loading preview...")
                    }
                    
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.secondarySystemGroupedBackground))
                            .shadow(radius: 2)
                        
                        let (newSchedule, newWidgetData) = PreviewHelper.generatePreviewSchedule(from: ["size": selectedSize], noConfig: true, timeFormat: selectedTimeFormat, showLastUpdatedStatus: showLastUpdatedStatus) ?? ([], [:])

                        
                        DynamicWidgetView(
                            widgetData: newWidgetData ?? [:],
                            scheduleData: newSchedule,
                            size: PreviewHelper.getWidgetSize(from: selectedSize),
                            updatedAt: Date(),
                            fullyLoaded: true,
                            forPreview: true
                            
                        )
                        .padding(8)
                        .foregroundColor(Color.primary)
                    }
                    .frame(maxWidth: getWidgetPreviewWidthForSize(widgetSizeSystemFormat: nil, widgetSizeStringFormat: selectedSize))
                    .frame(height: getWidgetPreviewHeightForSize(widgetSizeSystemFormat: nil, widgetSizeStringFormat: selectedSize))
                    .opacity(isLoading ? 0 : 1)
                }
                .padding()
                
                VStack(alignment: .leading, spacing: 16) {
                    Text("Time Format")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    Text(timeFormatExplainationText)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                    
                    VStack(spacing: 12) {
                        ForEach(TimeFormat.allCases, id: \.self) { format in
                            Button(action: {
                                selectedTimeFormat = format
                            }) {
                                HStack(alignment: .center, spacing: 8) {
                                    CircularCheckbox(isSelected: selectedTimeFormat == format)
                                        .frame(width: 24)
                                    Text(format.description)
                                        .foregroundColor(.primary)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .multilineTextAlignment(.leading)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding()
                                .background(Color(.secondarySystemGroupedBackground))
                                .cornerRadius(10)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                
                VStack(alignment: .leading, spacing: 16) {
                    Text("Last Updated Status")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    Text("Do you want your widget to show when it was last updated under the bus arrival times?\n\nExample: Last updated 12:34 PM\n\nNote that this text will always be in HH:MM AM/PM format")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                    
                    VStack(spacing: 12) {
                        Button(action: {
                            showLastUpdatedStatus = true
                        }) {
                            HStack(alignment: .center, spacing: 8) {
                                CircularCheckbox(isSelected: showLastUpdatedStatus == true)
                                    .frame(width: 24)
                                
                            Text("Show Last Updated Status")
                                    .foregroundColor(.primary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .multilineTextAlignment(.leading)
                                
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                            .background(Color(.secondarySystemGroupedBackground))
                            .cornerRadius(10)
                        }
                        
                        Button(action: {
                            showLastUpdatedStatus = false
                        }) {
                            HStack(alignment: .center, spacing: 8) {
                                CircularCheckbox(isSelected: showLastUpdatedStatus == false)
                                    .frame(width: 24)
                                
                            Text("Don't show Last Updated Status")
                                    .foregroundColor(.primary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .multilineTextAlignment(.leading)
                                
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                            .background(Color(.secondarySystemGroupedBackground))
                            .cornerRadius(10)
                        }
                    }
                    .padding(.horizontal)
                    
                }
                
                Spacer(minLength: 50)
            }
        }
        .onAppear {}
    }
}
