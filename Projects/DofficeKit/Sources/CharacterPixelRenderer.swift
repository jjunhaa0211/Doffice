import SwiftUI
import DesignSystem

// MARK: - Character Pixel Art Renderer (재사용 가능한 캐릭터 픽셀아트 렌더러)

public enum CharacterPixelRenderer {

    /// 캐릭터 픽셀아트를 Canvas 컨텍스트에 그립니다.
    public static func draw(character: WorkerCharacter, context: GraphicsContext, size: CGSize, scale: CGFloat = 2.5) {
        let s = scale
        let x: CGFloat = (size.width - 16 * s) / 2
        let y: CGFloat = (size.height - 22 * s) / 2 + 2

        let fur = Color(hex: character.skinTone)
        let hair = Color(hex: character.hairColor)
        let shirt = Color(hex: character.shirtColor)
        let pants = Color(hex: character.pantsColor)

        func px(_ px: CGFloat, _ py: CGFloat, _ w: CGFloat, _ h: CGFloat, _ c: Color) {
            context.fill(Path(CGRect(x: x + px * s, y: y + py * s, width: w * s, height: h * s)), with: .color(c))
        }

        // 서브픽셀 디테일용 (반투명 오버레이)
        func glow(_ px0: CGFloat, _ py0: CGFloat, _ w: CGFloat, _ h: CGFloat, _ c: Color, _ op: CGFloat) {
            context.fill(Path(CGRect(x: x + px0 * s, y: y + py0 * s, width: w * s, height: h * s)), with: .color(c.opacity(op)))
        }

        // 눈 하이라이트 (반짝)
        func eyeSparkle(_ ex: CGFloat, _ ey: CGFloat) {
            glow(ex, ey, 0.7, 0.7, .white, 0.85)
        }

        switch character.species {
        case .cat:
            // 귀 (그라데이션)
            px(3, -2, 3, 3, fur); px(10, -2, 3, 3, fur)
            glow(3.5, -1.5, 1.5, 1.5, .white, 0.12)  // 귀 하이라이트
            glow(10.5, -1.5, 1.5, 1.5, .white, 0.12)
            px(4, -1, 1, 1, Color(hex: "f0a0a0")); px(11, -1, 1, 1, Color(hex: "f0a0a0"))  // 귀 안쪽
            // 머리
            px(4, 1, 8, 6, fur)
            glow(5, 1.5, 6, 1, .white, 0.15)  // 이마 하이라이트
            glow(4, 6, 8, 1, .black, 0.08)  // 턱 그림자
            // 눈 (큰 고양이 눈)
            px(5, 3, 2, 2, Color(hex: "60c060")); px(6, 3, 1, 2, Color(hex: "1a1a1a"))
            px(9, 3, 2, 2, Color(hex: "60c060")); px(10, 3, 1, 2, Color(hex: "1a1a1a"))
            eyeSparkle(5, 3); eyeSparkle(9, 3)
            // 코 & 수염
            px(7, 5, 2, 1, Color(hex: "f08080"))
            glow(7.3, 4.6, 1.4, 0.4, Color(hex: "f0a0a0"), 0.5)  // 코 하이라이트
            px(2, 5, 2, 1, Color(hex: "ddd")); px(12, 5, 2, 1, Color(hex: "ddd"))  // 수염
            glow(1.5, 4.5, 2.5, 0.5, Color(hex: "eee"), 0.3)  // 수염 추가
            glow(12, 4.5, 2.5, 0.5, Color(hex: "eee"), 0.3)
            // 볼터치
            glow(4.5, 5.5, 2, 1, Color(hex: "f0a0a0"), 0.3)
            glow(9.5, 5.5, 2, 1, Color(hex: "f0a0a0"), 0.3)
            // 몸통
            px(4, 7, 8, 7, shirt)
            glow(5, 7.5, 6, 1.5, .white, 0.12)  // 옷 하이라이트
            glow(4, 12, 8, 2, .black, 0.08)  // 옷 그림자
            // 팔 & 다리
            px(3, 12, 3, 2, fur); px(10, 12, 3, 2, fur)
            px(4, 14, 3, 3, fur); px(9, 14, 3, 3, fur)
            glow(4.5, 14.5, 1, 1, Color(hex: "f0a0a0"), 0.4)  // 발바닥 패드
            glow(9.5, 14.5, 1, 1, Color(hex: "f0a0a0"), 0.4)
            // 꼬리 (더 풍성)
            px(13, 10, 2, 2, fur); px(14, 8, 2, 3, fur)
            glow(14.5, 8.5, 1, 2, .white, 0.15)  // 꼬리 하이라이트
            glow(13.5, 11, 1, 1, fur, 0.6)  // 꼬리 끝

        case .dog:
            // 늘어진 귀
            px(2, 1, 3, 5, hair); px(11, 1, 3, 5, hair)
            glow(2.5, 1.5, 1, 3, .white, 0.1)  // 귀 하이라이트
            glow(11.5, 1.5, 1, 3, .white, 0.1)
            // 머리
            px(4, 0, 8, 7, fur)
            glow(5, 0.5, 6, 1, .white, 0.14)  // 이마 반사
            // 눈
            px(5, 3, 2, 2, .white); px(6, 4, 1, 1, Color(hex: "333"))
            px(9, 3, 2, 2, .white); px(10, 4, 1, 1, Color(hex: "333"))
            eyeSparkle(5.2, 3.2); eyeSparkle(9.2, 3.2)
            // 코 & 입
            px(7, 5, 2, 1, Color(hex: "333"))
            glow(7.3, 4.6, 1.4, 0.4, Color(hex: "444"), 0.6)  // 코 위 하이라이트
            px(7, 6, 2, 1, Color(hex: "f06060"))
            // 볼터치
            glow(4.5, 5.5, 2, 1, Color(hex: "f0a0a0"), 0.25)
            glow(9.5, 5.5, 2, 1, Color(hex: "f0a0a0"), 0.25)
            // 몸통
            px(4, 7, 8, 7, shirt)
            glow(5, 7.5, 6, 1.5, .white, 0.12)
            glow(4, 12, 8, 2, .black, 0.07)
            px(3, 12, 3, 2, fur); px(10, 12, 3, 2, fur)
            px(4, 14, 3, 3, fur); px(9, 14, 3, 3, fur)
            glow(4.5, 14.5, 1.5, 1, Color(hex: "f0c0a0"), 0.3)  // 발바닥
            glow(9.5, 14.5, 1.5, 1, Color(hex: "f0c0a0"), 0.3)
            // 꼬리
            px(13, 5, 2, 2, fur); px(14, 3, 2, 3, fur)
            glow(14, 3.5, 1.5, 1, .white, 0.15)

        case .rabbit:
            // 긴 귀
            px(5, -5, 2, 6, fur); px(9, -5, 2, 6, fur)
            glow(5.3, -4.5, 0.8, 4, .white, 0.12)  // 귀 바깥 하이라이트
            glow(9.3, -4.5, 0.8, 4, .white, 0.12)
            px(5, -4, 1, 4, Color(hex: "f0a0a0")); px(10, -4, 1, 4, Color(hex: "f0a0a0"))  // 귀 안쪽
            glow(5.2, -3, 0.6, 2, Color(hex: "f5c0c0"), 0.4)  // 귀 안쪽 하이라이트
            glow(10.2, -3, 0.6, 2, Color(hex: "f5c0c0"), 0.4)
            // 머리
            px(4, 1, 8, 6, fur)
            glow(5, 1.5, 6, 1, .white, 0.16)
            // 눈
            px(5, 3, 2, 2, Color(hex: "d04060")); px(6, 3, 1, 1, Color(hex: "1a1a1a"))
            px(9, 3, 2, 2, Color(hex: "d04060")); px(10, 3, 1, 1, Color(hex: "1a1a1a"))
            eyeSparkle(5, 3); eyeSparkle(9, 3)
            // 코 & 볼터치
            px(7, 5, 2, 1, Color(hex: "f0a0a0"))
            glow(4.5, 5, 2, 1.5, Color(hex: "f5b0b0"), 0.3)
            glow(9.5, 5, 2, 1.5, Color(hex: "f5b0b0"), 0.3)
            // 몸통
            px(4, 7, 8, 7, shirt)
            glow(5, 7.5, 6, 1.5, .white, 0.12)
            glow(4, 12, 8, 2, .black, 0.07)
            px(3, 12, 3, 2, fur); px(10, 12, 3, 2, fur)
            px(5, 14, 3, 3, fur); px(8, 14, 3, 3, fur)
            // 꼬리 (솜뭉치)
            px(13, 11, 3, 3, .white)
            glow(13.5, 11.2, 1.5, 1, .white, 0.5)  // 꼬리 반사
            glow(13, 12.5, 2, 1, Color(hex: "e8e0e0"), 0.3)  // 꼬리 그림자

        case .bear:
            // 둥근 귀
            px(3, -1, 3, 3, fur); px(10, -1, 3, 3, fur)
            px(4, 0, 1, 1, Color(hex: "c09060")); px(11, 0, 1, 1, Color(hex: "c09060"))  // 귀 안쪽
            glow(3.5, -0.5, 1, 1, .white, 0.12)
            glow(10.5, -0.5, 1, 1, .white, 0.12)
            // 머리
            px(4, 1, 8, 7, fur)
            glow(5, 1.5, 6, 1, .white, 0.13)
            // 주둥이 영역
            px(6, 5, 4, 3, Color(hex: "d0b090"))
            glow(6.5, 5.2, 3, 0.8, Color(hex: "e0c8a8"), 0.4)  // 주둥이 하이라이트
            // 눈
            px(5, 3, 2, 2, Color(hex: "1a1a1a"))
            px(9, 3, 2, 2, Color(hex: "1a1a1a"))
            eyeSparkle(5, 3); eyeSparkle(9, 3)
            px(7, 5, 2, 1, Color(hex: "333"))
            // 볼터치
            glow(4.5, 5, 1.5, 1.5, Color(hex: "f0a0a0"), 0.22)
            glow(10, 5, 1.5, 1.5, Color(hex: "f0a0a0"), 0.22)
            // 몸통
            px(3, 8, 10, 7, shirt)
            glow(4, 8.5, 8, 1.5, .white, 0.1)
            glow(3, 13, 10, 2, .black, 0.06)
            // 배 무늬
            glow(5.5, 9.5, 5, 3, Color(hex: "e0c8a0"), 0.15)
            // 팔
            px(2, 10, 3, 3, fur); px(11, 10, 3, 3, fur)
            glow(2.5, 10.5, 1, 1.5, .white, 0.1)
            // 다리
            px(4, 15, 4, 3, fur); px(8, 15, 4, 3, fur)
            glow(5, 16, 1.5, 1, Color(hex: "c09060"), 0.4)  // 발바닥
            glow(9, 16, 1.5, 1, Color(hex: "c09060"), 0.4)

        case .penguin:
            let navy = Color(hex: "2a2a3a")
            // 머리
            px(4, 0, 8, 5, navy)
            glow(5.5, 0.5, 5, 1, Color(hex: "3a3a4a"), 0.5)  // 머리 반사
            px(5, 2, 6, 4, .white)
            // 눈
            px(6, 3, 1, 1, Color(hex: "1a1a1a")); px(9, 3, 1, 1, Color(hex: "1a1a1a"))
            eyeSparkle(6, 3); eyeSparkle(9, 3)
            // 부리
            px(7, 5, 2, 1, Color(hex: "f0b040"))
            glow(7.2, 4.7, 1.6, 0.4, Color(hex: "f0c060"), 0.5)
            // 볼터치
            glow(5, 4, 1.5, 1, Color(hex: "f0b0b0"), 0.25)
            glow(9.5, 4, 1.5, 1, Color(hex: "f0b0b0"), 0.25)
            // 몸통
            px(3, 6, 10, 8, navy)
            px(5, 7, 6, 6, .white)
            glow(6, 7.5, 4, 1.5, Color(hex: "f0f0ff"), 0.15)  // 배 하이라이트
            // 날개
            px(2, 8, 2, 5, navy); px(12, 8, 2, 5, navy)
            glow(2.5, 8.5, 1, 3, Color(hex: "3a3a4a"), 0.4)
            glow(12.5, 8.5, 1, 3, Color(hex: "3a3a4a"), 0.4)
            // 발
            px(5, 14, 3, 2, Color(hex: "f0b040")); px(8, 14, 3, 2, Color(hex: "f0b040"))
            glow(5.5, 14.2, 2, 0.5, Color(hex: "f0c060"), 0.4)
            glow(8.5, 14.2, 2, 0.5, Color(hex: "f0c060"), 0.4)

        case .fox:
            let foxOrange = Color(hex: "e07030")
            // 귀 (그라데이션)
            px(3, -2, 3, 4, foxOrange); px(10, -2, 3, 4, foxOrange)
            px(4, -1, 1, 2, .white); px(11, -1, 1, 2, .white)  // 귀 안쪽
            glow(3.5, -1.5, 1, 2, Color(hex: "f08040"), 0.5)  // 귀 하이라이트
            glow(10.5, -1.5, 1, 2, Color(hex: "f08040"), 0.5)
            // 머리
            px(4, 1, 8, 6, fur)
            glow(5, 1.5, 6, 1, .white, 0.14)
            // 뺨 흰색 무늬
            px(4, 4, 3, 3, .white); px(9, 4, 3, 3, .white)
            // 눈 (여우 특유의 날카로운 눈)
            px(5, 3, 2, 1, Color(hex: "f0c020")); px(6, 3, 1, 1, Color(hex: "1a1a1a"))
            px(9, 3, 2, 1, Color(hex: "f0c020")); px(10, 3, 1, 1, Color(hex: "1a1a1a"))
            eyeSparkle(5, 3); eyeSparkle(9, 3)
            // 코
            px(7, 5, 2, 1, Color(hex: "333"))
            glow(7.3, 4.6, 1.4, 0.4, Color(hex: "555"), 0.5)
            // 볼터치
            glow(4.5, 5, 2, 1.5, Color(hex: "f0b090"), 0.25)
            glow(9.5, 5, 2, 1.5, Color(hex: "f0b090"), 0.25)
            // 몸통
            px(4, 7, 8, 7, shirt)
            glow(5, 7.5, 6, 1.5, .white, 0.12)
            glow(4, 12, 8, 2, .black, 0.07)
            px(3, 12, 3, 2, fur); px(10, 12, 3, 2, fur)
            px(4, 14, 3, 3, fur); px(9, 14, 3, 3, fur)
            // 꼬리 (풍성하고 끝이 흰색)
            px(12, 9, 3, 2, fur); px(13, 7, 3, 4, fur)
            px(14, 11, 2, 1, .white)
            glow(13.5, 7.5, 1.5, 2, Color(hex: "f08040"), 0.3)  // 꼬리 하이라이트
            glow(14.2, 10.5, 1.5, 1, .white, 0.4)  // 흰 끝 부분 글로우

        case .robot:
            let metalBody = Color(hex: "a0b0c0")
            let metalDark = Color(hex: "8090a0")
            let led = Color(hex: "60f0a0")
            // 안테나
            px(7, -3, 2, 3, metalDark)
            px(6, -4, 4, 1, led)
            glow(6.5, -4, 3, 0.5, led, 0.5)  // LED 글로우
            glow(7, -4.5, 2, 0.5, led, 0.3)  // LED 확산
            // 머리
            px(3, 0, 10, 7, metalBody)
            px(4, 1, 8, 5, metalDark)
            glow(4.5, 1, 7, 1, Color(hex: "c0d0e0"), 0.3)  // 메탈 반사
            glow(3, 5, 10, 2, .black, 0.08)
            // 눈 (LED)
            px(5, 3, 2, 2, led); px(9, 3, 2, 2, led)
            glow(5, 3, 2, 2, led, 0.3)  // 눈 글로우
            glow(9, 3, 2, 2, led, 0.3)
            eyeSparkle(5.2, 3.2); eyeSparkle(9.2, 3.2)
            // 입
            px(6, 5, 4, 1, Color(hex: "506070"))
            glow(6.5, 5, 3, 0.5, led, 0.15)  // 입 LED
            // 몸통
            px(3, 7, 10, 8, shirt)
            px(3, 7, 10, 1, metalDark)
            glow(4, 8, 8, 1.5, .white, 0.1)
            glow(6.5, 10, 3, 2, led, 0.08)  // 가슴 LED 반사
            // 팔
            px(1, 9, 2, 5, metalDark); px(13, 9, 2, 5, metalDark)
            glow(1.3, 9.5, 0.8, 3, Color(hex: "b0c0d0"), 0.25)
            glow(13.3, 9.5, 0.8, 3, Color(hex: "b0c0d0"), 0.25)
            // 다리
            px(4, 15, 3, 3, Color(hex: "708090")); px(9, 15, 3, 3, Color(hex: "708090"))
            glow(4.5, 15.5, 1, 1.5, Color(hex: "90a0b0"), 0.3)
            glow(9.5, 15.5, 1, 1.5, Color(hex: "90a0b0"), 0.3)

        case .claude:
            let c = Color(hex: character.shirtColor)
            let eye = Color(hex: "2a1810")
            // 몸체
            px(4, 1, 8, 1, c)
            px(3, 2, 10, 7, c)
            glow(4, 2.5, 8, 1.5, .white, 0.15)  // 상단 하이라이트
            glow(3, 7, 10, 2, .black, 0.06)
            // 팔 (꽃잎처럼)
            px(1, 3, 2, 2, c); px(0, 4, 1, 1, c)
            px(13, 3, 2, 2, c); px(15, 4, 1, 1, c)
            glow(1.3, 3.3, 1.2, 1, .white, 0.15)
            glow(13.3, 3.3, 1.2, 1, .white, 0.15)
            // 눈
            px(5, 4, 1, 2, eye); px(10, 4, 1, 2, eye)
            eyeSparkle(5, 4)
            eyeSparkle(10, 4)
            // 다리 패턴
            px(4, 9, 1, 3, c); px(6, 9, 1, 3, c)
            px(9, 9, 1, 3, c); px(11, 9, 1, 3, c)
            glow(4, 9, 1, 2, .white, 0.1)
            glow(11, 9, 1, 2, .white, 0.1)

        case .alien:
            // 머리 (더 넓은 두상)
            px(3, -1, 10, 2, fur)
            px(2, 1, 12, 6, fur)
            glow(4, 0, 8, 1, .white, 0.12)  // 이마 반사
            glow(2, 5, 12, 2, .black, 0.06)
            // 눈 (큰 검은 눈)
            px(4, 3, 3, 3, Color(hex: "101010"))
            px(9, 3, 3, 3, Color(hex: "101010"))
            px(5, 4, 1, 1, Color(hex: "40ff80")); px(10, 4, 1, 1, Color(hex: "40ff80"))
            glow(5, 4, 1, 1, Color(hex: "40ff80"), 0.4)  // 눈 글로우
            glow(10, 4, 1, 1, Color(hex: "40ff80"), 0.4)
            eyeSparkle(4.5, 3.3); eyeSparkle(9.5, 3.3)
            // 몸통
            px(5, 7, 6, 5, shirt)
            px(3, 8, 2, 4, shirt); px(11, 8, 2, 4, shirt)
            glow(6, 7.5, 4, 1.5, .white, 0.1)
            // 다리
            px(5, 12, 2, 4, fur); px(9, 12, 2, 4, fur)
            // 안테나
            px(7, -3, 2, 2, Color(hex: "40ff80"))
            px(8, -4, 1, 1, Color(hex: "80ffa0"))
            glow(7, -3.5, 2, 1, Color(hex: "40ff80"), 0.35)  // 안테나 글로우

        case .ghost:
            // 머리 (반투명 효과)
            px(4, 0, 8, 3, fur)
            px(3, 3, 10, 6, fur)
            glow(5, 0.5, 6, 1.5, .white, 0.25)  // 유령 반사
            glow(4, 1, 8, 3, .white, 0.08)
            // 눈
            px(5, 4, 2, 2, Color(hex: "303040"))
            px(9, 4, 2, 2, Color(hex: "303040"))
            glow(5, 4, 2, 2, Color(hex: "5050a0"), 0.15)  // 눈 약간 보라빛
            glow(9, 4, 2, 2, Color(hex: "5050a0"), 0.15)
            eyeSparkle(5.2, 4.2); eyeSparkle(9.2, 4.2)
            // 입
            px(6, 7, 4, 1, Color(hex: "404050"))
            // 하체 (물결 형태)
            px(3, 9, 3, 3, fur); px(6, 10, 4, 2, fur); px(10, 9, 3, 3, fur)
            px(4, 12, 2, 1, fur); px(8, 12, 2, 1, fur); px(12, 12, 1, 1, fur)
            glow(3, 9, 10, 1, .white, 0.1)
            // 전체 글로우 효과
            glow(2.5, -0.5, 11, 13, .white, 0.04)

        case .dragon:
            // 뿔
            px(4, -2, 2, 2, Color(hex: "f0c030"))
            px(10, -2, 2, 2, Color(hex: "f0c030"))
            glow(4.3, -1.8, 1, 1, Color(hex: "f8e060"), 0.5)  // 뿔 하이라이트
            glow(10.3, -1.8, 1, 1, Color(hex: "f8e060"), 0.5)
            // 머리
            px(4, 0, 8, 6, fur)
            glow(5, 0.5, 6, 1, .white, 0.12)
            // 눈 (불꽃 같은)
            px(5, 2, 2, 2, Color(hex: "ff4020"))
            px(9, 2, 2, 2, Color(hex: "ff4020"))
            glow(5, 2, 2, 2, Color(hex: "ff6040"), 0.2)  // 눈 글로우
            glow(9, 2, 2, 2, Color(hex: "ff6040"), 0.2)
            eyeSparkle(5, 2); eyeSparkle(9, 2)
            // 입
            px(6, 5, 4, 1, Color(hex: "f06030"))
            glow(6.5, 5, 3, 0.5, Color(hex: "ff8050"), 0.4)
            // 몸통
            px(3, 6, 10, 6, shirt)
            glow(4, 6.5, 8, 1.5, .white, 0.1)
            // 날개
            px(0, 5, 3, 5, shirt.opacity(0.6))
            px(13, 5, 3, 5, shirt.opacity(0.6))
            glow(0.5, 5.5, 2, 2, .white, 0.1)
            glow(13.5, 5.5, 2, 2, .white, 0.1)
            // 배 비늘 무늬
            glow(5.5, 7.5, 5, 3, Color(hex: "f0d090"), 0.12)
            // 다리 & 꼬리
            px(4, 12, 3, 4, fur); px(9, 12, 3, 4, fur)
            px(13, 10, 3, 2, shirt); px(14, 12, 2, 1, shirt)
            glow(14, 10.5, 1.5, 1, shirt, 0.3)

        case .chicken:
            // 볏
            px(6, -2, 4, 2, Color(hex: "e03020"))
            glow(6.5, -1.8, 3, 0.8, Color(hex: "f05040"), 0.5)  // 볏 하이라이트
            // 머리
            px(5, 0, 6, 5, fur)
            glow(6, 0.5, 4, 1, .white, 0.15)
            // 눈
            px(6, 2, 2, 2, Color(hex: "101010"))
            eyeSparkle(6, 2)
            // 부리
            px(11, 3, 2, 1, Color(hex: "f0a020"))
            glow(11, 2.8, 1.5, 0.4, Color(hex: "f0c040"), 0.5)
            // 볏(아래)
            px(6, 5, 1, 2, Color(hex: "f03020"))
            // 볼터치
            glow(5.5, 3.5, 1.5, 1, Color(hex: "f0a0a0"), 0.25)
            // 몸통
            px(4, 5, 8, 7, shirt)
            glow(5, 5.5, 6, 1.5, .white, 0.1)
            // 날개
            px(2, 6, 2, 4, shirt.opacity(0.7)); px(12, 6, 2, 4, shirt.opacity(0.7))
            glow(2.3, 6.5, 1, 2, .white, 0.12)
            glow(12.3, 6.5, 1, 2, .white, 0.12)
            // 다리
            px(5, 12, 2, 4, Color(hex: "f0a020")); px(9, 12, 2, 4, Color(hex: "f0a020"))
            glow(5.3, 12.5, 0.8, 2, Color(hex: "f0c040"), 0.3)
            glow(9.3, 12.5, 0.8, 2, Color(hex: "f0c040"), 0.3)

        case .owl:
            // 귀 깃털
            px(3, -1, 3, 3, hair); px(10, -1, 3, 3, hair)
            glow(3.5, -0.5, 1.5, 1, .white, 0.12)
            glow(10.5, -0.5, 1.5, 1, .white, 0.12)
            // 머리
            px(4, 1, 8, 6, fur)
            glow(5, 1.5, 6, 1, .white, 0.14)
            // 눈 (큰 올빼미 눈)
            px(4, 3, 3, 3, Color(hex: "f0e0a0"))
            px(9, 3, 3, 3, Color(hex: "f0e0a0"))
            glow(4.3, 3.3, 2, 1.5, Color(hex: "f8ecc0"), 0.3)  // 눈테 하이라이트
            glow(9.3, 3.3, 2, 1.5, Color(hex: "f8ecc0"), 0.3)
            px(5, 4, 2, 2, Color(hex: "202020")); px(10, 4, 2, 2, Color(hex: "202020"))
            eyeSparkle(5, 4); eyeSparkle(10, 4)
            // 부리
            px(7, 6, 2, 1, Color(hex: "d09030"))
            glow(7.3, 5.8, 1.4, 0.4, Color(hex: "e0a050"), 0.5)
            // 몸통
            px(3, 7, 10, 6, shirt)
            glow(4, 7.5, 8, 1.5, .white, 0.1)
            // 배 깃털 무늬
            glow(5, 8.5, 6, 3, Color(hex: "f0e8d0"), 0.12)
            // 날개
            px(1, 8, 2, 4, hair); px(13, 8, 2, 4, hair)
            glow(1.3, 8.5, 1, 2, .white, 0.1)
            glow(13.3, 8.5, 1, 2, .white, 0.1)
            // 다리
            px(5, 13, 2, 3, fur); px(9, 13, 2, 3, fur)

        case .frog:
            // 눈 (돌출된 눈)
            px(3, 0, 4, 3, fur); px(9, 0, 4, 3, fur)
            glow(3.5, 0.5, 2, 1, .white, 0.15)
            glow(9.5, 0.5, 2, 1, .white, 0.15)
            px(4, 1, 2, 2, Color(hex: "101010")); px(10, 1, 2, 2, Color(hex: "101010"))
            eyeSparkle(4, 1); eyeSparkle(10, 1)
            // 머리
            px(3, 3, 10, 5, fur)
            glow(4, 3.5, 8, 1, .white, 0.12)
            // 입 (넓은 미소)
            px(4, 6, 8, 1, Color(hex: "f06060"))
            glow(5, 6, 6, 0.5, Color(hex: "f08080"), 0.4)
            // 볼터치
            glow(3.5, 5, 2, 1.5, Color(hex: "80d080"), 0.15)
            glow(10.5, 5, 2, 1.5, Color(hex: "80d080"), 0.15)
            // 몸통
            px(3, 8, 10, 5, shirt)
            glow(4, 8.5, 8, 1.5, .white, 0.1)
            px(1, 9, 2, 4, shirt); px(13, 9, 2, 4, shirt)
            // 다리
            px(4, 13, 3, 3, fur); px(9, 13, 3, 3, fur)
            glow(4.5, 14, 1.5, 1, Color(hex: "60b060"), 0.3)
            glow(9.5, 14, 1.5, 1, Color(hex: "60b060"), 0.3)

        case .panda:
            let black = Color(hex: "1a1a1a")
            // 귀
            px(2, -1, 4, 3, black); px(10, -1, 4, 3, black)
            glow(2.5, -0.5, 2, 1, Color(hex: "333"), 0.4)
            glow(10.5, -0.5, 2, 1, Color(hex: "333"), 0.4)
            // 머리
            px(4, 1, 8, 6, fur)
            glow(5, 1.5, 6, 1, .white, 0.18)
            // 눈 패치 (판다 특유의 검은 눈테)
            px(4, 3, 3, 3, black); px(9, 3, 3, 3, black)
            px(5, 4, 1, 1, .white); px(10, 4, 1, 1, .white)
            eyeSparkle(5, 4); eyeSparkle(10, 4)
            // 코
            px(7, 5, 2, 1, black)
            // 볼터치 (판다 특유의 둥글둥글)
            glow(4, 5.5, 2, 1, Color(hex: "f0b0b0"), 0.22)
            glow(10, 5.5, 2, 1, Color(hex: "f0b0b0"), 0.22)
            // 몸통
            px(3, 7, 10, 6, shirt)
            glow(4, 7.5, 8, 1.5, .white, 0.1)
            // 배 무늬
            glow(5, 8.5, 6, 3, .white, 0.08)
            // 팔
            px(1, 8, 2, 5, black); px(13, 8, 2, 5, black)
            glow(1.3, 8.5, 1, 3, Color(hex: "333"), 0.3)
            glow(13.3, 8.5, 1, 3, Color(hex: "333"), 0.3)
            // 다리
            px(4, 13, 3, 3, black); px(9, 13, 3, 3, black)
            glow(4.5, 14, 1.5, 1, Color(hex: "444"), 0.3)
            glow(9.5, 14, 1.5, 1, Color(hex: "444"), 0.3)

        case .unicorn:
            // 뿔 (무지개 그라데이션)
            px(7, -4, 2, 1, Color(hex: "f0d040"))
            px(7, -3, 2, 1, Color(hex: "f0c040"))
            px(7, -2, 2, 2, Color(hex: "f0b040"))
            glow(7.3, -3.8, 1, 3, Color(hex: "f8e870"), 0.4)  // 뿔 반짝
            glow(7, -4.5, 2, 0.5, Color(hex: "f8e870"), 0.25)  // 뿔 끝 글로우
            // 머리
            px(4, 0, 8, 6, fur)
            glow(5, 0.5, 6, 1, .white, 0.16)
            // 갈기
            px(2, 0, 2, 5, hair)
            glow(2.3, 0.5, 1, 3, .white, 0.12)
            // 눈 (보랏빛 큰 눈)
            px(5, 2, 2, 2, .white); px(6, 3, 1, 1, Color(hex: "c060c0"))
            px(9, 2, 2, 2, .white); px(10, 3, 1, 1, Color(hex: "c060c0"))
            eyeSparkle(5, 2); eyeSparkle(9, 2)
            // 볼터치 (반짝이)
            glow(4.5, 4, 2, 1.5, Color(hex: "f0a0d0"), 0.3)
            glow(9.5, 4, 2, 1.5, Color(hex: "f0a0d0"), 0.3)
            // 몸통
            px(3, 6, 10, 7, shirt)
            glow(4, 6.5, 8, 1.5, .white, 0.12)
            px(1, 7, 2, 4, shirt); px(13, 7, 2, 4, shirt)
            // 다리
            px(4, 13, 3, 3, fur); px(9, 13, 3, 3, fur)
            // 별 이펙트 (유니콘 특유)
            glow(1, 1, 1, 1, Color(hex: "f0d0f0"), 0.3)
            glow(14, 6, 0.8, 0.8, Color(hex: "f0e0a0"), 0.25)

        case .skeleton:
            let bone = Color(hex: "f0f0e0")
            let boneHi = Color(hex: "f8f8f0")
            // 머리
            px(4, 0, 8, 6, bone)
            glow(5, 0.5, 6, 1, boneHi, 0.3)  // 두개골 반사
            // 눈 (깊은 구멍)
            px(5, 2, 2, 2, Color(hex: "1a1a1a"))
            px(9, 2, 2, 2, Color(hex: "1a1a1a"))
            glow(5.3, 2.3, 0.7, 0.7, Color(hex: "ff3030"), 0.35)  // 붉은 눈빛
            glow(9.3, 2.3, 0.7, 0.7, Color(hex: "ff3030"), 0.35)
            // 코
            px(6, 4, 1, 1, Color(hex: "1a1a1a"))
            // 이빨
            px(5, 5, 6, 1, Color(hex: "1a1a1a"))
            px(5, 5, 1, 1, bone); px(7, 5, 1, 1, bone); px(9, 5, 1, 1, bone)
            // 몸통
            px(5, 6, 6, 6, Color(hex: "404040"))
            px(6, 7, 4, 1, bone); px(6, 9, 4, 1, bone)  // 갈비뼈
            glow(6.5, 7, 3, 0.5, boneHi, 0.2)
            glow(6.5, 9, 3, 0.5, boneHi, 0.2)
            // 팔
            px(3, 7, 2, 5, Color(hex: "404040")); px(11, 7, 2, 5, Color(hex: "404040"))
            glow(3.3, 7.5, 0.8, 3, Color(hex: "555"), 0.3)
            glow(11.3, 7.5, 0.8, 3, Color(hex: "555"), 0.3)
            // 다리
            px(5, 12, 2, 4, bone); px(9, 12, 2, 4, bone)
            glow(5.3, 12.5, 0.8, 2, boneHi, 0.2)
            glow(9.3, 12.5, 0.8, 2, boneHi, 0.2)

        case .human:
            // 모자
            switch character.hatType {
            case .beanie:
                px(3, -2, 10, 3, Color(hex: "4040a0"))
                glow(4, -1.5, 8, 1, Color(hex: "5050b0"), 0.4)  // 비니 하이라이트
                glow(7, -2.5, 2, 0.5, Color(hex: "6060c0"), 0.3)  // 폼폼
            case .cap:
                px(2, -1, 12, 2, Color(hex: "c04040")); px(1, 0, 4, 1, Color(hex: "a03030"))
                glow(3, -0.5, 9, 0.5, Color(hex: "d05050"), 0.4)
            case .hardhat:
                px(3, -2, 10, 3, Color(hex: "e0c040")); px(2, -1, 12, 1, Color(hex: "e0c040"))
                glow(4, -1.5, 8, 1, Color(hex: "f0d860"), 0.4)
            case .wizard:
                px(5, -5, 6, 2, Color(hex: "6040a0")); px(4, -3, 8, 2, Color(hex: "6040a0")); px(3, -1, 10, 2, Color(hex: "6040a0"))
                glow(5.5, -4.5, 4, 1, Color(hex: "7050b0"), 0.3)
                glow(7, -5.5, 1, 0.5, Color(hex: "f0d040"), 0.6)  // 별
            case .crown:
                px(4, -2, 8, 1, Color(hex: "e0c040"))
                px(4, -3, 2, 1, Color(hex: "e0c040")); px(7, -3, 2, 1, Color(hex: "e0c040")); px(10, -3, 2, 1, Color(hex: "e0c040"))
                glow(5, -2.5, 6, 0.5, Color(hex: "f0d860"), 0.4)
                glow(7.5, -3.5, 1, 0.5, Color(hex: "ff4040"), 0.5)  // 보석
            case .headphones:
                px(2, 2, 2, 4, Color(hex: "404040")); px(12, 2, 2, 4, Color(hex: "404040"))
                px(3, 0, 10, 1, Color(hex: "505050"))
                glow(2.5, 3, 1, 1.5, Color(hex: "60f0a0"), 0.3)  // LED
                glow(12.5, 3, 1, 1.5, Color(hex: "60f0a0"), 0.3)
            case .beret:
                px(3, -1, 11, 2, Color(hex: "c04040")); px(3, -2, 8, 1, Color(hex: "c04040"))
                glow(4, -1.5, 8, 0.5, Color(hex: "d05050"), 0.35)
            case .none: break
            }
            // 머리카락
            px(4, 0, 8, 3, hair); px(3, 1, 1, 2, hair); px(12, 1, 1, 2, hair)
            glow(5, 0.5, 6, 1, .white, 0.14)  // 머리카락 반사
            glow(4.5, 1.5, 3, 0.5, .white, 0.08)
            // 얼굴
            px(4, 3, 8, 5, fur)
            glow(5, 3.5, 6, 1, .white, 0.08)  // 이마 하이라이트
            // 눈 (밝은 눈)
            px(5, 4, 2, 2, .white); px(6, 5, 1, 1, Color(hex: "333"))
            px(9, 4, 2, 2, .white); px(10, 5, 1, 1, Color(hex: "333"))
            eyeSparkle(5, 4); eyeSparkle(9, 4)
            // 볼터치
            glow(4.5, 6, 2, 1, Color(hex: "f0a0a0"), 0.25)
            glow(9.5, 6, 2, 1, Color(hex: "f0a0a0"), 0.25)
            // 입
            glow(7, 6.5, 2, 0.5, Color(hex: "d08080"), 0.35)

            // 악세서리
            switch character.accessory {
            case .glasses:
                px(4, 4, 3, 1, Color(hex: "4060a0")); px(7, 4, 1, 1, Color(hex: "4060a0")); px(8, 4, 3, 1, Color(hex: "4060a0"))
                glow(4.5, 4, 1, 0.5, .white, 0.2)  // 렌즈 반사
                glow(8.5, 4, 1, 0.5, .white, 0.2)
            case .sunglasses:
                px(4, 4, 3, 2, Color(hex: "1a1a1a")); px(7, 4, 1, 1, Color(hex: "1a1a1a")); px(8, 4, 3, 2, Color(hex: "1a1a1a"))
                glow(4.5, 4.2, 2, 0.5, Color(hex: "4080c0"), 0.2)  // 렌즈 반사
                glow(8.5, 4.2, 2, 0.5, Color(hex: "4080c0"), 0.2)
            case .scarf:
                px(3, 7, 10, 2, Color(hex: "c04040"))
                glow(4, 7.2, 8, 0.5, Color(hex: "d05050"), 0.35)
                glow(3, 8, 10, 1, .black, 0.08)
            case .mask:
                px(4, 5, 8, 3, Color(hex: "2a2a2a"))
                glow(5, 5.5, 6, 1, Color(hex: "444"), 0.3)
            case .earring:
                px(13, 4, 1, 2, Color(hex: "e0c040"))
                glow(13, 4, 1, 1, Color(hex: "f0d860"), 0.4)  // 반짝
            case .none: break
            }

            // 몸통
            px(3, 8, 10, 6, shirt)
            glow(4, 8.5, 8, 1.5, .white, 0.1)  // 옷 하이라이트
            glow(7, 9, 2, 4, .black, 0.04)  // 중앙 주름
            glow(3, 12, 10, 2, .black, 0.06)  // 하단 그림자
            // 팔
            px(1, 9, 2, 5, shirt); px(13, 9, 2, 5, shirt)
            glow(1.3, 9.5, 0.8, 3, .white, 0.08)
            glow(13.3, 9.5, 0.8, 3, .white, 0.08)
            // 손
            px(0, 13, 2, 2, fur); px(14, 13, 2, 2, fur)
            glow(0.3, 13.3, 1, 0.5, .white, 0.1)
            glow(14.3, 13.3, 1, 0.5, .white, 0.1)
            // 바지
            px(4, 14, 4, 4, pants); px(8, 14, 4, 4, pants)
            glow(4.5, 14.5, 3, 1, .white, 0.06)
            glow(8.5, 14.5, 3, 1, .white, 0.06)
            px(4, 18, 3, 2, pants); px(9, 18, 3, 2, pants)
            // 신발
            px(3, 19, 4, 2, Color(hex: "4a5060")); px(9, 19, 4, 2, Color(hex: "4a5060"))
            glow(3.5, 19.2, 3, 0.5, Color(hex: "5a6070"), 0.4)
            glow(9.5, 19.2, 3, 0.5, Color(hex: "5a6070"), 0.4)
        }
    }
}

// MARK: - Character Mini Avatar View

public struct CharacterMiniAvatar: View {
    public let character: WorkerCharacter
    public var pixelScale: CGFloat
    public var bgOpacity: CGFloat

    public init(character: WorkerCharacter, pixelScale: CGFloat = 1.8, bgOpacity: CGFloat = 0.12) {
        self.character = character
        self.pixelScale = pixelScale
        self.bgOpacity = bgOpacity
    }

    public var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6)
                .fill(Color(hex: character.shirtColor).opacity(bgOpacity))
            Canvas { context, size in
                CharacterPixelRenderer.draw(character: character, context: context, size: size, scale: pixelScale)
            }
        }
    }
}
