# Basic Information

Here you'll find some basic information about the Zammad repository.

## Branches

The Zammad [repository](https://github.com/zammad/zammad) has several branches.

### `develop`

- Default GitHub branch
- Current unreleased development state of next major release
- Is the first instance where all features are being developed
- This branch will have open issues
- If current stable version is 1.1.0 this will become 1.2.0
- Unstable! Should not be used in production environment!
- Supported with minor- and security bug fixes.

### `stable`

- Current stable release
- Can be used for production
- Stable bug fixes will be merged from develop after evaluation of the developers
- Supported with minor- and security bug fixes.

### `stable-x.y`

- If your version is older and e.g. equals version 1.2.0 then the name of the
  branch is stable-1.2.
- No support for minor- and security bug fixes.

## Packages

- Zammad packages are built on [packager.io](https://packager.io).
- You can find all Zammad packages [on packager.io](https://packager.io/gh/zammad/zammad).
- Builds of new packages are triggered with every push to our GitHub repo
- If you fork the Zammad repo, you can use packager.io to get builds for your fork
- Just change the file `.pkgr.yml` to fit your needs
