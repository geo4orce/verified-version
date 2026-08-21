#!/bin/sh
set -eu

ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
VV=$ROOT/vv
TMP_ROOT=${TMPDIR:-/tmp}
TEST_DIR=$TMP_ROOT/vv-test-$$
BIN_DIR=$TEST_DIR/bin
EXPECTED_VERSION=$(cat "$ROOT/VERSION")
FAILURES=0

IS_MACOS=0
case $(uname -s) in
  Darwin) IS_MACOS=1 ;;
esac

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

check_exit_zero() {
  _name=$1
  shift

  set +e
  "$@" >"$TEST_DIR/output" 2>"$TEST_DIR/error"
  _status=$?
  set -e

  if [ "$_status" -eq 0 ]; then
    printf 'ok - %s\n' "$_name"
  else
    fail "$_name (status=$_status)"
  fi
}

check_contains() {
  _name=$1
  _needle=$2
  shift 2

  set +e
  "$@" >"$TEST_DIR/output" 2>"$TEST_DIR/error"
  _status=$?
  set -e

  if [ "$_status" -eq 0 ] && grep -qF "$_needle" "$TEST_DIR/output"; then
    printf 'ok - %s\n' "$_name"
  else
    fail "$_name (status=$_status output=$(cat "$TEST_DIR/output"))"
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

cat >"$BIN_DIR/dashversion-tool" <<'EOF'
#!/bin/sh
[ "${1:-}" = -version ] || exit 1
printf 'DashVersion Tool -version 8.4.1\n'
EOF

cat >"$BIN_DIR/subcommand-tool" <<'EOF'
#!/bin/sh
[ "${1:-}" = version ] || exit 1
printf 'subcommand-tool version 1.2.3\n'
EOF

cat >"$BIN_DIR/upperflag-tool" <<'EOF'
#!/bin/sh
[ "${1:-}" = -V ] || exit 1
printf 'upperflag-tool 1.9.8\n'
EOF

cat >"$BIN_DIR/lowerflag-tool" <<'EOF'
#!/bin/sh
[ "${1:-}" = -v ] || exit 1
printf 'v3.4\n'
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
  --version) printf 'nonzero-tool 6.1\n'; exit 3 ;;
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

cat >"$BIN_DIR/integer-only-tool" <<'EOF'
#!/bin/sh
case ${1:-} in
  --version) printf 'Build 4200\n' ;;
  *) exit 1 ;;
esac
EOF

cat >"$BIN_DIR/noversion-tool" <<'EOF'
#!/bin/sh
case ${1:-} in
  --version) printf 'usage: noversion-tool [-v] [file]\n' ;;
  *) exit 1 ;;
esac
EOF

cat >"$BIN_DIR/failed-tool" <<'EOF'
#!/bin/sh
printf 'error 999\n'
exit 1
EOF

cat >"$BIN_DIR/timed-tool" <<'EOF'
#!/bin/sh
printf 'timed-tool 7.8.9\n'
exit 124
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

# Declarative source: a version file next to the bin, plus a binary that records
# if it is ever run. The file must win first, so the binary must stay untouched.
DECL_PREFIX="$TEST_DIR/opt/declared"
mkdir -p "$DECL_PREFIX/bin" "$DECL_PREFIX/share/vv"
cat >"$DECL_PREFIX/bin/declared-tool" <<EOF
#!/bin/sh
: >"$TEST_DIR/declared-ran"
printf 'declared-tool 9.9.9\n'
EOF
chmod 755 "$DECL_PREFIX/bin/declared-tool"
printf '5.6.7\n' >"$DECL_PREFIX/share/vv/declared-tool"

cat >"$DECL_PREFIX/bin/declared-zero-tool" <<EOF
#!/bin/sh
: >"$TEST_DIR/declared-zero-ran"
printf 'declared-zero-tool 9.9.9\n'
EOF
chmod 755 "$DECL_PREFIX/bin/declared-zero-tool"
printf '0.0.0\n' >"$DECL_PREFIX/share/vv/declared-zero-tool"

