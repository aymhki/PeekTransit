import SwiftUI

struct SizeSelectionStep: View {
    @Binding var selectedSize: String
    @Binding var selectedTimeFormat: TimeFormat
    @Binding var showLastUpdatedStatus: Bool
    @Binding var multipleEntriesPerVariant: Bool
    @State private var isLoading = false
    
    
    private let availableSizes = [
        "small",
        "medium",
        "large",
        "lockscreen"
    ]
    
    private var currentTheme: StopViewTheme {
        if let savedTheme = SharedDefaults.userDefaults?.string(forKey: settingsUserDefaultsKeys.sharedStopViewTheme),
           let theme = StopViewTheme(rawValue: savedTheme) {
            return theme
        }
        return .default
    }
    
    private let timeFormatExplainationText = "Due to the nature of iOS Widgets limitations, a live API widget can only be updated once every fiften minutes. For that reason, and until there is a fix around this issue it might not be very practical to display X(X) minutes remaining if the widget updates after that amount of minutes has passed. Select from the options below which format you want the bus arrival times to be displayed in when glancing at your widget.\n\nNote that for both oopt-in to see when the widget was last updated"

    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Text("Select the widget configuration options")
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
                            .fill(Color(currentTheme == .classic ? .black : .secondarySystemGroupedBackground))
                            .shadow(radius: 2)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                            )
                        
                        let (newSchedule, newWidgetData) = PreviewHelper.generatePreviewSchedule(from: ["size": selectedSize, "multipleEntriesPerVariant": multipleEntriesPerVariant], noConfig: true, timeFormat: selectedTimeFormat, showLastUpdatedStatus: showLastUpdatedStatus, multipleEntriesPerVariant: multipleEntriesPerVariant,
                         showLateTextStatus: selectedSize == "small" || selectedSize == "lockscreen") ?? ([], [:])

                    
                        DynamicWidgetView(
                            widgetData: newWidgetData ?? [:],
                            scheduleData: newSchedule,
                            size: PreviewHelper.getWidgetSize(from: selectedSize),
                            updatedAt: Date(),
                            fullyLoaded: true,
                            forPreview: true,
                            isLoading: false
                        )
                        
                        .if(currentTheme == .classic) { view in
                            view.background(.black)
                        }
                        
                        .padding(8)
                        .foregroundColor(Color.primary)
                        
                    
                    }
                    .if(currentTheme == .classic) { view in
                        view.background(.black)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .frame(maxWidth: getWidgetPreviewWidthForSize(widgetSizeSystemFormat: nil, widgetSizeStringFormat: selectedSize))
                    .frame(height: getWidgetPreviewRowHeightForSize(widgetSizeSystemFormat: nil, widgetSizeStringFormat: selectedSize))
                    .opacity(isLoading ? 0 : 1)
                    

                }
                .padding()
                
//                Text("Note that the preview is filled with placeholder data. Some text might be smooshed or cut off. The real appearance of the widget will depend on your device's screen size and orientation when you add the widget in your home/lock screen.")
//                    .font(.subheadline)
//                    .foregroundColor(.secondary)
//                    .padding(.horizontal)
                
                

                
                
                VStack(alignment: .leading, spacing: 16) {
                    Text("Bus Variants Per Stop")
                        .font(.headline)
                        .padding(.horizontal)
                    
//                    Text("Choose between seeing multiple arrival times for a single bus variant in each bus stop or seeing a single arrival time for multiple bus variants in each bus stop\n\nNote that some widget sizes will only allow you to select one bus variant even if you selected the 'multiple variants' option as the space available on the widget is limited.")
//                        .font(.subheadline)
//                        .foregroundColor(.secondary)
//                        .padding(.horizontal)
                    
                    VStack(spacing: 12) {
                        
                        Button(action: {
                            multipleEntriesPerVariant = true
                        }) {
                            HStack(alignment: .center, spacing: 8) {
                                CircularCheckbox(isSelected: multipleEntriesPerVariant == true)
                                    .frame(width: 24)
                                
                            Text("Multiple arrival times for a single bus variant in each bus stop")
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
                            multipleEntriesPerVariant = false
                        }) {
                            HStack(alignment: .center, spacing: 8) {
                                CircularCheckbox(isSelected: multipleEntriesPerVariant == false)
                                    .frame(width: 24)
                                
                            Text("Single arrival time for multiple bus variants in each bus stop")
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
                
                VStack(alignment: .leading, spacing: 16) {
                    Text("Time Format")
                        .font(.headline)
                        .padding(.horizontal)
                    
//                    Text(timeFormatExplainationText)
//                        .font(.subheadline)
//                        .foregroundColor(.secondary)
//                        .padding(.horizontal)
                    
                    VStack(spacing: 12) {
                        
                        Button(action: {}) {
                            HStack(alignment: .center, spacing: 8) {
                                CircularCheckbox(isSelected: multipleEntriesPerVariant)
                                    .frame(width: 24)
                                Text("Mixed format, one entry in minutes and one in clock format (Available only for the 'Multiple Variants' option)")
                                    .foregroundColor(.primary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .multilineTextAlignment(.leading)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                            .background(Color(.secondarySystemGroupedBackground))
                            .cornerRadius(10)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .disabled(!multipleEntriesPerVariant)
                        
                        
                        ForEach(TimeFormat.allCases, id: \.self) { format in
                            
                            Button(action: {
                                selectedTimeFormat = format
                            }) {
                                HStack(alignment: .center, spacing: 8) {
                                    CircularCheckbox(isSelected: (selectedTimeFormat == format && !multipleEntriesPerVariant))
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
                            .buttonStyle(PlainButtonStyle())
                            .disabled(multipleEntriesPerVariant)
                            
                        }
                        

                        
                    }
                    .padding(.horizontal)
                }
                
                VStack(alignment: .leading, spacing: 16) {
                    Text("Last Updated Status")
                        .font(.headline)
                        .padding(.horizontal)
                    
//                    Text("Do you want your widget to show when it was last updated under the bus arrival times?\n\nExample: Last updated 12:34 \(getGlobalPMText())\n\nNote that this text will always be in HH:MM \(getGlobalAMText())/\(getGlobalPMText()) format")
//                        .font(.caption)
//                        .foregroundColor(.secondary)
//                        .padding(.horizontal)
                    
//                Text("Note: Technically, the widget is supposed to update everytime you look at it, but your phone won't always allow it. For example: Low Power/Battery Saving Mode, Weak Internet connection, etc... In these cases, it can take up to 15 minutes for the widget to update")
//                    .font(.caption)
//                    .foregroundColor(.secondary)
//                    .padding(.horizontal)
                    
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
