import WidgetKit
import SwiftUI

struct SmallWidgetView: View {
    var entry: Provider.Entry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if entry.scheduleData.isEmpty {
                ErrorView()
            } else {
                ForEach(entry.scheduleData.sorted(by: { $0.key < $1.key }), id: \.key) { variant, time in
                    HStack {
                        Text(variant)
                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                        Spacer()
                        Text(time)
                            .font(.system(size: 14, design: .monospaced))
                            .foregroundColor(timeColor(for: time))
                    }
                }
            }
        }
        .padding()
    }
    
    private func timeColor(for text: String) -> Color {
        if text.lowercased().contains("min") {
            return .blue
        } else if text == "Due" {
            return .green
        }
        return .primary
    }
}

struct MediumWidgetView: View {
    var entry: Provider.Entry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(entry.config.name)
                .font(.headline)
                .padding(.bottom, 4)
            
            if entry.scheduleData.isEmpty {
                ErrorView()
            } else {
                ForEach(entry.scheduleData.sorted(by: { $0.key < $1.key }), id: \.key) { variant, time in
                    HStack {
                        Text(abbreviatedVariantName(variant))
                            .font(.system(size: 12, design: .monospaced))
                        Spacer()
                        Text(time)
                            .font(.system(size: 14, design: .monospaced))
                            .foregroundColor(timeColor(for: time))
                    }
                }
            }
        }
        .padding()
    }
    
    private func abbreviatedVariantName(_ name: String) -> String {
        name.split(separator: " ")
            .compactMap { $0.first?.uppercased() }
            .joined(separator: " ")
    }
}

struct LargeWidgetView: View {
    var entry: Provider.Entry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(entry.config.name)
                .font(.headline)
                .padding(.bottom, 4)
            
            if entry.scheduleData.isEmpty {
                ErrorView()
            } else {
                ForEach(entry.scheduleData.sorted(by: { $0.key < $1.key }), id: \.key) { variant, time in
                    HStack {
                        Text(abbreviatedVariantName(variant))
                            .font(.system(size: 14, design: .monospaced))
                        Spacer()
                        Text(time)
                            .font(.system(size: 16, design: .monospaced))
                            .foregroundColor(timeColor(for: time))
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .padding()
    }
    
    private func abbreviatedVariantName(_ name: String) -> String {
        let abbreviations = [
            "University of Manitoba": "U of M",
            "Prairie Pointe": "Prairie P.",
            "Kildonan Place": "Kildonan P."
            // Add all your existing abbreviations from BusStopView
        ]
        return abbreviations[name] ?? name
    }
    
    private func timeColor(for text: String) -> Color {
        if text.lowercased().contains("min") {
            return .blue
        } else if text == "Due" {
            return .green
        } else if text.lowercased().contains("cancel") {
            return .red
        }
        return .primary
    }
}

struct LockScreenWidgetView: View {
    var entry: Provider.Entry
    
    var body: some View {
        VStack(alignment: .leading) {
            if let first = entry.scheduleData.first {
                Text(entry.config.name)
                    .font(.caption)
                Text(first.value)
                    .font(.title)
            } else {
                Text("No upcoming buses")
                    .font(.caption)
            }
        }
        .padding()
    }
}

struct ErrorView: View {
    var body: some View {
        VStack {
            Image(systemName: "exclamationmark.triangle")
            Text("No schedule data")
                .font(.caption)
        }
        .foregroundColor(.secondary)
    }
}


private func timeColor(for text: String) -> Color {
    if text.lowercased().contains("min") {
        return .blue
    } else if text == "Due" {
        return .green
    } else if text.lowercased().contains("cancel") {
        return .red
    }
    return .primary
}
