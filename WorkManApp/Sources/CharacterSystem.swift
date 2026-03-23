import SwiftUI

// MARK: - Character Definition

struct WorkerCharacter: Identifiable, Codable {
    let id: String
    var name: String
    var archetype: String
    let hairColor: String
    let skinTone: String
    let shirtColor: String
    let pantsColor: String
    let hatType: HatType
    let accessory: Accessory
    let species: Species
    var isHired: Bool = false
    var hiredAt: Date?
    var requiredAchievement: String?  // nil이면 자유 고용, 있으면 해당 업적 달성 필요

    enum HatType: String, Codable, CaseIterable {
        case none, beanie, cap, hardhat, wizard, crown, headphones, beret
    }

    enum Accessory: String, Codable, CaseIterable {
        case none, glasses, sunglasses, scarf, mask, earring
    }

    enum Species: String, Codable, CaseIterable {
        case human = "사람"
        case cat = "고양이"
        case dog = "강아지"
        case rabbit = "토끼"
        case bear = "곰"
        case penguin = "펭귄"
        case fox = "여우"
        case robot = "로봇"
        case claude = "Claude"
    }
}

// MARK: - Character Registry (전체 캐릭터 목록)

class CharacterRegistry: ObservableObject {
    static let shared = CharacterRegistry()

    @Published var allCharacters: [WorkerCharacter] = []

    private let saveKey = "WorkManCharacters"

    init() {
        loadOrCreate()
    }

    private func loadOrCreate() {
        if let data = UserDefaults.standard.data(forKey: saveKey),
           let saved = try? JSONDecoder().decode([WorkerCharacter].self, from: data) {
            allCharacters = saved
            let defaultMap = Dictionary(uniqueKeysWithValues: Self.defaultCharacters.map { ($0.id, $0) })
            // 새 캐릭터가 추가됐으면 머지
            let existing = Set(saved.map { $0.id })
            for char in Self.defaultCharacters where !existing.contains(char.id) {
                allCharacters.append(char)
            }
            // 기존 캐릭터의 requiredAchievement를 최신 default와 동기화
            for i in allCharacters.indices {
                if let def = defaultMap[allCharacters[i].id] {
                    allCharacters[i].requiredAchievement = def.requiredAchievement
                }
            }
        } else {
            allCharacters = Self.defaultCharacters
        }
    }

    func save() {
        if let data = try? JSONEncoder().encode(allCharacters) {
            UserDefaults.standard.set(data, forKey: saveKey)
        }
    }

    func hire(_ id: String) {
        guard let idx = allCharacters.firstIndex(where: { $0.id == id }) else { return }
        // 도전과제 잠금 체크
        if let req = allCharacters[idx].requiredAchievement {
            guard AchievementManager.shared.achievements.first(where: { $0.id == req })?.unlocked == true else { return }
        }
        allCharacters[idx].isHired = true
        allCharacters[idx].hiredAt = Date()
        allCharacters[idx].archetype = Self.personalities.randomElement() ?? "신입"
        save()
    }

    /// 해당 캐릭터의 도전과제 잠금이 해제되었는지 확인
    func isUnlocked(_ character: WorkerCharacter) -> Bool {
        guard let req = character.requiredAchievement else { return true }
        return AchievementManager.shared.achievements.first(where: { $0.id == req })?.unlocked == true
    }

    /// 필요한 도전과제 이름 반환
    func requiredAchievementName(_ character: WorkerCharacter) -> String? {
        guard let req = character.requiredAchievement else { return nil }
        return AchievementManager.shared.achievements.first(where: { $0.id == req })?.name
    }

    func hireAll() {
        for i in allCharacters.indices {
            allCharacters[i].isHired = true
            if allCharacters[i].hiredAt == nil { allCharacters[i].hiredAt = Date() }
            if allCharacters[i].archetype.isEmpty || allCharacters[i].archetype == "신입" {
                allCharacters[i].archetype = Self.personalities.randomElement() ?? "신입"
            }
        }
        save()
    }

    func fire(_ id: String) {
        if let idx = allCharacters.firstIndex(where: { $0.id == id }) {
            allCharacters[idx].isHired = false
            allCharacters[idx].hiredAt = nil
            save()
        }
    }

    func rename(_ id: String, to newName: String) {
        if let idx = allCharacters.firstIndex(where: { $0.id == id }) {
            allCharacters[idx].name = newName
            save()
        }
    }

    var hiredCharacters: [WorkerCharacter] {
        allCharacters.filter { $0.isHired }
    }

    var availableCharacters: [WorkerCharacter] {
        allCharacters.filter { !$0.isHired }
    }

    func nextAvailable() -> WorkerCharacter? {
        availableCharacters.first
    }

    // MARK: - Default Characters (20개)

