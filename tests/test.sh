#!/bin/sh
set -eu

ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
VV=$ROOT/vv
TMP_ROOT=${TMPDIR:-/tmp}
TEST_DIR=$TMP_ROOT/vv-test-$$
BIN_DIR=$TEST_DIR/bin
FAILURES=0

cleanup() {
  rm -rf "$TEST_DIR"
}
trap cleanup EXIT HUP INT TERM
mkdir -p "$BIN_DIR"

fail() {
  printf 'not ok - %s\n' "$1"
  FAILURES=$((FAILURES + 1))
}

check_version() {
  _name=$1
  _expected=$2
  shift 2
  _output=$TEST_DIR/output

  set +e
  "$@" >"$_output" 2>"$TEST_DIR/error"
  _status=$?
  set -e

  _actual=$(cat "$_output")
  _lines=$(wc -l <"$_output" | tr -d ' ')

  if [ "$_status" -eq 0 ] && [ "$_lines" -eq 1 ] && \
    [ "$_actual" = "$_expected" ] && \
    grep -Eq '^[0-9]+\.[0-9]+\.[0-9]+$' "$_output"; then
    printf 'ok - %s\n' "$_name"
  else
    fail "$_name (status=$_status output=$_actual lines=$_lines)"
  fi
}

cat >"$BIN_DIR/strict-tool" <<'EOF'
#!/bin/sh
case ${1:-} in
  -vv) printf '3.4.5\n' ;;
  --version) printf 'strict-tool 9.9.9\n' ;;
  *) exit 1 ;;
esac
EOF

cat >"$BIN_DIR/generic-tool" <<'EOF'
#!/bin/sh
case ${1:-} in
  -vv) printf 'not-semver\n' ;;
  --version) printf 'generic-tool version 2.7\n' ;;
  *) exit 1 ;;
esac
EOF

cat >"$BIN_DIR/integer-tool" <<'EOF'
#!/bin/sh
case ${1:-} in
  -vv) exit 1 ;;
  --version) printf 'Build 4200\n' ;;
  *) exit 1 ;;
esac
EOF

cat >"$BIN_DIR/failed-tool" <<'EOF'
#!/bin/sh
printf 'error 999\n'
exit 1
EOF

cat >"$BIN_DIR/go" <<'EOF'
#!/bin/sh
[ "${1:-}" = version ] || exit 1
printf 'go version go1.26.4 test/arch\n'
EOF

cat >"$BIN_DIR/kubectl" <<'EOF'
#!/bin/sh
[ "${1:-}" = version ] && [ "${2:-}" = --client ] || exit 1
printf 'Client Version: v1.30.2\n'
EOF

cat >"$BIN_DIR/terraform" <<'EOF'
#!/bin/sh
[ "${1:-}" = version ] || exit 1
printf 'Terraform v1.9.8\n'
EOF

chmod 755 "$BIN_DIR"/*

check_version 'self version' '1.0.2' "$VV" -vv
check_version 'missing tool' '0.0.0' "$VV" vv-missing-test-tool
check_version 'strict -vv' '3.4.5' env PATH="$BIN_DIR:$PATH" "$VV" strict-tool
check_version 'malformed -vv fallback' '2.7.0' env PATH="$BIN_DIR:$PATH" "$VV" generic-tool
check_version 'integer build' '4200.0.0' env PATH="$BIN_DIR:$PATH" "$VV" integer-tool
check_version 'failed command' '0.0.0' env PATH="$BIN_DIR:$PATH" "$VV" failed-tool
check_version 'go recipe' '1.26.4' env PATH="$BIN_DIR:$PATH" VV_RECIPES="$ROOT/recipes" "$VV" go
check_version 'kubectl recipe' '1.30.2' env PATH="$BIN_DIR:$PATH" VV_RECIPES="$ROOT/recipes" "$VV" kubectl
check_version 'terraform recipe' '1.9.8' env PATH="$BIN_DIR:$PATH" VV_RECIPES="$ROOT/recipes" "$VV" terraform

PREFIX=$TEST_DIR/prefix
VV_SOURCE_DIR=$ROOT sh "$ROOT/install.sh" --prefix "$PREFIX" >/dev/null
check_version 'installed version' '1.0.2' "$PREFIX/bin/vv" -vv
check_version 'installed recipe' '1.26.4' env PATH="$BIN_DIR:$PATH" "$PREFIX/bin/vv" go
sh "$ROOT/install.sh" --uninstall --prefix "$PREFIX" >/dev/null
if [ -e "$PREFIX/bin/vv" ]; then
  fail 'uninstall'
else
  printf 'ok - uninstall\n'
fi

if [ "$FAILURES" -ne 0 ]; then
  printf '%s test(s) failed\n' "$FAILURES" >&2
  exit 1
fi

printf '%s\n' 'all tests passed'
