# OS Packages

Package lists for `apt-get install`, organized by distro family and version.

## Merge order

The build script reads files in this sequence:

1. `common.env` — packages for all distros and versions
2. `ubuntu/common.env` — packages for all Ubuntu versions
3. `ubuntu/<version>.env` — Ubuntu version-specific overlays (20.04, 22.04, 24.04)
4. `debian/common.env` — packages for all Debian versions (future)

`apt-get install` deduplicates automatically — the same package listed in
multiple files is harmless.

## File format

One package name per line. Blank lines and starting with `#` are ignored.

## Adding a new package

- If it's needed on all distros → add to `common.env`
- If it's Ubuntu-only → add to `ubuntu/common.env`
- If it's Ubuntu version-specific → add to the matching `ubuntu/<version>.env`
