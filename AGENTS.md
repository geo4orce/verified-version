# Verified Version engineering context

## Two artifacts, one repository

This repository contains two deliberately separate artifacts for one product:

1. The `vv` command-line tool is installed and versioned software. Its code,
   compatibility behavior, tests, manual, completions, and release number live
   in this repository.
2. The verified-version.org website is a static explanation and installation
   page. Its production code has HTML, CSS, and one small clipboard script. It
   is not part of the command at runtime and has no independent package version.
   The dependency-free Node.js server under `tools/` is for local preview only.

Keep their implementation concerns separate:

- A CLI behavior change belongs in `vv`, `tests/test.sh`, `SPEC.md`, and when
  user-facing, `man/vv.1`.
- A website change belongs in `index.html`, `404.html`, `styles.css`,
  `site.js`, or a static image asset.
- `VERSION` and `VV_VERSION` version the CLI, not the website.
- The website may describe the CLI, but the CLI never reads website files.
- Website deployment must not install or execute the CLI.
- Homebrew packaging must not include website files.

They stay together while the website remains a tiny static front door for the
tool. Consider splitting only if the website gains a build system, backend,
dependencies, or an independent release cadence.

## Technical contract

`vv` is a small POSIX `sh` command for macOS and Linux. It accepts a tool
name and emits exactly one normalized numeric version line. There is no build
step, runtime service, database, or network lookup.

These invariants must remain true for normal lookups:

- Output is exactly one `X.Y.Z` line.
- Missing, failed, or unparseable tools produce `0.0.0`.
- Lookup results exit zero.
- Invalid `vv` options exit two.
- Commands run without prompts or standard input.

The detailed normative behavior is in `SPEC.md`.

## Lookup algorithm

The implementation is the single `vv` shell script.

1. Resolve the requested command with `command -v`.
2. Resolve symlinks and derive the command name, including from an explicit
   path.
3. Read `<prefix>/share/vv/<tool>` when the resolved command lives at
   `<prefix>/bin/<tool>` and the declaration contains a dotted version.
4. Return `0.0.0` without executing a command resolved inside a macOS `.app`
   bundle when no valid declaration exists.
5. Try `tool --verified-version` and accept only one strict numeric triple.
6. Try the generic flag ladder `--version`, `-version`, `version`, `-V`, and
   `-v`, taking the first dotted version even when the command exits non-zero.
7. Reject bare integers, empty output, and timed-out invocations, then normalize
   the first dotted version-like value.

## Compatibility policy

`vv` has no per-command compatibility exceptions, sourced recipes, or user
configuration files. Every tool follows the same declarative file, strict
protocol, and generic flag ladder. Compatibility should be added upstream by
shipping `<prefix>/share/vv/<tool>` or implementing `--verified-version`.

The only execution guard is structural: never probe a command resolved inside
a macOS `.app` bundle. Include representative fixtures for the generic ladder,
declarative files, strict protocol, and application-bundle guard.

## Repository map

- `vv`: complete command implementation.
- `VERSION`: release version used to check the embedded version.
- `tests/test.sh`: executable contract and protocol fixtures.
- `man/vv.1`: complete installed command reference.
- `completions/`: Bash, Zsh, and Fish completions.
- `index.html`: production website markup.
- `styles.css`: all production and 404-page styling.
- `site.js`: progressive enhancement for the install-command copy button only.
- `Makefile` and `tools/serve.mjs`: dependency-free local website preview.
- `404.html`, `favicon.svg`, `apple-touch-icon.png`, and `og-image.png`:
  static website support files.
- `SPEC.md`: normative product and behavior contract.
- `README.md`: deliberately short public introduction matching the website.
- `CONTRIBUTING.md`: human contribution guidance.

There is intentionally no `CHANGELOG.md`. Git tags and commit history are the
release history.

## Tests

Run:

```sh
sh tests/test.sh
shellcheck -s sh vv tests/test.sh
```

Every behavior change needs a focused fixture and assertion. Tests must verify
the one-line output and exit status contract, including that declarative and
application-bundle cases do not execute the target command.

Keep shell syntax portable. Do not add Bash-only syntax.

## Versioning and releases

Use semantic versioning for `vv` itself:

- Patch: fixes that preserve the public interface.
- Minor: backward-compatible commands or compatibility features.
- Major: incompatible output, exit-status, or lookup behavior.

For a version change:

1. Update `VERSION` and `VV_VERSION` in `vv`.
2. Update tests and the man-page date when behavior or documentation changes.
3. Run the complete test and shellcheck suite.
4. Commit the release state and create the matching `vX.Y.Z` Git tag.
5. After the tag exists, update the external Homebrew tap formula URL,
   checksum, version assertion, and installed file list.
6. Verify the tap formula installs and its test passes.

The Git tag releases the CLI source. The separate Homebrew tap publishes that
release to `brew`; pushing this repository alone does not update the formula.
The formula should install only `vv`, the manual, and shell completions.
Do not report a CLI release complete until the formula update is on the tap's
default branch and `brew install geo4orce/tap/vv` resolves to the new version.

## Website and deployment

The website is the static repository root. Its production files are
`index.html`, `404.html`, `styles.css`, `favicon.svg`,
`apple-touch-icon.png`, `og-image.png`, and `site.js`. Keep it semantic,
responsive, and free of a build step. Keep all styling in `styles.css`.
Production JavaScript is limited to the progressively enhanced copy button;
core content and navigation must work without it. Preserve canonical and social
metadata, the meta CSP, focus visibility, readable contrast, and no horizontal
overflow.

`main` automatically deploys the production site through DigitalOcean App
Platform. Application code and release details belong here. Use the
`infra` repository only for hosting, domain, DNS, redirect, TLS, or provider
configuration changes.

Preview the site locally from the repository root:

```sh
make serve
make serve PORT=3000
```

The preview server requires Node.js, installs no packages, binds only to
localhost, disables browser caching, and is not part of production deployment.

Validate the production HTML with the pinned, transient linter:

```sh
make lint
```

Keep HTML human-readable. Prefer structural layout over whitespace-sensitive
`<pre>` formatting when markup needs syntax highlighting or aligned columns.
Do not run Prettier over these files.

## Documentation ownership

- Put implementation and maintenance context in `AGENTS.md`.
- Put normative behavior and acceptance criteria in `SPEC.md`.
- Keep `README.md` short and consistent with `index.html`.
- Put installed command details in `man/vv.1`.
- Put public contribution procedure in `CONTRIBUTING.md`.
- Do not duplicate release history in a changelog.

Use ordinary hyphens, not em dashes.
