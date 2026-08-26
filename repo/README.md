# Pacman repository

The published repository is arranged by MSYS2 subsystem and architecture:

```text
msys/x86_64/
```

Add the official MSYS repository first, then this repository in
`/etc/pacman.conf`:

```ini
[msys]
Include = /etc/pacman.d/mirrorlist.msys

[unofficial-msys2-packages]
Server = https://tienngtr.github.io/unofficial-msys2-packages/msys/$arch
```

Release snapshots contain detached package and repository signatures. Import
the project key before enabling signature enforcement:

```bash
pacman-key --add unofficial-msys2-packages-release-key.asc
pacman-key --lsign-key 4A2AE240769ECAF4AF545F62CE3CAC802B9E17AF
```

The key fingerprint is:

```text
4A2A E240 769E CAF4 AF54 5F62 CE3C AC80 2B9E 17AF
```

The repository remains experimental; verify the key fingerprint through an
independent channel before trusting release packages.