    // 고용 시 랜덤 배정되는 성격
    static let personalities: [String] = [
        "커피머신 ☕", "일 안하는 대리", "야근 마스터", "회의실 점거범",
        "버그 제조기", "핫픽스 장인", "깃 충돌 유발자", "코드 예술가",
        "월급루팡", "Ctrl+Z 중독자", "새벽 커밋러", "점심 2시간",
        "무한 리팩토링", "TODO 수집가", "에러 친구", "빌드 깨는 자",
        "Stack Overflow 의존", "복붙 달인", "주석 없는 자", "PR 무시맨",
        "배포 두려움", "롤백 전문가", "슬랙 답장 안함", "일단 머지",
        "테스트 뭐하는거?", "의욕 만랩", "조용한 천재", "소리없는 강자",
        "에너지 드링크", "자리 이탈 중", "코딩하다 잠든 자", "런치 히어로",
    ]

    static let defaultCharacters: [WorkerCharacter] = [
        // 🧑 사람
        WorkerCharacter(id: "pixel", name: "Pixel", archetype: "커피머신 ☕", hairColor: "4a3728", skinTone: "ffd5b8", shirtColor: "f08080", pantsColor: "3a4050", hatType: .none, accessory: .glasses, species: .human, isHired: true),
        WorkerCharacter(id: "byte", name: "Byte", archetype: "야근 마스터", hairColor: "2c1810", skinTone: "ffd5b8", shirtColor: "72d6a0", pantsColor: "3a4050", hatType: .beanie, accessory: .none, species: .human, isHired: true),
        WorkerCharacter(id: "code", name: "Code", archetype: "Ctrl+Z 중독자", hairColor: "d4a574", skinTone: "e8c4a0", shirtColor: "f0c05a", pantsColor: "3a4050", hatType: .none, accessory: .none, species: .human, isHired: true),
        WorkerCharacter(id: "bug", name: "Bug", archetype: "버그 제조기", hairColor: "8b4513", skinTone: "ffd5b8", shirtColor: "78b4f0", pantsColor: "3a4050", hatType: .cap, accessory: .none, species: .human, isHired: true),
        WorkerCharacter(id: "chip", name: "Chip", archetype: "슬랙 답장 안함", hairColor: "1a1a30", skinTone: "c8a882", shirtColor: "c490e8", pantsColor: "3a4050", hatType: .none, accessory: .sunglasses, species: .human),
        WorkerCharacter(id: "kit", name: "Kit", archetype: "코드 예술가", hairColor: "e06060", skinTone: "ffd5b8", shirtColor: "f0a060", pantsColor: "3a4050", hatType: .beret, accessory: .none, species: .human),
        WorkerCharacter(id: "dot", name: "Dot", archetype: "TODO 수집가", hairColor: "4040a0", skinTone: "e8c4a0", shirtColor: "60d0c0", pantsColor: "3a4050", hatType: .none, accessory: .glasses, species: .human),
        WorkerCharacter(id: "rex", name: "Rex", archetype: "일단 머지", hairColor: "c4a474", skinTone: "ffd5b8", shirtColor: "f080c0", pantsColor: "3a4050", hatType: .headphones, accessory: .none, species: .human),

        WorkerCharacter(id: "nova", name: "Nova", archetype: "조용한 천재", hairColor: "e0e0ff", skinTone: "ffd5b8", shirtColor: "8080f0", pantsColor: "2a3040", hatType: .none, accessory: .glasses, species: .human, requiredAchievement: "session_streak_7"),
        WorkerCharacter(id: "dash", name: "Dash", archetype: "에너지 드링크", hairColor: "ff6060", skinTone: "e8c4a0", shirtColor: "40c0e0", pantsColor: "3a4050", hatType: .cap, accessory: .none, species: .human, requiredAchievement: "session_streak_3"),
        WorkerCharacter(id: "root", name: "Root", archetype: "소리없는 강자", hairColor: "606060", skinTone: "c8a882", shirtColor: "404040", pantsColor: "2a2a2a", hatType: .none, accessory: .sunglasses, species: .human, requiredAchievement: "centurion"),
        WorkerCharacter(id: "flux", name: "Flux", archetype: "무한 리팩토링", hairColor: "50b050", skinTone: "ffd5b8", shirtColor: "e0e0e0", pantsColor: "3a4050", hatType: .wizard, accessory: .none, species: .human, requiredAchievement: "marathon"),
        WorkerCharacter(id: "sage", name: "Sage", archetype: "회의실 점거범", hairColor: "b0b0b0", skinTone: "e8c4a0", shirtColor: "6080a0", pantsColor: "3a4050", hatType: .none, accessory: .glasses, species: .human, requiredAchievement: "complete_50"),
        WorkerCharacter(id: "bolt", name: "Bolt", archetype: "핫픽스 장인", hairColor: "f0c020", skinTone: "ffd5b8", shirtColor: "f0a020", pantsColor: "3a4050", hatType: .hardhat, accessory: .none, species: .human, requiredAchievement: "speed_demon"),
        WorkerCharacter(id: "pip", name: "Pip", archetype: "의욕 만랩", hairColor: "f0a060", skinTone: "ffd5b8", shirtColor: "60a0f0", pantsColor: "4050a0", hatType: .beanie, accessory: .none, species: .human),

        // 🐱 고양이
        WorkerCharacter(id: "mochi", name: "모찌", archetype: "자리 이탈 중", hairColor: "f0e0d0", skinTone: "f5e6d0", shirtColor: "f08080", pantsColor: "3a4050", hatType: .none, accessory: .none, species: .cat),
        WorkerCharacter(id: "nabi", name: "나비", archetype: "키보드 위의 고양이", hairColor: "404040", skinTone: "505050", shirtColor: "ffd369", pantsColor: "3a4050", hatType: .none, accessory: .glasses, species: .cat, requiredAchievement: "night_owl"),
        WorkerCharacter(id: "cheese", name: "치즈", archetype: "점심 2시간", hairColor: "f0a030", skinTone: "f0b040", shirtColor: "60c060", pantsColor: "3a4050", hatType: .none, accessory: .none, species: .cat),

        // 🐶 강아지
        WorkerCharacter(id: "bori", name: "보리", archetype: "런치 히어로", hairColor: "c09060", skinTone: "d0a070", shirtColor: "4090d0", pantsColor: "3a4050", hatType: .cap, accessory: .none, species: .dog),
        WorkerCharacter(id: "coco", name: "코코", archetype: "배포 두려움", hairColor: "f0f0f0", skinTone: "f0e8e0", shirtColor: "e06060", pantsColor: "3a4050", hatType: .none, accessory: .scarf, species: .dog),

        // 🐰 토끼
        WorkerCharacter(id: "ddu", name: "뚜", archetype: "새벽 커밋러", hairColor: "f0e0e0", skinTone: "f5e8e8", shirtColor: "f090c0", pantsColor: "3a4050", hatType: .none, accessory: .none, species: .rabbit),
        WorkerCharacter(id: "toki", name: "토키", archetype: "복붙 달인", hairColor: "e0d0c0", skinTone: "e8dcd0", shirtColor: "90c0f0", pantsColor: "3a4050", hatType: .beanie, accessory: .none, species: .rabbit, requiredAchievement: "bug_squasher"),

        // 🐻 곰
        WorkerCharacter(id: "gomi", name: "고미", archetype: "코딩하다 잠든 자", hairColor: "8b6040", skinTone: "a07050", shirtColor: "40a060", pantsColor: "3a4050", hatType: .hardhat, accessory: .none, species: .bear, requiredAchievement: "ultra_marathon"),

        // 🐧 펭귄
        WorkerCharacter(id: "pengu", name: "펭구", archetype: "월급루팡", hairColor: "2a2a3a", skinTone: "3a3a4a", shirtColor: "f0f0f0", pantsColor: "2a2a3a", hatType: .none, accessory: .sunglasses, species: .penguin, requiredAchievement: "token_whale"),

        // 🦊 여우
        WorkerCharacter(id: "yuri", name: "유리", archetype: "깃 충돌 유발자", hairColor: "e07030", skinTone: "e08040", shirtColor: "f0c060", pantsColor: "3a4050", hatType: .none, accessory: .glasses, species: .fox, requiredAchievement: "git_master"),

        // 🤖 로봇
        WorkerCharacter(id: "zero", name: "Zero", archetype: "Stack Overflow 의존", hairColor: "8090a0", skinTone: "a0b0c0", shirtColor: "6080a0", pantsColor: "506070", hatType: .none, accessory: .none, species: .robot, requiredAchievement: "level_5"),
        WorkerCharacter(id: "ai01", name: "AI-01", archetype: "주석 없는 자", hairColor: "60f0a0", skinTone: "90a0b0", shirtColor: "304050", pantsColor: "203040", hatType: .headphones, accessory: .none, species: .robot, requiredAchievement: "command_500"),

        // ✨ Claude
        WorkerCharacter(id: "claude_opus", name: "Claude", archetype: "Opus", hairColor: "d97757", skinTone: "f5e6d0", shirtColor: "d97757", pantsColor: "2a2a3a", hatType: .none, accessory: .none, species: .claude, isHired: true),
        WorkerCharacter(id: "claude_sonnet", name: "Sonnet", archetype: "Sonnet", hairColor: "5b9cf6", skinTone: "f5e6d0", shirtColor: "5b9cf6", pantsColor: "2a2a3a", hatType: .none, accessory: .none, species: .claude, requiredAchievement: "three_models"),
        WorkerCharacter(id: "claude_haiku", name: "Haiku", archetype: "Haiku", hairColor: "56d97e", skinTone: "f5e6d0", shirtColor: "56d97e", pantsColor: "2a2a3a", hatType: .none, accessory: .none, species: .claude, requiredAchievement: "haiku_user"),
    ]
}

