# MyWorkStudio

Claude Code 세션을 시각적으로 관리하는 macOS 네이티브 앱

## Features

- 멀티 세션 관리 (동시에 여러 Claude Code 세션 운영)
- 픽셀 아트 캐릭터 시스템 (작업 상태 시각화)
- 실시간 토큰 사용량 추적 (일간/주간)
- 마크다운 렌더링 지원
- 메뉴바 위젯
- macOS 알림 (작업 완료 시)
- 도전과제 & 레벨 시스템

## Requirements

- macOS 14.0+
- Claude Code (`npm install -g @anthropic-ai/claude-code`)

## Install

### Homebrew

```bash
brew tap jjunhaa0211/tap
brew install --cask myworkstudio
```

### Manual

1. Clone this repo
2. Open `WorkManApp/WorkManApp.xcodeproj` in Xcode
3. Build & Run (Cmd+R)

## License

MIT
