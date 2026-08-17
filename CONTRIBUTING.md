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
Then `vv` needs no recipe.

## Compatibility exceptions

An internal compatibility exception is a last resort. Add one only when
upstream `--verified-version` is impractical and normal version output needs
special handling.

1. First propose or implement `--verified-version` in the upstream tool.
2. If that is not practical, explain why in the pull request.
3. Update only the relevant compatibility function in `vv`.
4. Do not use the network, modify files, prompt, or cause side effects.
5. Add a fixture and assertion to `tests/test.sh`.
6. Run `sh tests/test.sh` and open a focused pull request.

All results must remain one strict `X.Y.Z` line with exit status `0`.

## Website

The website is static. Preview the repository root with any local web server.
Preserve semantic HTML, keyboard focus, contrast, and canonical metadata.
