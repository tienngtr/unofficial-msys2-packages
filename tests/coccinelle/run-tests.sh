#!/usr/bin/env bash
set -euo pipefail

root=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
spatch=${SPATCH:-spatch}
tmpdir="${root}/.tmp"

rm -rf "${tmpdir}"
mkdir -p "${tmpdir}"
trap 'rm -rf "${tmpdir}"' EXIT

run_transform_test() {
  local name=$1
  local input="${root}/${name}/input.c"
  local patch_file="${root}/${name}/test.cocci"
  local expected="${root}/${name}/expected.txt"
  local work="${tmpdir}/${name}"
  mkdir -p "${work}"
  cp "${input}" "${work}/input.c"
  "${spatch}" --sp-file "${patch_file}" --in-place "${work}/input.c" >/dev/null
  grep -Fxq "$(<"${expected}")" "${work}/input.c"
  echo "PASS ${name}"
}

run_output_test() {
  local name=$1
  local expected="${root}/${name}/expected.txt"
  local output="${tmpdir}/${name}.out"
  "${spatch}" --sp-file "${root}/${name}/test.cocci" "${root}/${name}/input.c" \
    >"${output}" 2>&1
  grep -Fxq "$(<"${expected}")" "${output}"
  echo "PASS ${name}"
}

run_transform_test core
run_output_test python
run_transform_test pcre
run_transform_test optimized

"${spatch}" --version | grep -Fq "spatch version"
echo 'PASS version'

completion=/usr/share/bash-completion/completions/spatch
test -r "${completion}"
bash -n "${completion}"
grep -Fq '_spatch' "${completion}"
echo 'PASS bash-completion'
