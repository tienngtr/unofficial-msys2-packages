#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
package=${1:?usage: build-package.sh <package> [build-root]}
build_root=${2:-"${repo_root}/build"}
package_dir="${repo_root}/packages/${package}"
artifact_dir="${build_root}/packages"

case "${package}" in
  ocaml|ocaml-findlib|coccinelle) ;;
  *) echo "unknown package: ${package}" >&2; exit 2 ;;
esac

mkdir -p "${artifact_dir}"
rm -f "${package_dir}"/*.pkg.tar.zst

echo "==> Building ${package}"
(
  cd "${package_dir}"
  makepkg --syncdeps --noconfirm --cleanbuild --clean --force
)

mapfile -t artifacts < <(find "${package_dir}" -maxdepth 1 -type f -name "${package}-*.pkg.tar.zst" -print)
if ((${#artifacts[@]} != 1)); then
  echo "expected one ${package} package, found ${#artifacts[@]}" >&2
  exit 1
fi
cp "${artifacts[0]}" "${artifact_dir}/"
