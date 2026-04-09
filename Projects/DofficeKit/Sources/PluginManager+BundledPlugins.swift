import Foundation
import DesignSystem

#if os(macOS)
import AppKit
#endif

extension PluginManager {

    public static func bundledRegistryCatalog() -> [RegistryPlugin] {
        [
            RegistryPlugin(
                id: "flea-market-hidden-pack",
                name: "플리 마켓 히든 캐릭터 팩",
                author: "Doffice",
                description: "플리 마켓에서 바로 고용할 수 있는 히든 캐릭터 3종을 추가합니다.",
                version: "1.0.0",
                downloadURL: "bundled://flea-market-hidden-pack",
                characterCount: 3,
                tags: ["hidden", "market", "characters"],
                previewImageURL: nil,
                stars: 42
            ),
            RegistryPlugin(
                id: "typing-combo-pack",
                name: "타이핑 콤보 팩",
                author: "Doffice",
                description: "터미널 외부에서 타이핑할 때 콤보 카운터, 파티클, 화면 흔들림 이펙트가 발동합니다.",
                version: "1.0.0",
                downloadURL: "bundled://typing-combo-pack",
                characterCount: 0,
                tags: ["effects", "combo", "typing", "particles"],
                previewImageURL: nil,
                stars: 128
            ),
            RegistryPlugin(
                id: "premium-furniture-pack",
                name: "프리미엄 가구 팩",
                author: "Doffice",
                description: "아쿠아리움, 아케이드 머신, 네온사인 등 프리미엄 가구 8종을 추가합니다.",
                version: "1.0.0",
                downloadURL: "bundled://premium-furniture-pack",
                characterCount: 0,
                tags: ["furniture", "office", "premium"],
                previewImageURL: nil,
                stars: 85
            ),
            RegistryPlugin(
                id: "vacation-beach-pack",
                name: "바캉스 비치 팩",
                author: "Doffice",
                description: "사무실을 열대 해변으로! 야자수, 파라솔, 비치 테마 2종, 캐릭터 2종 포함.",
                version: "1.0.0",
                downloadURL: "bundled://vacation-beach-pack",
                characterCount: 2,
                tags: ["theme", "beach", "furniture", "characters", "effects"],
                previewImageURL: nil,
                stars: 156
            ),
            RegistryPlugin(
                id: "battleground-pack",
                name: "배틀그라운드 팩",
                author: "Doffice",
                description: "사무실이 전장으로! 참나무, 바위, 수풀 가구 8종 + 배그 테마 + 전투 이펙트.",
                version: "1.0.0",
                downloadURL: "bundled://battleground-pack",
                characterCount: 3,
                tags: ["theme", "battle", "furniture", "characters", "effects"],
                previewImageURL: nil,
                stars: 201
            ),
            RegistryPlugin(
                id: "cozy-cafe-pack",
                name: "아늑한 카페 팩",
                author: "Doffice",
                description: "따뜻한 카페 분위기의 배경, 커피 바 가구, 카페 캐릭터를 추가합니다.",
                version: "1.0.0",
                downloadURL: "bundled://cozy-cafe-pack",
                characterCount: 2,
                tags: ["theme", "cafe", "furniture", "characters", "cozy"],
                previewImageURL: nil,
                stars: 94
            ),
            RegistryPlugin(
                id: "cyberpunk-neon-pack",
                name: "사이버펑크 네온 팩",
                author: "Doffice",
                description: "네온 테마, 홀로그램 가구, 사이버 캐릭터와 글리치 연출을 추가합니다.",
                version: "1.0.0",
                downloadURL: "bundled://cyberpunk-neon-pack",
                characterCount: 3,
                tags: ["theme", "cyberpunk", "furniture", "characters", "effects"],
                previewImageURL: nil,
                stars: 173
            ),
            RegistryPlugin(
                id: "retro-arcade-pack",
                name: "레트로 아케이드 팩",
                author: "Doffice",
                description: "오락실 감성 배경과 아케이드 가구, 픽셀 캐릭터를 추가합니다.",
                version: "1.0.0",
                downloadURL: "bundled://retro-arcade-pack",
                characterCount: 2,
                tags: ["theme", "arcade", "furniture", "characters", "retro"],
                previewImageURL: nil,
                stars: 119
            ),
            RegistryPlugin(
                id: "space-station-pack",
                name: "우주 정거장 팩",
                author: "Doffice",
                description: "딥 스페이스 테마, 우주 정거장 가구, 우주 캐릭터와 미션 연출을 추가합니다.",
                version: "1.0.0",
                downloadURL: "bundled://space-station-pack",
                characterCount: 3,
                tags: ["theme", "space", "furniture", "characters", "effects"],
                previewImageURL: nil,
                stars: 167
            ),
            RegistryPlugin(
                id: "pastel-dream-pack",
                name: "파스텔 드림 팩",
                author: "Doffice",
                description: "말랑하고 화사한 색감의 예쁜 캐릭터 4종을 추가합니다.",
                version: "1.0.0",
                downloadURL: "bundled://pastel-dream-pack",
                characterCount: 4,
                tags: ["characters", "pretty", "pastel", "dreamy"],
                previewImageURL: nil,
                stars: 141
            ),
            RegistryPlugin(
                id: "moonlit-garden-pack",
                name: "문라이트 가든 팩",
                author: "Doffice",
                description: "달빛 정원 분위기의 우아한 캐릭터 4종을 추가합니다.",
                version: "1.0.0",
                downloadURL: "bundled://moonlit-garden-pack",
                characterCount: 4,
                tags: ["characters", "pretty", "moonlight", "garden"],
                previewImageURL: nil,
                stars: 133
            ),
            RegistryPlugin(
                id: "sakura-atelier-pack",
                name: "사쿠라 아틀리에 팩",
                author: "Doffice",
                description: "벚꽃빛 작업실 무드의 사랑스러운 캐릭터 4종을 추가합니다.",
                version: "1.0.0",
                downloadURL: "bundled://sakura-atelier-pack",
                characterCount: 4,
                tags: ["characters", "pretty", "sakura", "atelier"],
                previewImageURL: nil,
                stars: 152
            ),
            RegistryPlugin(
                id: "aurora-synth-pack",
                name: "오로라 신스 팩",
                author: "Doffice",
                description: "오로라와 신스웨이브 감성의 세련된 캐릭터 4종을 추가합니다.",
                version: "1.0.0",
                downloadURL: "bundled://aurora-synth-pack",
                characterCount: 4,
                tags: ["characters", "pretty", "aurora", "synthwave"],
                previewImageURL: nil,
                stars: 164
            ),
            RegistryPlugin(
                id: "velvet-noir-pack",
                name: "벨벳 느와르 팩",
                author: "Doffice",
                description: "짙은 벨벳과 와인빛 포인트가 살아있는 시크한 캐릭터 4종을 추가합니다.",
                version: "1.0.0",
                downloadURL: "bundled://velvet-noir-pack",
                characterCount: 4,
                tags: ["characters", "pretty", "velvet", "noir"],
                previewImageURL: nil,
                stars: 127
            ),
            RegistryPlugin(
                id: "crystal-aquarium-pack",
                name: "크리스털 아쿠아리움 팩",
                author: "Doffice",
                description: "맑고 투명한 아쿠아 팔레트의 캐릭터 4종을 추가합니다.",
                version: "1.0.0",
                downloadURL: "bundled://crystal-aquarium-pack",
                characterCount: 4,
                tags: ["characters", "pretty", "aquarium", "crystal"],
                previewImageURL: nil,
                stars: 138
            ),
            RegistryPlugin(
                id: "storybook-forest-pack",
                name: "스토리북 포레스트 팩",
                author: "Doffice",
                description: "동화책 숲의 따뜻한 색감을 담은 캐릭터 4종을 추가합니다.",
                version: "1.0.0",
                downloadURL: "bundled://storybook-forest-pack",
                characterCount: 4,
                tags: ["characters", "pretty", "storybook", "forest"],
                previewImageURL: nil,
                stars: 129
            ),
            RegistryPlugin(
                id: "sunset-lagoon-pack",
                name: "선셋 라군 팩",
                author: "Doffice",
                description: "노을과 라군 물빛을 닮은 화사한 캐릭터 4종을 추가합니다.",
                version: "1.0.0",
                downloadURL: "bundled://sunset-lagoon-pack",
                characterCount: 4,
                tags: ["characters", "pretty", "sunset", "lagoon"],
                previewImageURL: nil,
                stars: 146
            ),
            RegistryPlugin(
                id: "standup-sidekick-pack",
                name: "스탠드업 사이드킥 팩",
                author: "Doffice",
                description: "최근 커밋과 변경 파일을 읽어서 팀 공유용 스탠드업 초안을 만들어 줍니다.",
                version: "1.0.0",
                downloadURL: "bundled://standup-sidekick-pack",
                characterCount: 0,
                tags: ["utility", "git", "standup", "team", "command"],
                previewImageURL: nil,
                stars: 118
            ),
            RegistryPlugin(
                id: "commit-coach-pack",
                name: "커밋 코치 팩",
                author: "Doffice",
                description: "현재 변경 내용을 바탕으로 바로 쓸 수 있는 커밋 메시지 후보를 제안합니다.",
                version: "1.0.0",
                downloadURL: "bundled://commit-coach-pack",
                characterCount: 0,
                tags: ["utility", "git", "commit", "command", "workflow"],
                previewImageURL: nil,
                stars: 124
            ),
            RegistryPlugin(
                id: "branch-janitor-pack",
                name: "브랜치 청소부 팩",
                author: "Doffice",
                description: "정리해도 비교적 안전한 머지 완료 브랜치를 찾아서 삭제 명령까지 준비합니다.",
                version: "1.0.0",
                downloadURL: "bundled://branch-janitor-pack",
                characterCount: 0,
                tags: ["utility", "git", "branch", "cleanup", "command"],
                previewImageURL: nil,
                stars: 109
            ),
            RegistryPlugin(
                id: "pr-brief-pack",
                name: "PR 브리프 팩",
                author: "Doffice",
                description: "현재 브랜치의 변경 사항을 읽고 PR 설명 초안을 빠르게 정리해 줍니다.",
                version: "1.0.0",
                downloadURL: "bundled://pr-brief-pack",
                characterCount: 0,
                tags: ["utility", "git", "pr", "review", "command"],
                previewImageURL: nil,
                stars: 121
            ),
            RegistryPlugin(
                id: "context-capsule-pack",
                name: "컨텍스트 캡슐 팩",
                author: "Doffice",
                description: "프로젝트 구조와 현재 Git 상태를 한 번에 정리한 공유용 스냅샷을 만들어 줍니다.",
                version: "1.0.0",
                downloadURL: "bundled://context-capsule-pack",
                characterCount: 0,
                tags: ["utility", "snapshot", "context", "handoff", "command"],
                previewImageURL: nil,
                stars: 115
            )
        ]
    }