// MARK: - Character Collection View

struct CharacterCollectionView: View {
    @ObservedObject var registry = CharacterRegistry.shared
    @State private var editingId: String?
    @State private var editName = ""
    @State private var selectedSpecies: WorkerCharacter.Species? = nil

    let columns = Array(repeating: GridItem(.flexible(), spacing: 14), count: 3)

    private var filteredHired: [WorkerCharacter] {
        let chars = registry.hiredCharacters
        guard let sp = selectedSpecies else { return chars }
        return chars.filter { $0.species == sp }
    }

    private var filteredAvailable: [WorkerCharacter] {
        let chars = registry.availableCharacters.filter { registry.isUnlocked($0) }
        guard let sp = selectedSpecies else { return chars }
        return chars.filter { $0.species == sp }
    }

    private var filteredLocked: [WorkerCharacter] {
        let chars = registry.availableCharacters.filter { !registry.isUnlocked($0) }
        guard let sp = selectedSpecies else { return chars }
        return chars.filter { $0.species == sp }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 12) {
                ZStack {
                    Circle().fill(Theme.accent.opacity(0.1)).frame(width: 40, height: 40)
                    Image(systemName: "person.3.fill").font(.system(size: 14)).foregroundColor(Theme.accent)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("CHARACTERS").font(Theme.mono(12, weight: .heavy)).foregroundColor(Theme.textPrimary).tracking(1.5)
                    Text("\(registry.hiredCharacters.count)명 고용 / \(registry.allCharacters.count)명 전체")
                        .font(Theme.monoSmall).foregroundColor(Theme.textDim)
                }
                Spacer()

                // Species filter
                HStack(spacing: 3) {
                    speciesFilter(nil, label: "All")
                    speciesFilter(.human, label: "👤")
                    speciesFilter(.cat, label: "🐱")
                    speciesFilter(.dog, label: "🐶")
                    speciesFilter(.robot, label: "🤖")
                    speciesFilter(.claude, label: "✨")
                }
            }
            .padding(.horizontal, 20).padding(.vertical, 14)
            .background(Theme.bgCard)

