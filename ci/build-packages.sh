#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
build_root=${1:-"${repo_root}/build"}
artifact_dir="${build_root}/packages"

rm -rf "${artifact_dir}"
mkdir -p "${artifact_dir}"

for package in ocaml ocaml-findlib coccinelle; do
  bash "${repo_root}/ci/build-package.sh" "${package}" "${build_root}"
  pacman -U --noconfirm "${artifact_dir}/${package}-"*.pkg.tar.zst
done
