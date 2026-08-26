#!/usr/bin/env bash
set -euo pipefail

root=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
work="${root}/scratch/zephyr"
python_bin=${PYTHON:-python}
zephyr_ref=${ZEPHYR_REF:-v4.4.0}
zephyr_url=${ZEPHYR_REPOSITORY:-https://github.com/zephyrproject-rtos/zephyr.git}

rm -rf "${work}"
mkdir -p "${work}/python"
trap 'rm -rf "${work}"' EXIT

"${python_bin}" -m pip install \
  --disable-pip-version-check \
  --no-input \
  --target "${work}/python" \
  -r "${root}/tests/zephyr/requirements.txt"
export PYTHONPATH="${work}/python${PYTHONPATH:+:${PYTHONPATH}}"

git clone \
  --depth 1 \
  --filter=blob:none \
  --sparse \
  --branch "${zephyr_ref}" \
  "${zephyr_url}" "${work}/zephyr"
git -C "${work}/zephyr" sparse-checkout set --no-cone \
  /scripts/ci \
  /scripts/coccicheck \
  /scripts/coccinelle

base_commit=$(git -C "${work}/zephyr" rev-parse HEAD)
git -C "${work}/zephyr" config user.name 'Coccinelle package test'
git -C "${work}/zephyr" config user.email 'coccinelle-test@example.invalid'
cat >"${work}/zephyr/scripts/coccinelle/zephyr_coccinelle_fixture.c" <<'EOF'
int zephyr_coccinelle_fixture(void)
{
    return 0;
}
EOF
git -C "${work}/zephyr" add scripts/coccinelle/zephyr_coccinelle_fixture.c
git -C "${work}/zephyr" commit -m 'Add downstream Coccinelle fixture' >/dev/null

export ZEPHYR_BASE="${work}/zephyr"
export PATH="${ZEPHYR_BASE}/scripts:${PATH}"
"${python_bin}" "${ZEPHYR_BASE}/scripts/ci/guideline_check.py" \
  --repository "${ZEPHYR_BASE}" \
  --commits "${base_commit}..HEAD"
echo 'PASS Zephyr guideline_check.py'
