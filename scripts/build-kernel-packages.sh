#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(git rev-parse --show-toplevel)"
OUT_DIR="${ROOT_DIR}/output/pkgs"

export SRCDEST="${SRCDEST:-/var/cache/makepkg/src}"

MAKEPKG_CONF="$(mktemp)"
trap 'rm -f "$MAKEPKG_CONF"' EXIT

cp /etc/makepkg.conf "$MAKEPKG_CONF"

sed -i \
  -e 's/^CARCH=.*/CARCH="aarch64"/' \
  -e 's/^CHOST=.*/CHOST="aarch64-linux-gnu"/' \
  "$MAKEPKG_CONF"

mkdir -p "${OUT_DIR}"
mkdir -p "${SRCDEST}"

packages=(
  "linux-uconsole-cm5-git"
  "linux-uconsole-cm4-git"
)

for pkg in "${packages[@]}"; do
  echo "==> Building ${pkg}"

  cd "${ROOT_DIR}/pkgs/${pkg}"

  # Keep src/ for git/kernel build cache, but remove old package output.
  rm -rf pkg
  rm -f ./*.pkg.tar.zst ./*.pkg.tar.zst.sig

  makepkg --config "$MAKEPKG_CONF" -sA --noconfirm --needed

  cp -v ./*.pkg.tar.zst "${OUT_DIR}/"

  if compgen -G "./*.pkg.tar.zst.sig" > /dev/null; then
    cp -v ./*.pkg.tar.zst.sig "${OUT_DIR}/"
  fi
done

echo "==> Built packages:"
ls -lh "${OUT_DIR}"