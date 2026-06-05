import SwiftUI

struct TabKeyCap: View {
    var body: some View {
        MacBookKeyCap(title: "tab")
    }
}

struct ReturnKeyCap: View {
    var body: some View {
        MacBookKeyCap(title: "return")
    }
}

struct DeleteKeyCap: View {
    var body: some View {
        MacBookKeyCap(title: "delete")
    }
}

struct EscapeKeyCap: View {
    var body: some View {
        MacBookKeyCap(title: "escape")
    }
}

struct CommandKeyCap: View {
    var body: some View {
        MacBookModifierKeyCap(symbol: "⌘", title: "command")
    }
}

struct ControlKeyCap: View {
    var body: some View {
        MacBookModifierKeyCap(
            symbol: "⌃",
            title: "control",
            width: 58,
            symbolTrailingPadding: 8
        )
    }
}

struct LetterKeyCap: View {
    let title: String

    init(_ title: String) {
        self.title = title
    }

    var body: some View {
        Text(title)
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(.white.opacity(0.48))
            .frame(width: 52, height: 52)
            .background {
                KeyboardKeyBackground()
            }
    }
}

struct MacBookModifierKeyCap: View {
    let symbol: String
    let title: String
    var width: CGFloat = 69
    var symbolSize: CGFloat = 12
    var titleSize: CGFloat = 11
    var leadingPadding: CGFloat = 10
    var trailingPadding: CGFloat = 3
    var symbolTrailingPadding: CGFloat = 7

    var body: some View {
        VStack(alignment: .trailing, spacing: 1) {
            Text(symbol)
                .font(.system(size: symbolSize, weight: .regular))
                .foregroundStyle(.white.opacity(0.48))
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.trailing, symbolTrailingPadding)

            Spacer(minLength: 0)

            Text(title)
                .font(.system(size: titleSize, weight: .regular))
                .foregroundStyle(.white.opacity(0.48))
                .frame(maxWidth: .infinity, alignment: .leading)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .padding(.leading, leadingPadding)
        .padding(.trailing, trailingPadding)
        .padding(.top, 7)
        .padding(.bottom, 8)
        .frame(width: width, height: 52)
        .background {
            KeyboardKeyBackground()
        }
    }
}

struct FunctionKeyCap: View {
    let systemName: String

    var body: some View {
        Image(systemName: systemName)
            .font(.system(size: 13, weight: .medium))
            .foregroundStyle(.white.opacity(0.58))
            .frame(width: 52, height: 52)
            .background {
                KeyboardKeyBackground()
            }
    }
}

struct NumberKeyCap: View {
    let number: Int
    let isSelected: Bool

    var body: some View {
        Text("\(number)")
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(.white.opacity(isSelected ? 0.68 : 0.42))
            .frame(width: 52, height: 52)
            .background {
                KeyboardKeyBackground()
                    .opacity(isSelected ? 1 : 0.74)
            }
    }
}

enum ArrowKeyDirection {
    case up
    case down
}

struct ArrowKeyCap: View {
    let direction: ArrowKeyDirection

    var body: some View {
        ArrowGlyph(direction: direction)
            .fill(Color(red: 0.957, green: 0.961, blue: 0.984).opacity(0.5))
            .frame(width: 52, height: 52)
            .background {
                KeyboardKeyBackground()
            }
    }
}

struct ArrowGlyph: Shape {
    let direction: ArrowKeyDirection

    func path(in rect: CGRect) -> Path {
        let glyphWidth: CGFloat = 7
        let glyphHeight: CGFloat = 8
        let minX = rect.midX - glyphWidth / 2
        let minY = rect.midY - glyphHeight / 2
        let maxX = minX + glyphWidth
        let maxY = minY + glyphHeight
        let midX = rect.midX

        var path = Path()
        switch direction {
        case .up:
            path.move(to: CGPoint(x: maxX, y: maxY))
            path.addLine(to: CGPoint(x: minX, y: maxY))
            path.addLine(to: CGPoint(x: midX, y: minY))
        case .down:
            path.move(to: CGPoint(x: minX, y: minY))
            path.addLine(to: CGPoint(x: maxX, y: minY))
            path.addLine(to: CGPoint(x: midX, y: maxY))
        }
        path.closeSubpath()
        return path
    }
}

struct MacBookKeyCap: View {
    let title: String

    var body: some View {
        VStack {
            Spacer()
            Text(title)
                .font(.system(size: 11, weight: .regular))
                .foregroundStyle(.white.opacity(0.48))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 10)
        .padding(.bottom, 8)
        .frame(width: 82, height: 52)
        .background {
            KeyboardKeyBackground()
        }
    }
}

struct KeyboardKeyBackground: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 6, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [
                        Color(red: 0.18, green: 0.18, blue: 0.19),
                        Color(red: 0.11, green: 0.11, blue: 0.12)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .overlay {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .strokeBorder(Color.black.opacity(0.78), lineWidth: 1.5)
            }
            .overlay(alignment: .bottom) {
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .fill(Color(red: 0.06, green: 0.06, blue: 0.065))
                    .frame(height: 3)
                    .padding(.horizontal, 1.5)
                    .padding(.bottom, 1.5)
            }
            .shadow(color: .black.opacity(0.48), radius: 1.5, y: 2)
    }
}
