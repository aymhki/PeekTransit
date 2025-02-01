import SwiftUI


struct BusScheduleRow: View {
    let schedule: String
    let size: String
    
    var body: some View {
        let components = schedule.components(separatedBy: " ---- ")
        if components.count >= 4 {
            HStack {
                Text(components[0])
                    .bold()
                
                if !components[1].isEmpty {
                    Text(components[1])
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.leading, 4)
                }
                
                Spacer()
                if components[2] == "Late" || components[2] == "Early" {
                    Text(components[2])
                        .foregroundColor(components[2] == "Late" ? .red : .yellow)
                        .font(.caption)
                }
                Text(components[3])
            }
        }
    }
}