            Rectangle().fill(Theme.border).frame(height: 1)

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // 고용 중
                    if !filteredHired.isEmpty {
                        sectionHeader("고용 중", count: filteredHired.count, color: Theme.green, icon: "person.fill.checkmark")
                        LazyVGrid(columns: columns, spacing: 14) {
                            ForEach(filteredHired) { char in
                                CharacterCard(character: char, isHired: true, editingId: $editingId, editName: $editName)
                            }
                        }
                    }

                    if !filteredHired.isEmpty && !filteredAvailable.isEmpty {
                        HStack(spacing: 8) {
                            Rectangle().fill(Theme.border).frame(height: 1)
                            Text("AVAILABLE").font(Theme.mono(7, weight: .bold)).foregroundColor(Theme.textDim).tracking(1.5)
                            Rectangle().fill(Theme.border).frame(height: 1)
                        }.padding(.vertical, 6)
                    }

                    // 대기 중 (잠금 해제된 것만)
                    if !filteredAvailable.isEmpty {
                        sectionHeader("대기 중", count: filteredAvailable.count, color: Theme.textSecondary, icon: "person.fill.questionmark")
                        LazyVGrid(columns: columns, spacing: 14) {
                            ForEach(filteredAvailable) { char in
                                CharacterCard(character: char, isHired: false, editingId: $editingId, editName: $editName)
                            }
                        }
                    }

                    // 잠금 캐릭터
                    if !filteredLocked.isEmpty {
                        if !filteredHired.isEmpty || !filteredAvailable.isEmpty {
                            HStack(spacing: 8) {
                                Rectangle().fill(Theme.yellow.opacity(0.2)).frame(height: 1)
                                HStack(spacing: 4) {
                                    Image(systemName: "lock.fill").font(.system(size: 7)).foregroundColor(Theme.yellow.opacity(0.5))
                                    Text("LOCKED").font(Theme.mono(7, weight: .bold)).foregroundColor(Theme.yellow.opacity(0.5)).tracking(1.5)
                                }
                                Rectangle().fill(Theme.yellow.opacity(0.2)).frame(height: 1)
                            }.padding(.vertical, 6)
                        }

                        sectionHeader("잠금", count: filteredLocked.count, color: Theme.yellow.opacity(0.6), icon: "lock.fill")
                        LazyVGrid(columns: columns, spacing: 14) {
                            ForEach(filteredLocked) { char in
                                LockedCharacterCard(character: char)
                            }
                        }
                    }
                }
                .padding(.horizontal, 18).padding(.vertical, 16)
            }
        }
        .background(Theme.bg)
    }

    private func speciesFilter(_ species: WorkerCharacter.Species?, label: String) -> some View {
        let active = selectedSpecies == species
        return Button(action: { withAnimation(.easeInOut(duration: 0.15)) { selectedSpecies = species } }) {
            Text(label).font(species == nil ? Theme.mono(8, weight: active ? .bold : .regular) : .system(size: 11))
                .padding(.horizontal, 5).padding(.vertical, 3)
                .background(active ? Theme.accent.opacity(0.12) : .clear)
                .cornerRadius(4)
                .overlay(RoundedRectangle(cornerRadius: 4).stroke(active ? Theme.accent.opacity(0.3) : .clear, lineWidth: 1))
        }.buttonStyle(.plain)
    }

    private func sectionHeader(_ title: String, count: Int, color: Color, icon: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon).font(Theme.monoSmall).foregroundColor(color)
            Text(title.uppercased()).font(Theme.mono(9, weight: .bold)).foregroundColor(color).tracking(1.5)
            Text("\(count)").font(Theme.mono(8, weight: .bold)).foregroundColor(color)
                .padding(.horizontal, 6).padding(.vertical, 2)
                .background(color.opacity(0.1)).cornerRadius(4)
            Spacer()
        }
    }
}

