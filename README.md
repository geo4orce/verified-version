# vv

`vv <tool>` prints one strict version triple: `X.Y.Z`.

Current release: `1.0.2`.

```console
$ vv git
2.55.0
$ vv nope
0.0.0
```

No tool, noise, or parseable version means `0.0.0`. Exit status is always `0`.

## Install

Inspect, then run the installer:

```sh
curl -fsSLO https://verified-version.org/install.sh
sh install.sh
```

Or clone it:

```sh
git clone https://github.com/geo4orce/verified-version.git
./verified-version/vv -vv
```

## Usage

```text
vv <tool>        print the tool version as X.Y.Z
vv -vv           print the vv version
vv -h            show help
```

`vv` first tries the optional [`-vv` convention](SPEC.md), then a trusted
recipe, then `<tool> --version`.

## Contribute

Tool owners should implement `-vv` upstream when possible. Otherwise, see
[CONTRIBUTING.md](CONTRIBUTING.md) for the small recipe format.

## Development

```sh
sh tests/test.sh
```

Website: <https://verified-version.org/>. MIT licensed.