cat >"$DECL_PREFIX/bin/declared-integer-tool" <<EOF
#!/bin/sh
: >"$TEST_DIR/declared-integer-ran"
printf 'declared-integer-tool 9.9.9\n'
EOF
chmod 755 "$DECL_PREFIX/bin/declared-integer-tool"
printf '4200\n' >"$DECL_PREFIX/share/vv/declared-integer-tool"

# GUI launcher: the bundle entry point at Contents/MacOS/<App> must never run.
APP_MACOS_DIR="$TEST_DIR/Sample.app/Contents/MacOS"
mkdir -p "$APP_MACOS_DIR"
cat >"$APP_MACOS_DIR/Sample" <<EOF
#!/bin/sh
: >"$TEST_DIR/gui-launched"
printf '9.9.9\n'
EOF
chmod 755 "$APP_MACOS_DIR/Sample"
ln -s "$APP_MACOS_DIR/Sample" "$BIN_DIR/sample-gui"

# Bundled CLI without a declaration: inside a .app it must never be executed
# (even a safe-looking flag can pop a window, as subl does), so it is 0.0.0.
APP_CLI_DIR="$TEST_DIR/Sample.app/Contents/Resources/bin"
mkdir -p "$APP_CLI_DIR"
cat >"$APP_CLI_DIR/samplecli" <<EOF
#!/bin/sh
: >"$TEST_DIR/bundlecli-ran"
printf 'samplecli 7.8.9\n'
EOF
chmod 755 "$APP_CLI_DIR/samplecli"
ln -s "$APP_CLI_DIR/samplecli" "$BIN_DIR/samplecli"

# Bundled CLI that opts in with a declared version file: it resolves without
# being executed, the only way a tool inside a .app can report a version.
mkdir -p "$TEST_DIR/Sample.app/Contents/Resources/share/vv"
cat >"$APP_CLI_DIR/declaredcli" <<EOF
#!/bin/sh
: >"$TEST_DIR/declaredcli-ran"
printf 'declaredcli 9.9.9\n'
EOF
chmod 755 "$APP_CLI_DIR/declaredcli"
printf '4.5.6\n' >"$TEST_DIR/Sample.app/Contents/Resources/share/vv/declaredcli"
ln -s "$APP_CLI_DIR/declaredcli" "$BIN_DIR/declaredcli"

# plist reader: a bundle whose Info.plist has CFBundleShortVersionString must
# resolve that value without ever executing the bundled binary.
PLIST_CLI_DIR="$TEST_DIR/PlistSample.app/Contents/Resources/bin"
mkdir -p "$PLIST_CLI_DIR"
cat >"$TEST_DIR/PlistSample.app/Contents/Info.plist" <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>CFBundleShortVersionString</key>
	<string>4200</string>
</dict>
</plist>
EOF
cat >"$PLIST_CLI_DIR/plistcli" <<EOF
#!/bin/sh
: >"$TEST_DIR/plistcli-ran"
printf 'plistcli 9.9.9\n'
EOF
chmod 755 "$PLIST_CLI_DIR/plistcli"
ln -s "$PLIST_CLI_DIR/plistcli" "$BIN_DIR/plistcli"

# plist reader: a bundle with no CFBundleShortVersionString must fall back to
# CFBundleVersion, accepting a bare integer since the source is trusted.
PLIST_FALLBACK_DIR="$TEST_DIR/PlistFallbackSample.app/Contents/Resources/bin"
mkdir -p "$PLIST_FALLBACK_DIR"
cat >"$TEST_DIR/PlistFallbackSample.app/Contents/Info.plist" <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>CFBundleVersion</key>
	<string>4201</string>
</dict>
</plist>
EOF
cat >"$PLIST_FALLBACK_DIR/plistfallbackcli" <<EOF
#!/bin/sh
: >"$TEST_DIR/plistfallbackcli-ran"
printf 'plistfallbackcli 9.9.9\n'
EOF
chmod 755 "$PLIST_FALLBACK_DIR/plistfallbackcli"
ln -s "$PLIST_FALLBACK_DIR/plistfallbackcli" "$BIN_DIR/plistfallbackcli"