// MARK: - Character Card

struct CharacterCard: View {
    let character: WorkerCharacter
    let isHired: Bool
    @Binding var editingId: String?
    @Binding var editName: String
    @ObservedObject var registry = CharacterRegistry.shared
    @State private var isHovered = false

    private var shirtColor: Color { Color(hex: character.shirtColor) }

    var body: some View {
        VStack(spacing: 8) {
            // Pixel character + 배경
            ZStack {
                // 배경 글로우
                if isHired {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(RadialGradient(
                            colors: [shirtColor.opacity(0.12), .clear],
                            center: .center, startRadius: 0, endRadius: 40
                        ))
                }
                Canvas { context, size in drawCharacter(context: context, size: size) }
                    .frame(width: 48, height: 64)

                // Species badge
                VStack { Spacer(); HStack { Spacer()
                    Text(speciesEmoji(character.species)).font(.system(size: 10))
                        .padding(2).background(Circle().fill(Theme.bgCard.opacity(0.9)))
                } }
                .frame(width: 52, height: 68)
            }
            .frame(width: 52, height: 68)

            // Name
            if editingId == character.id {
                TextField("이름", text: $editName)
                    .textFieldStyle(.plain).font(Theme.mono(10, weight: .bold))
                    .foregroundColor(shirtColor).multilineTextAlignment(.center).frame(width: 70)
                    .onSubmit {
                        if !editName.trimmingCharacters(in: .whitespaces).isEmpty { registry.rename(character.id, to: editName) }
                        editingId = nil
                    }
            } else {
                Text(character.name).font(Theme.mono(10, weight: .bold)).foregroundColor(shirtColor).lineLimit(1)
                    .onTapGesture(count: 2) { editName = character.name; editingId = character.id }
            }

            // Role
            Text(character.archetype).font(Theme.mono(7)).foregroundColor(Theme.textDim).lineLimit(1)

            // Items (항상 고정 높이)
            HStack(spacing: 2) {
                if character.hatType != .none { Text(hatEmoji(character.hatType)).font(.system(size: 9)) }
                if character.accessory != .none { Text(accessoryEmoji(character.accessory)).font(.system(size: 9)) }
            }.frame(height: 12)

            // Action button
            Button(action: { isHired ? registry.fire(character.id) : registry.hire(character.id) }) {
                Text(isHired ? "해고" : "고용")
                    .font(Theme.mono(8, weight: .medium))
                    .foregroundColor(isHired ? Theme.red : Theme.green)
                    .frame(maxWidth: .infinity).padding(.vertical, 4)
                    .background(RoundedRectangle(cornerRadius: 5).fill(isHired ? Theme.red.opacity(0.08) : Theme.green.opacity(0.08))
                        .overlay(RoundedRectangle(cornerRadius: 5).stroke(isHired ? Theme.red.opacity(0.15) : Theme.green.opacity(0.15), lineWidth: 0.5)))
            }.buttonStyle(.plain)
        }
        .padding(10)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 12).fill(Theme.bgCard)
                if isHired {
                    VStack { RoundedRectangle(cornerRadius: 1).fill(
                        LinearGradient(colors: [shirtColor.opacity(0.5), shirtColor.opacity(0.1)], startPoint: .leading, endPoint: .trailing)
                    ).frame(height: 2).padding(.horizontal, 10); Spacer() }
                }
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isHired ? shirtColor.opacity(isHovered ? 0.4 : 0.2) : Theme.border.opacity(isHovered ? 0.4 : 0.15), lineWidth: isHired ? 1 : 0.5)
            }
        )
        .frame(maxWidth: .infinity, minHeight: 180, maxHeight: 180, alignment: .top)
        .opacity(isHired ? 1 : 0.65)
        .shadow(color: isHired && isHovered ? shirtColor.opacity(0.15) : .clear, radius: 8)
        .scaleEffect(isHovered ? 1.03 : 1.0)
        .animation(.easeOut(duration: 0.12), value: isHovered)
        .onHover { isHovered = $0 }
    }

    // MARK: - Draw Character

    private func drawCharacter(context: GraphicsContext, size: CGSize) {
        let s: CGFloat = 2.5
        let x: CGFloat = (size.width - 16 * s) / 2
        let y: CGFloat = (size.height - 22 * s) / 2 + 2

        let fur = Color(hex: character.skinTone)
        let hair = Color(hex: character.hairColor)
        let shirt = Color(hex: character.shirtColor)
        let pants = Color(hex: character.pantsColor)

        func px(_ px: CGFloat, _ py: CGFloat, _ w: CGFloat, _ h: CGFloat, _ c: Color) {
            context.fill(Path(CGRect(x: x + px * s, y: y + py * s, width: w * s, height: h * s)), with: .color(c))
        }

        switch character.species {
        case .cat:
            // 귀 (삼각형)
            px(3, -2, 3, 3, fur); px(10, -2, 3, 3, fur)
            px(4, -1, 1, 1, Color(hex: "f0a0a0")); px(11, -1, 1, 1, Color(hex: "f0a0a0")) // 귀 안쪽
            // 머리
            px(4, 1, 8, 6, fur)
            // 눈 (고양이 눈 - 세로 동공)
            px(5, 3, 2, 2, Color(hex: "60c060")); px(6, 3, 1, 2, Color(hex: "1a1a1a"))
            px(9, 3, 2, 2, Color(hex: "60c060")); px(10, 3, 1, 2, Color(hex: "1a1a1a"))
            // 코 + 입
            px(7, 5, 2, 1, Color(hex: "f08080"))
            // 수염
            px(2, 5, 2, 1, Color(hex: "ddd")); px(12, 5, 2, 1, Color(hex: "ddd"))
            // 몸
            px(4, 7, 8, 7, shirt)
            // 앞발
            px(3, 12, 3, 2, fur); px(10, 12, 3, 2, fur)
            // 뒷발
            px(4, 14, 3, 3, fur); px(9, 14, 3, 3, fur)
            // 꼬리
            px(13, 10, 2, 2, fur); px(14, 8, 2, 3, fur)

        case .dog:
            // 귀 (늘어진)
            px(2, 1, 3, 5, hair); px(11, 1, 3, 5, hair)
            // 머리
            px(4, 0, 8, 7, fur)
            // 눈
            px(5, 3, 2, 2, .white); px(6, 4, 1, 1, Color(hex: "333"))
            px(9, 3, 2, 2, .white); px(10, 4, 1, 1, Color(hex: "333"))
            // 코
            px(7, 5, 2, 1, Color(hex: "333"))
            // 혀
            px(7, 6, 2, 1, Color(hex: "f06060"))
            // 몸
            px(4, 7, 8, 7, shirt)
            px(3, 12, 3, 2, fur); px(10, 12, 3, 2, fur)
            px(4, 14, 3, 3, fur); px(9, 14, 3, 3, fur)
            // 꼬리 (위로)
            px(13, 5, 2, 2, fur); px(14, 3, 2, 3, fur)

        case .rabbit:
            // 긴 귀
            px(5, -5, 2, 6, fur); px(9, -5, 2, 6, fur)
            px(5, -4, 1, 4, Color(hex: "f0a0a0")); px(10, -4, 1, 4, Color(hex: "f0a0a0"))
            // 머리 (둥근)
            px(4, 1, 8, 6, fur)
            // 눈 (크고 둥근)
            px(5, 3, 2, 2, Color(hex: "d04060")); px(6, 3, 1, 1, Color(hex: "1a1a1a"))
            px(9, 3, 2, 2, Color(hex: "d04060")); px(10, 3, 1, 1, Color(hex: "1a1a1a"))
            // 코
            px(7, 5, 2, 1, Color(hex: "f0a0a0"))
            // 몸
            px(4, 7, 8, 7, shirt)
            px(3, 12, 3, 2, fur); px(10, 12, 3, 2, fur)
            px(5, 14, 3, 3, fur); px(8, 14, 3, 3, fur)
            // 솜뭉치 꼬리
            px(13, 11, 3, 3, .white)

        case .bear:
            // 둥근 귀
            px(3, -1, 3, 3, fur); px(10, -1, 3, 3, fur)
            px(4, 0, 1, 1, Color(hex: "c09060")); px(11, 0, 1, 1, Color(hex: "c09060"))
            // 머리
            px(4, 1, 8, 7, fur)
            // 주둥이
            px(6, 5, 4, 3, Color(hex: "d0b090"))
            // 눈
            px(5, 3, 2, 2, Color(hex: "1a1a1a"))
            px(9, 3, 2, 2, Color(hex: "1a1a1a"))
            // 코
            px(7, 5, 2, 1, Color(hex: "333"))
            // 몸 (통통)
            px(3, 8, 10, 7, shirt)
            px(2, 10, 3, 3, fur); px(11, 10, 3, 3, fur)
            px(4, 15, 4, 3, fur); px(8, 15, 4, 3, fur)

        case .penguin:
            // 머리 (검정)
            px(4, 0, 8, 5, Color(hex: "2a2a3a"))
            // 흰 얼굴
            px(5, 2, 6, 4, .white)
            // 눈
            px(6, 3, 1, 1, Color(hex: "1a1a1a")); px(9, 3, 1, 1, Color(hex: "1a1a1a"))
            // 부리
            px(7, 5, 2, 1, Theme.yellow)
            // 몸 (검정 + 흰 배)
            px(3, 6, 10, 8, Color(hex: "2a2a3a"))
            px(5, 7, 6, 6, .white)
            // 날개
            px(2, 8, 2, 5, Color(hex: "2a2a3a")); px(12, 8, 2, 5, Color(hex: "2a2a3a"))
            // 발
            px(5, 14, 3, 2, Theme.yellow); px(8, 14, 3, 2, Theme.yellow)

        case .fox:
            // 귀 (뾰족)
            px(3, -2, 3, 4, Color(hex: "e07030")); px(10, -2, 3, 4, Color(hex: "e07030"))
            px(4, -1, 1, 2, .white); px(11, -1, 1, 2, .white)
            // 머리
            px(4, 1, 8, 6, fur)
            // 흰 뺨
            px(4, 4, 3, 3, .white); px(9, 4, 3, 3, .white)
            // 눈 (날카로운)
            px(5, 3, 2, 1, Color(hex: "f0c020")); px(6, 3, 1, 1, Color(hex: "1a1a1a"))
            px(9, 3, 2, 1, Color(hex: "f0c020")); px(10, 3, 1, 1, Color(hex: "1a1a1a"))
            // 코
            px(7, 5, 2, 1, Color(hex: "333"))
            // 몸
            px(4, 7, 8, 7, shirt)
            px(3, 12, 3, 2, fur); px(10, 12, 3, 2, fur)
            px(4, 14, 3, 3, fur); px(9, 14, 3, 3, fur)
            // 큰 꼬리
            px(12, 9, 3, 2, fur); px(13, 7, 3, 4, fur); px(14, 11, 2, 1, .white)

        case .robot:
            // 안테나
            px(7, -3, 2, 3, Color(hex: "8090a0"))
            px(6, -4, 4, 1, Color(hex: "60f0a0"))
            // 머리 (사각)
            px(3, 0, 10, 7, Color(hex: "a0b0c0"))
            px(4, 1, 8, 5, Color(hex: "8090a0"))
            // 눈 (LED)
            px(5, 3, 2, 2, Color(hex: "60f0a0")); px(9, 3, 2, 2, Color(hex: "60f0a0"))
            // 입 (격자)
            px(6, 5, 4, 1, Color(hex: "506070"))
            // 몸
            px(3, 7, 10, 8, shirt)
            // 관절
            px(3, 7, 10, 1, Color(hex: "8090a0"))
            // 팔
            px(1, 9, 2, 5, Color(hex: "8090a0")); px(13, 9, 2, 5, Color(hex: "8090a0"))
            // 다리
            px(4, 15, 3, 3, Color(hex: "708090")); px(9, 15, 3, 3, Color(hex: "708090"))

        case .claude:
            // Claude 마스코트 — 게/외계생물 미니멀 픽셀
            // 넓적 블록 몸통 + 양옆 집게 + 세로눈 2개 + 다리 4개 + 입 없음
            let c = Color(hex: character.shirtColor)
            let eye = Color(hex: "2a1810")

            // 몸통 상단 (약간 좁게 시작)
            px(4, 1, 8, 1, c)

            // 몸통 메인 (넓적한 블록)
            px(3, 2, 10, 7, c)

            // 양옆 집게팔 (수평 돌출, 게 느낌)
            px(1, 3, 2, 2, c)
            px(0, 4, 1, 1, c)
            px(13, 3, 2, 2, c)
            px(15, 4, 1, 1, c)

            // 눈 (세로 직사각형, 넓은 간격, 무표정)
            px(5, 4, 1, 2, eye)
            px(10, 4, 1, 2, eye)

            // 다리 4개 (짧고 균등 간격)
            px(4, 9, 1, 3, c)
            px(6, 9, 1, 3, c)
            px(9, 9, 1, 3, c)
            px(11, 9, 1, 3, c)

        case .human:
            // 기존 사람 그리기
            // Hat
            switch character.hatType {
            case .beanie: px(3, -2, 10, 3, Color(hex: "4040a0"))
            case .cap: px(2, -1, 12, 2, Color(hex: "c04040")); px(1, 0, 4, 1, Color(hex: "a03030"))
            case .hardhat: px(3, -2, 10, 3, Theme.yellow); px(2, -1, 12, 1, Theme.yellow)
            case .wizard: px(5, -5, 6, 2, Color(hex: "6040a0")); px(4, -3, 8, 2, Color(hex: "6040a0")); px(3, -1, 10, 2, Color(hex: "6040a0"))
            case .crown: px(4, -2, 8, 1, Theme.yellow); px(4, -3, 2, 1, Theme.yellow); px(7, -3, 2, 1, Theme.yellow); px(10, -3, 2, 1, Theme.yellow)
            case .headphones: px(2, 2, 2, 4, Color(hex: "404040")); px(12, 2, 2, 4, Color(hex: "404040")); px(3, 0, 10, 1, Color(hex: "505050"))
            case .beret: px(3, -1, 11, 2, Color(hex: "c04040")); px(3, -2, 8, 1, Color(hex: "c04040"))
            case .none: break
            }
            px(4, 0, 8, 3, hair); px(3, 1, 1, 2, hair); px(12, 1, 1, 2, hair)
            px(4, 3, 8, 5, fur)
            px(5, 4, 2, 2, .white); px(6, 5, 1, 1, Color(hex: "333"))
            px(9, 4, 2, 2, .white); px(10, 5, 1, 1, Color(hex: "333"))

            switch character.accessory {
            case .glasses: px(4, 4, 3, 1, Color(hex: "4060a0")); px(7, 4, 1, 1, Color(hex: "4060a0")); px(8, 4, 3, 1, Color(hex: "4060a0"))
            case .sunglasses: px(4, 4, 3, 2, Color(hex: "1a1a1a")); px(7, 4, 1, 1, Color(hex: "1a1a1a")); px(8, 4, 3, 2, Color(hex: "1a1a1a"))
            case .scarf: px(3, 7, 10, 2, Color(hex: "c04040"))
            case .mask: px(4, 5, 8, 3, Color(hex: "2a2a2a"))
            case .earring: px(13, 4, 1, 2, Theme.yellow)
            case .none: break
            }

            px(3, 8, 10, 6, shirt)
            px(1, 9, 2, 5, shirt); px(13, 9, 2, 5, shirt)
            px(0, 13, 2, 2, fur); px(14, 13, 2, 2, fur)
            px(4, 14, 4, 4, pants); px(8, 14, 4, 4, pants)
            px(4, 18, 3, 2, pants); px(9, 18, 3, 2, pants)
            px(3, 19, 4, 2, Color(hex: "4a5060")); px(9, 19, 4, 2, Color(hex: "4a5060"))
        } // end switch species
    }

    private func hatEmoji(_ hat: WorkerCharacter.HatType) -> String {
        switch hat {
        case .beanie: return "🧢"
        case .cap: return "🧢"
        case .hardhat: return "⛑"
        case .wizard: return "🧙"
        case .crown: return "👑"
        case .headphones: return "🎧"
        case .beret: return "🎨"
        case .none: return ""
        }
    }

    private func accessoryEmoji(_ acc: WorkerCharacter.Accessory) -> String {
        switch acc {
        case .glasses: return "👓"
        case .sunglasses: return "🕶"
        case .scarf: return "🧣"
        case .mask: return "😷"
        case .earring: return "💎"
        case .none: return ""
        }
    }

    private func speciesEmoji(_ species: WorkerCharacter.Species) -> String {
        switch species {
        case .human: return "🧑"
        case .cat: return "🐱"
        case .dog: return "🐶"
        case .rabbit: return "🐰"
        case .bear: return "🐻"
        case .penguin: return "🐧"
        case .fox: return "🦊"
        case .robot: return "🤖"
        case .claude: return "✦"
        }
    }
}

