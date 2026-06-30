# PRD — pub-Server-Init

## 1. 개요 / Overview

서버(온프렘·클라우드) 할당 후 OS 설치부터 프로젝트 배포·운영까지 필요한 표준 초기화 스크립트.
단일 curl 명령으로 실행되며 멱등성(idempotent)을 보장한다.

## 2. 대상 / Target

- TA/AA/IA/SA 역할의 인프라·개발 매니저
- 신규 서버 프로비저닝 담당자
- CI/CD 파이프라인 자동화 담당자

## 3. 기능 범위 / Scope

### 3.1 OS 감지 및 패키지 업데이트
- 지원 배포판: Ubuntu/Debian, Fedora/RHEL/CentOS/Rocky/Alma, Arch, openSUSE
- 패키지 매니저 자동 감지: apt / dnf / yum / pacman / zypper
- 시스템 패키지 업데이트 (사용자 확인 후)

### 3.2 핵심 도구 설치
- git, curl, wget, unzip, jq, make, build-essential 등 기본 패키지
- Docker Engine + Docker Compose (plugin 방식)
- Docker 그룹에 현재 사용자 추가

### 3.3 GitHub CLI 연동
- gh 설치 (공식 저장소 경유)
- gh auth login 인터랙티브 진행
- git 전역 사용자 설정 (name, email)

### 3.4 개발 환경 선택 설치 (사용자 입력)
- Python: uv, virtualenv, uvicorn
- Node.js: nvm, pnpm, (Next.js / Nest.js CLI 선택)
- Go: 공식 바이너리 설치
- Rust: rustup

### 3.5 멱등성 보장
- 재실행 시 기존 설치 감지 → 버전 표시 → 업데이트 여부 확인
- 새 개발환경 추가 설치 지원

### 3.6 실행 방법
```bash
bash <(curl -fsSL https://raw.githubusercontent.com/WisemanLim/pub-Server-Init/refs/heads/main/server-init.sh)
```

### 3.7 문서
- README.md (한국어, 상세)
- README.en.md (영어, 동일 구성)

## 4. 비기능 요구사항

- root 없이 sudo 로 실행 가능
- 컬러 출력으로 진행 상태 시각화
- 오류 발생 시 안내 메시지 + 종료 (set -e 미사용, 개별 오류 핸들링)
- 네트워크 없는 환경에서 명확한 오류 메시지

## 5. 성공 지표

- Ubuntu 22.04 / 24.04 에서 최초 실행 PASS
- Fedora 40 에서 최초 실행 PASS
- 재실행 시 기존 설치 감지 + 추가 설치 지원 PASS
- curl pipe 실행 PASS

## 6. 범위 외

- Windows / macOS 미지원
- k8s / helm 설치 (추후 확장)
- 방화벽 설정 자동화

## 7. 기술 메모

- nvm은 .bashrc/.zshrc 에 직접 source 라인 추가
- Docker Compose v2 plugin 방식 (`docker compose` not `docker-compose`)
- gh 공식 패키지 저장소: https://cli.github.com/packages

## 변경 이력

| 날짜 | 내용 |
|------|------|
| 2026-06-30 | 최초 작성 |
