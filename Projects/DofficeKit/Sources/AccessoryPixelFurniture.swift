import SwiftUI
import DesignSystem

public func drawAccessoryPixelFurniture(context: GraphicsContext, itemId: String, at pos: CGPoint, dark: Bool, frame: Int = 0) {
    let x = pos.x
    let y = pos.y

    func px(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat, _ color: Color, _ opacity: Double = 1) {
        context.fill(Path(CGRect(x: x, y: y, width: w, height: h)), with: .color(color.opacity(opacity)))
    }

    switch itemId {
    case "sofa":
        let base = dark ? Color(hex: "70508E") : Color(hex: "8E6AB0")
        let shade = dark ? Color(hex: "533A6C") : Color(hex: "73588F")
        let light = dark ? Color(hex: "8A6BA7") : Color(hex: "AF8BCB")
        px(x + 1, y + 15, 43, 3, .black, dark ? 0.22 : 0.12)
        px(x - 2, y - 9, 49, 10, shade)
        px(x, y, 45, 13, base)
        px(x + 3, y + 2, 18, 8, light, 0.55)
        px(x + 24, y + 2, 18, 8, light, 0.55)
        px(x + 22, y + 2, 1, 8, shade, 0.7)
        px(x - 4, y - 8, 7, 22, base)
        px(x + 42, y - 8, 7, 22, base)
        px(x + 1, y - 8, 1, 20, Color.white, 0.08)
        px(x + 4, y + 13, 4, 7, shade)
        px(x + 37, y + 13, 4, 7, shade)

    case "sideTable":
        let wood = dark ? Color(hex: "7A5631") : Color(hex: "B8824A")
        let woodLight = dark ? Color(hex: "9E7248") : Color(hex: "E1AA6E")
        let woodDark = dark ? Color(hex: "5A3A1F") : Color(hex: "8B5A2D")
        px(x + 1, y + 11, 16, 2, .black, dark ? 0.20 : 0.10)
        px(x, y + 1, 18, 3, woodLight)
        px(x, y + 4, 18, 2, wood)
        px(x + 2, y + 6, 14, 7, wood)
        px(x + 8, y + 4, 2, 10, woodDark)
        px(x + 3, y + 8, 2, 2, Color(hex: "D7D0C5"))
        px(x + 6, y + 7, 5, 1, Color(hex: "5F7FB0"))
        px(x + 12, y + 3, 3, 3, Color(hex: "F2E7D7"))
        px(x + 14, y + 4, 1, 2, Color(hex: "F2E7D7"))
        px(x + 2, y + 13, 2, 6, woodDark)
        px(x + 14, y + 13, 2, 6, woodDark)

    case "coffeeMachine":
        let body = dark ? Color(hex: "59626E") : Color(hex: "7F8895")
        let top = dark ? Color(hex: "7A8591") : Color(hex: "A5B0BA")
        let slot = dark ? Color(hex: "2E3740") : Color(hex: "505A65")
        px(x + 2, y + 15, 12, 2, .black, dark ? 0.22 : 0.12)
        px(x + 1, y, 14, 16, body)
        px(x, y - 1, 16, 3, top)
        px(x + 3, y + 3, 10, 6, top, 0.9)
        px(x + 4, y + 4, 4, 1, Theme.green, 0.8)
        px(x + 3, y + 11, 10, 5, slot)
        px(x + 5, y + 13, 6, 5, Color(hex: "F7F3EE"))
        px(x + 11, y + 14, 2, 3, Color(hex: "F7F3EE"), 0.8)
        px(x + 6, y + 12, 4, 1, Color(hex: "7A4B35"), 0.65)
        let steam = sin(Double(frame) * 0.12)
        px(x + 6 + CGFloat(steam * 1.5), y + 9, 1, 2, .white, 0.25)
        px(x + 8 - CGFloat(steam), y + 7, 1, 2, .white, 0.18)

    case "plant":
        let pot = dark ? Color(hex: "A96A45") : Color(hex: "C98958")
        let potShade = dark ? Color(hex: "7C4B2E") : Color(hex: "955B33")
        let leaf = dark ? Color(hex: "3E7A38") : Color(hex: "5BAF4E")
        let leafLight = dark ? Color(hex: "5CA351") : Color(hex: "7ED16B")
        px(x + 1, y + 17, 12, 2, .black, dark ? 0.18 : 0.09)
        px(x, y + 12, 12, 6, pot)
        px(x - 1, y + 10, 14, 3, Color(hex: dark ? "BC7E57" : "E4A772"))
        px(x + 1, y + 10, 10, 2, potShade, 0.45)
        px(x + 5, y + 4, 2, 8, Color(hex: "497A35"))
        px(x - 1, y + 3, 8, 8, leaf)
        px(x + 4, y, 9, 9, leafLight, 0.95)
        px(x + 1, y - 3, 7, 7, leaf, 0.9)
        px(x + 4, y - 4, 4, 4, Color(hex: "F0B4B8"), 0.75)
        px(x + 5, y - 3, 2, 2, Color(hex: "F7E08A"), 0.8)

    case "clock":
        let rim = dark ? Color(hex: "CCD3DA") : Color(hex: "F5F6F8")
        let face = dark ? Color(hex: "F3EEE4") : Color(hex: "FFFDF8")
        let hand = dark ? Color(hex: "243040") : Color(hex: "3B4652")
        let cx = x + 7
        let cy = y + 7
        px(x, y, 14, 14, Color(hex: dark ? "8792A0" : "BEC8D1"), 0.8)
        px(x + 1, y + 1, 12, 12, rim)
        px(x + 2, y + 2, 10, 10, face)
        let minuteAngle = Double(frame % 120) / 120.0 * .pi * 2 - .pi / 2
        var minute = Path()
        minute.move(to: CGPoint(x: cx, y: cy))
        minute.addLine(to: CGPoint(x: cx + cos(minuteAngle) * 4, y: cy + sin(minuteAngle) * 4))
        context.stroke(minute, with: .color(hand.opacity(0.8)), lineWidth: 0.8)
        var hour = Path()
        hour.move(to: CGPoint(x: cx, y: cy))
        hour.addLine(to: CGPoint(x: cx + 1.6, y: cy - 2.6))
        context.stroke(hour, with: .color(hand), lineWidth: 0.9)
        px(cx - 1, cy - 1, 2, 2, Theme.red, 0.7)

    case "picture":
        let frame = dark ? Color(hex: "7C5B3C") : Color(hex: "B2895A")
        let frameLight = dark ? Color(hex: "9D734D") : Color(hex: "D7AB78")
        px(x, y, 20, 16, frame)
        px(x + 1, y, 18, 1, frameLight, 0.6)
        px(x + 2, y + 2, 16, 12, Color(hex: dark ? "CAE0F0" : "D9EEF8"))
        px(x + 2, y + 9, 16, 5, Color(hex: dark ? "527749" : "79B06C"), 0.75)
        var mountain = Path()
        mountain.move(to: CGPoint(x: x + 4, y: y + 13))
        mountain.addLine(to: CGPoint(x: x + 9, y: y + 6))
        mountain.addLine(to: CGPoint(x: x + 13, y: y + 10))
        mountain.addLine(to: CGPoint(x: x + 17, y: y + 5))
        mountain.addLine(to: CGPoint(x: x + 18, y: y + 13))
        mountain.closeSubpath()
        context.fill(mountain, with: .color(Color(hex: dark ? "5C7AA2" : "8AB7DE").opacity(0.8)))
        px(x + 13, y + 4, 3, 3, Color(hex: "F6E28D"), 0.85)

    case "neonSign":
        px(x, y, 64, 16, Color(hex: dark ? "0E1118" : "252B36"))
        px(x - 1, y - 1, 66, 18, Theme.yellow, dark ? 0.08 : 0.12)
        px(x + 3, y + 3, 12, 2, Theme.yellow, 0.7)
        px(x + 17, y + 3, 8, 2, Theme.yellow, 0.7)
        px(x + 27, y + 3, 11, 2, Theme.yellow, 0.7)
        px(x + 40, y + 3, 10, 2, Theme.yellow, 0.7)
        px(x + 52, y + 3, 8, 2, Theme.yellow, 0.7)
        context.draw(
            Text("BREAK").font(.system(size: 8, weight: .bold, design: .monospaced)).foregroundColor(Theme.yellow.opacity(0.9)),
            at: CGPoint(x: x + 23, y: y + 8)
        )
        context.draw(
            Text("ROOM").font(.system(size: 8, weight: .bold, design: .monospaced)).foregroundColor(Theme.cyan.opacity(0.85)),
            at: CGPoint(x: x + 47, y: y + 8)
        )

    case "rug":
        let rug = dark ? Color(hex: "91A582") : Color(hex: "B4C89C")
        let border = dark ? Color(hex: "617255") : Color(hex: "7E926A")
        px(x, y, 100, 14, rug, 0.82)
        px(x + 2, y + 2, 96, 10, border, 0.18)
        px(x + 4, y + 4, 92, 6, Color(hex: dark ? "D8E8BB" : "EFF7D8"), 0.12)
        for stripe in stride(from: CGFloat(6), to: 94, by: 8) {
            px(x + stripe, y + 6, 3, 1, border, 0.45)
        }

    case "bookshelf":
        let wood = dark ? Color(hex: "765132") : Color(hex: "A97444")
        let woodShade = dark ? Color(hex: "5A3A22") : Color(hex: "85572E")
        let woodHi = dark ? Color(hex: "976A46") : Color(hex: "D39A66")
        let bookColors = [
            Color(hex: "D85A4F"), Color(hex: "4F7FDE"), Color(hex: "59B569"),
            Color(hex: "E5B04E"), Color(hex: "A26BDA"), Color(hex: "42B7C6")
        ]
        px(x, y, 20, 36, wood)
        px(x + 1, y, 18, 1, woodHi, 0.55)
        for row in 0..<3 {
            let shelfY = y + CGFloat(row) * 12 + 11
            px(x, shelfY, 20, 2, woodShade)
            let startY = y + CGFloat(row) * 12 + 2
            for b in 0..<4 {
                let bx = x + 2 + CGFloat(b) * 4
                let color = bookColors[(row * 4 + b) % bookColors.count]
                px(bx, startY + CGFloat(b % 2), 3, 8 - CGFloat(b % 2), color, 0.85)
                px(bx + 1, startY + 1 + CGFloat(b % 2), 1, 5, .white, 0.18)
            }
        }

    case "aquarium":
        let glass = Color(hex: dark ? "7AA9C6" : "A8D9F1")
        let water = Color(hex: dark ? "2D6A9D" : "5FB5E4")
        let stand = dark ? Color(hex: "55626F") : Color(hex: "8696A4")
        px(x + 1, y + 18, 20, 2, .black, dark ? 0.18 : 0.10)
        px(x, y, 22, 18, glass, 0.35)
        px(x + 1, y + 3, 20, 14, water, 0.55)
        px(x + 2, y + 2, 18, 1, .white, 0.18)
        px(x + 2, y + 14, 18, 2, Color(hex: "CFB078"), 0.65)
        let fishX = x + 5 + sin(Double(frame) * 0.06) * 5
        px(CGFloat(fishX), y + 8, 5, 3, Color(hex: "F48E47"), 0.85)
        px(CGFloat(fishX) + 4, y + 9, 2, 1, Color(hex: "F48E47"), 0.85)
        let fish2X = x + 12 + sin(Double(frame) * 0.04 + 2) * 4
        px(CGFloat(fish2X), y + 12, 4, 2, Color(hex: "63D4E6"), 0.8)
        px(CGFloat(fish2X) + 3, y + 12, 1, 1, Color(hex: "63D4E6"), 0.8)
        let bubbleY = y + 7 - sin(Double(frame) * 0.08) * 3
        px(x + 15, CGFloat(bubbleY), 2, 2, .white, 0.28)
        px(x + 13, CGFloat(bubbleY) + 4, 1.5, 1.5, .white, 0.22)
        px(x - 1, y + 17, 24, 2, stand)

    case "arcade":
        let body = dark ? Color(hex: "4B2A80") : Color(hex: "6B43B8")
        let bodyDark = dark ? Color(hex: "33195B") : Color(hex: "4B2D83")
        px(x + 1, y + 28, 14, 2, .black, dark ? 0.24 : 0.13)
        px(x, y + 2, 16, 28, body)
        px(x + 2, y, 12, 5, Color(hex: dark ? "6B4DAD" : "8F6CDB"))
        px(x + 2, y + 4, 12, 9, Color(hex: dark ? "12202E" : "1B2C38"))
        px(x + 4, y + 6, 8, 5, Theme.green, 0.35)
        px(x + 5, y + 16, 2, 2, Theme.red, 0.82)
        px(x + 10, y + 17, 2, 2, Color(hex: "F1D05A"), 0.7)
        px(x + 2, y + 27, 3, 4, bodyDark)
        px(x + 11, y + 27, 3, 4, bodyDark)
        px(x + 6, y + 1, 4, 1, Color.white, 0.2)

    case "whiteboard":
        let frameColor = dark ? Color(hex: "9BA5B3") : Color(hex: "C2C8D0")
        let board = dark ? Color(hex: "EEF2F6") : Color(hex: "F9FBFD")
        px(x + 1, y + 20, 28, 2, .black, dark ? 0.14 : 0.08)
        px(x, y, 30, 22, frameColor)
        px(x + 1.5, y + 1.5, 27, 19, board)
        px(x + 3, y + 4, 12, 1, Theme.red, 0.45)
        px(x + 3, y + 7, 18, 1, Theme.accent, 0.35)
        px(x + 3, y + 10, 10, 1, Theme.green, 0.35)
        px(x + 18, y + 6, 6, 4, Color(hex: "EACB93"), 0.35)
        px(x + 8, y + 20, 14, 2, Color(hex: dark ? "7D8793" : "9AA4AE"))

    case "lamp":
        let pole = dark ? Color(hex: "556270") : Color(hex: "90A0AE")
        let shade = dark ? Color(hex: "E7C76B") : Color(hex: "F4DB8B")
        let glow = 0.08 + sin(Double(frame) * 0.04) * 0.03
        px(x + 4, y + 8, 2, 22, pole)
        px(x + 1, y + 28, 8, 2, pole)
        px(x, y, 10, 8, shade, 0.8)
        px(x + 1, y + 1, 8, 2, .white, 0.12)
        context.fill(Path(ellipseIn: CGRect(x: x - 5, y: y + 5, width: 20, height: 22)), with: .color(shade.opacity(glow)))

    case "cat":
        let fur = dark ? Color(hex: "CE9B58") : Color(hex: "D3A05E")
        let furLight = dark ? Color(hex: "E0BD7D") : Color(hex: "E9C889")
        px(x + 1, y + 10, 10, 2, .black, dark ? 0.14 : 0.08)
        px(x + 1, y + 3, 8, 6, fur)
        px(x + 7, y, 5, 5, fur)
        px(x + 7, y - 1, 2, 2, furLight)
        px(x + 10, y - 1, 2, 2, furLight)
        px(x + 8, y + 2, 1, 1, Theme.green, 0.85)
        px(x + 10, y + 2, 1, 1, Theme.green, 0.85)
        let tailWave = sin(Double(frame) * 0.08) * 2
        px(x - 1, y + 4 + CGFloat(tailWave), 3, 1, fur)

    case "tv":
        let body = dark ? Color(hex: "1A1E28") : Color(hex: "2A2E38")
        let screen = dark ? Color(hex: "0E2436") : Color(hex: "16364A")
        let cabinet = dark ? Color(hex: "765031") : Color(hex: "A16F44")
        px(x + 1, y + 16, 26, 2, .black, dark ? 0.20 : 0.10)
        px(x, y, 28, 18, body)
        px(x + 2, y + 2, 24, 13, screen)
        px(x + 4, y + 4, 20, 9, Theme.accent, 0.25)
        px(x + 11, y + 16, 6, 2, body)
        px(x + 4, y + 19, 20, 3, cabinet)
        px(x + 7, y + 20, 4, 1, Color(hex: "F0C25A"), 0.55)

    case "fan":
        let body = dark ? Color(hex: "5B6772") : Color(hex: "94A1AC")
        px(x + 5, y + 10, 2, 12, body)
        px(x + 2, y + 20, 8, 3, body)
        let fanAngle = Double(frame) * 0.3
        for blade in 0..<3 {
            let angle = fanAngle + Double(blade) * 2.094
            let bx = x + 6 + cos(angle) * 5
            let by = y + 6 + sin(angle) * 5
            context.fill(Path(ellipseIn: CGRect(x: CGFloat(bx) - 2, y: CGFloat(by) - 1, width: 4, height: 3)),
                         with: .color(body.opacity(0.6)))
        }
        px(x + 4, y + 4, 4, 4, body)

    case "calendar":
        let paper = dark ? Color(hex: "EDF0F5") : Color(hex: "FFFDF8")
        px(x, y, 14, 14, paper, 0.95)
        px(x, y, 14, 4, Theme.red, 0.82)
        px(x + 3, y + 2, 2, 2, Theme.overlayBg, 0.18)
        context.draw(
            Text("23").font(.system(size: 6, weight: .bold, design: .monospaced)).foregroundColor(Theme.overlay.opacity(0.55)),
            at: CGPoint(x: x + 7, y: y + 10)
        )

    case "poster":
        px(x, y, 16, 20, Color(hex: dark ? "2D4D72" : "4178C2"), 0.92)
        px(x + 2, y + 2, 12, 16, Color(hex: dark ? "3B658F" : "5E90D7"), 0.45)
        px(x + 5, y + 4, 6, 6, Color(hex: "F6D96E"), 0.55)
        px(x + 3, y + 13, 10, 1, .white, 0.32)
        px(x + 4, y + 16, 8, 1, .white, 0.24)

    case "trashcan":
        let bin = dark ? Color(hex: "69737E") : Color(hex: "88929D")
        let lid = dark ? Color(hex: "85909B") : Color(hex: "A0A9B3")
        px(x + 1, y + 10, 8, 2, .black, dark ? 0.16 : 0.08)
        px(x + 1, y + 2, 8, 10, bin)
        px(x, y, 10, 3, lid)
        px(x + 4, y - 1, 2, 2, lid)
        px(x + 2, y + 4, 1, 5, .white, 0.10)

    case "cushion":
        let base = dark ? Color(hex: "A76B86") : Color(hex: "DD95B6")
        let light = dark ? Color(hex: "C288A1") : Color(hex: "F5B5CE")
        context.fill(Path(ellipseIn: CGRect(x: x, y: y, width: 12, height: 8)), with: .color(base.opacity(0.85)))
        context.fill(Path(ellipseIn: CGRect(x: x + 2, y: y + 1, width: 8, height: 5)), with: .color(light.opacity(0.45)))
        px(x + 5.5, y + 2, 1, 3, Color(hex: dark ? "8B536C" : "C27A98"), 0.45)

    default:
        break
    }
}

