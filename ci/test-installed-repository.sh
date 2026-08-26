#!/usr/bin/env bash
set -euo pipefail

repo_dir=${1:?generated repository directory is required}
repo_root=$(cd "${repo_dir}" && pwd)
project_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
test_root="${repo_root}/.pacman-real-test"
config="${test_root}/pacman.conf"
gpg_dir="${test_root}/gnupg"

rm -rf "${test_root}"
mkdir -p "${test_root}/cache" "${gpg_dir}"
chmod 700 "${gpg_dir}"

sig_level='Optional TrustAll'
if [[ "${VERIFY_SIGNATURES:-0}" == 1 ]]; then
  # Pacman 6.1 still looks for the legacy pubring.gpg keyring.  A plain
  # gpg --import creates pubring.kbx instead, which leaves pacman unable to
  # verify package signatures in this disposable installation test.
  gpg --no-autostart --homedir "${gpg_dir}" --no-default-keyring \
    --keyring "${gpg_dir}/pubring.gpg" --batch --import \
    "${repo_root}/unofficial-msys2-packages-release-key.asc" >/dev/null
  sig_level='Required TrustAll'
fi

cat >"${config}" <<EOF
[options]
Architecture = x86_64
# The disposable test uses the runner's official package sources only for
# dependencies; the custom repository section below is tested separately.
SigLevel = Never
RootDir = /
DBPath = /var/lib/pacman
CacheDir = ${test_root}/cache
LogFile = ${test_root}/pacman.log
GPGDir = ${gpg_dir}

[msys]
Server = https://repo.msys2.org/msys/\$arch/

[unofficial-msys2-packages]
SigLevel = ${sig_level}
Server = file://${repo_root}/msys/\$arch
EOF

cleanup() {
  pacman --config "${config}" --noconfirm -R coccinelle >/dev/null 2>&1 || true
  rm -rf "${test_root}"
}
trap cleanup EXIT

pacman --config "${config}" --noconfirm -Sy
pacman --config "${config}" --noconfirm -S coccinelle
pacman --config "${config}" -Q coccinelle

SPATCH=/usr/bin/spatch bash "${project_root}/tests/coccinelle/run-tests.sh"
echo 'PASS repository-installed feature tests'
