#!/bin/sh
set -eu

ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
VV=$ROOT/vv
TMP_ROOT=${TMPDIR:-/tmp}
TEST_DIR=$TMP_ROOT/vv-test-$$
BIN_DIR=$TEST_DIR/bin
EXPECTED_VERSION=$(cat "$ROOT/VERSION")
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

cat >"$BIN_DIR/brew" <<'EOF'
#!/bin/sh
case ${1:-} in
  --verified-version) exit 1 ;;
  --version) printf 'Homebrew 5.0.3\n' ;;
  *) exit 1 ;;
esac
EOF

cat >"$BIN_DIR/man" <<'EOF'
#!/bin/sh
case ${1:-} in
  --verified-version) exit 1 ;;
  --version) printf 'man 2.13.1\n' ;;
  *) exit 1 ;;
esac
EOF

cat >"$BIN_DIR/smerge" <<'EOF'
#!/bin/sh
case ${1:-} in
  --verified-version) printf '9.9.9\n' ;;
  --version) printf 'Sublime Merge Build 2125\n' ;;
  *) exit 1 ;;
esac
EOF

cat >"$BIN_DIR/subl" <<'EOF'
#!/bin/sh
case ${1:-} in
  --verified-version) printf '9.9.9\n' ;;
  --version) printf 'Sublime Text Build 4200\n' ;;
  *) exit 1 ;;
esac
EOF

cat >"$BIN_DIR/sw_vers" <<'EOF'
#!/bin/sh
case ${1:-} in
  --verified-version) printf '9.9.9\n' ;;
  -productVersion) printf '26.6.1\n' ;;
  *) exit 1 ;;
esac
EOF

chmod 755 "$BIN_DIR"/*

check_version 'self verified version' "$EXPECTED_VERSION" "$VV" --verified-version
check_version 'self version' "$EXPECTED_VERSION" "$VV" --version
check_rejected 'old -vv rejected' "$VV" -vv
check_version 'missing tool' '0.0.0' "$VV" vv-missing-test-tool
check_version 'strict protocol' '3.4.5' env PATH="$BIN_DIR:$PATH" "$VV" strict-tool
check_version 'malformed protocol fallback' '2.7.0' env PATH="$BIN_DIR:$PATH" "$VV" generic-tool
check_version 'extra output fallback' '5.6.0' env PATH="$BIN_DIR:$PATH" "$VV" noisy-tool
check_version 'nonzero protocol fallback' '6.1.0' env PATH="$BIN_DIR:$PATH" "$VV" nonzero-tool
check_version 'leading zero fallback' '1.2.3' env PATH="$BIN_DIR:$PATH" "$VV" zero-tool
check_version 'integer build' '4200.0.0' env PATH="$BIN_DIR:$PATH" "$VV" integer-tool
check_version 'failed command' '0.0.0' env PATH="$BIN_DIR:$PATH" "$VV" failed-tool
check_version 'nano compatibility' '8.4.0' env PATH="$BIN_DIR:$PATH" "$VV" nano
check_version 'pico compatibility' '8.4.0' env PATH="$BIN_DIR:$PATH" "$VV" pico
check_version 'go compatibility' '1.26.4' env PATH="$BIN_DIR:$PATH" "$VV" go
check_version 'kubectl compatibility' '1.30.2' env PATH="$BIN_DIR:$PATH" "$VV" kubectl
check_version 'terraform compatibility' '1.9.8' env PATH="$BIN_DIR:$PATH" "$VV" terraform
check_version 'Homebrew standard version' '5.0.3' env PATH="$BIN_DIR:$PATH" "$VV" brew
check_version 'man-db standard version' '2.13.1' env PATH="$BIN_DIR:$PATH" "$VV" man
check_version 'smerge skips unsafe probe' '2125.0.0' env PATH="$BIN_DIR:$PATH" "$VV" smerge
check_version 'subl skips unsafe probe' '4200.0.0' env PATH="$BIN_DIR:$PATH" "$VV" subl
check_version 'subl path uses compatibility' '4200.0.0' "$VV" "$BIN_DIR/subl"
check_version 'macOS product version' '26.6.1' env PATH="$BIN_DIR:$PATH" "$VV" sw_vers

if [ "$FAILURES" -ne 0 ]; then
  printf '%s test(s) failed\n' "$FAILURES" >&2
  exit 1
fi

printf '%s\n' 'all tests passed'
