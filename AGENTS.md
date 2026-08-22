# Verified Version engineering context

## Two artifacts, one repository

This repository contains two deliberately separate artifacts for one product:

1. The `vv` command-line tool is installed and versioned software. Its code,
   behavior, tests, manual, completions, and release number live here.
2. The verified-version.org website is a static explanation and installation
   page. It has no independent package version. The dependency-free Node.js
   server under `tools/` is for local preview only.

Keep their implementation concerns separate:

- A CLI behavior change belongs in `vv`, `tests/test.sh`, and, when
  user-facing, `man/vv.1` or `CONTRIBUTING.md`.
- A website change belongs in `index.html`, `404.html`, `styles.css`,
  `site.js`, or a static image asset.
- `VERSION` and `VV_VERSION` version the CLI, not the website.
- The website may describe the CLI, but the CLI never reads website files.
- Website deployment must not install or execute the CLI.
- Homebrew packaging must not include website files.

Keep the artifacts together while the website remains a tiny static front
door. Consider splitting only if it gains a build system, backend,
dependencies, or an independent release cadence.

## CLI contract

`vv` is a small POSIX `sh` command for macOS and Linux. A normal lookup accepts
one tool name and must:

- Write exactly one `X.Y.Z` line to standard output.
- Produce `0.0.0` for missing, failed, timed-out, or unparseable tools.
- Exit zero and produce no separate diagnostic output.
- Run commands without prompts or standard input.

Invalid `vv` options exit two. Informational commands such as
`--quarantine` may emit explanatory text but exit zero.

The implementation is the single `vv` shell script. Its lookup order is:

1. Resolve the requested command with `command -v`, then follow symlinks.
2. Read a trusted `<prefix>/share/vv/<tool>` declaration when the resolved
   path is `<prefix>/bin/<tool>`. Declarations may contain a dotted version or
   a bare integer and always win without executing the tool.
3. Apply an exact quarantine entry by invoked name or resolved binary name.
4. For a non-quarantined command inside a macOS `.app`, read the nearest
   enclosing `Info.plist` without executing the command. Prefer
   `CFBundleShortVersionString`, then `CFBundleVersion`.
5. Try `tool --verified-version` and accept only one strict numeric triple.
6. Try `--version`, `-version`, `version`, `-V`, and `-v`, accepting the first
   dotted numeric version even when the command exits non-zero.
7. Reject bare integers from executable output, empty output, and timed-out
   invocations, then normalize the first accepted value to three components.

## Compatibility and quarantine

Prefer upstream `--verified-version` support. A safe conventional `--version`
is also compatible when the normal executable path is reachable. A trusted
`share/vv/<tool>` declaration is the non-executing option and works before all
other sources.

The only per-tool state is the small inline quarantine registry in `vv`. Each
row is `name|action|reason` and is queryable with `vv --quarantine [tool]`:

- `flag=<x>` runs only one known-safe flag and never the generic ladder.
- `exec` runs the protocol and ladder despite the `.app` execution guard.

Keep entries narrow and documented. A `flag=` entry can leave quarantine when
the tool implements `--verified-version`, makes conventional `--version` safe,
or ships a declaration. An app-bundled `exec` entry needs a declaration,
authoritative bundle metadata, or a CLI installed outside the bundle before
the execution exception can be removed.

Do not add sourced recipes, user configuration, parser hooks, or other
per-command tables. Put public compatibility guidance in `CONTRIBUTING.md`.

## Repository map

- `vv`: complete command implementation.
- `VERSION`: release version used to check the embedded version.
- `tests/test.sh`: executable CLI contract and protocol fixtures.
- `man/vv.1`: complete installed command reference.
- `completions/`: Bash, Zsh, and Fish completions.
- `README.md`: short public introduction matching the website.
- `CONTRIBUTING.md`: public compatibility and contribution guidance.
- `index.html`, `404.html`, `styles.css`, `favicon.svg`,
  `apple-touch-icon.png`, `og-image.png`, and `site.js`: production website.
- `Makefile` and `tools/serve.mjs`: dependency-free local website preview.

There is intentionally no `SPEC.md` or `CHANGELOG.md`. The command, tests, and
manual own CLI behavior; Git tags, GitHub Releases, and commit history own
release history.

## Tests

Run the complete CLI suite:

```sh
sh tests/test.sh
shellcheck -s sh vv tests/test.sh
```

Every behavior change needs a focused fixture and assertion. Verify the
one-line output and exit-status contract, including whether declarative,
application-bundle, and quarantine cases execute the target. `Info.plist`
fixtures require macOS; quarantine behavior and non-execution guards run on
both supported operating systems.

Keep shell syntax portable. Do not add Bash-only syntax.

## Versioning and releases

Use semantic versioning for `vv` itself:

- Patch: fixes that preserve the public interface.
- Minor: backward-compatible commands or compatibility features, including
  quarantine registry changes.
- Major: incompatible output, exit-status, or lookup behavior.

For a version change:

1. Update `VERSION`, `VV_VERSION` in `vv`, and any CLI version displayed by
   `index.html`.
2. Update tests and the man-page date when behavior or documentation changes.
3. Run the complete local test and shellcheck suite.
4. Commit the release state, create the matching annotated `vX.Y.Z` Git tag,
   and push `main` and the tag atomically.
5. Create a GitHub Release named `vv X.Y.Z` from the tag, mark it latest, and
   verify the repository's latest-release page resolves to it.
6. Verify the source workflow passes on Ubuntu and macOS and the deployed
   website shows the intended CLI version.
7. Validate the tagged source checkout on macOS before publishing Homebrew.
8. Update the external Homebrew tap formula URL, checksum, version assertion,
   and installed file list.
9. Verify the tap's macOS workflow installs the formula and its test passes.

The Git tag and GitHub Release publish the CLI source. The separate Homebrew
tap publishes that release to `brew`; pushing this repository alone does not
update the formula. The formula installs only `vv`, the manual, and shell
completions. Do not report source publication complete until the tag, GitHub
Release, latest-release page, source workflow, and visible website version are
verified. Do not report the CLI release complete until the formula update is
on the tap's default branch and `brew install geo4orce/tap/vv` resolves to the
new version.

## Website and deployment

The website is the static repository root. Keep it semantic, responsive, and
free of a build step. Keep all styling in `styles.css`. Production JavaScript
is limited to the progressively enhanced copy button; core content and
navigation must work without it. Preserve canonical and social metadata, the
meta CSP, focus visibility, readable contrast, and no horizontal overflow.

The website does not need to expose internal compatibility or quarantine
details. Its primary installation command is:

```sh
brew install geo4orce/tap/vv
```

`main` automatically deploys the site through DigitalOcean App Platform. Use
the `infra` repository only for hosting, domain, DNS, redirect, TLS, or
provider configuration changes.

Preview and validate from the repository root:

```sh
make serve
make serve PORT=3000
make lint
```

The preview server installs no packages, binds only to localhost, disables
browser caching, and is not part of production deployment. `make lint` uses a
pinned transient HTML validator. Keep HTML human-readable and do not run
Prettier over it.

## Documentation ownership

- Keep `README.md` terse and public.
- Put installed command behavior in `man/vv.1`.
- Put tool-maintainer compatibility guidance in `CONTRIBUTING.md`.
- Keep implementation, testing, release, and deployment rules in `AGENTS.md`.
- Treat `tests/test.sh` as the executable acceptance contract.
- Do not recreate `SPEC.md` or duplicate release history in a changelog.

Use ordinary hyphens, not em dashes.
