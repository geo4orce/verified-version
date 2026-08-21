# Contributing

Keep changes small, portable, and POSIX `sh` compatible.

## Make your tool compatible

The preferred upstream integration is `--verified-version`:

```text
$ your-tool --verified-version
1.2.3
```

It must print exactly one `X.Y.Z` line, write no labels or color, and exit `0`.

A conventional, non-interactive `your-tool --version` is also compatible when
the tool is safe to probe and its output contains a dotted numeric version.
Labels and ordinary version suffixes are acceptable because `vv` extracts and
normalizes the numeric part. Prefer `--verified-version` when adding a new
machine-readable interface; keep `--version` familiar for people and scripts
that already expect it.

If the tool should not be executed, install a text file containing its version
at `<prefix>/share/vv/<tool>` beside `<prefix>/bin/<tool>`. Declarative files
are trusted, may contain a dotted version or a bare integer, and are checked
before every executable probe.

## Quarantine

The quarantine is a small inline registry for tools that are unsafe under the
generic flag ladder or whose enclosing macOS application reports a different
version. Inspect it with:

```text
$ vv --quarantine
$ vv --quarantine your-tool
```

The list reports each tool's action and reason. A direct lookup also explains
the applicable upstream fix.

- For `flag=<x>`, `vv` runs only the known-safe flag. Prefer adding
  `--verified-version`. Making the conventional `--version` path safe and
  version-bearing is also sufficient once the quarantine entry is removed.
  A `share/vv/<tool>` declaration works immediately and avoids execution.
- For `exec`, the CLI resolves inside a `.app` bundle whose metadata describes
  the containing application rather than the CLI. Ship a `share/vv/<tool>`
  declaration, make the bundle metadata authoritative for the CLI, or install
  the CLI outside the bundle. Once outside the bundle, `--verified-version` or
  a safe conventional `--version` can use the normal lookup path.

Quarantine is a documented exception, not a permanent compatibility recipe.
Keep each entry narrow, state the concrete reason, and remove it when the
ordinary lookup flow becomes correct and safe.

## Compatibility changes

`vv` follows one generic lookup flow for every tool, plus a small documented
quarantine list for the exceptions described above. Do not add tool-name
tables, custom arguments, recipes, or parser hooks outside that inline list.

1. First propose or implement `--verified-version` in the upstream tool.
2. Accept a safe conventional `--version` when that interface is appropriate.
3. If execution is undesirable, ship a declarative `share/vv/<tool>` file.
4. Keep fallback behavior tool-agnostic and free of side effects.
5. Add a focused fixture and assertion to `tests/test.sh`.
6. Run `sh tests/test.sh` and `shellcheck -s sh vv tests/test.sh`.
7. Keep the resulting commit focused.

All results must remain one strict `X.Y.Z` line with exit status `0`.

## Website

The website is static. Preview the repository root with any local web server.
Preserve semantic HTML, keyboard focus, contrast, and canonical metadata.
