#!/bin/sh
set -e

cd "$(dirname "$0")"

gpg --import keys/pgp/EC4AA0A991A5F2464582D52D2B6EF432EFC895FA.asc
makepkg -s
