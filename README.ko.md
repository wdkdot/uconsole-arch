# uconsole-arch

[English](README.md) | [한국어](README.ko.md)

ClockworkPi uConsole용 Arch Linux ARM 이미지와 커널 패키지를 제공하는 저장소입니다.

이 저장소는 다음을 제공합니다.

- 바로 플래시 가능한 CM5 이미지
- pacman 저장소로 제공되는 CM4, CM5, CM5 4K 커널 패키지
- ClockworkPi uConsole CM4/CM5용 부팅 프로파일
- Raspberry Pi / Broadcom 무선 호환성 패키지

> 현재 사전 빌드 이미지는 CM5용만 제공됩니다.
> CM4 커널 패키지는 제공되지만, CM4 이미지는 아직 배포되지 않았습니다.

설치된 시스템은 `pacman`으로 커널 업데이트를 받을 수 있으므로, 커널 패키지가 갱신될 때마다 새 이미지를 다시 플래시할 필요는 없습니다.

## 빠른 시작

1. `uconsole-arch-cm5.img`를 다운로드합니다.
2. microSD 카드 또는 eMMC 대상 장치에 플래시합니다.
3. uConsole CM5를 부팅합니다.
4. Arch Linux ARM 기본 계정으로 로그인합니다.
5. 기본 비밀번호를 변경합니다.
6. `pacman`으로 시스템을 업데이트합니다.

```bash
sudo pacman -Syu
```

## 제공 이미지

| Image | Status | Target | Notes |
|---|---|---|---|
| `uconsole-arch-cm5.img` | Available | CM5 | 기본 이미지, 16K page 커널 |
| `uconsole-arch-cm4.img` | Planned | CM4 | 커널 패키지는 제공되지만 이미지는 아직 미배포 |
| `uconsole-arch-cm5-4k.img` | Not provided | CM5 | 필요하면 부팅 후 `linux-uconsole-cm5-4k-git` 설치 |

## 기본 로그인

현재 이미지는 Arch Linux ARM의 기본 계정 정보를 그대로 유지합니다.

- User: `alarm`
- Password: `alarm`
- Root password: `root`

첫 부팅 후 두 비밀번호를 모두 변경하세요.

```bash
passwd
sudo passwd root
```

## 패키지 저장소

사전 빌드된 이미지에는 이 저장소가 `/etc/pacman.conf`에 이미 추가되어 있으므로, 이미지 사용자는 바로 `pacman`으로 업데이트할 수 있습니다.

수동 설치 환경이나 기존 Arch Linux ARM 시스템에서는 `/etc/pacman.conf`에 저장소를 추가합니다.

```ini
[uconsole-arch]
SigLevel = Optional TrustAll
Server = https://repo.wdk.kr/uconsole-arch/$arch
```

이후 `pacman`으로 패키지를 설치하거나 업데이트할 수 있습니다.

## 커널 패키지

커널 패키지는 Rex가 관리하는 uConsole 지원 Raspberry Pi 커널을 기반으로 빌드됩니다: <https://github.com/ak-rex/ClockworkPi-linux>

| Package | Target | Page size | Notes |
|---|---|---|---|
| `linux-uconsole-cm5-git` | CM5 | 16K | 기본 CM5 커널 |
| `linux-uconsole-cm5-4k-git` | CM5 | 4K | 호환성용 커널 |
| `linux-uconsole-cm4-git` | CM4 | 4K | CM4 커널 |

`linux-uconsole-cm4-git`, `linux-uconsole-cm5-git`, `linux-uconsole-cm5-4k-git`는 부팅 파일과 DTB/DTBO 경로가 겹치므로 동시에 설치하지 않습니다.

부팅된 CM5 시스템을 4K page 커널로 전환하려면 다음 패키지를 설치합니다.

```bash
sudo pacman -S linux-uconsole-cm5-4k-git
```

CM5 4K 패키지는 기본 CM5 커널과 같은 부팅 슬롯을 사용하므로 `/boot/config.txt`는 수정하지 않아도 됩니다.

## 무선 패키지

`wpa_supplicant-raspberrypi`는 Raspberry Pi / Broadcom brcmfmac Wi-Fi 환경을 위한 패치가 적용된 `wpa_supplicant` 패키지입니다. 이미지 빌더는 이 패키지가 있으면 우선 설치하고, 저장소에 없으면 Arch Linux ARM 기본 `wpa_supplicant` 패키지로 대체합니다.

## 빌드와 배포 방식

- 커널 패키지는 self-hosted GitHub Actions runner에서 자동 빌드됩니다.
- 커널 빌드가 성공하면 pacman 저장소가 다시 생성되고 미러 서버로 배포됩니다.
- `wpa_supplicant-raspberrypi`는 교차 컴파일이 아직 번거로워 uConsole에서 수동 빌드합니다.
- 부팅 가능한 이미지는 `scripts/build-image.sh`로 수동 빌드합니다.
- 설치된 시스템은 `pacman`으로 업데이트할 수 있으므로 커널 업데이트마다 새 이미지를 만들지는 않습니다.

## 수동 이미지 빌드

수동 이미지 빌드 방법은 [docs/build-image.md](docs/build-image.md)에 정리되어 있습니다.

## 저장소 구조

```text
docs/       설치, 이미지 빌드, 패키지, 부팅 관련 문서
pkgs/       PKGBUILD와 관련 패키지 파일
profiles/   이미지에 복사되는 부팅 설정 파일
scripts/    커널 패키지와 이미지 빌드 스크립트
```

## Credits

개발 과정에서는 uConsole 커뮤니티의 기존 작업을 참고하고 있으며, PeterCxy가 공유한 패키징 및 통합 아이디어, 그리고 Rex를 비롯한 여러 기여자의 하드웨어 지원 작업에서 많은 도움을 받고 있습니다.

## 라이선스

이 저장소의 파일은 별도 명시가 없는 한 MIT License를 따릅니다.

패키징 대상이 되는 업스트림 프로젝트는 각 프로젝트의 원래 라이선스를 따릅니다.
