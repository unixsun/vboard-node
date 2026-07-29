#!/usr/bin/env bash
set -euo pipefail

if [ "$(id -u)" -ne 0 ]; then
  echo "run this test as root" >&2
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEST_ROOT="$(mktemp -d)"
trap 'rm -rf "$TEST_ROOT"' EXIT

INSTALL_DIR="$TEST_ROOT/bin"
CONFIG_DIR="$TEST_ROOT/etc"
RUNTIME_DIR="$TEST_ROOT/runtime"
FAKE_BIN_DIR="$TEST_ROOT/fake-bin"
mkdir -p "$INSTALL_DIR" "$CONFIG_DIR" "$RUNTIME_DIR" "$FAKE_BIN_DIR"

cat >"$FAKE_BIN_DIR/systemctl" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF
chmod 0755 "$FAKE_BIN_DIR/systemctl"

cat >"$INSTALL_DIR/vboard-node" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF
chmod 0755 "$INSTALL_DIR/vboard-node"
ORIGINAL_SHA256="$(sha256sum "$INSTALL_DIR/vboard-node" | awk '{print $1}')"

cat >"$CONFIG_DIR/vboard-node.env" <<EOF
PANEL_URL=http://127.0.0.1:8080
SERVER_TOKEN=test-token
MACHINE_ID=1
KERNEL=sing-box
KERNEL_MODE=embedded
INTERVAL=15
RUNTIME_DIR=$RUNTIME_DIR
SING_BOX_BIN=sing-box
STATS_API=127.0.0.1:10085
ENABLE_KERNEL=false
ENABLE_UPGRADE=false
CERTIFICATE_PATH=
PRIVATE_KEY_PATH=
EOF

FAIL_BINARY="$TEST_ROOT/failing-vboard-node"
cat >"$FAIL_BINARY" <<'EOF'
#!/usr/bin/env bash
if [ "${1:-}" = "--help" ]; then
  exit 0
fi
exit 42
EOF
chmod 0755 "$FAIL_BINARY"
FAIL_SHA256="$(sha256sum "$FAIL_BINARY" | awk '{print $1}')"

set +e
OUTPUT="$(
  PATH="$FAKE_BIN_DIR:$PATH" bash "$SCRIPT_DIR/install.sh" upgrade \
    --install-dir "$INSTALL_DIR" \
    --config-dir "$CONFIG_DIR" \
    --runtime-dir "$RUNTIME_DIR" \
    --binary-url "file://$FAIL_BINARY" \
    --binary-sha256 "$FAIL_SHA256" 2>&1
)"
EXIT_CODE=$?
set -e

if [ "$EXIT_CODE" -eq 0 ]; then
  echo "expected the injected self-test failure" >&2
  exit 1
fi

grep -q "upgrade failed; restoring backup" <<<"$OUTPUT"
grep -q "backup restored" <<<"$OUTPUT"

RESTORED_SHA256="$(sha256sum "$INSTALL_DIR/vboard-node" | awk '{print $1}')"
if [ "$RESTORED_SHA256" != "$ORIGINAL_SHA256" ]; then
  echo "installer did not restore the previous binary" >&2
  exit 1
fi

echo "installer rollback test passed"
