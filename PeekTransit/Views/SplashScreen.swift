import SwiftUI

struct SplashScreenView: View {
    let onContinue: () -> Void
    @State private var showContent = false
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        ScrollView {
            ZStack {
                Color(UIColor.systemBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 30) {
                    VStack(spacing: 15) {
                        Image(systemName: "location.fill.viewfinder")
                            .font(.system(size: 70, weight: .medium))
                            .foregroundColor(.blue)
                            .background(
                                Circle()
                                    .fill(Color.blue.opacity(0.1))
                                    .frame(width: 110, height: 110)
                            )
                            .padding(.bottom, 5)
                            .opacity(showContent ? 1 : 0)
                            .scaleEffect(showContent ? 1 : 0.8)
                        
                        Text("Welcome to")
                            .font(.title2)
                            .foregroundColor(.secondary)
                            .opacity(showContent ? 1 : 0)
                            .offset(y: showContent ? 0 : 10)
                        
                        Text("Peek Transit")
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(.primary)
                            .opacity(showContent ? 1 : 0)
                            .offset(y: showContent ? 0 : 10)
                    }
                    
                    VStack(alignment: .leading, spacing: 24) {
                        Text("Location Access")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        Text("Peek Transit needs access to your location to:")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding(.bottom, 5)
                        
                        VStack(spacing: 15) {
                            FeatureCard(
                                icon: "mappin.circle.fill",
                                color: .blue,
                                title: "Find Nearby Stops",
                                description: "Show nearby bus stops to access live bus schedules"
                            )
                            
                            FeatureCard(
                                icon: "map.fill",
                                color: .green,
                                title: "Plan Your Routes",
                                description: "Start planning transit routes to your destination"
                            )
                            
                            FeatureCard(
                                icon: "note.text",
                                color: .purple,
                                title: "Widget Support",
                                description: "Update widget information on your home and lock screens"
                            )
                        }
                        
                        HStack(alignment: .top, spacing: 15) {
                            Image(systemName: "lock.shield.fill")
                                .foregroundColor(.blue.opacity(0.8))
                                .font(.system(size: 20))
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Privacy Note")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                
                                Text("Peek Transit does not collect, store, or share any personal information or location data. Your location is only used within the app.")
                                    .font(.footnote)
                                    .foregroundColor(.secondary)
                                    .lineSpacing(3)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                        .padding(.top, 8)
                        .padding(.horizontal, 4)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 25)
                    .padding(.vertical, 25)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color(UIColor.secondarySystemBackground))
                            .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
                    )
                    .padding(.horizontal, 20)
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : 20)
                    
                    Button(action: onContinue) {
                        HStack {
                            Text("Continue")
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                            
                            Image(systemName: "arrow.right")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.8)]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(15)
                        .shadow(color: Color.blue.opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : 20)
                }
                .padding(.vertical, 30)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                showContent = true
            }
        }
    }
}

struct FeatureCard: View {
    let icon: String
    let color: Color
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 15) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(color.opacity(0.15))
                    .frame(width: 48, height: 48)
                
                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundColor(color)
            }
            
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color(UIColor.tertiarySystemBackground))
        .cornerRadius(16)
    }
}
