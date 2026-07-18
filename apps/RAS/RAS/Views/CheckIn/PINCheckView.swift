import SwiftUI

struct PINCheckView: View {
    @Binding var pin: String
    let isLockedOut: Bool
    let lockoutRemaining: TimeInterval
    let onDigit: (String) -> Void
    let onDelete: () -> Void

    private let digits = [["1", "2", "3"], ["4", "5", "6"], ["7", "8", "9"], ["", "0", "⌫"]]

    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 12) {
                ForEach(0..<AppConstants.pinLength, id: \.self) { index in
                    Circle()
                        .fill(index < pin.count ? Color.primary : Color.gray.opacity(0.3))
                        .frame(width: 14, height: 14)
                }
            }

            if isLockedOut {
                Text("Réessaie dans \(Int(lockoutRemaining)) s")
                    .foregroundStyle(.safeRed)
            }

            ForEach(digits, id: \.self) { row in
                HStack(spacing: 24) {
                    ForEach(row, id: \.self) { digit in
                        if digit.isEmpty {
                            Color.clear.frame(width: 64, height: 64)
                        } else {
                            Button {
                                if digit == "⌫" {
                                    onDelete()
                                } else {
                                    onDigit(digit)
                                }
                            } label: {
                                Text(digit)
                                    .font(.title)
                                    .frame(width: 64, height: 64)
                                    .background(Color.safeCard)
                                    .clipShape(Circle())
                            }
                            .disabled(isLockedOut)
                        }
                    }
                }
            }
        }
    }
}
