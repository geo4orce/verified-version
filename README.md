# Verified Version

One strict SemVer triple, always.

Give it a tool. Get strict `X.Y.Z`.

Missing or unparseable? Becomes `0.0.0`.

Maintaining a tool? See [CONTRIBUTING.md](CONTRIBUTING.md) for compatibility
guidance, including how to inspect and leave the quarantine list.

## Install

```console
$ brew install geo4orce/tap/vv
```

## Examples

```console
$ vv git       2.55.0
$ vv node      26.6.0
$ vv nope-xyz  0.0.0
```

POSIX sh. No build.

## Local preview

```console
$ make serve
```

Open <http://localhost:8000>. To use another port, run
`make serve PORT=3000`. The development server uses Node.js, has no package
dependencies, and does not participate in production deployment.

Validate both HTML pages with:

```console
$ make lint
```

The linter is pinned and runs through `npx`, so no `package.json` or local
dependency installation is required.

## Support

geo@web-opt.com