# nested bundle: use the nearest enclosing app's plist, not an outer bundle.
NESTED_PLIST_DIR="$TEST_DIR/Outer.app/Contents/Helpers/Inner.app/Contents/Resources/bin"
mkdir -p "$NESTED_PLIST_DIR"
cat >"$TEST_DIR/Outer.app/Contents/Info.plist" <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>CFBundleShortVersionString</key>
	<string>1.0.0</string>
</dict>
</plist>
EOF
cat >"$TEST_DIR/Outer.app/Contents/Helpers/Inner.app/Contents/Info.plist" <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>CFBundleShortVersionString</key>
	<string>2.3.4</string>
</dict>
</plist>
EOF
cat >"$NESTED_PLIST_DIR/nestedplistcli" <<EOF
#!/bin/sh
: >"$TEST_DIR/nestedplistcli-ran"
printf 'nestedplistcli 9.9.9\n'
EOF
chmod 755 "$NESTED_PLIST_DIR/nestedplistcli"
ln -s "$NESTED_PLIST_DIR/nestedplistcli" "$BIN_DIR/nestedplistcli"

# declared share/vv file must still beat the plist reader, even when the
# bundle's Info.plist carries a different, decoy version.
PLIST_DECLARED_DIR="$TEST_DIR/PlistDeclaredSample.app/Contents/Resources/bin"
mkdir -p "$PLIST_DECLARED_DIR" "$TEST_DIR/PlistDeclaredSample.app/Contents/Resources/share/vv"
cat >"$TEST_DIR/PlistDeclaredSample.app/Contents/Info.plist" <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>CFBundleShortVersionString</key>
	<string>9.9.9</string>
</dict>
</plist>
EOF
cat >"$PLIST_DECLARED_DIR/plistdeclaredcli" <<EOF
#!/bin/sh
: >"$TEST_DIR/plistdeclaredcli-ran"
printf 'plistdeclaredcli 9.9.9\n'
EOF
chmod 755 "$PLIST_DECLARED_DIR/plistdeclaredcli"
printf '4.5.6\n' >"$TEST_DIR/PlistDeclaredSample.app/Contents/Resources/share/vv/plistdeclaredcli"
ln -s "$PLIST_DECLARED_DIR/plistdeclaredcli" "$BIN_DIR/plistdeclaredcli"

# quarantine flag=: pico's real --version opens the editor, so vv must probe
# only -version and never fall back to the ladder.
cat >"$BIN_DIR/pico" <<EOF
#!/bin/sh
case \${1:-} in
  -version) printf 'Pico 5.09\n' ;;
  *) : >"$TEST_DIR/pico-badflag-used"; printf 'bad output\n'; exit 1 ;;
esac
EOF

# quarantine exec: docker resolves inside an app bundle, but its quarantine
# entry is `exec`, so vv must run it despite the .app guard.
DOCKER_APP_DIR="$TEST_DIR/FakeRancher.app/Contents/Resources/bin"
mkdir -p "$DOCKER_APP_DIR"
cat >"$DOCKER_APP_DIR/docker" <<'EOF'
#!/bin/sh
case ${1:-} in
  --version) printf 'Docker version 29.6.2-rd, build ede120b\n' ;;
  *) exit 1 ;;
esac
EOF
chmod 755 "$DOCKER_APP_DIR/docker"
ln -s "$DOCKER_APP_DIR/docker" "$BIN_DIR/docker"

# quarantine realpath match: an alias whose real binary is pico (like macOS
# nano, a symlink to pico) must inherit pico's flag=-version entry via the real
# binary's name, even though the alias name is not in the registry.
ln -s "$BIN_DIR/pico" "$BIN_DIR/mynano"

# a real binary literally named nano (like GNU nano) must NOT be quarantined:
# its real name is not in the registry, so it uses the safe --version ladder
# and its unsafe -version is never probed.
cat >"$BIN_DIR/nano" <<EOF
#!/bin/sh
case \${1:-} in
  --version) printf 'GNU nano, version 8.7\n' ;;
  -version) : >"$TEST_DIR/nano-badflag-used"; printf 'opened editor\n' ;;
  *) exit 1 ;;
