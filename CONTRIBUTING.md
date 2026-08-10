# Contributing

Keep changes small, portable, and POSIX `sh` compatible.

## Prefer `-vv`

If you own the binary, prefer implementing `-vv` upstream:

```text
$ your-tool -vv
1.2.3
```

It must print exactly one `X.Y.Z` line, write no labels or color, and exit `0`.
Then `vv` needs no recipe.

## Recipes

Add a recipe only when upstream `-vv` is not practical and normal version
output needs special handling.

1. Copy `recipes/_template` to `recipes/<binary>`.
2. Use only `VV_CMD`, `VV_LINE`, `VV_GREP`, or `vv_extract()`.
3. Do not use the network, modify files, prompt, or cause side effects.
4. Add a fixture and assertion to `tests/test.sh`.
5. Run `sh tests/test.sh`.
6. Open a focused pull request.

All results must remain one strict `X.Y.Z` line with exit status `0`.

## Website

The website is static. Preview the repository root with any local web server.
Preserve semantic HTML, keyboard focus, contrast, and canonical metadata.
