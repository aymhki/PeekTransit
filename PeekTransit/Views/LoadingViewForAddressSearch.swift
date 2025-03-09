import SwiftUI

struct LoadingViewForAddressSearch: View {
    var body: some View {
        VStack {
            ProgressView("Finding routes...")
                .padding()
        }
        .frame(maxWidth: .infinity)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding()
    }
}
