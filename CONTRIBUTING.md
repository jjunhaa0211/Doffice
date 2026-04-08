# Contributing Plugins to Doffice

Doffice 플러그인을 만들고 공유하는 가이드입니다.

## Quick Start (3단계)

### 1. 플러그인 생성
도피스 설정 > 플러그인 > "Create New Plugin" 버튼을 클릭하고 템플릿을 선택하세요.

또는 CLI로:
```bash
mkdir my-plugin && cd my-plugin
touch plugin.json
```

### 2. `plugin.json` 작성

```json
{
  "name": "My Plugin",
  "version": "1.0.0",
  "description": "나만의 도피스 플러그인",
  "author": "Your Name",
  "contributes": {
    "themes": [...],
    "characters": "characters.json",
    "commands": [...],
    "effects": [...],
    "furniture": [...],
    "panels": [...]
  }
}
```

### 3. 설치 & 테스트
도피스 설정 > 플러그인 > 로컬 폴더로 설치하거나:
```
~/my-plugin
```

---

## Manifest Reference

### Extension Points

| Key | Type | Description |
|-----|------|-------------|
| `themes` | Array | 색상 테마 프리셋 |
| `characters` | String | 캐릭터 JSON 파일 경로 |
| `commands` | Array | 셸 스크립트 명령어 |
| `effects` | Array | 이벤트 트리거 이펙트 |
| `furniture` | Array | 오피스 가구 스프라이트 |
| `panels` | Array | HTML/JS 커스텀 패널 |
| `statusBar` | Array | 상태바 위젯 |
| `achievements` | Array | 커스텀 업적 |
| `bossLines` | Array | 보스 대사 추가 |
| `officePresets` | Array | 오피스 레이아웃 프리셋 |

### Theme

```json
{
  "id": "unique-id",
  "name": "Display Name",
  "isDark": true,
  "accentHex": "3291ff",
  "bgHex": "0f0f0f",
  "cardHex": "1a1a1a",
  "textHex": "e0e0e0",
  "greenHex": "3ecf8e",
  "redHex": "f14c4c",
  "yellowHex": "f5a623",
  "purpleHex": "8e4ec6",
  "cyanHex": "06b6d4",
  "useGradient": false,
  "gradientStartHex": "...",
  "gradientEndHex": "..."
}
```

### Command

```json
{
  "id": "my-command",
  "title": "My Command",
  "icon": "terminal.fill",
  "script": "scripts/my-script.sh",
  "keybinding": "cmd+shift+m"
}
```

### Effect

```json
{
  "id": "my-effect",
  "trigger": "onSessionComplete",
  "type": "confetti",
  "config": {
    "colors": ["5b9cf6", "3ecf8e"],
    "count": 30,
    "duration": 2.5
  },
  "enabled": true
}
```

**Trigger types**: `onPromptKeyPress`, `onPromptSubmit`, `onSessionComplete`, `onSessionError`, `onAchievementUnlock`, `onCharacterHire`, `onLevelUp`

**Effect types**: `combo-counter`, `particle-burst`, `screen-shake`, `flash`, `sound`, `toast`, `confetti`, `typewriter`, `progress-bar`, `glow`

### Character (`characters.json`)

```json
[
  {
    "id": "unique_id",
    "name": "Display Name",
    "archetype": "성격 설명",
    "hairColor": "4a3728",
    "skinTone": "ffd5b8",
    "shirtColor": "f08080",
    "pantsColor": "3a4050",
    "hatType": "none",
    "accessory": "glasses",
    "species": "Human",
    "jobRole": "developer"
  }
]
```

**species**: Human, Cat, Dog, Rabbit, Bear, Penguin, Fox, Robot, Claude, Alien, Ghost, Dragon, Chicken, Owl, Frog, Panda, Unicorn, Skeleton
**jobRole**: developer, qa, reporter, boss, planner, reviewer, designer, sre
**hatType**: none, beanie, cap, hardhat, wizard, crown, headphones, beret
**accessory**: none, glasses, sunglasses, scarf, mask, earring

### Furniture

```json
{
  "id": "my-desk",
  "name": "My Desk",
  "sprite": [
    ["8b7355", "8b7355", "8b7355"],
    ["6b5335", "", "6b5335"]
  ],
  "width": 2,
  "height": 1,
  "zone": "mainOffice"
}
```

Sprite format: 2D array of hex colors. Empty string = transparent pixel.

### Panel (HTML/JS)

```json
{
  "id": "my-panel",
  "title": "My Panel",
  "icon": "puzzlepiece.fill",
  "entry": "panel/index.html",
  "position": "panel"
}
```

---

## JS Bridge API

패널에서 네이티브 앱과 통신할 수 있습니다.

### Actions (JS -> Native)

```javascript
// 세션 정보 요청
window.webkit.messageHandlers.doffice.postMessage({
  action: 'getSessionInfo'
})

// 토스트 알림
window.webkit.messageHandlers.doffice.postMessage({
  action: 'showToast',
  text: 'Hello!',
  icon: 'star.fill',
  tint: 'f5a623'
})

// 테마 색상 조회
window.webkit.messageHandlers.doffice.postMessage({
  action: 'getThemeColors'
})

// 활성 탭 정보
window.webkit.messageHandlers.doffice.postMessage({
  action: 'getActiveTab'
})

// 이펙트 트리거
window.webkit.messageHandlers.doffice.postMessage({
  action: 'triggerEffect',
  effectType: 'confetti'
})

// 플러그인 스토리지
window.webkit.messageHandlers.doffice.postMessage({
  action: 'readPluginStorage',
  key: 'myKey'
})
window.webkit.messageHandlers.doffice.postMessage({
  action: 'writePluginStorage',
  key: 'myKey',
  value: 'myValue'
})
```

### Events (Native -> JS)

```javascript
// 앱이 패널에 이벤트를 전달합니다
window.addEventListener('doffice-event', (e) => {
  console.log(e.detail.type, e.detail.data)
})
```

---

## 레지스트리 등록

플러그인을 마켓플레이스에 등록하려면:

1. GitHub에 플러그인 리포를 만듭니다
2. Release에 `plugin.tar.gz`를 첨부합니다
3. [registry.json](https://github.com/jjunhaa0211/Doffice/blob/main/registry.json)에 PR을 보냅니다:

```json
{
  "id": "my-plugin",
  "name": "My Plugin",
  "author": "Your Name",
  "description": "설명",
  "version": "1.0.0",
  "downloadURL": "https://github.com/.../releases/download/v1.0.0/plugin.tar.gz",
  "characterCount": 0,
  "tags": ["theme", "dark"],
  "stars": 0
}
```

---

## 디버그

도피스 설정 > 플러그인에서 "Debug Console" 버튼으로 디버그 뷰를 열 수 있습니다.
- 이벤트/이펙트 실행 로그 확인
- 수동으로 이벤트 발사 테스트
- 스크립트 실행 결과 확인

## 라이선스

플러그인은 원하는 라이선스를 자유롭게 적용할 수 있습니다. 도피스 본체는 MIT 라이선스입니다.
