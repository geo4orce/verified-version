# vv - Verified Version

`vv <tool>` prints one strict version triple: `X.Y.Z`.

```console
$ vv git
2.55.0
$ vv nope
0.0.0
```

Missing or unparseable versions produce `0.0.0`. Lookups always exit `0`.

## Install

```sh
curl -fsSLO https://verified-version.org/install.sh
sh install.sh
```

Or clone it:

```sh
git clone https://github.com/geo4orce/verified-version.git
./verified-version/vv --verified-version
```

## Usage

```text
vv <tool>               print the tool version as X.Y.Z
vv --verified-version   print the vv version
vv --version            print the vv version
vv -h                   show help
```

## Compatibility

A tool may implement `--verified-version` for machine-readable output:

```text
$ tool --verified-version
1.2.3
```

The command must:

- Print exactly one `X.Y.Z` line using non-negative integers without leading zeroes.
- Write no label, prefix, suffix, color, or extra output.
- Exit `0` without network access, prompts, or side effects.

The output follows the three numeric components of
[Semantic Versioning 2.0.0](https://semver.org/). `vv` tries this protocol,
then a trusted recipe, then `<tool> --version`.

## Contribute

Tool owners should implement `--verified-version` upstream when possible.

Otherwise, see [CONTRIBUTING.md](CONTRIBUTING.md) for the small recipe format.

## Development

```sh
sh tests/test.sh
```

## Contact

Website: <https://verified-version.org/>.
Email: <geo@web-opt.com>
