import SwiftUI

struct SplashScreenView: View {
    let onContinue: () -> Void
    
    @State private var showHeader = false
    @State private var showLocationCard = false
    @State private var showWidgetCard = false
    @State private var showContinueButton = false

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                VStack(spacing: 16) {
                    if showHeader {
                        HStack(spacing: 16) {
                            HeaderIcon(iconName: "square.grid.2x2.fill", color: .purple)
                            HeaderIcon(iconName: "location.fill", color: .blue)
                            HeaderIcon(iconName: getGlobalBusIconSystemImageName(), color: .orange)
                        }
                        .transition(.scale.combined(with: .opacity))
                    }
                    
                    VStack(spacing: 8) {
                        Text("Welcome to")
                            .font(.title3)
                            .foregroundColor(.secondary)
                        
                        Text("Peek Transit")
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(.primary)
                    }
                    .opacity(showHeader ? 1 : 0)
                    .offset(y: showHeader ? 0 : 10)
                }

                if showLocationCard {
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Location Access")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text("Peek Transit needs access to your location to:")
                            .font(.body)
                            .foregroundColor(.secondary)
                        
                        VStack(spacing: 12) {
                            FeatureCard(
                                icon: "location.north.circle.fill",
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
                                icon: "square.grid.2x2.fill",
                                color: .purple,
                                title: "Widget Support",
                                description: "Update widget information on your home and lock screens"
                            )
                        }
                        
                        InfoNoteCard(
                            icon: "lock.fill",
                            title: "Privacy Note",
                            message: "Peek Transit does not collect, store, or share any personal information or location data. Your location is only used within the app."
                        )
                    }
                    .modifier(CardModifier())
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .offset(y: 40)),
                        removal: .opacity)
                    )
                }
                
                if showWidgetCard {
                     VStack(alignment: .leading, spacing: 20) {
                        Text("Widget Setup")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text("Get quick access to transit information right from your home or lock screen:")
                            .font(.body)
                            .foregroundColor(.secondary)
                        
                        VStack(spacing: 12) {
                            FeatureCard(
                                icon: "paintbrush.pointed.fill",
                                color: .orange,
                                title: "Customizable Widgets",
                                description: "Create widgets with your preferred settings and appearance."
                            )
                            FeatureCard(
                                icon: "eye.fill",
                                color: .teal,
                                title: "See only what you need",
                                description: "Select which bus stops and bus variants to display on your widgets"
                            )
                            FeatureCard(
                                icon: "apps.iphone",
                                color: .pink,
                                title: "Flexible Placement",
                                description: "Place widgets on your home screen or lock screen for easy access and resize them as you need."
                            )
                        }
                    }
                    .modifier(CardModifier())
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .offset(y: 40)),
                        removal: .opacity)
                    )
                }
                
                if showContinueButton {
                    Button(action: onContinue) {
                        HStack {
                            Text("Continue")
                                .fontWeight(.semibold)
                            Image(systemName: "arrow.right")
                                .font(.system(size: 16, weight: .medium))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(16)
                        .shadow(color: Color.blue.opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .offset(y: 40)),
                        removal: .opacity)
                    )
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 32)
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .onAppear(perform: setupAnimations)
    }

    private func setupAnimations() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                showHeader = true
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.easeOut(duration: 0.7)) {
                showLocationCard = true
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            withAnimation(.easeOut(duration: 0.7)) {
                showWidgetCard = true
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            withAnimation(.easeOut(duration: 0.7)) {
                showContinueButton = true
            }
        }
    }
}

struct HeaderIcon: View {
    let iconName: String
    let color: Color

    var body: some View {
        Image(systemName: iconName)
            .font(.system(size: 50, weight: .regular))
            .foregroundColor(color)
            .frame(width: 100, height: 100)
            .background(color.opacity(0.1))
            .clipShape(Circle())
    }
}

struct FeatureCard: View {
    let icon: String
    let color: Color
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)
                .frame(width: 48, height: 48)
                .background(color.opacity(0.15))
                .cornerRadius(12)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.body.weight(.medium))
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
    }
}

struct InfoNoteCard: View {
    let icon: String
    let title: String
    let message: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(.blue.opacity(0.8))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.body.weight(.semibold))
                
                Text(message)
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .lineSpacing(3)
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
    }
}

struct CardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(16)
            .background(Color(.systemBackground))
            .cornerRadius(20)
            .shadow(color: .black.opacity(0.05), radius: 10, y: 5)
    }
}

