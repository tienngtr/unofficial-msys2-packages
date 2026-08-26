#!/usr/bin/env bash
set -euo pipefail

packages_dir=${1:?package artifact directory is required}
: "${GPG_PRIVATE_KEY:?GPG_PRIVATE_KEY is required}"
: "${GPGKEY:?GPGKEY is required}"

printf '%s' "${GPG_PRIVATE_KEY}" | gpg --batch --import >/dev/null
gpg --batch --list-secret-keys "${GPGKEY}" >/dev/null

shopt -s nullglob
packages=("${packages_dir}"/*.pkg.tar.zst)
if ((${#packages[@]} == 0)); then
  echo 'no package artifacts found' >&2
  exit 1
fi

for package in "${packages[@]}"; do
  gpg --batch --yes --local-user "${GPGKEY}" \
    --detach-sign --output "${package}.sig" "${package}"
done
