import SwiftUI

struct TermsAndPrivacyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Terms of Use & Privacy Policy")
                    .font(.title.bold())
                    .padding(.bottom)
                
                Group {
                    Text("Introduction")
                        .font(.headline)
                    Text("Peek Transit is a third-party application that utilizes the Winnipeg Transit API to provide bus stop information, schedules, and transit widgets. This app is not affiliated with or endorsed by Winnipeg Transit or The City of Winnipeg.")
                }
                
                Group {
                    Text("Data Usage & Attribution")
                        .font(.headline)
                    Text("All transit data is provided by permission of Winnipeg Transit, a department of The City of Winnipeg. The data is licensed under the Public Domain Dedication and License (PDDL).")
                }
                
                Group {
                    Text("Privacy Policy")
                        .font(.headline)
                    Text("• Peek Transit does not collect or store any personal information\n• Your saved widgets and stops are stored locally on your device\n• No analytics or tracking services are implemented\n• No data is shared with third parties")
                }
                
                Group {
                    Text("Disclaimer")
                        .font(.headline)
                    Text("This application is provided 'as is' without warranty of any kind. While Peek Transit strive to provide accurate and timely information, it cannot guarantee the accuracy of the data as it is directly sourced from Winnipeg Transit's API.")
                }
                
                Group {
                    Text("Contact")
                        .font(.headline)
                    Text("For any questions or concerns regarding this application, please contact the developer through the About section.")
                }
            }
            .padding()
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

