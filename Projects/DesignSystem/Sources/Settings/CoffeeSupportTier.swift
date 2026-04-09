import SwiftUI

public struct CoffeeSupportTier: Identifiable, Hashable {
    public let id: String
    public let title: String
    public let subtitle: String
    public let amount: Int
    public let icon: String

    public init(id: String, title: String, subtitle: String, amount: Int, icon: String) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.amount = amount
        self.icon = icon
    }

    private static let formatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter
    }()

    public var amountLabel: String {
        let number = NSNumber(value: amount)
        let formatted = Self.formatter.string(from: number) ?? "\(amount)"
        return "\(formatted)원"
    }

    public var tint: Color {
        switch id {
        case "starter": return Theme.orange
        case "booster": return Theme.cyan
        default: return Theme.pink
        }
        
    }

    public static let presets: [CoffeeSupportTier] = [
        CoffeeSupportTier(id: "starter", title: NSLocalizedString("coffee.tier.americano", comment: ""), subtitle: NSLocalizedString("coffee.tier.americano.sub", comment: ""), amount: 3000, icon: "cup.and.saucer.fill"),
        CoffeeSupportTier(id: "booster", title: NSLocalizedString("coffee.tier.latte", comment: ""), subtitle: NSLocalizedString("coffee.tier.latte.sub", comment: ""), amount: 5000, icon: "mug.fill"),
        CoffeeSupportTier(id: "nightshift", title: NSLocalizedString("coffee.tier.nightshift", comment: ""), subtitle: NSLocalizedString("coffee.tier.nightshift.sub", comment: ""), amount: 10000, icon: "takeoutbag.and.cup.and.straw.fill")
    ]
}
