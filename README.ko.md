# uconsole-arch

Raspberry Pi CM5를 사용하는 ClockworkPi uConsole용 Arch Linux ARM 기반 프로젝트입니다.

`uconsole-arch`는 ClockworkPi uConsole에서 Arch Linux ARM을 구동하기 위한 기본 구성과 패키지 빌드 파일을 정리한 저장소입니다.

커널, 부팅 설정, Raspberry Pi / Broadcom 무선 호환성 패키지를 Arch Linux ARM 환경에서 재현 가능하게 관리하는 데 초점을 둡니다.

개발 과정에서는 uConsole 커뮤니티의 기존 작업을 참고하고 있으며, PeterCxy가 공유한 패키징 및 통합 아이디어, 그리고 Rex를 비롯한 여러 기여자의 하드웨어 지원 작업에서 많은 도움을 받고 있습니다.

## 제공 내용

- `linux-uconsole-cm5-git`: ClockworkPi uConsole CM5용 커널 패키지
- `wpa_supplicant-raspberrypi`: Raspberry Pi / Broadcom brcmfmac 환경을 위한 `wpa_supplicant` 패키지
- `profiles/`: Raspberry Pi CM5와 uConsole용 부팅 설정 예시
- `docs/`: 설치, 부팅, 패키지 관련 문서

## 범위

이 저장소는 uConsole에서 Arch Linux ARM을 부팅하기 위한 기본 시스템 레이어에 집중합니다.

- 커널 패키징
- 부팅 설정 예시
- 디바이스 트리 및 오버레이 처리
- 네트워크 호환성 패키지

데스크톱 환경, 윈도우 매니저, 개인 취향의 UI 프리셋 같은 상위 레이어 구성은 포함하지 않습니다.

## 예정 항목

- `uconsole-4g-utils`
- `uconsole-audio-switch`

## 저장소 구조

```text
docs/       문서
pkgs/       PKGBUILD와 관련 패키지 파일
profiles/   부팅 설정 예시 파일
```

## 참고

이 저장소의 파일은 개인 데스크톱 구성보다 장치 구동에 필요한 기본 구성과 패키징 정보를 우선합니다. 사용 환경별 설정은 이 기반 위에서 별도로 추가하는 것을 권장합니다.

## 라이선스

추후 결정 예정
