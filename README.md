# unofficial-msys2-packages

Reproducible MSYS2 package recipes for useful software that is unavailable,
insufficiently functional, or difficult to obtain from the official MSYS2
repositories.

The first package family targets the MSYS subsystem on Windows x86_64:

| Package | Version | Purpose |
| --- | --- | --- |
| `ocaml` | 4.14.4-1 | OCaml compiler and runtime bootstrap |
| `ocaml-findlib` | 1.9.8-1 | OCaml library manager |
| `coccinelle` | 1.3.1-1 | C source matching and transformation |

The Coccinelle recipe keeps its bundled OCaml libraries, including PyML, and
contains the MSYS2-specific patch at
[`packages/coccinelle/001-coccinelle-msys2-build.patch`](packages/coccinelle/001-coccinelle-msys2-build.patch). The PKGBUILDs are
authoritative; CI only builds, installs, and tests them.

Required Coccinelle behavior is tested after package installation:

- core SmPL processing;
- Python scripting through `@script:python@`;
- PCRE identifier matching;
- the optimized/native `spatch` build;
- invocation of `/usr/bin/spatch` from an MSYS2 shell.

Build locally from an MSYS shell with the normal MSYS2 packaging tools:

```bash
export MAKEFLAGS="-j$(nproc)"
bash ci/build-packages.sh
bash tests/coccinelle/run-tests.sh
bash ci/build-repository.sh build/packages build/repo
bash ci/test-repository.sh build/repo
```

CI performs the same chain in separate disposable Windows/MSYS2 jobs: OCaml,
Findlib, and Coccinelle each start with `base-devel` and receive only the
previous package artifacts plus their declared dependencies. It enables
`MAKEPKG_LINT_PKGBUILD=1` and uses `makepkg --cleanbuild --syncdeps`.

GitHub Releases contain historical package artifacts, detached signatures,
checksums, and a source archive. GitHub Pages hosts only the current Pacman
repository snapshot and its repository signature.
