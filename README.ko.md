# uconsole-arch

Raspberry Pi CM5를 사용하는 ClockworkPi uConsole용 Arch Linux ARM 기반 프로젝트입니다.

`uconsole-arch`는 ClockworkPi uConsole에서 Arch Linux ARM을 구동하기 위한 기본 환경을 만들고 정리하는 저장소입니다.

이 프로젝트는 uConsole에서 Arch Linux ARM이 무리 없이 부팅되도록, 커널과 부팅 관련 파일, 각종 하드웨어 지원 요소를 패키지 중심으로 관리할 수 있는 깔끔하고 유지보수하기 쉬운 기반을 마련하는 데 목적이 있습니다.

개발 과정에서는 uConsole 커뮤니티의 기존 작업을 참고하고 있으며, PeterCxy가 공유한 패키징 및 통합 아이디어, 그리고 Rex를 비롯한 여러 기여자의 하드웨어 지원 작업에서 많은 도움을 받고 있습니다.

## 목표

- Raspberry Pi CM5 기반 ClockworkPi uConsole에서 Arch Linux ARM이 부팅되도록 한다
- 필요한 커널과 관련 파일을 Arch 스타일에 맞게 관리 가능한 형태로 패키징한다
- uConsole 전용 하드웨어 지원을 재사용 가능한 패키지로 정리한다
- 기본 시스템은 단순하고 깔끔하게 유지해, 이후 확장이 쉽도록 한다

## 범위

이 저장소는 기본 시스템 레이어에 집중합니다.

- 커널 패키징
- 부팅 설정 예시
- 디바이스 트리 및 오버레이 처리
- 네트워크 호환성 패키지
- uConsole 전용 기능을 위한 선택형 하드웨어 헬퍼 패키지

데스크톱 환경, 윈도우 매니저, 개인 취향의 UI 프리셋 같은 상위 레이어 구성은 이 저장소 바깥에서 별도로 다루는 것을 전제로 합니다.

## 예정 패키지

패키지 구성은 앞으로 달라질 수 있지만, 현재는 아래와 같은 항목을 중심으로 초기 구조를 잡고 있습니다.

- `linux-uconsole-cm5-git`
- `wpa_supplicant-raspberrypi-git`
- `uconsole-4g-utils`
- `uconsole-audio-switch`

## 저장소 구조

```text
docs/       문서
pkgs/       PKGBUILD와 관련 패키지 파일
profiles/   부팅 설정 예시 파일
scripts/    빌드 및 저장소 관리 보조 스크립트
```

## 참고

이 저장소는 uConsole용 Arch Linux ARM 작업의 기반이 되는 베이스 레이어를 깔끔하게 정리하는 데 초점을 둡니다. 데스크톱 환경이나 UI처럼 더 상위 수준의 구성은 이 기반 위에서 별도 저장소로 발전시킬 수 있습니다.

## 라이선스

추후 결정 예정