    static func resolveRegistryItems(data: Data?, response: URLResponse?, error: Error?) -> [RegistryPlugin] {
        if error != nil {
            return []
        }

        if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
            return []
        }

        guard let data else { return [] }
        return decodeRegistryPayload(data) ?? []
    }

    static func mergedRegistry(remote: [RegistryPlugin]) -> [RegistryPlugin] {
        var seenIDs = Set<String>()
        var seenNames = Set<String>()
        var merged: [RegistryPlugin] = []

        for item in bundledRegistryCatalog() + remote {
            let idKey = item.id.lowercased()
            let nameKey = item.name.lowercased()
            guard !seenIDs.contains(idKey), !seenNames.contains(nameKey) else { continue }
            seenIDs.insert(idKey)
            seenNames.insert(nameKey)
            merged.append(item)
        }

        return merged
    }

    static func registryPlugin(from raw: [String: Any]) -> RegistryPlugin? {
        guard let name = firstString(in: raw, keys: ["name", "title"]),
              let downloadURL = firstString(in: raw, keys: ["downloadURL", "downloadUrl", "download_url", "url"]) else {
            return nil
        }

        let id = firstString(in: raw, keys: ["id"]) ?? slugifiedRegistryID(from: name)
        let author = firstString(in: raw, keys: ["author", "creator", "maker"]) ?? "Unknown"
        let description = firstString(in: raw, keys: ["description", "summary"]) ?? ""
        let version = firstString(in: raw, keys: ["version"]) ?? "1.0.0"
        let previewImageURL = firstString(in: raw, keys: ["previewImageURL", "previewImageUrl", "preview_image_url"])
        let tags = stringArray(in: raw, keys: ["tags"])
        let stars = firstInt(in: raw, keys: ["stars", "starCount", "star_count"])
        let characterCount = firstInt(in: raw, keys: ["characterCount", "character_count"])
            ?? ((raw["characters"] as? [[String: Any]])?.count ?? 0)

        return RegistryPlugin(
            id: id,
            name: name,
            author: author,
            description: description,
            version: version,
            downloadURL: downloadURL,
            characterCount: characterCount,
            tags: tags,
            previewImageURL: previewImageURL,
            stars: stars
        )
    }

    static func bundledPluginID(from source: String) -> String? {
        guard let url = URL(string: source), url.scheme == "bundled" else { return nil }

        let host = url.host?.trimmingCharacters(in: CharacterSet(charactersIn: "/")) ?? ""
        let path = url.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let identifier = host.isEmpty ? path : host
        return identifier.isEmpty ? nil : identifier
    }

    struct BundledPluginFile {
        let path: String
        let contents: String
    }

    struct BundledPluginDefinition {
        let directoryName: String
        let files: [BundledPluginFile]
    }

    static func bundledDefinition(from directoryURL: URL, directoryName: String) -> BundledPluginDefinition? {
        let fm = FileManager.default
        var files: [BundledPluginFile] = []

        // 재귀적으로 모든 파일 수집
        if let enumerator = fm.enumerator(at: directoryURL, includingPropertiesForKeys: nil) {
            while let fileURL = enumerator.nextObject() as? URL {
                var isDir: ObjCBool = false
                fm.fileExists(atPath: fileURL.path, isDirectory: &isDir)
                if !isDir.boolValue {
                    let relativePath = fileURL.path.replacingOccurrences(of: directoryURL.path + "/", with: "")
                    do {
                        let content = try String(contentsOf: fileURL, encoding: .utf8)
                        files.append(BundledPluginFile(path: relativePath, contents: content))
                    } catch {
                        print("[Plugin] Failed to read bundled file \(relativePath): \(error.localizedDescription)")
                    }
                }
            }
        }

        guard !files.isEmpty, files.contains(where: { $0.path == "plugin.json" }) else {
            return nil
        }

        return BundledPluginDefinition(directoryName: directoryName, files: files)
    }

    /// Bundle 리소스에서 번들 플러그인 로드 (plugins/ 디렉토리)
    static func loadBundledFromBundle(id: String) -> BundledPluginDefinition? {
        guard let bundleURL = Bundle.main.resourceURL?.appendingPathComponent("plugins").appendingPathComponent(id),
              FileManager.default.fileExists(atPath: bundleURL.path) else {
            return nil
        }

        return bundledDefinition(from: bundleURL, directoryName: id)
    }

    /// 개발 워크스페이스 루트의 plugins/ 디렉토리에서 번들 플러그인 로드
    static func loadBundledFromWorkspace(id: String) -> BundledPluginDefinition? {
        let fm = FileManager.default
        let seeds = [
            Bundle.main.bundleURL,
            Bundle.main.resourceURL,
            URL(fileURLWithPath: fm.currentDirectoryPath, isDirectory: true),
            URL(fileURLWithPath: #filePath, isDirectory: false).deletingLastPathComponent()
        ].compactMap { $0?.standardizedFileURL }

        var visited = Set<String>()

        for seed in seeds {
            var current = seed

            while true {
                let candidate = current.appendingPathComponent("plugins", isDirectory: true)
                    .appendingPathComponent(id, isDirectory: true)
                    .standardizedFileURL

                if visited.insert(candidate.path).inserted,
                   fm.fileExists(atPath: candidate.path),
                   let definition = bundledDefinition(from: candidate, directoryName: id) {
                    return definition
                }

                let parent = current.deletingLastPathComponent().standardizedFileURL
                if parent.path == current.path { break }
                current = parent
            }
        }

        return nil
    }

    static func resolvedBundledRuntimePath(id: String) -> String? {
        let fm = FileManager.default
        let seeds = [
            Bundle.main.resourceURL,
            Bundle.main.bundleURL,
            URL(fileURLWithPath: fm.currentDirectoryPath, isDirectory: true),
            URL(fileURLWithPath: #filePath, isDirectory: false).deletingLastPathComponent()
        ].compactMap { $0?.standardizedFileURL }

        var visited = Set<String>()

        for seed in seeds {
            var current = seed

            while true {
                let candidate = current.appendingPathComponent("plugins", isDirectory: true)
                    .appendingPathComponent(id, isDirectory: true)
                    .standardizedFileURL

                if visited.insert(candidate.path).inserted,
                   fm.fileExists(atPath: candidate.path),
                   fm.fileExists(atPath: candidate.appendingPathComponent("plugin.json").path) {
                    return candidate.path
                }

                let parent = current.deletingLastPathComponent().standardizedFileURL
                if parent.path == current.path { break }
                current = parent
            }
        }

        return nil
    }

    static func bundledPluginDefinition(for id: String) -> BundledPluginDefinition? {
        // 먼저 Bundle 리소스에서 찾기
        if let def = loadBundledFromBundle(id: id) { return def }
        if let def = loadBundledFromWorkspace(id: id) { return def }

        // fallback: 인라인 데이터 (flea-market-hidden-pack만)
        switch id {
        case "flea-market-hidden-pack":
            let characters = """
            [
              {
                "id": "night_vendor",
                "name": "히든 야시장",
                "archetype": "플리 마켓의 비밀 셀러",
                "hairColor": "3b2f2f",
                "skinTone": "e8c4a0",
                "shirtColor": "6d597a",
                "pantsColor": "2b2d42",
                "hatType": "cap",
                "accessory": "glasses",
                "species": "Fox",
                "jobRole": "reviewer"
              },
              {
                "id": "lucky_tag",
                "name": "히든 럭키태그",
                "archetype": "숨겨둔 딜을 먼저 찾는 흥정 장인",
                "hairColor": "b08968",
                "skinTone": "f1d3b3",
                "shirtColor": "84a59d",
                "pantsColor": "3d405b",
                "hatType": "beanie",
                "accessory": "earring",
                "species": "Cat",
                "jobRole": "planner"
              },
              {
                "id": "ghost_dealer",
                "name": "히든 고스트딜러",
                "archetype": "새벽에만 등장하는 히든 캐릭터",
                "hairColor": "d9d9ff",
                "skinTone": "d9d9ff",
                "shirtColor": "adb5bd",
                "pantsColor": "495057",
                "hatType": "wizard",
                "accessory": "mask",
                "species": "Ghost",
                "jobRole": "designer"
              }
            ]
            """

            let pluginJSON = """
            {
              "name": "플리 마켓 히든 캐릭터 팩",
              "version": "1.0.0",
              "description": "플리 마켓에서 바로 고용할 수 있는 히든 캐릭터 3종 팩",
              "author": "Doffice",
              "contributes": {
                "characters": "characters.json"
              }
            }
            """

            let packageJSON = """
            {
              "name": "flea-market-hidden-pack",
              "version": "1.0.0",
              "description": "Bundled hidden character pack for the Doffice marketplace"
            }
            """

            let readme = """
            # 플리 마켓 히든 캐릭터 팩

            Doffice 마켓플레이스에서 바로 설치할 수 있는 기본 캐릭터 플러그인입니다.
            설치하면 히든 캐릭터 3종이 캐릭터 목록에 추가됩니다.
            """

            return BundledPluginDefinition(
                directoryName: "flea-market-hidden-pack",
                files: [
                    BundledPluginFile(path: "plugin.json", contents: pluginJSON),
                    BundledPluginFile(path: "package.json", contents: packageJSON),
                    BundledPluginFile(path: "characters.json", contents: characters),
                    BundledPluginFile(path: "README.md", contents: readme)
                ]
            )

        // typing-combo-pack removed

        case "typing-combo-pack":
            let pluginJSON = """
            {
              "name": "타이핑 콤보 팩",
              "version": "1.0.0",
              "description": "터미널 외부에서 타이핑할 때 콤보 카운터와 파티클 이펙트가 발동합니다",
              "author": "Doffice",
              "contributes": {
                "effects": [
                  {
                    "id": "typing-combo",
                    "trigger": "onPromptKeyPress",
                    "type": "combo-counter",
                    "config": {
                      "decaySeconds": 2.5,
                      "shakeOnMilestone": true
                    },
                    "enabled": true
                  },
                  {
                    "id": "typing-particles",
                    "trigger": "onPromptKeyPress",
                    "type": "particle-burst",
                    "config": {
                      "emojis": ["⌨️", "💥", "🔥", "⚡", "✨", "💫"],
                      "count": 5,
                      "duration": 0.8
                    },
                    "enabled": true
                  },
                  {
                    "id": "submit-confetti",
                    "trigger": "onPromptSubmit",
                    "type": "confetti",
                    "config": {
                      "colors": ["3291ff", "3ecf8e", "f5a623", "f14c4c", "8e4ec6"],
                      "count": 30,
                      "duration": 2.5
                    },
                    "enabled": true
                  },
                  {
                    "id": "submit-flash",
                    "trigger": "onPromptSubmit",
                    "type": "flash",
                    "config": {
                      "colorHex": "3291ff",
                      "duration": 0.2
                    },
                    "enabled": true
                  },
                  {
                    "id": "submit-sound",
                    "trigger": "onPromptSubmit",
                    "type": "sound",
                    "config": {
                      "name": "Pop"
                    },
                    "enabled": true
                  },
                  {
                    "id": "error-shake",
                    "trigger": "onSessionError",
                    "type": "screen-shake",
                    "config": {
                      "intensity": 6.0,
                      "duration": 0.4
                    },
                    "enabled": true
                  },
                  {
                    "id": "complete-toast",
                    "trigger": "onSessionComplete",
                    "type": "toast",
                    "config": {
                      "text": "세션 완료! GG 🎮",
                      "icon": "checkmark.circle.fill",
                      "tint": "3ecf8e",
                      "duration": 4.0
                    },
                    "enabled": true
                  },
                  {
                    "id": "levelup-confetti",
                    "trigger": "onLevelUp",
                    "type": "confetti",
                    "config": {
                      "colors": ["f5a623", "f14c4c", "8e4ec6", "3ecf8e", "3291ff"],
                      "count": 60,
                      "duration": 4.0
                    },
                    "enabled": true
                  }
                ]
              }
            }
            """

            let readme = """
            # 타이핑 콤보 팩

            터미널 외부(프롬프트 입력)에서 타이핑할 때 콤보 카운터가 올라가고,
            파티클 이펙트가 터집니다. 프롬프트 제출 시 컨페티 + 플래시!

            ## 포함 이펙트
            - 타이핑 콤보 카운터 (2.5초 디케이)
            - 키 입력 파티클 (⌨️💥🔥⚡)
            - 프롬프트 제출 시 컨페티 + 플래시 + 사운드
            - 에러 발생 시 화면 흔들림
            - 세션 완료 토스트
            - 레벨업 대형 컨페티
            """

            return BundledPluginDefinition(
                directoryName: "typing-combo-pack",
                files: [
                    BundledPluginFile(path: "plugin.json", contents: pluginJSON),
                    BundledPluginFile(path: "README.md", contents: readme)
                ]
            )

        // ── 프리미엄 가구 팩 ──
        case "premium-furniture-pack":
            let pluginJSON = """
            {
              "name": "프리미엄 가구 팩",
              "version": "1.0.0",
              "description": "프리미엄 가구 8종을 추가합니다",
              "author": "Doffice",
              "contributes": {
                "furniture": [
                  {
                    "id": "aquarium",
                    "name": "아쿠아리움",
                    "sprite": [
                      ["4a90d9", "4a90d9", "4a90d9", "4a90d9"],
                      ["5bb8f5", "7ec8e3", "5bb8f5", "7ec8e3"],
                      ["5bb8f5", "f5a623", "7ec8e3", "f14c4c"],
                      ["5bb8f5", "7ec8e3", "5bb8f5", "7ec8e3"],
                      ["3ecf8e", "5bb8f5", "3ecf8e", "5bb8f5"],
                      ["8b7355", "8b7355", "8b7355", "8b7355"]
                    ],
                    "width": 2,
                    "height": 2,
                    "zone": "pantry"
                  },
                  {
                    "id": "arcade-machine",
                    "name": "아케이드 머신",
                    "sprite": [
                      ["", "2d2d2d", "2d2d2d", ""],
                      ["2d2d2d", "1a1a2e", "1a1a2e", "2d2d2d"],
                      ["2d2d2d", "3291ff", "3ecf8e", "2d2d2d"],
                      ["2d2d2d", "f14c4c", "f5a623", "2d2d2d"],
                      ["2d2d2d", "1a1a2e", "1a1a2e", "2d2d2d"],
                      ["", "f14c4c", "3291ff", ""],
                      ["2d2d2d", "2d2d2d", "2d2d2d", "2d2d2d"]
                    ],
                    "width": 2,
                    "height": 2,
                    "zone": "pantry"
                  },
                  {
                    "id": "neon-sign",
                    "name": "네온사인 'CODE'",
                    "sprite": [
                      ["ff6ec7", "3291ff", "3ecf8e", "f5a623"],
                      ["ff6ec7", "", "", "f5a623"],
                      ["ff6ec7", "3291ff", "3ecf8e", "f5a623"]
                    ],
                    "width": 2,
                    "height": 1,
                    "zone": "mainOffice"
                  },
                  {
                    "id": "bean-bag",
                    "name": "빈백 의자",
                    "sprite": [
                      ["", "8e4ec6", "8e4ec6", ""],
                      ["8e4ec6", "a06cd5", "a06cd5", "8e4ec6"],
                      ["8e4ec6", "a06cd5", "a06cd5", "8e4ec6"],
                      ["", "8e4ec6", "8e4ec6", ""]
                    ],
                    "width": 2,
                    "height": 1,
                    "zone": "pantry"
                  },
                  {
                    "id": "monstera",
                    "name": "몬스테라 화분",
                    "sprite": [
                      ["", "2d8a4e", "", ""],
                      ["2d8a4e", "3ecf8e", "2d8a4e", ""],
                      ["", "3ecf8e", "2d8a4e", "3ecf8e"],
                      ["", "2d8a4e", "3ecf8e", ""],
                      ["", "", "6b4226", ""],
                      ["", "8b5e3c", "8b5e3c", ""]
                    ],
                    "width": 1,
                    "height": 2,
                    "zone": "mainOffice"
                  },
                  {
                    "id": "standing-desk",
                    "name": "스탠딩 데스크",
                    "sprite": [
                      ["5a5a5a", "5a5a5a", "5a5a5a", "5a5a5a", "5a5a5a", "5a5a5a"],
                      ["8b7355", "d4a574", "d4a574", "d4a574", "d4a574", "8b7355"],
                      ["", "8b7355", "", "", "8b7355", ""],
                      ["", "8b7355", "", "", "8b7355", ""],
                      ["", "5a5a5a", "", "", "5a5a5a", ""]
                    ],
                    "width": 3,
                    "height": 2,
                    "zone": "mainOffice"
                  },
                  {
                    "id": "vending-machine",
                    "name": "자판기",
                    "sprite": [
                      ["3a3a3a", "3a3a3a", "3a3a3a", "3a3a3a"],
                      ["3a3a3a", "5bb8f5", "5bb8f5", "3a3a3a"],
                      ["3a3a3a", "f14c4c", "3ecf8e", "3a3a3a"],
                      ["3a3a3a", "f5a623", "3291ff", "3a3a3a"],
                      ["3a3a3a", "1a1a2e", "1a1a2e", "3a3a3a"],
                      ["3a3a3a", "3a3a3a", "3a3a3a", "3a3a3a"]
                    ],
                    "width": 2,
                    "height": 2,
                    "zone": "pantry"
                  },
                  {
                    "id": "ping-pong-table",
                    "name": "탁구대",
                    "sprite": [
                      ["2d6a4f", "2d6a4f", "ffffff", "2d6a4f", "2d6a4f", "2d6a4f"],
                      ["2d6a4f", "3ecf8e", "ffffff", "3ecf8e", "2d6a4f", ""],
                      ["", "8b7355", "", "", "8b7355", ""]
                    ],
                    "width": 3,
                    "height": 1,
                    "zone": "meetingRoom"
                  }
                ],
                "achievements": [
                  {
                    "id": "furniture-collector",
                    "name": "가구 컬렉터",
                    "description": "프리미엄 가구 팩을 설치했습니다",
                    "icon": "sofa.fill",
                    "rarity": "rare",
                    "xp": 200
                  }
                ]
              }
            }
            """

            let readme = """
            # 프리미엄 가구 팩

            사무실을 더욱 풍성하게 꾸밀 수 있는 프리미엄 가구 8종!

            ## 포함 가구
            - 🐠 아쿠아리움 — 팬트리에 놓는 수족관
            - 🕹️ 아케이드 머신 — 레트로 게임기
            - 💡 네온사인 'CODE' — 벽에 거는 네온
            - 🫘 빈백 의자 — 편안한 휴식 공간
            - 🌿 몬스테라 화분 — 대형 관엽식물
            - 🖥️ 스탠딩 데스크 — 일어서서 코딩
            - 🥤 자판기 — 음료 자판기
            - 🏓 탁구대 — 미팅룸 레크리에이션
            """

            return BundledPluginDefinition(
                directoryName: "premium-furniture-pack",
                files: [
                    BundledPluginFile(path: "plugin.json", contents: pluginJSON),
                    BundledPluginFile(path: "README.md", contents: readme)
                ]
            )

        // ── 바캉스 비치 팩 ──
        case "vacation-beach-pack":
            let characters = """
            [
              {
                "id": "beach_lifeguard",
                "name": "비치 라이프가드",
                "archetype": "해변 안전 요원 겸 시니어 개발자",
                "hairColor": "f5d380",
                "skinTone": "d4a574",
                "shirtColor": "f14c4c",
                "pantsColor": "f5d380",
                "hatType": "cap",
                "accessory": "sunglasses",
                "species": "Human",
                "jobRole": "developer"
              },
              {
                "id": "coconut_coder",
                "name": "코코넛 코더",
                "archetype": "코코넛 워터를 마시며 코딩하는 디지털 노마드",
                "hairColor": "2d2d2d",
                "skinTone": "e8c4a0",
                "shirtColor": "4ac6b7",
                "pantsColor": "3291ff",
                "hatType": "beanie",
                "accessory": "sunglasses",
                "species": "Human",
                "jobRole": "developer"
              }
            ]
            """

            let pluginJSON = """
            {
              "name": "바캉스 비치 팩",
              "version": "1.0.0",
              "description": "사무실을 열대 해변으로! 야자수 아래에서 코딩하는 바캉스 오피스",
              "author": "Doffice",
              "contributes": {
                "characters": "characters.json",
                "themes": [
                  {
                    "id": "beach-day",
                    "name": "비치 데이",
                    "isDark": false,
                    "accentHex": "00bcd4",
                    "bgHex": "e0f7fa",
                    "cardHex": "ffffff",
                    "textHex": "263238",
                    "greenHex": "4caf50",
                    "redHex": "ff5722",
                    "yellowHex": "ffc107",
                    "purpleHex": "9c27b0",
                    "cyanHex": "00bcd4",
                    "useGradient": true,
                    "gradientStartHex": "00bcd4",
                    "gradientEndHex": "ff9800"
                  },
                  {
                    "id": "sunset-beach",
                    "name": "선셋 비치",
                    "isDark": true,
                    "accentHex": "ff6f00",
                    "bgHex": "1a0a2e",
                    "cardHex": "2d1b4e",
                    "textHex": "ffe0b2",
                    "greenHex": "66bb6a",
                    "redHex": "ff7043",
                    "yellowHex": "ffca28",
                    "purpleHex": "ab47bc",
                    "cyanHex": "4dd0e1",
                    "useGradient": true,
                    "gradientStartHex": "ff6f00",
                    "gradientEndHex": "e91e63"
                  }
                ],
                "furniture": [
                  {
                    "id": "palm-tree",
                    "name": "야자수",
                    "sprite": [
                      ["", "", "2d8a4e", "3ecf8e", "2d8a4e", ""],
                      ["", "3ecf8e", "2d8a4e", "2d8a4e", "3ecf8e", "3ecf8e"],
                      ["3ecf8e", "2d8a4e", "", "", "2d8a4e", "3ecf8e"],
                      ["", "", "", "8b5e3c", "", ""],
                      ["", "", "", "8b5e3c", "", ""],
                      ["", "", "", "8b5e3c", "", ""],
                      ["", "", "", "8b5e3c", "", ""],
                      ["", "", "8b5e3c", "8b5e3c", "", ""]
                    ],
                    "width": 2,
                    "height": 3,
                    "zone": "mainOffice"
                  },
                  {
                    "id": "beach-parasol",
                    "name": "파라솔",
                    "sprite": [
                      ["", "f14c4c", "ffffff", "f14c4c", "ffffff", ""],
                      ["f14c4c", "ffffff", "f14c4c", "ffffff", "f14c4c", "ffffff"],
                      ["", "", "", "8b7355", "", ""],
                      ["", "", "", "8b7355", "", ""]
                    ],
                    "width": 2,
                    "height": 2,
                    "zone": "mainOffice"
                  },
                  {
                    "id": "surfboard",
                    "name": "서핑보드",
                    "sprite": [
                      ["", "3291ff", ""],
                      ["3291ff", "ffffff", "3291ff"],
                      ["3291ff", "00bcd4", "3291ff"],
                      ["3291ff", "ffffff", "3291ff"],
                      ["3291ff", "00bcd4", "3291ff"],
                      ["", "3291ff", ""]
                    ],
                    "width": 1,
                    "height": 2,
                    "zone": "mainOffice"
                  },
                  {
                    "id": "beach-chair",
                    "name": "비치 체어",
                    "sprite": [
                      ["", "ff9800", "ff9800", "ff9800", ""],
                      ["8b5e3c", "ffffff", "ff9800", "ffffff", "8b5e3c"],
                      ["", "8b5e3c", "", "8b5e3c", ""]
                    ],
                    "width": 2,
                    "height": 1,
                    "zone": "mainOffice"
                  },
                  {
                    "id": "tiki-bar",
                    "name": "티키 바",
                    "sprite": [
                      ["8b5e3c", "d4a574", "d4a574", "d4a574", "8b5e3c"],
                      ["8b5e3c", "d4a574", "d4a574", "d4a574", "8b5e3c"],
                      ["6b4226", "3ecf8e", "6b4226", "3ecf8e", "6b4226"],
                      ["8b5e3c", "", "", "", "8b5e3c"]
                    ],
                    "width": 2,
                    "height": 2,
                    "zone": "pantry"
                  },
                  {
                    "id": "sand-castle",
                    "name": "모래성",
                    "sprite": [
                      ["", "f5d380", ""],
                      ["f5d380", "e8c4a0", "f5d380"],
                      ["f5d380", "f5d380", "f5d380"]
                    ],
                    "width": 1,
                    "height": 1,
                    "zone": "mainOffice"
                  }
                ],
                "officePresets": [
                  {
                    "id": "beach-office",
                    "name": "비치 오피스",
                    "description": "야자수와 파라솔이 있는 해변 사무실",
                    "furniture": [
                      {"furnitureId": "palm-tree", "col": 2, "row": 1},
                      {"furnitureId": "palm-tree", "col": 18, "row": 1},
                      {"furnitureId": "beach-parasol", "col": 6, "row": 3},
                      {"furnitureId": "beach-parasol", "col": 14, "row": 3},
                      {"furnitureId": "surfboard", "col": 1, "row": 5},
                      {"furnitureId": "beach-chair", "col": 7, "row": 5},
                      {"furnitureId": "beach-chair", "col": 15, "row": 5},
                      {"furnitureId": "tiki-bar", "col": 10, "row": 2},
                      {"furnitureId": "sand-castle", "col": 5, "row": 8},
                      {"furnitureId": "sand-castle", "col": 16, "row": 7}
                    ]
                  }
                ],
                "effects": [
                  {
                    "id": "wave-sound",
                    "trigger": "onPromptSubmit",
                    "type": "toast",
                    "config": {
                      "text": "🌊 파도가 밀려옵니다... 코드도 밀어넣자!",
                      "icon": "water.waves",
                      "tint": "00bcd4",
                      "duration": 3.0
                    },
                    "enabled": true
                  },
                  {
                    "id": "beach-complete",
                    "trigger": "onSessionComplete",
                    "type": "confetti",
                    "config": {
                      "colors": ["00bcd4", "ff9800", "ffeb3b", "4caf50", "e91e63"],
                      "count": 50,
                      "duration": 3.5
                    },
                    "enabled": true
                  }
                ],
                "achievements": [
                  {
                    "id": "beach-coder",
                    "name": "비치 코더",
                    "description": "바캉스 비치 팩을 설치하고 해변에서 코딩을 시작했습니다",
                    "icon": "sun.max.fill",
                    "rarity": "epic",
                    "xp": 300
                  }
                ],
                "bossLines": [
                  "여기가 사무실이야, 해변이야? 코드 리뷰나 해!",
                  "파라솔 아래서 코딩하면 버그가 선크림처럼 묻어나온다고!",
                  "서핑보드 치워! 스프린트 보드에 집중해!",
                  "코코넛 워터 마시면서 코딩? ...나도 한 잔 줘."
                ]
              }
            }
            """

            let readme = """
            # 바캉스 비치 팩

            사무실을 열대 해변으로 변신시키는 테마 플러그인!
            야자수 아래에서, 파라솔 그늘에서, 티키 바 옆에서 코딩하세요.

            ## 포함 콘텐츠
            - 🌴 비치 테마 2종 (비치 데이 / 선셋 비치)
            - 🏖️ 해변 가구 6종 (야자수, 파라솔, 서핑보드, 비치체어, 티키바, 모래성)
            - 🏄 비치 오피스 프리셋
            - 🌊 서핑 이펙트 + 토스트
            - 👤 비치 캐릭터 2종 (라이프가드, 코코넛 코더)
            - 💬 사장 대사 4종 추가
            """

            return BundledPluginDefinition(
                directoryName: "vacation-beach-pack",
                files: [
                    BundledPluginFile(path: "plugin.json", contents: pluginJSON),
                    BundledPluginFile(path: "characters.json", contents: characters),
                    BundledPluginFile(path: "README.md", contents: readme)
                ]
            )

        // ── 배틀그라운드 팩 ──
        case "battleground-pack":
            let characters = """
            [
              {
                "id": "sniper_dev",
                "name": "스나이퍼 개발자",
                "archetype": "먼 거리에서 버그를 정조준하는 저격수",
                "hairColor": "3b3b3b",
                "skinTone": "c4a882",
                "shirtColor": "4b5320",
                "pantsColor": "3b3b2e",
                "hatType": "cap",
                "accessory": "sunglasses",
                "species": "Human",
                "jobRole": "developer"
              },
              {
                "id": "medic_coder",
                "name": "메딕 코더",
                "archetype": "쓰러진 코드를 되살리는 전장의 의무병",
                "hairColor": "8b4513",
                "skinTone": "e8c4a0",
                "shirtColor": "ffffff",
                "pantsColor": "4b5320",
                "hatType": "hardhat",
                "accessory": "scarf",
                "species": "Human",
                "jobRole": "qa"
              },
              {
                "id": "scout_hacker",
                "name": "정찰병 해커",
                "archetype": "적진을 정찰하며 취약점을 찾는 침투 전문가",
                "hairColor": "2d2d2d",
                "skinTone": "d4a574",
                "shirtColor": "556b2f",
                "pantsColor": "3b3b2e",
                "hatType": "beret",
                "accessory": "glasses",
                "species": "Human",
                "jobRole": "sre"
              }
            ]
            """

            let pluginJSON = """
            {
              "name": "배틀그라운드 팩",
              "version": "1.0.0",
              "description": "사무실이 전장으로! 나무와 바위에 은신하며 코딩하는 배그 컨셉",
              "author": "Doffice",
              "contributes": {
                "characters": "characters.json",
                "themes": [
                  {
                    "id": "battleground-day",
                    "name": "배틀그라운드 (낮)",
                    "isDark": false,
                    "accentHex": "4b5320",
                    "bgHex": "e8e0d0",
                    "cardHex": "f0ead6",
                    "textHex": "2b2b1b",
                    "greenHex": "556b2f",
                    "redHex": "b22222",
                    "yellowHex": "daa520",
                    "purpleHex": "6b4226",
                    "cyanHex": "708090",
                    "useGradient": true,
                    "gradientStartHex": "4b5320",
                    "gradientEndHex": "8b7355"
                  },
                  {
                    "id": "battleground-night",
                    "name": "배틀그라운드 (밤)",
                    "isDark": true,
                    "accentHex": "556b2f",
                    "bgHex": "0d0d0d",
                    "cardHex": "1a1a1a",
                    "textHex": "a0a080",
                    "greenHex": "556b2f",
                    "redHex": "8b0000",
                    "yellowHex": "b8860b",
                    "purpleHex": "483d28",
                    "cyanHex": "4a5859",
                    "useGradient": true,
                    "gradientStartHex": "1a2e1a",
                    "gradientEndHex": "0d0d0d"
                  }
                ],
                "furniture": [
                  {
                    "id": "oak-tree",
                    "name": "참나무 (은엄폐)",
                    "sprite": [
                      ["", "2d5a1e", "3ecf8e", "2d5a1e", ""],
                      ["2d5a1e", "3ecf8e", "2d8a4e", "3ecf8e", "2d5a1e"],
                      ["3ecf8e", "2d8a4e", "3ecf8e", "2d8a4e", "3ecf8e"],
                      ["2d5a1e", "3ecf8e", "2d8a4e", "3ecf8e", "2d5a1e"],
                      ["", "", "6b4226", "", ""],
                      ["", "", "6b4226", "", ""],
                      ["", "6b4226", "6b4226", "6b4226", ""]
                    ],
                    "width": 2,
                    "height": 3,
                    "zone": "mainOffice"
                  },
                  {
                    "id": "boulder",
                    "name": "바위 (엄폐물)",
                    "sprite": [
                      ["", "808080", "808080", ""],
                      ["696969", "808080", "a9a9a9", "808080"],
                      ["808080", "a9a9a9", "808080", "696969"],
                      ["", "808080", "808080", ""]
                    ],
                    "width": 2,
                    "height": 1,
                    "zone": "mainOffice"
                  },
                  {
                    "id": "bush-cover",
                    "name": "수풀 (은신처)",
                    "sprite": [
                      ["", "2d8a4e", "3ecf8e", "2d8a4e", ""],
                      ["2d8a4e", "3ecf8e", "2d5a1e", "3ecf8e", "2d8a4e"],
                      ["3ecf8e", "2d5a1e", "3ecf8e", "2d5a1e", "3ecf8e"]
                    ],
                    "width": 2,
                    "height": 1,
                    "zone": "mainOffice"
                  },
                  {
                    "id": "sandbag-wall",
                    "name": "모래주머니 바리케이드",
                    "sprite": [
                      ["c2b280", "c2b280", "c2b280", "c2b280", "c2b280", "c2b280"],
                      ["b8a070", "c2b280", "b8a070", "c2b280", "b8a070", "c2b280"],
                      ["c2b280", "b8a070", "c2b280", "b8a070", "c2b280", "b8a070"]
                    ],
                    "width": 3,
                    "height": 1,
                    "zone": "mainOffice"
                  },
                  {
                    "id": "supply-crate",
                    "name": "보급 상자",
                    "sprite": [
                      ["5a5a3e", "5a5a3e", "5a5a3e", "5a5a3e"],
                      ["5a5a3e", "f5a623", "f5a623", "5a5a3e"],
                      ["5a5a3e", "5a5a3e", "5a5a3e", "5a5a3e"]
                    ],
                    "width": 2,
                    "height": 1,
                    "zone": "mainOffice"
                  },
                  {
                    "id": "watchtower",
                    "name": "감시탑",
                    "sprite": [
                      ["8b7355", "8b7355", "8b7355", "8b7355"],
                      ["", "5a5a3e", "5a5a3e", ""],
                      ["", "6b4226", "6b4226", ""],
                      ["", "6b4226", "6b4226", ""],
                      ["", "6b4226", "6b4226", ""],
                      ["6b4226", "6b4226", "6b4226", "6b4226"]
                    ],
                    "width": 2,
                    "height": 3,
                    "zone": "mainOffice"
                  },
                  {
                    "id": "military-tent",
                    "name": "군용 텐트",
                    "sprite": [
                      ["", "", "4b5320", "", ""],
                      ["", "4b5320", "556b2f", "4b5320", ""],
                      ["4b5320", "556b2f", "3b3b2e", "556b2f", "4b5320"],
                      ["4b5320", "3b3b2e", "3b3b2e", "3b3b2e", "4b5320"]
                    ],
                    "width": 2,
                    "height": 2,
                    "zone": "meetingRoom"
                  },
                  {
                    "id": "barbed-wire",
                    "name": "철조망",
                    "sprite": [
                      ["808080", "", "808080", "", "808080", "", "808080"],
                      ["", "808080", "", "808080", "", "808080", ""],
                      ["808080", "", "808080", "", "808080", "", "808080"]
                    ],
                    "width": 3,
                    "height": 1,
                    "zone": "mainOffice"
                  }
                ],
                "officePresets": [
                  {
                    "id": "battleground-map",
                    "name": "배틀그라운드 맵",
                    "description": "나무, 바위, 수풀로 가득한 전장. 엄폐하며 코딩하라!",
                    "furniture": [
                      {"furnitureId": "oak-tree", "col": 2, "row": 1},
                      {"furnitureId": "oak-tree", "col": 16, "row": 2},
                      {"furnitureId": "oak-tree", "col": 9, "row": 7},
                      {"furnitureId": "boulder", "col": 5, "row": 4},
                      {"furnitureId": "boulder", "col": 13, "row": 6},
                      {"furnitureId": "boulder", "col": 19, "row": 8},
                      {"furnitureId": "bush-cover", "col": 3, "row": 6},
                      {"furnitureId": "bush-cover", "col": 11, "row": 3},
                      {"furnitureId": "bush-cover", "col": 17, "row": 5},
                      {"furnitureId": "sandbag-wall", "col": 7, "row": 2},
                      {"furnitureId": "sandbag-wall", "col": 14, "row": 8},
                      {"furnitureId": "supply-crate", "col": 10, "row": 5},
                      {"furnitureId": "watchtower", "col": 1, "row": 8},
                      {"furnitureId": "military-tent", "col": 18, "row": 1},
                      {"furnitureId": "barbed-wire", "col": 6, "row": 9}
                    ]
                  }
                ],
                "effects": [
                  {
                    "id": "airdrop-alert",
                    "trigger": "onPromptSubmit",
                    "type": "toast",
                    "config": {
                      "text": "📦 에어드랍 투하! 프롬프트 전송 완료",
                      "icon": "shippingbox.fill",
                      "tint": "f5a623",
                      "duration": 3.0
                    },
                    "enabled": true
                  },
                  {
                    "id": "zone-shrink",
                    "trigger": "onSessionError",
                    "type": "screen-shake",
                    "config": {
                      "intensity": 8.0,
                      "duration": 0.5
                    },
                    "enabled": true
                  },
                  {
                    "id": "zone-warning",
                    "trigger": "onSessionError",
                    "type": "flash",
                    "config": {
                      "colorHex": "b22222",
                      "duration": 0.4
                    },
                    "enabled": true
                  },
                  {
                    "id": "zone-warning-toast",
                    "trigger": "onSessionError",
                    "type": "toast",
                    "config": {
                      "text": "⚠️ 자기장이 줄어들고 있습니다! 버그를 처치하세요!",
                      "icon": "exclamationmark.triangle.fill",
                      "tint": "b22222",
                      "duration": 4.0
                    },
                    "enabled": true
                  },
                  {
                    "id": "chicken-dinner",
                    "trigger": "onSessionComplete",
                    "type": "confetti",
                    "config": {
                      "colors": ["f5a623", "4b5320", "daa520", "556b2f", "8b7355"],
                      "count": 60,
                      "duration": 4.0
                    },
                    "enabled": true
                  },
                  {
                    "id": "winner-toast",
                    "trigger": "onSessionComplete",
                    "type": "toast",
                    "config": {
                      "text": "🍗 이겼닭! 오늘 저녁은 치킨이닭!",
                      "icon": "trophy.fill",
                      "tint": "f5a623",
                      "duration": 5.0
                    },
                    "enabled": true
                  },
                  {
                    "id": "kill-combo",
                    "trigger": "onPromptKeyPress",
                    "type": "combo-counter",
                    "config": {
                      "decaySeconds": 3.0,
                      "shakeOnMilestone": true
                    },
                    "enabled": true
                  }
                ],
                "achievements": [
                  {
                    "id": "chicken-dinner",
                    "name": "이겼닭! 오늘 저녁은 치킨이닭!",
                    "description": "배틀그라운드 테마에서 첫 세션을 완료했습니다",
                    "icon": "trophy.fill",
                    "rarity": "legendary",
                    "xp": 500
                  },
                  {
                    "id": "bush-camper",
                    "name": "수풀 캠퍼",
                    "description": "수풀에 숨어서 30분 이상 코딩했습니다",
                    "icon": "leaf.fill",
                    "rarity": "epic",
                    "xp": 350
                  }
                ],
                "bossLines": [
                  "적이 접근 중이다! 코드 커밋 서둘러!",
                  "자기장 밖에 있으면 CR 리젝당한다!",
                  "에어드랍에 핫픽스가 들어있다! 빨리 수거해!",
                  "수풀에 숨어있지 말고 PR 올려!",
                  "보급 상자에서 새 라이브러리 발견! 도입 검토 해봐!",
                  "이겼닭? 아직 배포 안 했잖아!"
                ]
              }
            }
            """

            let readme = """
            # 배틀그라운드 팩

            사무실이 전장으로 변합니다! 나무와 바위 사이에서 은신하며 코딩하세요.
            에러가 나면 자기장이 줄어들고, 세션 완료하면 치킨 디너!

            ## 포함 콘텐츠
            - 🎯 배틀그라운드 테마 2종 (낮/밤)
            - 🌲 전장 가구 8종 (참나무, 바위, 수풀, 모래주머니, 보급상자, 감시탑, 군용텐트, 철조망)
            - 🗺️ 배틀그라운드 맵 프리셋
            - 📦 에어드랍 토스트 + 자기장 이펙트
            - 🍗 치킨 디너 컨페티
            - 👤 전장 캐릭터 3종 (스나이퍼, 메딕, 정찰병)
            - 💬 전장 사장 대사 6종
            - 🏆 업적 2종 (치킨 디너, 수풀 캠퍼)
            """

            return BundledPluginDefinition(
                directoryName: "battleground-pack",
                files: [
                    BundledPluginFile(path: "plugin.json", contents: pluginJSON),
                    BundledPluginFile(path: "characters.json", contents: characters),
                    BundledPluginFile(path: "README.md", contents: readme)
                ]
            )

        default:
            return nil
        }
    }

    static func firstString(in raw: [String: Any], keys: [String]) -> String? {
        for key in keys {
            if let value = raw[key] as? String {
                let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty {
                    return trimmed
                }
            }
        }
        return nil
    }

    static func firstInt(in raw: [String: Any], keys: [String]) -> Int? {
        for key in keys {
            if let value = raw[key] as? Int {
                return max(0, value)
            }
            if let value = raw[key] as? NSNumber {
                return max(0, value.intValue)
            }
            if let value = raw[key] as? String,
               let parsed = Int(value.trimmingCharacters(in: .whitespacesAndNewlines)) {
                return max(0, parsed)
            }
        }
        return nil
    }

    static func stringArray(in raw: [String: Any], keys: [String]) -> [String] {
        for key in keys {
            if let values = raw[key] as? [String] {
                return values.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
            }
            if let value = raw[key] as? String {
                return value
                    .split(separator: ",")
                    .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                    .filter { !$0.isEmpty }
            }
        }
        return []
    }

    static func slugifiedRegistryID(from text: String) -> String {
        let allowed = CharacterSet.alphanumerics
        let components = text.lowercased()
            .components(separatedBy: allowed.inverted)
            .filter { !$0.isEmpty }
        return components.isEmpty ? UUID().uuidString.lowercased() : components.joined(separator: "-")
    }
}
