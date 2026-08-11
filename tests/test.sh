#!/bin/sh
set -eu

ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
VV=$ROOT/vv
TMP_ROOT=${TMPDIR:-/tmp}
TEST_DIR=$TMP_ROOT/vv-test-$$
BIN_DIR=$TEST_DIR/bin
RECIPE_DIR=$TEST_DIR/recipes
FAILURES=0

cleanup() {
  rm -rf "$TEST_DIR"
}
trap cleanup EXIT HUP INT TERM
mkdir -p "$BIN_DIR" "$RECIPE_DIR"
cp "$ROOT"/recipes/go "$ROOT"/recipes/kubectl "$ROOT"/recipes/nano \
  "$ROOT"/recipes/pico "$ROOT"/recipes/terraform "$RECIPE_DIR/"

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

check_rejected() {
  _name=$1
  shift

  set +e
  "$@" >"$TEST_DIR/output" 2>"$TEST_DIR/error"
  _status=$?
  set -e

  if [ "$_status" -ne 0 ]; then
    printf 'ok - %s\n' "$_name"
  else
    fail "$_name (status=$_status)"
  fi
}

cat >"$BIN_DIR/strict-tool" <<'EOF'
#!/bin/sh
case ${1:-} in
  --verified-version) printf '3.4.5\n' ;;
  --version) printf 'strict-tool 9.9.9\n' ;;
  *) exit 1 ;;
esac
EOF

cat >"$BIN_DIR/generic-tool" <<'EOF'
#!/bin/sh
case ${1:-} in
  --verified-version) printf 'not-semver\n' ;;
  --version) printf 'generic-tool version 2.7\n' ;;
  *) exit 1 ;;
esac
EOF

cat >"$BIN_DIR/integer-tool" <<'EOF'
#!/bin/sh
case ${1:-} in
  --verified-version) exit 1 ;;
  --version) printf 'Build 4200\n' ;;
  *) exit 1 ;;
esac
EOF

cat >"$BIN_DIR/noisy-tool" <<'EOF'
#!/bin/sh
case ${1:-} in
  --verified-version) printf '3.4.5\nextra\n' ;;
  --version) printf 'noisy-tool 5.6\n' ;;
  *) exit 1 ;;
esac
EOF

cat >"$BIN_DIR/nonzero-tool" <<'EOF'
#!/bin/sh
case ${1:-} in
  --verified-version) printf '8.8.8\n'; exit 1 ;;
  --version) printf 'nonzero-tool 6.1\n' ;;
  *) exit 1 ;;
esac
EOF

cat >"$BIN_DIR/zero-tool" <<'EOF'
#!/bin/sh
case ${1:-} in
  --verified-version) printf '01.2.3\n' ;;
  --version) printf 'zero-tool 01.002.0003\n' ;;
  *) exit 1 ;;
esac
EOF

cat >"$BIN_DIR/failed-tool" <<'EOF'
#!/bin/sh
printf 'error 999\n'
exit 1
EOF

cat >"$BIN_DIR/nano" <<'EOF'
#!/bin/sh
case ${1:-} in
  --verified-version) printf '9.9.9\n' ;;
  -version) printf 'GNU nano, version 8.4\n'; exit 1 ;;
  *) exit 1 ;;
esac
EOF

cp "$BIN_DIR/nano" "$BIN_DIR/pico"

cat >"$BIN_DIR/recipe-protocol-tool" <<'EOF'
#!/bin/sh
case ${1:-} in
  --verified-version) printf '7.8.9\n' ;;
  --version) printf 'recipe-protocol-tool 1.2.3\n' ;;
  *) exit 1 ;;
esac
EOF

cat >"$RECIPE_DIR/recipe-protocol-tool" <<'EOF'
VV_CMD="--version"
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

check_version 'self verified version' '2.1.0' "$VV" --verified-version
check_version 'self version' '2.1.0' "$VV" --version
check_rejected 'old -vv rejected' "$VV" -vv
check_version 'missing tool' '0.0.0' "$VV" vv-missing-test-tool
check_version 'strict protocol' '3.4.5' env PATH="$BIN_DIR:$PATH" "$VV" strict-tool
check_version 'malformed protocol fallback' '2.7.0' env PATH="$BIN_DIR:$PATH" "$VV" generic-tool
check_version 'extra output fallback' '5.6.0' env PATH="$BIN_DIR:$PATH" "$VV" noisy-tool
check_version 'nonzero protocol fallback' '6.1.0' env PATH="$BIN_DIR:$PATH" "$VV" nonzero-tool
check_version 'leading zero fallback' '1.2.3' env PATH="$BIN_DIR:$PATH" "$VV" zero-tool
check_version 'integer build' '4200.0.0' env PATH="$BIN_DIR:$PATH" "$VV" integer-tool
check_version 'failed command' '0.0.0' env PATH="$BIN_DIR:$PATH" "$VV" failed-tool
check_version 'recipe skips probe' '8.4.0' env PATH="$BIN_DIR:$PATH" VV_RECIPES="$RECIPE_DIR" "$VV" nano
check_version 'pico recipe' '8.4.0' env PATH="$BIN_DIR:$PATH" VV_RECIPES="$RECIPE_DIR" "$VV" pico
check_version 'upstream protocol precedes recipe' '7.8.9' env PATH="$BIN_DIR:$PATH" VV_RECIPES="$RECIPE_DIR" "$VV" recipe-protocol-tool
check_version 'go recipe' '1.26.4' env PATH="$BIN_DIR:$PATH" VV_RECIPES="$RECIPE_DIR" "$VV" go
check_version 'kubectl recipe' '1.30.2' env PATH="$BIN_DIR:$PATH" VV_RECIPES="$RECIPE_DIR" "$VV" kubectl
check_version 'terraform recipe' '1.9.8' env PATH="$BIN_DIR:$PATH" VV_RECIPES="$RECIPE_DIR" "$VV" terraform

PREFIX=$TEST_DIR/prefix
VV_SOURCE_DIR=$ROOT sh "$ROOT/install.sh" --prefix "$PREFIX" >/dev/null
check_version 'installed version' '2.1.0' "$PREFIX/bin/vv" --verified-version
check_version 'installed recipe' '1.26.4' env PATH="$BIN_DIR:$PATH" "$PREFIX/bin/vv" go
check_version 'installed nano recipe' '8.4.0' env PATH="$BIN_DIR:$PATH" "$PREFIX/bin/vv" nano
check_version 'installed pico recipe' '8.4.0' env PATH="$BIN_DIR:$PATH" "$PREFIX/bin/vv" pico
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
