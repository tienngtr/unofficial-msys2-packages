# Contributing

Each package has an independent directory under `packages/` and its PKGBUILD
must describe the complete source, patch, build, check, and package procedure.
Keep source URLs pinned to released versions and update every checksum when a
source archive changes.

For Coccinelle changes, run the installed-package tests from an MSYS2 shell:

```bash
export MAKEFLAGS="-j$(nproc)"
bash ci/build-packages.sh
bash tests/coccinelle/run-tests.sh
```

Pull-request CI rebuilds each package in a fresh Windows/MSYS2 job with
`MAKEPKG_LINT_PKGBUILD=1`, passing only declared dependencies and freshly built
package artifacts between stages. This is the project's clean-chroot-equivalent
dependency check.

Changes to package recipes and patches are built by pull-request CI. Release
and GitHub Pages publication runs only from the trusted tag workflow. Do not
commit generated package files, package databases, `build/`, or scratch data.
