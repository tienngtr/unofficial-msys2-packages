#!/usr/bin/env bash
set -euo pipefail

packages_dir=${1:?package artifact directory is required}
repo_dir=${2:?repository output directory is required}

packages_dir=$(cd "${packages_dir}" && pwd)
repo_dir="$(cd "$(dirname "${repo_dir}")" && pwd)/$(basename "${repo_dir}")"
script_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
repo_name=unofficial-msys2-packages
target="${repo_dir}/msys/x86_64"

rm -rf "${repo_dir}"
mkdir -p "${target}"
find "${packages_dir}" -maxdepth 1 -type f \( \
  -name '*.pkg.tar.zst' -o -name '*.pkg.tar.zst.sig' \
\) -exec cp '{}' "${target}/" \;
if [[ -f "${script_root}/keys/${repo_name}-release-key.asc" ]]; then
  cp "${script_root}/keys/${repo_name}-release-key.asc" "${repo_dir}/"
fi

shopt -s nullglob
packages=("${target}"/*.pkg.tar.zst)
if ((${#packages[@]} == 0)); then
  echo 'no package artifacts found' >&2
  exit 1
fi

(
  cd "${target}"
  if [[ -n "${GPGKEY:-}" ]]; then
    # repo-add's built-in signing path relies on an interactive gpg-agent on
    # some MSYS2 versions.  Build the database first, then sign it explicitly
    # in batch mode so release CI is deterministic and non-interactive.
    repo-add -n "${repo_name}.db.tar.zst" "${packages[@]}"
    gpg --batch --yes --local-user "${GPGKEY}" --detach-sign \
      --output "${repo_name}.db.tar.zst.sig" "${repo_name}.db.tar.zst"
    # Pacman requests the signature using the same database basename that it
    # requests from the repository URL, so publish both conventional names.
    cp "${repo_name}.db.tar.zst.sig" "${repo_name}.db.sig"
  else
    repo-add -n "${repo_name}.db.tar.zst" "${packages[@]}"
  fi

  # Pages artifacts cannot contain links. Preserve pacman's conventional .db URL
  # by materializing the database and files database as ordinary files.
  for link in "${repo_name}.db" "${repo_name}.files"; do
    if [[ -L "${link}" ]]; then
      target_file=$(readlink "${link}")
      rm "${link}"
      cp "${target_file}" "${link}"
    fi
  done
)

if find "${repo_dir}" -type l -print -quit | grep -q .; then
  echo 'repository output contains a symbolic link' >&2
  exit 1
fi