// MARK: - Locked Character Card (블러 + 잠금)

struct LockedCharacterCard: View {
    let character: WorkerCharacter
    @ObservedObject var registry = CharacterRegistry.shared
    @State private var showAlert = false
    @State private var isHovered = false

    var body: some View {
        VStack(spacing: 8) {
            // 블러 처리된 캐릭터 실루엣
            ZStack {
                Canvas { context, size in
                    let s: CGFloat = 2.5
                    let x: CGFloat = (size.width - 16 * s) / 2
                    let y: CGFloat = (size.height - 22 * s) / 2 + 2
                    let c = Color.gray.opacity(0.4)
                    func px(_ px: CGFloat, _ py: CGFloat, _ w: CGFloat, _ h: CGFloat) {
                        context.fill(Path(CGRect(x: x + px * s, y: y + py * s, width: w * s, height: h * s)), with: .color(c))
                    }
                    px(5, 0, 6, 6); px(4, 6, 8, 8)
                    px(3, 10, 3, 4); px(10, 10, 3, 4)
                    px(5, 14, 3, 4); px(8, 14, 3, 4)
                }
                .frame(width: 48, height: 64)
                .blur(radius: 4)
                .opacity(0.35)

                // 자물쇠
                ZStack {
                    Circle().fill(Theme.bgCard.opacity(0.8)).frame(width: 30, height: 30)
                    Circle().stroke(Theme.yellow.opacity(0.3), lineWidth: 1).frame(width: 30, height: 30)
                    Image(systemName: "lock.fill").font(.system(size: 12)).foregroundColor(Theme.yellow.opacity(0.6))
                }
            }
            .frame(width: 52, height: 68)

            Text("???").font(Theme.mono(10, weight: .bold)).foregroundColor(Theme.textDim.opacity(0.4))
            Text(character.species.rawValue).font(Theme.mono(7)).foregroundColor(Theme.textDim.opacity(0.3))

            Spacer(minLength: 0).frame(height: 12)

            // 필요 업적 힌트
            VStack(spacing: 2) {
                Image(systemName: "trophy.fill").font(.system(size: 8)).foregroundColor(Theme.yellow.opacity(0.35))
                if let name = registry.requiredAchievementName(character) {
                    Text(name).font(Theme.mono(6, weight: .medium)).foregroundColor(Theme.yellow.opacity(0.3)).lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity).padding(.vertical, 4)
        }
        .padding(10)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 12).fill(Theme.bgSurface.opacity(0.15))
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Theme.yellow.opacity(isHovered ? 0.2 : 0.08), style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
            }
        )
        .frame(maxWidth: .infinity, minHeight: 180, maxHeight: 180, alignment: .top)
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .animation(.easeOut(duration: 0.12), value: isHovered)
        .onHover { isHovered = $0 }
        .onTapGesture { showAlert = true }
        .alert("잠금 해제 필요", isPresented: $showAlert) {
            Button("확인", role: .cancel) {}
        } message: {
            if let name = registry.requiredAchievementName(character) {
                Text("도전과제 「\(name)」을(를) 달성하면\n이 캐릭터를 고용할 수 있습니다!")
            } else {
                Text("도전과제를 달성하면 잠금이 해제됩니다.")
            }
        }
    }
}
