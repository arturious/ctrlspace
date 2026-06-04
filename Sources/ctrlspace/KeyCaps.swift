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

struct CommandKeyCap: View {
    var body: some View {
        MacBookModifierKeyCap(symbol: "⌘", title: "command")
    }
}

struct MacBookModifierKeyCap: View {
    let symbol: String
    let title: String

    var body: some View {
        VStack(alignment: .trailing, spacing: 1) {
            Text(symbol)
                .font(.system(size: 12, weight: .regular))
                .foregroundStyle(.white.opacity(0.48))
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.trailing, 7)

            Spacer(minLength: 0)

            Text(title)
                .font(.system(size: 11, weight: .regular))
                .foregroundStyle(.white.opacity(0.48))
                .frame(maxWidth: .infinity, alignment: .leading)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .padding(.leading, 10)
        .padding(.trailing, 3)
        .padding(.top, 7)
        .padding(.bottom, 8)
        .frame(width: 69, height: 52)
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
