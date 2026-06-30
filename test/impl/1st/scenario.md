# Impl Test — 1st Iteration

## 범위
server-init.sh 전체 기능 구현 검증 (정적 분석 + 구조 검토)

## 시나리오

| ID | 항목 | 기대값 |
|----|------|--------|
| T01 | bash -n syntax check | 오류 없음 |
| T02 | shellcheck -S warning | 경고 없음 |
| T03 | 실행 권한 | -rwxr-xr-x |
| T04 | OS 감지 함수 존재 | detect_os() 정의 확인 |
| T05 | 패키지매니저 분기 | apt/dnf/yum/pacman/zypper 모두 존재 |
| T06 | Docker apt 설치 | _install_docker_apt() 존재 |
| T07 | Docker dnf 설치 | _install_docker_dnf() 존재 |
| T08 | gh 설치 (apt/dnf/pacman/zypper) | _do_install_gh() 분기 4종 |
| T09 | Python/uv 설치 | install_python() 존재 |
| T10 | Node/nvm/pnpm 설치 | install_node() 존재 |
| T11 | Go 설치 | install_go() + _do_install_go() 존재 |
| T12 | Rust 설치 | install_rust() 존재 |
| T13 | 멱등성 — 재실행 분기 | is_installed() + ask_yes_no "n" 기본값 |
| T14 | shell RC 추가 | _add_to_shell_rc() 중복 방지 grep |
| T15 | curl pipe URL 포맷 | main README 에 올바른 URL 포함 |
