#!/usr/bin/env bash
set -euo pipefail

repo_dir=${1:?generated repository directory is required}
repo_root=$(cd "${repo_dir}" && pwd)
test_root="${repo_root}/.pacman-test"
config="${test_root}/pacman.conf"
gpg_dir="${test_root}/gnupg"

for page in "${repo_root}/index.html" "${repo_root}/msys/x86_64/index.html"; do
  if [[ ! -f "${page}" ]]; then
    echo "missing Pages landing page: ${page}" >&2
    exit 1
  fi
done

rm -rf "${test_root}"
mkdir -p "${test_root}/root" "${test_root}/db" "${test_root}/cache" "${gpg_dir}"
chmod 700 "${gpg_dir}"

sig_level='Optional TrustAll'
if [[ "${VERIFY_SIGNATURES:-0}" == 1 ]]; then
  gpg --no-autostart --homedir "${gpg_dir}" --no-default-keyring \
    --keyring "${gpg_dir}/pubring.gpg" --batch --import \
    "${repo_dir}/unofficial-msys2-packages-release-key.asc" >/dev/null
  sig_level='Required TrustAll'
fi

cat >"${config}" <<EOF
[options]
Architecture = x86_64
# The isolated test keyring contains only the custom repository key.  Official
# MSYS2 signatures are outside this test's scope; the custom repository section
# below overrides this policy when VERIFY_SIGNATURES=1.
SigLevel = Never
RootDir = ${test_root}/root
DBPath = ${test_root}/db
CacheDir = ${test_root}/cache
LogFile = ${test_root}/pacman.log
GPGDir = ${gpg_dir}

[msys]
Server = https://repo.msys2.org/msys/\$arch/

[unofficial-msys2-packages]
SigLevel = ${sig_level}
Server = file://${repo_root}/msys/\$arch
EOF

pacman --config "${config}" --noconfirm -Sy
pacman --config "${config}" --noconfirm -S coccinelle
pacman --config "${config}" -Q coccinelle

# Exercise the custom dependency packages independently as well.  Coccinelle
# links its OCaml code into spatch, so OCaml and Findlib are build-time inputs,
# not runtime dependencies of the coccinelle package.
pacman --config "${config}" --noconfirm -S ocaml-findlib
pacman --config "${config}" -Q ocaml ocaml-findlib
pacman --config "${config}" --noconfirm -R coccinelle ocaml-findlib ocaml
for package in coccinelle ocaml-findlib ocaml; do
  if pacman --config "${config}" -Q "${package}" >/dev/null 2>&1; then
    echo "${package} was not removed" >&2
    exit 1
  fi
done

rm -rf "${test_root}"
