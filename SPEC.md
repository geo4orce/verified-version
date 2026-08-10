# The `-vv` convention

A tool may support `-vv` as a machine-readable version command.

## Contract

- Print exactly one line matching `^[0-9]+\.[0-9]+\.[0-9]+$`.
- Write no label, prefix, suffix, color, or extra output.
- Exit `0` when the version is available.
- Avoid network access, prompts, and side effects.

Example:

```text
$ tool -vv
1.2.3
```

`vv` prefers a valid `-vv` response. Invalid output safely falls back to a
recipe or normal version parsing.