esac
EOF

chmod 755 "$BIN_DIR"/*

check_version 'self verified version' "$EXPECTED_VERSION" "$VV" --verified-version
check_version 'self version' "$EXPECTED_VERSION" "$VV" --version
check_rejected 'old -vv rejected' "$VV" -vv
check_version 'missing tool' '0.0.0' "$VV" vv-missing-test-tool
check_version 'gold protocol wins over ladder' '3.4.5' env PATH="$BIN_DIR:$PATH" "$VV" strict-tool
check_version 'declared file wins without executing' '5.6.7' "$VV" "$DECL_PREFIX/bin/declared-tool"
check_version 'declared zero wins without executing' '0.0.0' "$VV" "$DECL_PREFIX/bin/declared-zero-tool"
check_version 'trusted bare-integer declaration wins without executing' '4200.0.0' "$VV" "$DECL_PREFIX/bin/declared-integer-tool"
check_version 'ladder --version' '2.7.0' env PATH="$BIN_DIR:$PATH" "$VV" generic-tool
check_version 'ladder -version' '8.4.1' env PATH="$BIN_DIR:$PATH" "$VV" dashversion-tool
check_version 'ladder version subcommand' '1.2.3' env PATH="$BIN_DIR:$PATH" "$VV" subcommand-tool
check_version 'ladder -V' '1.9.8' env PATH="$BIN_DIR:$PATH" "$VV" upperflag-tool
check_version 'ladder -v' '3.4.0' env PATH="$BIN_DIR:$PATH" "$VV" lowerflag-tool
check_version 'noisy protocol falls to ladder' '5.6.0' env PATH="$BIN_DIR:$PATH" "$VV" noisy-tool
check_version 'nonzero exit still parsed' '6.1.0' env PATH="$BIN_DIR:$PATH" "$VV" nonzero-tool
check_version 'leading zeros normalized' '1.2.3' env PATH="$BIN_DIR:$PATH" "$VV" zero-tool
check_version 'bare integer rejected' '0.0.0' env PATH="$BIN_DIR:$PATH" "$VV" integer-only-tool
check_version 'no version is 0.0.0' '0.0.0' env PATH="$BIN_DIR:$PATH" "$VV" noversion-tool
check_version 'failed command is 0.0.0' '0.0.0' env PATH="$BIN_DIR:$PATH" "$VV" failed-tool
check_version 'timed-out output is rejected' '0.0.0' env PATH="$BIN_DIR:$PATH" "$VV" timed-tool
check_version 'brew standard version' '5.0.3' env PATH="$BIN_DIR:$PATH" "$VV" brew
check_version 'man-db standard version' '2.13.1' env PATH="$BIN_DIR:$PATH" "$VV" man
check_version 'gui launcher path is dead' '0.0.0' "$VV" "$APP_MACOS_DIR/Sample"
check_version 'gui launcher via PATH symlink is dead' '0.0.0' env PATH="$BIN_DIR:$PATH" "$VV" sample-gui
check_version 'bundled cli without declaration is dead' '0.0.0' "$VV" "$APP_CLI_DIR/samplecli"
check_version 'bundled cli via PATH symlink is dead' '0.0.0' env PATH="$BIN_DIR:$PATH" "$VV" samplecli
check_version 'bundled cli with declared file resolves' '4.5.6' env PATH="$BIN_DIR:$PATH" "$VV" declaredcli
check_version 'quarantine matches via realpath alias (nano->pico)' '5.9.0' env PATH="$BIN_DIR:$PATH" "$VV" mynano
check_version 'real nano is not quarantined, uses safe ladder' '8.7.0' env PATH="$BIN_DIR:$PATH" "$VV" nano
check_version 'quarantine flag= uses only the safe flag' '5.9.0' env PATH="$BIN_DIR:$PATH" "$VV" pico
check_version 'quarantine exec runs despite .app guard' '29.6.2' env PATH="$BIN_DIR:$PATH" "$VV" docker

if [ "$IS_MACOS" -eq 1 ]; then
  check_version 'plist short-version resolves without executing' '4200.0.0' env PATH="$BIN_DIR:$PATH" "$VV" plistcli
  check_version 'plist falls back to CFBundleVersion' '4201.0.0' env PATH="$BIN_DIR:$PATH" "$VV" plistfallbackcli
  check_version 'nested app reads nearest plist' '2.3.4' env PATH="$BIN_DIR:$PATH" "$VV" nestedplistcli
  check_version 'declared file still beats plist' '4.5.6' env PATH="$BIN_DIR:$PATH" "$VV" plistdeclaredcli
fi

check_contains 'quarantine list includes pico' 'pico' "$VV" --quarantine
check_contains 'quarantine list includes docker' 'docker' "$VV" --quarantine
check_contains 'quarantine list includes actions' 'flag=-version' "$VV" --quarantine
check_contains 'quarantine list includes reasons' 'opens the editor' "$VV" --quarantine
check_contains 'quarantine explain includes action' '(flag=-version)' "$VV" --quarantine pico
check_contains 'quarantine explain includes reason' 'opens the editor' "$VV" --quarantine pico
check_contains 'flag quarantine prefers strict protocol' 'implement --verified-version' "$VV" --quarantine pico
check_contains 'flag quarantine accepts conventional output' 'conventional --version' "$VV" --quarantine pico
check_contains 'flag quarantine offers declaration' 'share/vv' "$VV" --quarantine pico
check_contains 'app quarantine offers declaration' 'share/vv' "$VV" --quarantine docker
check_contains 'app quarantine explains bundle escape' 'outside the bundle' "$VV" --quarantine docker
check_exit_zero 'quarantine list exits zero' "$VV" --quarantine
check_exit_zero 'quarantine explain exits zero' "$VV" --quarantine pico
check_exit_zero 'quarantine unknown tool exits zero' "$VV" --quarantine vv-not-a-real-tool
check_contains 'unquarantined tool reports as such' 'not quarantined' "$VV" --quarantine vv-not-a-real-tool

if [ -f "$TEST_DIR/declared-ran" ]; then
  fail 'declared-tool was executed (a declared version file must resolve without running it)'
fi

if [ -f "$TEST_DIR/declared-zero-ran" ]; then
  fail 'declared-zero-tool was executed (0.0.0 is a valid declared version)'
fi

if [ -f "$TEST_DIR/declared-integer-ran" ]; then
  fail 'declared-integer-tool was executed (a trusted bare integer must resolve without running it)'
fi

if [ -f "$TEST_DIR/gui-launched" ]; then
  fail 'GUI launcher was executed (must never run <App>.app/Contents/MacOS/*)'
fi

if [ -f "$TEST_DIR/bundlecli-ran" ]; then
  fail 'bundled CLI inside a .app was executed (must never run a tool inside a .app)'
fi

if [ -f "$TEST_DIR/declaredcli-ran" ]; then
  fail 'declared bundled CLI was executed (declared file must resolve without running it)'
fi

if [ -f "$TEST_DIR/plistcli-ran" ]; then
  fail 'plistcli was executed (a .app tool must resolve via Info.plist without running it)'
fi

if [ -f "$TEST_DIR/plistfallbackcli-ran" ]; then
  fail 'plistfallbackcli was executed (a .app tool must resolve via Info.plist without running it)'
fi

if [ -f "$TEST_DIR/nestedplistcli-ran" ]; then
  fail 'nestedplistcli was executed (a nested .app tool must resolve via the nearest Info.plist)'
fi

if [ -f "$TEST_DIR/plistdeclaredcli-ran" ]; then
  fail 'plistdeclaredcli was executed (declared file must resolve without running it)'
fi

if [ -f "$TEST_DIR/pico-badflag-used" ]; then
  fail 'quarantined pico was probed with a flag other than the declared safe one'
fi

if [ -f "$TEST_DIR/nano-badflag-used" ]; then
  fail "real nano was probed with -version (must use the safe --version ladder, not pico's recipe)"
fi

if [ "$FAILURES" -ne 0 ]; then
  printf '%s test(s) failed\n' "$FAILURES" >&2
  exit 1
fi

printf '%s\n' 'all tests passed'
