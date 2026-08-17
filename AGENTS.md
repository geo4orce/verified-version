# Verified Version engineering context

## Two artifacts, one repository

This repository contains two deliberately separate artifacts for one product:

1. The `vv` command-line tool is installed and versioned software. Its code,
   compatibility behavior, tests, manual, completions, and release number live
   in this repository.
2. The verified-version.org website is a static explanation and installation
   page. It has HTML, CSS, and one small clipboard script. It is not part of the
   command at runtime and has no independent package version.

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
2. Derive the command name from the argument, including an explicit path.
3. Unless the internal compatibility table marks that command unsafe to probe,
   try `tool --verified-version` and accept only one strict numeric triple.
4. Run the fallback arguments selected by the internal compatibility table, or
   `tool --version` by default.
5. Reject empty output, timeouts, and non-zero exits unless that known command
   is explicitly allowed to return non-zero.
6. Extract and normalize the first version-like value.

## Compatibility policy

Compatibility exceptions are explicit functions in `vv`; there are no sourced
recipes or user configuration files. Keep these three decisions distinct:

- `vv_probe_is_safe`: commands that may receive `--verified-version` without
  side effects.
- `vv_run_fallback`: the exact fallback arguments for known commands.
- `vv_fallback_allows_nonzero`: known commands whose useful version output is
  accompanied by a non-zero exit.

Add an exception only for confirmed real-world behavior. Include a fixture and
test for every exception. Prefer upstream adoption of `--verified-version` so
the exception can eventually be removed.

## Repository map

- `vv`: complete command implementation.
- `VERSION`: release version used to check the embedded version.
- `tests/test.sh`: executable contract and compatibility fixtures.
- `man/vv.1`: complete installed command reference.
- `completions/`: Bash, Zsh, and Fish completions.
- `index.html`: production website markup.
- `styles.css`: all production and 404-page styling.
- `site.js`: progressive enhancement for the install-command copy button only.
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

Every behavior change needs a focused fixture and assertion. Every compatibility
exception must be tested against representative output. Tests must verify the
one-line output and exit status contract.

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

The Git tag releases the CLI source. The separate Homebrew tap publishes that
release to `brew`; pushing this repository alone does not update the formula.
The formula should install only `vv`, the manual, and shell completions.

## Website and deployment

The website is the static repository root. Its production files are
`index.html`, `404.html`, `styles.css`, `favicon.svg`,
`apple-touch-icon.png`, `og-image.png`, and `site.js`. Keep it semantic,
responsive, and free of a build step. Keep all styling in `styles.css`.
JavaScript is limited to the progressively enhanced copy button; core content
and navigation must work without it. Preserve canonical and social metadata,
the meta CSP, focus visibility, readable contrast, and no horizontal overflow.

`main` automatically deploys the production site through DigitalOcean App
Platform. Application code and release details belong here. Use the
`infra` repository only for hosting, domain, DNS, redirect, TLS, or provider
configuration changes.

## Documentation ownership

- Put implementation and maintenance context in `AGENTS.md`.
- Put normative behavior and acceptance criteria in `SPEC.md`.
- Keep `README.md` short and consistent with `index.html`.
- Put installed command details in `man/vv.1`.
- Put public contribution procedure in `CONTRIBUTING.md`.
- Do not duplicate release history in a changelog.

Use ordinary hyphens, not em dashes.
