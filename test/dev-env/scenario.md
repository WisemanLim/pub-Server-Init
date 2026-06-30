# Dev-Env Test Scenario

## 환경
- Host: macOS (Darwin) — bash syntax validation only
- Target: Linux (Ubuntu 22.04 / Fedora 40) — functional test

## 시나리오

| ID | 항목 | 검증 방법 |
|----|------|---------|
| E01 | bash syntax 검증 | `bash -n server-init.sh` |
| E02 | shellcheck 경고 없음 (warning 이상) | `shellcheck -S warning` |
| E03 | 실행 권한 설정 | `chmod +x` 후 `ls -l` |
| E04 | curl pipe 실행 포맷 | URL 문자열 검증 |
