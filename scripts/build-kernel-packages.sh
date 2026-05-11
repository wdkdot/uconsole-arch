#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(git rev-parse --show-toplevel)"
OUT_DIR="${ROOT_DIR}/output/pkgs"

mkdir -p "${OUT_DIR}"

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

  makepkg -sA --noconfirm --needed

  cp -v ./*.pkg.tar.zst "${OUT_DIR}/"

  if compgen -G "./*.pkg.tar.zst.sig" > /dev/null; then
    cp -v ./*.pkg.tar.zst.sig "${OUT_DIR}/"
  fi
done

echo "==> Built packages:"
ls -lh "${OUT_DIR}"