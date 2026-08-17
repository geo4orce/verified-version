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

For a command that resolves through `command -v`, `vv`:

1. Derives the command name, including from an explicit path.
2. Tries the strict upstream protocol unless the internal compatibility policy
   marks the command unsafe to probe.
3. Runs the known fallback command or `--version`.
4. Extracts a version from the combined standard output and standard error.
5. Normalizes the extracted value to three numeric components.

If `timeout` or `gtimeout` is available, command execution is limited by
`VV_TIMEOUT`, which defaults to five seconds. Without either utility, no
external timeout is enforced.

Non-zero fallback commands are rejected unless the internal compatibility
policy explicitly allows that command's result.

## Normalization

Generic extraction:

1. Removes basic ANSI control sequences.
2. Selects the first dotted numeric sequence.
3. If none exists, selects the first integer.

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
| `4200` | `4200.0.0` |
| `01.002.0003` | `1.2.3` |
| no version | `0.0.0` |

## Compatibility exceptions

Known command exceptions are maintained in three internal tables in `vv`:

- Commands that must not receive the strict probe because an unknown option can
  cause side effects.
- Commands that use fallback arguments other than `--version`.
- Commands whose useful fallback output accompanies a non-zero exit.

There are no user recipes, sourced configuration files, or configurable parser
functions. Explicit tool paths use the policy for their final command name.

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

The website remains a static, responsive, accessible page with no JavaScript
and no build step. All styling lives in `styles.css`; HTML files contain no
inline styles.

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
- Every compatibility exception has a representative fixture.
- Version output remains one strict line with the documented exit status.
- The website has no horizontal overflow or console errors at desktop and
  mobile sizes.
- `README.md` and `index.html` use consistent product language and install
  instructions.
