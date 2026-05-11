# uconsole-arch

[English](README.md) | [한국어](README.ko.md)

`uconsole-arch`는 ClockworkPi uConsole에서 Arch Linux ARM을 구동하기 위한 기본 구성과 패키지 빌드 파일을 정리한 저장소입니다.

커널, 부팅 설정, Raspberry Pi / Broadcom 무선 호환성 패키지를 Arch Linux ARM 환경에서 재현 가능하게 관리하는 데 초점을 둡니다.

개발 과정에서는 uConsole 커뮤니티의 기존 작업을 참고하고 있으며, PeterCxy가 공유한 패키징 및 통합 아이디어, 그리고 Rex를 비롯한 여러 기여자의 하드웨어 지원 작업에서 많은 도움을 받고 있습니다.

## 내용

- `linux-uconsole-cm5-git`: ClockworkPi uConsole CM5용 커널 패키지
- `linux-uconsole-cm4-git`: ClockworkPi uConsole CM4용 커널 패키지
- `wpa_supplicant-raspberrypi`: Raspberry Pi / Broadcom brcmfmac 환경을 위한 `wpa_supplicant` 패키지
- `profiles/`: Raspberry Pi CM4/CM5와 uConsole용 부팅 설정 예시
- `docs/`: 설치, 부팅, 패키지 관련 문서 예정

## 설치

### 사전 빌드 이미지

사전 빌드 이미지는 제공할 예정이지만 아직 사용할 수 없습니다.

현재는 아래의 직접 구성 절차를 따라 SD 카드나 이미지를 수동으로 만들어 사용합니다.

- `uconsole-arch-cm5.img`
  - Raspberry Pi CM5를 사용하는 uConsole용 이미지
  - `linux-uconsole-cm5-git` 커널 패키지 사용
  - 16K 메모리 페이지 커널 사용

- `uconsole-arch-cm4.img`
  - Raspberry Pi CM4를 사용하는 uConsole용 이미지
  - `linux-uconsole-cm4-git` 커널 패키지 사용
  - 4K 메모리 페이지 커널 사용

일반 사용자는 자신의 Compute Module 모델에 맞는 이미지를 선택하면 됩니다.

### 직접 구성하는 경우

Arch Linux ARM rootfs를 SD 카드 또는 이미지의 root 파티션에 풀어 둔 뒤, 해당 rootfs에 chroot하여 커널 패키지 설치와 initramfs 생성을 진행합니다.

root 파일시스템 파티션의 라벨은 `alarm-root`로 설정해야 합니다. 새 ext4 파일시스템을 만드는 경우에는 다음과 같이 라벨을 함께 지정합니다.

```bash
mkfs.ext4 -L alarm-root /dev/ROOT_PARTITION
```

이미 ext4 파일시스템을 만든 뒤 라벨만 바꾸는 경우에는 다음 명령을 사용할 수 있습니다.

```bash
e2label /dev/ROOT_PARTITION alarm-root
```

예를 들어 부트 파티션을 `/mnt/boot`, root 파티션을 `/mnt/root`에 마운트한다면 다음과 같은 흐름으로 작업합니다.

```bash
mount /dev/ROOT_PARTITION /mnt/root
mount /dev/BOOT_PARTITION /mnt/boot
```

Arch Linux ARM rootfs를 `/mnt/root`에 풀어 둔 뒤, 부트 파티션에는 저장소의 프로파일 파일을 복사합니다.

```bash
cp profiles/config.txt /mnt/boot/config.txt
cp profiles/cmdline.txt /mnt/boot/cmdline.txt
```

`profiles/config.txt`는 CM4와 CM5를 모두 고려한 공용 설정 파일입니다. 실제 부팅 시 Compute Module 모델에 따라 알맞은 커널과 오버레이가 선택됩니다.

rootfs의 `/boot`가 부트 파티션을 가리키도록 바인드 마운트한 뒤 chroot에 진입합니다.

```bash
mount --bind /mnt/boot /mnt/root/boot
arch-chroot /mnt/root
```

CM5 이미지에는 다음 커널 패키지를 설치합니다.

```bash
pacman -U linux-uconsole-cm5-git-*.pkg.tar.zst
mkinitcpio -p linux-uconsole-cm5-git
```

CM4 이미지에는 다음 커널 패키지를 설치합니다.

```bash
pacman -U linux-uconsole-cm4-git-*.pkg.tar.zst
mkinitcpio -p linux-uconsole-cm4-git
```

`linux-uconsole-cm4-git`와 `linux-uconsole-cm5-git`는 같은 DTB/DTBO 경로를 설치하므로 동시에 설치하지 않습니다.

## 범위

이 저장소는 uConsole에서 Arch Linux ARM을 부팅하는 데 필요한 기본 시스템 계층에 초점을 둡니다.

- 커널 패키징
- 부팅 설정 예시
- 디바이스 트리와 오버레이 처리
- 네트워크 호환성 패키지

데스크톱 환경, 윈도우 매니저, 개인 UI 프리셋은 포함하지 않습니다.

## 저장소 구조

```text
docs/       문서 예정
pkgs/       PKGBUILD와 관련 패키지 파일
profiles/   부팅 설정 예시 파일
```

## 참고

이 저장소의 파일은 개인 데스크톱 구성보다 장치 구동에 필요한 기본 구성과 패키징 정보를 우선합니다. 사용 환경별 설정은 이 기반 위에서 별도로 추가하는 것을 권장합니다.

## 라이선스

이 저장소의 파일은 별도 명시가 없는 한 MIT License를 따릅니다.

패키징 대상이 되는 업스트림 프로젝트는 각 프로젝트의 원래 라이선스를 따릅니다.
