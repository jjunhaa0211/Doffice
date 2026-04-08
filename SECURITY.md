# Security Policy

## Reporting a Vulnerability

If you discover a security vulnerability in Doffice, please report it responsibly.

**Do NOT open a public issue.**

Instead, contact the maintainer directly:
- GitHub: [@jjunhaa0211](https://github.com/jjunhaa0211)

Include:
- Description of the vulnerability
- Steps to reproduce
- Potential impact

You will receive a response within 48 hours.

## Scope

Doffice handles:
- Terminal process execution (Claude Code, Codex, Gemini CLI)
- File system access via AI agents
- Session data persistence (`~/Library/Application Support/Doffice/`)
- Log files (`~/Library/Logs/Doffice/`)

Security-sensitive areas:
- Command injection through session parameters
- Sensitive file access detection (`SensitiveFileShield`)
- Dangerous command detection (`DangerousCommandDetector`)
- Plugin system validation
