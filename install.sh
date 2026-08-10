#!/bin/sh
set -eu

VV_INSTALL_VERSION=${VV_INSTALL_VERSION:-1.0.2}
VV_PREFIX=${VV_PREFIX:-"$HOME/.local"}
VV_MODE=install

usage() {
  cat <<EOF
Install vv $VV_INSTALL_VERSION

Usage:
  sh install.sh [--prefix DIR]
  sh install.sh --uninstall [--prefix DIR]
EOF
}

while [ $# -gt 0 ]; do
  case $1 in
    --prefix)
      [ $# -ge 2 ] || { printf '%s\n' 'missing --prefix value' >&2; exit 1; }
      VV_PREFIX=$2
      shift 2
      ;;
    --uninstall)
      VV_MODE=uninstall
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      printf 'unknown option: %s\n' "$1" >&2
      exit 1
      ;;
  esac
done

case $VV_PREFIX in
  ''|/)
    printf '%s\n' 'refusing unsafe prefix' >&2
    exit 1
    ;;
esac

VV_BIN_DIR=$VV_PREFIX/bin
VV_SHARE_DIR=$VV_PREFIX/share/vv
VV_MAN_DIR=$VV_PREFIX/share/man/man1
VV_BASH_DIR=$VV_PREFIX/share/bash-completion/completions
VV_ZSH_DIR=$VV_PREFIX/share/zsh/site-functions
VV_FISH_DIR=$VV_PREFIX/share/fish/vendor_completions.d

if [ "$VV_MODE" = uninstall ]; then
  rm -f "$VV_BIN_DIR/vv" "$VV_MAN_DIR/vv.1" \
    "$VV_BASH_DIR/vv" "$VV_ZSH_DIR/_vv" "$VV_FISH_DIR/vv.fish"
  rm -rf "$VV_SHARE_DIR"
  printf 'removed vv from %s\n' "$VV_PREFIX"
  exit 0
fi

VV_TMP=
cleanup() {
  [ -z "$VV_TMP" ] || rm -rf "$VV_TMP"
}
trap cleanup EXIT HUP INT TERM

if [ -n "${VV_SOURCE_DIR:-}" ]; then
  VV_SOURCE=$VV_SOURCE_DIR
else
  VV_TMP=$(mktemp -d 2>/dev/null || mktemp -d -t vv)
  VV_ARCHIVE=$VV_TMP/vv.tar.gz
  VV_URL=https://github.com/geo4orce/verified-version/archive/refs/tags/v$VV_INSTALL_VERSION.tar.gz

  if command -v curl >/dev/null 2>&1; then
    curl -fsSL "$VV_URL" -o "$VV_ARCHIVE"
  elif command -v wget >/dev/null 2>&1; then
    wget -qO "$VV_ARCHIVE" "$VV_URL"
  else
    printf '%s\n' 'curl or wget is required' >&2
    exit 1
  fi

  tar -xzf "$VV_ARCHIVE" -C "$VV_TMP"
  set -- "$VV_TMP"/verified-version-*
  VV_SOURCE=$1
fi

[ -f "$VV_SOURCE/vv" ] || { printf '%s\n' 'vv source not found' >&2; exit 1; }

mkdir -p "$VV_BIN_DIR" "$VV_SHARE_DIR/recipes" "$VV_MAN_DIR" \
  "$VV_BASH_DIR" "$VV_ZSH_DIR" "$VV_FISH_DIR"

cp "$VV_SOURCE/vv" "$VV_BIN_DIR/vv"
chmod 755 "$VV_BIN_DIR/vv"
cp "$VV_SOURCE"/recipes/go "$VV_SOURCE"/recipes/kubectl \
  "$VV_SOURCE"/recipes/terraform "$VV_SHARE_DIR/recipes/"
cp "$VV_SOURCE/man/vv.1" "$VV_MAN_DIR/vv.1"
cp "$VV_SOURCE/completions/vv.bash" "$VV_BASH_DIR/vv"
cp "$VV_SOURCE/completions/_vv" "$VV_ZSH_DIR/_vv"
cp "$VV_SOURCE/completions/vv.fish" "$VV_FISH_DIR/vv.fish"

[ "$("$VV_BIN_DIR/vv" -vv)" = "$VV_INSTALL_VERSION" ] || {
  printf '%s\n' 'installed version does not match' >&2
  exit 1
}

printf 'installed vv %s to %s\n' "$VV_INSTALL_VERSION" "$VV_BIN_DIR/vv"
case :$PATH: in
  *:"$VV_BIN_DIR":*) ;;
  *) printf 'add %s to PATH\n' "$VV_BIN_DIR" ;;
esac
