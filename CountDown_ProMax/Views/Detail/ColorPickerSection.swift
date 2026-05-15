import SwiftUI

struct ColorPickerSection: View {
    @Binding var selectedColor: ColorToken

    private let columns = Array(repeating: GridItem(.fixed(36), spacing: 8), count: 9)

    var body: some View {
        Section("Color") {
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(ColorToken.allCases) { token in
                    Circle()
                        .fill(token.color)
                        .frame(width: 28, height: 28)
                        .overlay {
                            if selectedColor == token {
                                Image(systemName: "checkmark")
                                    .font(.caption.bold())
                                    .foregroundStyle(.white)
                            }
                        }
                        .overlay {
                            Circle()
                                .strokeBorder(
                                    selectedColor == token ? token.color : .clear,
                                    lineWidth: 2
                                )
                                .frame(width: 34, height: 34)
                        }
                        .contentShape(Circle())
                        .onTapGesture { selectedColor = token }
                }
            }
            .padding(.vertical, 4)
        }
    }
}

#Preview {
    Form {
        ColorPickerSection(selectedColor: .constant(.blue))
    }
    .padding()
    .frame(width: 400)
}
