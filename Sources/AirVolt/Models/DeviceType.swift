import Foundation

public enum DeviceType: String, Codable, CaseIterable {
    case mouse
    case keyboard
    case headset
    case gamepad
    case trackpad
    case other

    public var sfSymbol: String {
        switch self {
        case .mouse:
            return "magicmouse"
        case .keyboard:
            return "keyboard"
        case .headset:
            return "headphones"
        case .gamepad:
            return "gamecontroller"
        case .trackpad:
            return "hand.draw"
        case .other:
            return "battery.100"
        }
    }

    public var unicodeEmoji: String {
        switch self {
        case .mouse:
            return "🖱"
        case .keyboard:
            return "⌨️"
        case .headset:
            return "🎧"
        case .gamepad:
            return "🎮"
        case .trackpad:
            return "🖐"
        case .other:
            return "🔋"
        }
    }

    public var displayName: String {
        switch self {
        case .mouse:
            return "Мышь"
        case .keyboard:
            return "Клавиатура"
        case .headset:
            return "Наушники"
        case .gamepad:
            return "Геймпад"
        case .trackpad:
            return "Трекпад"
        case .other:
            return "Устройство"
        }
    }
}
