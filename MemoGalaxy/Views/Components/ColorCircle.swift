import SwiftUI

struct ColorCircle: View {
    @Environment(\.colorScheme) var colorScheme
    let color: String
    let colorName: String
    let isSelected: Bool

    var body: some View {
        ZStack {
            Circle()
                .stroke(isSelected ? Color.white : Color.clear, lineWidth: 3)
                .frame(width: 54, height: 54)

            Circle()
                .fill(Color(hex: color))
                .frame(width: isSelected ? 48 : 44, height: isSelected ? 48 : 44)
                .shadow(color: .primary.opacity(0.2), radius: isSelected ? 8 : 4, x: 0, y: 2)
                .animation(.spring(), value: isSelected)

            if isSelected {
                VStack(spacing: 4) {
                    Text(colorName)
                        .font(.caption2)
                        .padding(6)
                        .background(
                            Capsule()
                                .fill(colorScheme == .dark ?
                                      Color.black.opacity(0.7) :
                                        Color.white.opacity(0.9))
                                .shadow(radius: 2)
                        )
                        .foregroundColor(colorScheme == .dark ? .white : .black)
                        .offset(y: 32)
                        .transition(.move(edge: .bottom).combined(with: .opacity))

                    Image(systemName: "arrowtriangle.down.fill")
                        .font(.system(size: 8))
                        .foregroundColor(colorScheme == .dark ?
                                         Color.black.opacity(0.7) :
                                            Color.white.opacity(0.9))
                        .offset(y: 24)
                }
            }
        }
    }
}
