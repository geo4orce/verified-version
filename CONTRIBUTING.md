# Contributing

Keep changes small, portable, and POSIX `sh` compatible.

## Make your tool compatible

The best contribution is adding `--verified-version` to the tool itself. If you
own or maintain the binary, implement this upstream:

```text
$ your-tool --verified-version
1.2.3
```

It must print exactly one `X.Y.Z` line, write no labels or color, and exit `0`.
Alternatively, install a text file containing a dotted version at
`<prefix>/share/vv/<tool>` beside `<prefix>/bin/<tool>`. A declarative version
file is checked first and lets `vv` resolve the version without running the
tool.

## Compatibility changes

`vv` intentionally has no per-command exceptions. Do not add tool-name tables,
custom arguments, recipes, or parser hooks.

1. First propose or implement `--verified-version` in the upstream tool.
2. If execution is undesirable, ship a declarative `share/vv/<tool>` file.
3. Keep fallback behavior tool-agnostic and free of side effects.
4. Add a focused fixture and assertion to `tests/test.sh`.
5. Run `sh tests/test.sh` and `shellcheck -s sh vv tests/test.sh`.
6. Open a focused pull request.

All results must remain one strict `X.Y.Z` line with exit status `0`.

## Website

The website is static. Preview the repository root with any local web server.
Preserve semantic HTML, keyboard focus, contrast, and canonical metadata.
