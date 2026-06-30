# pub-Server-Init

**서버 초기화 자동화 스크립트** — 온프렘/클라우드 서버에 OS 설치 직후 한 줄로 개발 환경을 구성합니다.

🇬🇧 [English version → README.en.md](README.en.md)

---

## 빠른 시작

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/WisemanLim/pub-Server-Init/refs/heads/main/server-init.sh)
```

> **재실행 가능** — 이미 설치된 도구는 건너뛰고, 업데이트 여부만 확인합니다.

---

## 지원 OS

| 배포판 | 패키지 매니저 |
|--------|-------------|
| Ubuntu 20.04 / 22.04 / 24.04 | apt |
| Debian 11 / 12 | apt |
| Fedora 38+ | dnf |
| RHEL / CentOS / Rocky / AlmaLinux 8+ | dnf / yum |
| Arch Linux | pacman |
| openSUSE Leap / Tumbleweed | zypper |

---

## 설치 항목

### 기본 환경 (자동)
- **시스템 패키지 업데이트** — 확인 후 진행
- **기본 도구** — git, curl, wget, unzip, jq, make, build-essential
- **Docker Engine** + **Docker Compose v2** (plugin)
- **GitHub CLI (gh)** + 인증 설정

### 개발 환경 (선택)
스크립트 실행 중 메뉴에서 선택합니다.

| 번호 | 환경 | 설치 내용 |
|------|------|---------|
| 1 | **Python** | uv, uvicorn |
| 2 | **Node.js** | nvm, pnpm (+ Next.js / Nest.js CLI 선택) |
| 3 | **Go** | 공식 최신 바이너리 |
| 4 | **Rust** | rustup |
| 5 | **전체** | 1~4 모두 |

---

## 실행 흐름

```
1. OS 감지 + 패키지 매니저 확인
2. 시스템 패키지 업데이트 (선택)
3. 기본 패키지 설치
4. Docker + Docker Compose 설치/확인
5. GitHub CLI 설치/확인
6. Git 사용자 설정 + gh 인증
7. 개발 환경 선택 설치
8. 설치 결과 요약 출력
```

---

## 멱등성 (Idempotent)

이미 설치된 도구가 있으면:
- 버전 정보 출력
- 업데이트 여부 확인 (기본값: 건너뜀)
- 추가 개발환경 설치 가능

---

## 사전 요구사항

- Linux (지원 배포판)
- `sudo` 권한 또는 root
- 인터넷 연결

---

## 주의 사항

- Docker 그룹 적용은 **재로그인** 후 반영됩니다
- nvm, uv, Rust 등 PATH 변경은 **새 터미널** 열기 후 적용됩니다
- Docker Compose v2 사용: `docker compose` (하이픈 없음)

---

## 참고 링크

| 도구 | 공식 문서 |
|------|---------|
| Docker | https://docs.docker.com/engine/install/ |
| GitHub CLI | https://cli.github.com/ |
| uv (Python) | https://docs.astral.sh/uv/ |
| nvm | https://github.com/nvm-sh/nvm |
| pnpm | https://pnpm.io/ |
| Go | https://go.dev/doc/install |
| Rust (rustup) | https://rustup.rs/ |

---

## 라이선스

MIT
