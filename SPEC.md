# Verified Version specification

## Purpose

`vv <tool>` converts a tool's reported version into exactly one numeric
version triple:

```text
X.Y.Z
```

The command is deterministic, local, non-interactive, and suitable for shell
automation. “Verified” means that a strict upstream response is validated
against this contract. It does not mean cryptographic, publisher, provenance,
or binary verification.

## Command interface

```text
vv <tool>               print the tool version as X.Y.Z
vv --verified-version   print the vv version
vv --version            print the vv version
vv -h                   show help
```

No argument and `--help` also show help. Unknown options exit two. Normal
lookups and informational commands exit zero.

Only the first positional tool argument is used.

## Result contract

A normal tool lookup must:

- Write exactly one line to standard output.
- Match `^[0-9]+\.[0-9]+\.[0-9]+$`.
- Exit zero.
- Produce no separate diagnostic output.

Missing, empty, failed, timed-out, or unparseable results become `0.0.0`.

`0.0.0` is both a valid strict upstream version and the unknown sentinel.
Consumers that receive it cannot distinguish those two cases.

## Strict upstream protocol

A tool may implement:

```text
tool --verified-version
```

A valid response must:

- Print exactly one line.
- Contain three dot-separated non-negative integers.
- Use no leading zeroes except for the integer zero.
- Include no label, prefix, suffix, color, prerelease, build metadata, or
  additional output.
- Exit zero.
- Avoid network access, prompts, input, and side effects.

Examples of valid output are `0.0.0`, `1.2.3`, and `4200.0.0`.

## Lookup behavior

For a command that resolves through `command -v`, `vv` tries these sources in
order and takes the first that yields a dotted numeric version:

1. A declared version file at `<prefix>/share/vv/<tool>`, read without executing
   the tool (`<prefix>` is derived from the resolved `.../bin/<tool>` path).
2. The strict upstream protocol, `<tool> --verified-version`.
3. A tool-agnostic ladder of common version flags, in order: `--version`,
   `-version`, `version`, `-V`, `-v`.

From every source `vv` extracts the first dotted numeric sequence and normalizes
it to three components. Bare integers are not accepted, because an unadorned
number in help text is the main source of false positives. The same procedure
applies to every tool; `vv` never names or special-cases a specific command.

If `timeout` or `gtimeout` is available, command execution is limited by
`VV_TIMEOUT`, which defaults to five seconds. Without either utility, no
external timeout is enforced.

Ladder invocations ignore non-zero exit status except timeout status 124: a tool
that prints a usable version while exiting non-zero is still accepted, but a
timed-out invocation is rejected. If no source yields a dotted version, the
result is `0.0.0`.

A command that resolves to a path inside a macOS application bundle (`*.app`) is
never executed, because even a bundled command-line stub (for example `subl`) may
open a window on an unknown option. Such a tool resolves only through the
declarative `share/vv/<tool>` file described above; otherwise it is `0.0.0`.

## Normalization

Generic extraction:

1. Removes basic ANSI control sequences.
2. Selects the first dotted numeric sequence (`X.Y[.Z...]`).
3. If none exists, the value is empty and the result is `0.0.0`. A bare integer
   with no dot is not treated as a version.

Normalization then:

- Removes one leading `v` or `V`.
- Uses at most the first three dot-separated components.
- Fills missing components with zero.
- Removes leading zeroes from every component.
- Replaces missing or non-numeric components with zero.

Examples:

| Input | Result |
| --- | --- |
| `v1.2.3` | `1.2.3` |
| `2.7` | `2.7.0` |
| `4200` (no dot) | `0.0.0` |
| `01.002.0003` | `1.2.3` |
| no version | `0.0.0` |

## Compatibility

`vv` keeps no per-command exceptions. A tool becomes fully compatible either by
shipping a `share/vv/<tool>` version file (declarative, no execution) or by
implementing `--verified-version`. Failing that, the generic flag ladder is
tried. A tool becomes compatible by declaring or reporting a dotted version;
anything else is `0.0.0`. `vv` never adapts its invocation to a specific tool.

The sole built-in guard is generic: a command that resolves inside a macOS
application bundle (`*.app`) is never executed, because bundled launchers and
stubs may open a window on an unknown option. Inside a bundle, only the
declarative `share/vv/<tool>` file can resolve a version. There are no user
recipes, sourced configuration files, or configurable parser functions.

## Website contract

The website and README use the same core language:

- “Verified Version”
- “One strict SemVer triple, always.”
- “Give it a tool, get back strict X.Y.Z. Never blank, never noise.”
- “Missing or unparseable becomes 0.0.0. POSIX sh, no build.”

The primary installation command is:

```sh
brew install geo4orce/tap/vv
```

The website remains a static, responsive, accessible page with no build step.
All styling lives in `styles.css`; HTML files contain no inline styles. The
only JavaScript progressively enhances the install-command copy button. Core
content and navigation work without it. Social previews use the local
`og-image.png`, and supported Apple devices use the local
`apple-touch-icon.png`.

## Non-goals

- Cryptographic or supply-chain verification.
- Network-based version discovery.
- Preserving SemVer prerelease or build metadata.
- Running arbitrary version-command arguments supplied by the caller.
- User-defined compatibility recipes.
- A native Windows implementation.

## Acceptance

A release is acceptable when:

- The shell suite passes on Ubuntu and macOS.
- Shellcheck passes for `vv` and `tests/test.sh`.
- The generic protocol and the application-bundle rule have representative
  fixtures.
- Version output remains one strict line with the documented exit status.
- The website has no horizontal overflow or console errors at desktop and
  mobile sizes.
- `README.md` and `index.html` use consistent product language and install
  instructions.
