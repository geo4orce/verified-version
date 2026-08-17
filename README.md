# vv - Verified Version

One strict SemVer triple, always.

Give it a tool, get back strict `X.Y.Z`. Never blank, never noise.

Missing or unparseable becomes `0.0.0`. POSIX sh, no build.

```console
$ vv git
2.55.0
$ vv node
22.13.1
$ vv nope-xyz
0.0.0
```

## Install

```sh
brew install geo4orce/tap/vv
```

Homebrew works on macOS and Linux. You can also clone it from GitHub:

```sh
git clone https://github.com/geo4orce/verified-version.git
```

## Support

geo@web-opt.com
